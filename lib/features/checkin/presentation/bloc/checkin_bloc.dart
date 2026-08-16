import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/alarm_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/widget_sync_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/ticker.dart';
import '../../../../core/widgets/vigi_mascot.dart';
import '../../domain/entities/monitoring_mode_entity.dart';
import '../../domain/usecases/confirm_checkin_usecase.dart';
import '../../domain/usecases/create_custom_mode_usecase.dart';
import '../../domain/usecases/get_available_modes_usecase.dart';
import '../../domain/usecases/get_monitoring_status_usecase.dart';
import '../../domain/usecases/save_monitoring_settings_usecase.dart';
import '../../domain/usecases/start_monitoring_usecase.dart';
import '../../domain/usecases/stop_monitoring_usecase.dart';
import 'checkin_event.dart';
import 'checkin_state.dart';

class CheckinBloc extends Bloc<CheckinEvent, CheckinState> {
  CheckinBloc({
    required this.startMonitoringUseCase,
    required this.confirmCheckinUseCase,
    required this.stopMonitoringUseCase,
    required this.getMonitoringStatusUseCase,
    required this.getAvailableModesUseCase,
    required this.createCustomModeUseCase,
    required this.saveMonitoringSettingsUseCase,
    required this.ticker,
    required this.clock,
    required this.alarmService,
    required this.notificationService,
    this.widgetSyncService = const WidgetSyncServiceImpl(),
  }) : super(const CheckinInitial()) {
    on<LoadCheckinStatusRequested>(_onLoadCheckinStatusRequested);
    on<LoadAvailableModesRequested>(_onLoadAvailableModesRequested);
    on<SelectModeRequested>(_onSelectModeRequested);
    on<SaveMonitoringSettingsRequested>(_onSaveMonitoringSettingsRequested);
    on<StartMonitoringRequested>(_onStartMonitoringRequested);
    on<CreateCustomModeRequested>(_onCreateCustomModeRequested);
    on<ConfirmCheckinRequested>(_onConfirmCheckinRequested);
    on<StopMonitoringRequested>(_onStopMonitoringRequested);
    on<CheckinTickReceived>(_onCheckinTickReceived);
  }

  final StartMonitoringUseCase startMonitoringUseCase;
  final ConfirmCheckinUseCase confirmCheckinUseCase;
  final StopMonitoringUseCase stopMonitoringUseCase;
  final GetMonitoringStatusUseCase getMonitoringStatusUseCase;
  final GetAvailableModesUseCase getAvailableModesUseCase;
  final CreateCustomModeUseCase createCustomModeUseCase;
  final SaveMonitoringSettingsUseCase saveMonitoringSettingsUseCase;
  final Ticker ticker;
  final Clock clock;
  final AlarmService alarmService;
  final NotificationService notificationService;
  final WidgetSyncService widgetSyncService;

  StreamSubscription<int>? _tickerSubscription;
  int _currentIntervalMinutes = 60;
  int _savedRoutineIntervalMinutes = 60;
  List<MonitoringModeEntity> _availableModes = [];
  MonitoringModeEntity? _selectedMode;
  MonitoringModeEntity? _activeMode;

  MonitoringModeEntity? _findRoutineMode(List<MonitoringModeEntity> modes) {
    return modes
            .where(
              (m) =>
                  m.iconKey == 'routine' ||
                  m.name.toLowerCase().contains('rotina'),
            )
            .firstOrNull ??
        modes.where((m) => m.isSystemDefault).firstOrNull ??
        modes.firstOrNull;
  }

  bool _isTemporaryMode(MonitoringModeEntity? mode) {
    if (mode == null) return false;
    final nameLower = mode.name.toLowerCase();
    return mode.iconKey == 'shower' ||
        nameLower.contains('banho') ||
        mode.iconKey == 'sleep' ||
        nameLower.contains('sono');
  }

  void _syncWidget({
    required String vigiState,
    required int minutesRemaining,
    required bool isMonitoring,
  }) {
    unawaited(
      widgetSyncService.updateWidgetData(
        vigiState: vigiState,
        minutesRemaining: minutesRemaining,
        modeName: _activeMode?.name ?? _selectedMode?.name ?? 'Rotina padrão',
        isMonitoring: isMonitoring,
      ),
    );
  }

