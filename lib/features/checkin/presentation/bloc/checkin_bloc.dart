import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/alarm_service.dart';
import '../../../../core/services/checkin_messages.dart';
import '../../../../core/services/emergency_dispatcher.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/widget_sync_service.dart';
import '../../../../core/theme/vigi_state.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/ticker.dart';
import '../../../../core/utils/vigi_text.dart';
import '../../domain/entities/checkin_schedule.dart';
import '../../domain/entities/monitoring_mode_entity.dart';
import '../../domain/usecases/confirm_checkin_usecase.dart';
import '../../domain/usecases/create_custom_mode_usecase.dart';
import '../../domain/usecases/extend_deadline_usecase.dart';
import '../../domain/usecases/get_available_modes_usecase.dart';
import '../../domain/usecases/get_monitoring_status_usecase.dart';
import '../../domain/usecases/save_monitoring_settings_usecase.dart';
import '../../domain/usecases/start_monitoring_usecase.dart';
import '../../domain/usecases/stop_monitoring_usecase.dart';
import 'checkin_event.dart';
import 'checkin_state.dart';

/// Coração do dead man's switch no app. Conduz a escada de estados:
///
/// ```text
/// Vigiando → Sua vez → Última chamada → Alerta
///     ↑__________ Aliviado ←______________|   (a qualquer momento, ao confirmar)
/// ```
///
/// - **Vigiando**: contagem regressiva em silêncio.
/// - **Sua vez**: o prazo chegou; chamada gentil, com "Estou bem" e
///   "Preciso de mais 10 minutos" (uma vez por ciclo).
/// - **Última chamada**: minutos finais da tolerância; alarme em tela cheia.
/// - **Alerta**: sem resposta, os contatos são avisados por SMS e push.
///
/// A confirmação funciona sem internet: o ciclo local recomeça e o servidor é
/// atualizado quando a conexão voltar.
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
    this.extendDeadlineUseCase,
    this.widgetSyncService = const WidgetSyncServiceImpl(),
    this.emergencyDispatcher,
    this.escalationDelay,
    this.firstNameProvider,
    this.contactNamesProvider,
  }) : super(const CheckinInitial()) {
    on<LoadCheckinStatusRequested>(_onLoadCheckinStatusRequested);
    on<LoadAvailableModesRequested>(_onLoadAvailableModesRequested);
    on<SelectModeRequested>(_onSelectModeRequested);
    on<SaveMonitoringSettingsRequested>(_onSaveMonitoringSettingsRequested);
    on<StartMonitoringRequested>(_onStartMonitoringRequested);
    on<CreateCustomModeRequested>(_onCreateCustomModeRequested);
    on<ConfirmCheckinRequested>(_onConfirmCheckinRequested);
    on<SnoozeCheckinRequested>(_onSnoozeCheckinRequested);
    on<StopMonitoringRequested>(_onStopMonitoringRequested);
    on<CheckinTickReceived>(_onCheckinTickReceived);
    on<CheckinGraceTickReceived>(_onCheckinGraceTickReceived);
    on<CheckinEscalationRequested>(_onCheckinEscalationRequested);
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

  /// Adia o prazo no servidor ("Preciso de mais 10 minutos"). Opcional para
  /// permitir testes isolados.
  final ExtendDeadlineUseCase? extendDeadlineUseCase;

  /// Aciona os contatos de emergência quando a chamada não é respondida.
  /// Opcional para permitir testes isolados do fluxo de contagem.
  final EmergencyDispatcher? emergencyDispatcher;

  /// Tolerância entre o prazo e o aviso aos contatos. `null` usa a regra do
  /// produto ([CheckinSchedule.graceFor]): 15 minutos, limitados ao intervalo.
  final Duration? escalationDelay;

  /// Primeiro nome da pessoa, para a chamada ("Tudo bem por aí, Lúcia?").
  final String? Function()? firstNameProvider;

  /// Nomes de quem será avisado ("...vamos avisar Maria e João.").
  final Future<List<String>> Function()? contactNamesProvider;

  StreamSubscription<int>? _tickerSubscription;
  StreamSubscription<int>? _graceSubscription;
  Timer? _serverRetryTimer;
  int _currentIntervalMinutes = 60;
  int _savedRoutineIntervalMinutes = 60;
  List<MonitoringModeEntity> _availableModes = [];
  MonitoringModeEntity? _selectedMode;
  MonitoringModeEntity? _activeMode;
  List<String> _contactNames = const [];

  /// "Preciso de mais 10 minutos" já usado neste ciclo.
  bool _snoozeUsed = false;

  /// Até quando o estado "Aliviado" fica na tela.
  DateTime? _reliefUntil;
  bool _reliefAfterAlert = false;

  MonitoringModeEntity? _findRoutineMode(List<MonitoringModeEntity> modes) {
    return modes.where((m) => m.isRoutine).firstOrNull ??
        modes.where((m) => m.isSystemDefault).firstOrNull ??
        modes.firstOrNull;
  }

  String get _firstName => VigiText.firstName(firstNameProvider?.call());

  Future<List<String>> _loadContactNames() async {
    final provider = contactNamesProvider;
    if (provider == null) return _contactNames;
    try {
      _contactNames = await provider();
    } catch (_) {
      // Sem os nomes a chamada diz "seus contatos".
    }
    return _contactNames;
  }

  Duration get _grace =>
      escalationDelay ?? CheckinSchedule.graceFor(_currentIntervalMinutes);

  CheckinCallInfo _callInfo(DateTime deadline) {
    final grace = _grace;
    return CheckinCallInfo(
      deadline: deadline,
      lastCallAt: CheckinSchedule.lastCallAt(deadline, grace),
      escalatesAt: CheckinSchedule.escalatesAt(deadline, grace),
      firstName: _firstName,
      contactNames: _contactNames,
      canSnooze: !_snoozeUsed,
    );
  }

  /// O widget da tela inicial só precisa mudar quando o degrau muda: ele
  /// mostra o horário absoluto do próximo check-in, não uma contagem.
  void _syncWidget(
    VigiState vigiState, {
    DateTime? deadline,
    String? statusDisplay,
  }) {
    final isMonitoring = vigiState != VigiState.descansando;
    final minutes = deadline == null
        ? _currentIntervalMinutes
        : (deadline.difference(clock.now()).inSeconds / 60).ceil().clamp(
            0,
            1 << 20,
          );
    unawaited(
      widgetSyncService.updateWidgetData(
        vigiState: vigiState.name,
        minutesRemaining: minutes,
        modeName:
            _activeMode?.shortName ?? _selectedMode?.shortName ?? 'Rotina',
        isMonitoring: isMonitoring,
        timeDisplay: deadline == null ? null : VigiText.clock(deadline),
        statusDisplay: statusDisplay,
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
          _beginCycle(status.nextDeadline!, keepSnooze: true);
        } else {
          _selectedMode =
              _activeMode ??
              _availableModes
                  .where((m) => m.id == status.activeModeId)
                  .firstOrNull ??
              routineMode;
          _activeMode = null;

          _syncWidget(VigiState.descansando);

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

    final previousInterval = _currentIntervalMinutes;
    final previousMode = _activeMode;

    emit(const CheckinLoading());

    final effectiveInterval =
        event.intervalOverrideMinutes ??
        mode?.defaultIntervalMinutes ??
        _currentIntervalMinutes;

    final result = await startMonitoringUseCase(
      StartMonitoringParams(
        modeId: event.modeId,
        intervalOverrideMinutes: event.intervalOverrideMinutes,
      ),
    );

    result.fold(
      (failure) {
        emit(CheckinFailure(failure.message));
        if (currentState is CheckinMonitoring ||
            currentState is CheckinCalling ||
            currentState is CheckinAlertActive) {
          // A troca de modo falhou, mas a vigília que já estava ativa
          // continua: nada foi cancelado.
          _currentIntervalMinutes = previousInterval;
          _activeMode = previousMode;
          emit(currentState);
          return;
        }
        emit(
          CheckinIdle(
            intervalMinutes: _currentIntervalMinutes,
            availableModes: modes,
            selectedMode: mode,
          ),
        );
      },
      (_) {
        _currentIntervalMinutes = effectiveInterval;
        _activeMode = mode;

        // O intervalo escolhido passa a ser o padrão do modo.
        _availableModes = modes.map((m) {
          return m.id == event.modeId
              ? m.copyWith(defaultIntervalMinutes: effectiveInterval)
              : m;
        }).toList();
        final routineMode = _findRoutineMode(_availableModes);
        if (routineMode != null && routineMode.id == event.modeId) {
          _savedRoutineIntervalMinutes = effectiveInterval;
        }
        _activeMode =
            _availableModes.where((m) => m.id == event.modeId).firstOrNull ??
            mode;

        _reliefUntil = null;
        _beginCycle(
          clock.now().add(Duration(minutes: effectiveInterval)),
        );
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

    final wasActive = currentState is CheckinMonitoring;
    if (!wasActive) emit(const CheckinLoading());

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
        if (wasActive) {
          emit(currentState);
          return;
        }
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
        // Com a vigília ativa, o novo modo só entra na lista: o próximo
        // pulso da contagem já o inclui.
        if (wasActive) return;
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
    // Silencia a chamada, se estiver tocando.
    unawaited(_graceSubscription?.cancel());
    _graceSubscription = null;
    unawaited(alarmService.stopAlert());
    unawaited(notificationService.cancelAlert());

    final currentState = state;
    // Sem monitoramento ativo (ex.: "Estou bem" tocado no widget), não há
    // prazo a renovar: iniciar um ciclo só local divergiria do servidor.
    if (currentState is CheckinIdle || currentState is CheckinInitial) {
      return;
    }

    final resolvesAlert = currentState is CheckinAlertActive;

    // Se a pessoa estava em modo temporário (Banho ou Sono), ao confirmar
    // volta automaticamente para a Rotina, com o intervalo dela.
    if (_activeMode?.isTemporary ?? false) {
      final routineMode = _findRoutineMode(_availableModes);
      _activeMode = routineMode;
      _currentIntervalMinutes =
          routineMode?.defaultIntervalMinutes ?? _savedRoutineIntervalMinutes;
    }

    final params = ConfirmCheckinParams(
      latitude: event.latitude,
      longitude: event.longitude,
      intervalMinutes: _currentIntervalMinutes,
      modeId: _activeMode?.id,
      resolvesAlert: resolvesAlert,
    );
    final result = await confirmCheckinUseCase(params);
    final failure = result.getLeft().toNullable();
    if (failure is AuthFailure) {
      emit(CheckinFailure(failure.message));
      return;
    }
    if (failure == null) {
      _serverRetryTimer?.cancel();
    } else {
      // Sem conexão: a pessoa RESPONDEU, então o ciclo local continua (não pode
      // ficar preso no alerta sem proteção); o servidor é atualizado depois.
      emit(
        const CheckinFailure(
          'Sem conexão: confirmação registrada no aparelho. '
          'Será enviada ao servidor quando a internet voltar.',
        ),
      );
      _scheduleServerRetry(() => confirmCheckinUseCase(params));
    }

    // Quem recebeu o susto também recebe o alívio.
    if (resolvesAlert) {
      unawaited(emergencyDispatcher?.dispatchAllClear());
    }

    // Aliviado: a coruja pisca, uma vibração única e suave, e o agradecimento.
    unawaited(alarmService.confirmFeedback());
    _reliefUntil = clock.now().add(const Duration(seconds: 3));
    _reliefAfterAlert = resolvesAlert;

    _beginCycle(
      clock.now().add(Duration(minutes: _currentIntervalMinutes)),
    );
  }

  /// "Preciso de mais 10 minutos": adia o prazo, uma única vez por ciclo.
  Future<void> _onSnoozeCheckinRequested(
    SnoozeCheckinRequested event,
    Emitter<CheckinState> emit,
  ) async {
    final current = state;
    if (current is! CheckinCalling || !current.canSnooze || _snoozeUsed) {
      return;
    }

    _snoozeUsed = true;
    unawaited(_graceSubscription?.cancel());
    _graceSubscription = null;
    unawaited(alarmService.stopAlert());
    unawaited(notificationService.cancelAlert());

    final newDeadline = clock.now().add(CheckinSchedule.snooze);
    final extend = extendDeadlineUseCase;
    if (extend != null) {
      final result = await extend(newDeadline);
      if (result.isLeft()) {
        // Sem conexão o adiamento vale no aparelho; o servidor é avisado
        // assim que possível para não alertar a família por engano.
        _scheduleServerRetry(() => extend(newDeadline));
      }
    }

    _beginCycle(newDeadline, keepSnooze: true);
  }

  /// Reenvia ao servidor a cada 30 s até conseguir, para o dead man's switch
  /// do servidor não alertar a família por engano.
  void _scheduleServerRetry(
    Future<Either<Failure, void>> Function() operation, [
    int attempt = 1,
  ]) {
    _serverRetryTimer?.cancel();
    if (attempt > 20) return;
    _serverRetryTimer = Timer(const Duration(seconds: 30), () async {
      if (isClosed) return;
      final retry = await operation();
      if (retry.isLeft() && !isClosed) {
        _scheduleServerRetry(operation, attempt + 1);
      }
    });
  }

  Future<void> _onStopMonitoringRequested(
    StopMonitoringRequested event,
    Emitter<CheckinState> emit,
  ) async {
    await _tickerSubscription?.cancel();
    await _graceSubscription?.cancel();
    _graceSubscription = null;
    unawaited(alarmService.stopAlert());
    unawaited(notificationService.cancelAlert());

    emit(const CheckinLoading());
    final result = await stopMonitoringUseCase(const NoParams());
    result.fold(
      (failure) => emit(CheckinFailure(failure.message)),
      (_) {
        _selectedMode =
            _findRoutineMode(_availableModes) ?? _activeMode ?? _selectedMode;
        _activeMode = null;
        _snoozeUsed = false;
        _reliefUntil = null;
        unawaited(notificationService.cancelScheduledAlarm());
        unawaited(notificationService.cancelMonitoringOngoing());
        _syncWidget(VigiState.descansando);
        emit(
          CheckinIdle(
            intervalMinutes:
                _selectedMode?.defaultIntervalMinutes ??
                _currentIntervalMinutes,
            availableModes: _availableModes,
            selectedMode: _selectedMode,
          ),
        );
      },
    );
  }

  /// Começa (ou retoma) um ciclo de vigília que vence em [deadline].
  void _beginCycle(DateTime deadline, {bool keepSnooze = false}) {
    if (!keepSnooze) _snoozeUsed = false;
    unawaited(_tickerSubscription?.cancel());
    unawaited(_graceSubscription?.cancel());
    _graceSubscription = null;

    final activeMode = _activeMode;

    // Agenda a chamada e a última chamada no sistema (AlarmManager): elas
    // tocam mesmo com o app fechado.
    unawaited(_scheduleCall(deadline));

    // Notificação persistente e discreta enquanto o Vigi vigia.
    unawaited(
      notificationService.showMonitoringOngoing(
        modeName: activeMode?.shortName ?? 'Rotina',
        nextDeadline: deadline,
      ),
    );

    _syncWidget(
      (activeMode?.isSleep ?? false) ? VigiState.noturno : VigiState.vigiando,
      deadline: deadline,
    );

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

  Future<void> _scheduleCall(DateTime deadline) async {
    await _loadContactNames();
    if (isClosed) return;
    await notificationService.scheduleCheckinCall(_callInfo(deadline));
  }

  void _onCheckinTickReceived(
    CheckinTickReceived event,
    Emitter<CheckinState> emit,
  ) {
    if (event.remainingSeconds <= 0) {
      _enterCalling(event.nextDeadline, event.activeMode, emit);
      return;
    }

    final relief = _reliefUntil;
    final relieved = relief != null && clock.now().isBefore(relief);
    if (!relieved) _reliefUntil = null;

    emit(
      CheckinMonitoring(
        remainingSeconds: event.remainingSeconds,
        totalSeconds: _currentIntervalMinutes * 60,
        nextDeadline: event.nextDeadline,
        activeMode: event.activeMode,
        availableModes: _availableModes,
        relieved: relieved,
        reliefAfterAlert: relieved && _reliefAfterAlert,
      ),
    );
  }

  /// O prazo chegou: "Sua vez".
  void _enterCalling(
    DateTime deadline,
    MonitoringModeEntity? activeMode,
    Emitter<CheckinState> emit,
  ) {
    unawaited(_tickerSubscription?.cancel());
    unawaited(notificationService.cancelMonitoringOngoing());
    _reliefUntil = null;

    final now = clock.now();
    final grace = _grace;
    var escalatesAt = CheckinSchedule.escalatesAt(deadline, grace);

    // Quem abre o app com o prazo vencido há muito tempo ainda ganha um
    // tempo mínimo para responder antes de os contatos serem avisados.
    final minimum = now.add(
      escalationDelay ?? CheckinSchedule.minimumResponse,
    );
    if (escalatesAt.isBefore(minimum)) escalatesAt = minimum;

    final window = CheckinSchedule.lastCallWindow(grace);
    final lastCallAt = escalatesAt.subtract(window);
    final lastCall = !now.isBefore(lastCallAt);

    final info = CheckinCallInfo(
      deadline: deadline,
      lastCallAt: lastCallAt,
      escalatesAt: escalatesAt,
      firstName: _firstName,
      contactNames: _contactNames,
      canSnooze: !_snoozeUsed,
    );

    if (lastCall) {
      unawaited(_ringLastCall(info));
    } else {
      // A primeira chamada sai pela notificação; o serviço repete a cada 30 s.
      unawaited(alarmService.startCall());
      unawaited(notificationService.showCheckinCall(info));
    }
    _syncWidget(
      lastCall ? VigiState.ultimaChamada : VigiState.suaVez,
      deadline: escalatesAt,
    );

    unawaited(_graceSubscription?.cancel());
    _graceSubscription = ticker
        .secondsUntil(escalatesAt, clock: clock)
        .listen((remaining) => add(CheckinGraceTickReceived(remaining)));

    emit(
      CheckinCalling(
        deadline: deadline,
        lastCallAt: lastCallAt,
        escalatesAt: escalatesAt,
        lastCall: lastCall,
        canSnooze: !_snoozeUsed,
        activeMode: activeMode,
      ),
    );
  }

  Future<void> _ringLastCall(CheckinCallInfo info) async {
    // Com as notificações ligadas o alarme vem da própria notificação (que
    // toca até com o app fechado); sem elas, o app toca sozinho.
    final notifications = await notificationService.areNotificationsEnabled();
    if (isClosed) return;
    await alarmService.startLastCall(playSound: !notifications);
    await notificationService.showLastCall(info);
  }

  void _onCheckinGraceTickReceived(
    CheckinGraceTickReceived event,
    Emitter<CheckinState> emit,
  ) {
    final current = state;
    if (current is! CheckinCalling) return;

    if (event.remainingSeconds <= 0) {
      unawaited(_graceSubscription?.cancel());
      _graceSubscription = null;
      if (emergencyDispatcher != null) add(const CheckinEscalationRequested());
      return;
    }

    final window = current.escalatesAt.difference(current.lastCallAt);
    if (!current.lastCall && event.remainingSeconds <= window.inSeconds) {
      // "Última chamada": alarme contínuo, tela cheia.
      unawaited(
        _ringLastCall(
          CheckinCallInfo(
            deadline: current.deadline,
            lastCallAt: current.lastCallAt,
            escalatesAt: current.escalatesAt,
            firstName: _firstName,
            contactNames: _contactNames,
            canSnooze: false,
          ),
        ),
      );
      _syncWidget(VigiState.ultimaChamada, deadline: current.escalatesAt);
      emit(
        CheckinCalling(
          deadline: current.deadline,
          lastCallAt: current.lastCallAt,
          escalatesAt: current.escalatesAt,
          lastCall: true,
          canSnooze: current.canSnooze,
          activeMode: current.activeMode,
        ),
      );
    }
  }

  /// Dead man's switch: a pessoa não respondeu dentro da tolerância, então os
  /// contatos de emergência são avisados automaticamente.
  Future<void> _onCheckinEscalationRequested(
    CheckinEscalationRequested event,
    Emitter<CheckinState> emit,
  ) async {
    final current = state;
    final dispatcher = emergencyDispatcher;
    if (current is! CheckinCalling || dispatcher == null) return;

    final result = await dispatcher.dispatch(
      reason: EmergencyReason.checkinTimeout,
      deadline: current.deadline,
    );

    // A pessoa pode ter confirmado enquanto o envio acontecia: quem já
    // recebeu o SMS precisa saber que está tudo bem.
    if (state is! CheckinCalling) {
      if (result.smsSent > 0) unawaited(dispatcher.dispatchAllClear());
      return;
    }

    final alertedAt = result.sentAt ?? clock.now();
    unawaited(alarmService.playAlertConfirmed());
    unawaited(
      notificationService.showContactsAlerted(
        notified: result.smsSent,
        at: alertedAt,
        withLocation: result.hasLocation,
      ),
    );
    _syncWidget(VigiState.alerta);

    emit(
      CheckinAlertActive(
        expiredAt: current.deadline,
        alertedAt: alertedAt,
        activeMode: current.activeMode,
        contactsFound: result.contactsFound,
        smsSent: result.smsSent,
        deliveries: result.deliveries,
        latitude: result.latitude,
        longitude: result.longitude,
        address: result.address,
      ),
    );
  }

  @override
  Future<void> close() async {
    _serverRetryTimer?.cancel();
    await _tickerSubscription?.cancel();
    await _graceSubscription?.cancel();
    unawaited(alarmService.stopAlert());
    unawaited(notificationService.cancelAlert());
    unawaited(notificationService.cancelScheduledAlarm());
    unawaited(notificationService.cancelMonitoringOngoing());
    return super.close();
  }
}