  Future<void> _onLoadCheckinStatusRequested(
    LoadCheckinStatusRequested event,
    Emitter<CheckinState> emit,
  ) async {
    emit(const CheckinLoading());

    // Carrega os modos disponíveis primeiro
    final modesResult = await getAvailableModesUseCase(const NoParams());
    modesResult.fold(
      (_) {},
      (modes) {
        _availableModes = modes;
      },
    );

    final result = await getMonitoringStatusUseCase(const NoParams());
    result.fold(
      (failure) => emit(CheckinFailure(failure.message)),
      (status) {
        // Atualiza o modo correspondente em _availableModes se houver intervalo salvo
        if (status.activeModeId != null) {
          _availableModes = _availableModes.map((m) {
            if (m.id == status.activeModeId) {
              return m.copyWith(
                defaultIntervalMinutes: status.intervalMinutes,
              );
            }
            return m;
          }).toList();
        }

        // Usa o intervalo salvo como verdade
        _currentIntervalMinutes = status.intervalMinutes;

        final routineMode = _findRoutineMode(_availableModes);
        if (routineMode != null && status.activeModeId == routineMode.id) {
          _savedRoutineIntervalMinutes = status.intervalMinutes;
        } else {
          _savedRoutineIntervalMinutes =
              routineMode?.defaultIntervalMinutes ?? 60;
        }

        // Identifica o modo ativo ou selecionado a partir do ID salvo
        if (status.activeMode != null) {
          _activeMode = status.activeMode;
        } else if (status.activeModeId != null) {
          _activeMode = _availableModes
              .where((m) => m.id == status.activeModeId)
              .firstOrNull;
        }

        if (status.active && status.nextDeadline != null) {
          _startTicker(status.nextDeadline!, activeMode: _activeMode);
        } else {
          _selectedMode =
              _activeMode ??
              _availableModes
                  .where((m) => m.id == status.activeModeId)
                  .firstOrNull ??
              routineMode;

          _syncWidget(
            vigiState: 'normal',
            minutesRemaining: _currentIntervalMinutes,
            isMonitoring: false,
          );

          emit(
            CheckinIdle(
              intervalMinutes: _currentIntervalMinutes,
              availableModes: _availableModes,
              selectedMode: _selectedMode,
            ),
          );
        }
      },
    );
  }

  Future<void> _onLoadAvailableModesRequested(
    LoadAvailableModesRequested event,
    Emitter<CheckinState> emit,
  ) async {
    final result = await getAvailableModesUseCase(const NoParams());
    result.fold(
      (failure) => emit(CheckinFailure(failure.message)),
      (modes) {
        _availableModes = modes;
        if (state is CheckinIdle) {
          final current = state as CheckinIdle;
          emit(
            current.copyWith(
              availableModes: _availableModes,
              selectedMode: current.selectedMode ?? _availableModes.firstOrNull,
            ),
          );
        }
      },
    );
  }

  void _onSelectModeRequested(
    SelectModeRequested event,
    Emitter<CheckinState> emit,
  ) {
    _selectedMode = event.mode;
    _currentIntervalMinutes = event.mode.defaultIntervalMinutes;
    if (state is CheckinIdle) {
      final current = state as CheckinIdle;
      if (_availableModes.isEmpty && current.availableModes.isNotEmpty) {
        _availableModes = current.availableModes;
      }
      emit(
        current.copyWith(
          selectedMode: _selectedMode,
          intervalMinutes: _currentIntervalMinutes,
        ),
      );
    }
  }

  Future<void> _onSaveMonitoringSettingsRequested(
    SaveMonitoringSettingsRequested event,
    Emitter<CheckinState> emit,
  ) async {
    final currentState = state;
    final modes = _availableModes.isNotEmpty
        ? _availableModes
        : (currentState is CheckinIdle
              ? currentState.availableModes
              : <MonitoringModeEntity>[]);

    final mode =
        modes.where((m) => m.id == event.modeId).firstOrNull ??
        _selectedMode ??
        (currentState is CheckinIdle ? currentState.selectedMode : null);

    emit(const CheckinLoading());

    final result = await saveMonitoringSettingsUseCase(
      SaveMonitoringSettingsParams(
        modeId: event.modeId,
        intervalMinutes: event.intervalMinutes,
      ),
    );

    result.fold(
      (failure) {
        emit(CheckinFailure(failure.message));
        emit(
          CheckinIdle(
            intervalMinutes: _currentIntervalMinutes,
            availableModes: modes,
            selectedMode: mode,
          ),
        );
      },
      (_) {
        _currentIntervalMinutes = event.intervalMinutes;

        // Atualiza a lista de modos com o novo intervalo para o modo configurado
        _availableModes = modes.map((m) {
          if (m.id == event.modeId) {
            return m.copyWith(defaultIntervalMinutes: event.intervalMinutes);
          }
          return m;
        }).toList();

        final updatedMode =
            _availableModes.where((m) => m.id == event.modeId).firstOrNull ??
            mode?.copyWith(defaultIntervalMinutes: event.intervalMinutes);

        _selectedMode = updatedMode;

        final routineMode = _findRoutineMode(_availableModes);
        if (event.modeId == routineMode?.id) {
          _savedRoutineIntervalMinutes = event.intervalMinutes;
        }

        emit(
          CheckinIdle(
            intervalMinutes: _currentIntervalMinutes,
            availableModes: _availableModes,
            selectedMode: _selectedMode,
          ),
        );
      },
    );
  }

  Future<void> _onStartMonitoringRequested(
    StartMonitoringRequested event,
    Emitter<CheckinState> emit,
  ) async {
    final currentState = state;
    if (_availableModes.isEmpty &&
        currentState is CheckinIdle &&
        currentState.availableModes.isNotEmpty) {
      _availableModes = currentState.availableModes;
    }

    final modes = _availableModes.isNotEmpty
        ? _availableModes
        : (currentState is CheckinIdle
              ? currentState.availableModes
              : <MonitoringModeEntity>[]);

    final mode =
        modes.where((m) => m.id == event.modeId).firstOrNull ??
        _selectedMode ??
        (currentState is CheckinIdle ? currentState.selectedMode : null);

    emit(const CheckinLoading());

    final effectiveInterval =
        event.intervalOverrideMinutes ??
        mode?.defaultIntervalMinutes ??
        _currentIntervalMinutes;

    _currentIntervalMinutes = effectiveInterval;
    _activeMode = mode;

    final result = await startMonitoringUseCase(
      StartMonitoringParams(
        modeId: event.modeId,
        intervalOverrideMinutes: event.intervalOverrideMinutes,
      ),
    );

    result.fold(
      (failure) {
        emit(CheckinFailure(failure.message));
        // Restaura para estado Idle
        emit(
          CheckinIdle(
            intervalMinutes: _currentIntervalMinutes,
            availableModes: modes,
            selectedMode: mode,
          ),
        );
      },
      (_) {
        final nextDeadline = clock.now().add(
          Duration(minutes: effectiveInterval),
        );
        _startTicker(nextDeadline, activeMode: _activeMode);
      },
    );
  }

  Future<void> _onCreateCustomModeRequested(
    CreateCustomModeRequested event,
    Emitter<CheckinState> emit,
  ) async {
    final currentState = state;
    final currentModes = _availableModes.isNotEmpty
        ? _availableModes
        : (currentState is CheckinIdle
              ? currentState.availableModes
              : <MonitoringModeEntity>[]);

    emit(const CheckinLoading());
    final result = await createCustomModeUseCase(
      CreateCustomModeParams(
        name: event.name,
        defaultIntervalMinutes: event.defaultIntervalMinutes,
        iconKey: event.iconKey,
      ),
    );

    result.fold(
      (failure) {
        emit(CheckinFailure(failure.message));
        emit(
          CheckinIdle(
            intervalMinutes: _currentIntervalMinutes,
            availableModes: currentModes,
            selectedMode: _selectedMode,
          ),
        );
      },
      (createdMode) {
        _availableModes = [...currentModes, createdMode];
        _selectedMode = createdMode;
        _currentIntervalMinutes = createdMode.defaultIntervalMinutes;
        emit(
          CheckinIdle(
            intervalMinutes: _currentIntervalMinutes,
            availableModes: _availableModes,
            selectedMode: _selectedMode,
          ),
        );
      },
    );
  }

  Future<void> _onConfirmCheckinRequested(
    ConfirmCheckinRequested event,
    Emitter<CheckinState> emit,
  ) async {
    // Interrompe o alarme se estiver soando
    unawaited(alarmService.stopAlert());
    unawaited(notificationService.cancelAlert());

    final currentState = state;
    if (_availableModes.isEmpty &&
        currentState is CheckinIdle &&
        currentState.availableModes.isNotEmpty) {
      _availableModes = currentState.availableModes;
    }

    final result = await confirmCheckinUseCase(
      ConfirmCheckinParams(
        latitude: event.latitude,
        longitude: event.longitude,
      ),
    );
    result.fold(
      (failure) => emit(CheckinFailure(failure.message)),
      (_) {
        // Se o usuário estava em modo temporário (Banho ou Sono), ao confirmar presença
        // retorna automaticamente para o modo de Rotina padrão com seu respectivo intervalo.
        if (_isTemporaryMode(_activeMode)) {
          final routineMode = _findRoutineMode(_availableModes);
          _activeMode = routineMode;
          _currentIntervalMinutes =
              routineMode?.defaultIntervalMinutes ??
              _savedRoutineIntervalMinutes;
        }

        final nextDeadline = clock.now().add(
          Duration(minutes: _currentIntervalMinutes),
        );
        _syncWidget(
          vigiState: 'normal',
          minutesRemaining: _currentIntervalMinutes,
          isMonitoring: true,
        );
        _startTicker(nextDeadline, activeMode: _activeMode);
      },
    );
  }

  Future<void> _onStopMonitoringRequested(
    StopMonitoringRequested event,
    Emitter<CheckinState> emit,
  ) async {
    await _tickerSubscription?.cancel();
    unawaited(alarmService.stopAlert());
    unawaited(notificationService.cancelAlert());

    emit(const CheckinLoading());
    final result = await stopMonitoringUseCase(const NoParams());
    result.fold(
      (failure) => emit(CheckinFailure(failure.message)),
      (_) {
        _activeMode = null;
        _syncWidget(
          vigiState: 'normal',
          minutesRemaining: _currentIntervalMinutes,
          isMonitoring: false,
        );
        emit(
          CheckinIdle(
            intervalMinutes: _currentIntervalMinutes,
            availableModes: _availableModes,
            selectedMode: _selectedMode,
          ),
        );
      },
    );
  }

  void _startTicker(DateTime deadline, {MonitoringModeEntity? activeMode}) {
    unawaited(_tickerSubscription?.cancel());
    _tickerSubscription = ticker.secondsUntil(deadline, clock: clock).listen((
      remaining,
    ) {
      add(
        CheckinTickReceived(
          remainingSeconds: remaining,
          nextDeadline: deadline,
          activeMode: activeMode,
        ),
      );
    });
  }

  void _onCheckinTickReceived(
    CheckinTickReceived event,
    Emitter<CheckinState> emit,
  ) {
    if (event.remainingSeconds <= 0) {
      unawaited(_tickerSubscription?.cancel());

      // Aciona som insistente, vibração contínua e notificação de alta prioridade
      unawaited(alarmService.startAlert());
      unawaited(notificationService.showTimeoutAlert());

      _syncWidget(
        vigiState: 'alerta',
        minutesRemaining: 0,
        isMonitoring: true,
      );

      emit(
        CheckinAlertActive(
          expiredAt: event.nextDeadline,
          activeMode: event.activeMode,
        ),
      );
      return;
    }

    final totalSec = _currentIntervalMinutes * 60;
    final fractionRemaining = totalSec > 0
        ? event.remainingSeconds / totalSec
        : 1.0;

    VigiState vigiState;
    if (fractionRemaining > 0.3) {
      vigiState = VigiState.normal;
    } else {
      vigiState = VigiState.atento;
    }

    final remainingMins = (event.remainingSeconds / 60).ceil();
    _syncWidget(
      vigiState: vigiState.name,
      minutesRemaining: remainingMins,
      isMonitoring: true,
    );

    emit(
      CheckinMonitoring(
        remainingSeconds: event.remainingSeconds,
        totalSeconds: totalSec,
        nextDeadline: event.nextDeadline,
        vigiState: vigiState,
        activeMode: event.activeMode,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _tickerSubscription?.cancel();
    unawaited(alarmService.stopAlert());
    unawaited(notificationService.cancelAlert());
    return super.close();
  }
}
