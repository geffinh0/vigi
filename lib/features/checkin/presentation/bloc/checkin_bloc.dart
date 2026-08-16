import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/ticker.dart';
import '../../../../core/widgets/vigi_mascot.dart';
import '../../domain/usecases/confirm_checkin_usecase.dart';
import '../../domain/usecases/get_monitoring_status_usecase.dart';
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
    required this.ticker,
    required this.clock,
  }) : super(const CheckinInitial()) {
    on<LoadCheckinStatusRequested>(_onLoadCheckinStatusRequested);
    on<StartMonitoringRequested>(_onStartMonitoringRequested);
    on<ConfirmCheckinRequested>(_onConfirmCheckinRequested);
    on<StopMonitoringRequested>(_onStopMonitoringRequested);
    on<CheckinTickReceived>(_onCheckinTickReceived);
  }

  final StartMonitoringUseCase startMonitoringUseCase;
  final ConfirmCheckinUseCase confirmCheckinUseCase;
  final StopMonitoringUseCase stopMonitoringUseCase;
  final GetMonitoringStatusUseCase getMonitoringStatusUseCase;
  final Ticker ticker;
  final Clock clock;

  StreamSubscription<int>? _tickerSubscription;
  int _currentIntervalMinutes = 60;

  Future<void> _onLoadCheckinStatusRequested(
    LoadCheckinStatusRequested event,
    Emitter<CheckinState> emit,
  ) async {
    emit(const CheckinLoading());
    final result = await getMonitoringStatusUseCase(const NoParams());
    result.fold(
      (failure) => emit(CheckinFailure(failure.message)),
      (status) {
        _currentIntervalMinutes = status.intervalMinutes;
        if (status.active && status.nextDeadline != null) {
          _startTicker(status.nextDeadline!);
        } else {
          emit(CheckinIdle(intervalMinutes: status.intervalMinutes));
        }
      },
    );
  }

  Future<void> _onStartMonitoringRequested(
    StartMonitoringRequested event,
    Emitter<CheckinState> emit,
  ) async {
    emit(const CheckinLoading());
    _currentIntervalMinutes = event.intervalMinutes;
    final result = await startMonitoringUseCase(
      StartMonitoringParams(intervalMinutes: event.intervalMinutes),
    );
    result.fold(
      (failure) => emit(CheckinFailure(failure.message)),
      (_) {
        final nextDeadline = clock.now().add(
          Duration(minutes: event.intervalMinutes),
        );
        _startTicker(nextDeadline);
      },
    );
  }

  Future<void> _onConfirmCheckinRequested(
    ConfirmCheckinRequested event,
    Emitter<CheckinState> emit,
  ) async {
    final result = await confirmCheckinUseCase(
      ConfirmCheckinParams(
        latitude: event.latitude,
        longitude: event.longitude,
      ),
    );
    result.fold(
      (failure) => emit(CheckinFailure(failure.message)),
      (_) {
        final nextDeadline = clock.now().add(
          Duration(minutes: _currentIntervalMinutes),
        );
        _startTicker(nextDeadline);
      },
    );
  }

  Future<void> _onStopMonitoringRequested(
    StopMonitoringRequested event,
    Emitter<CheckinState> emit,
  ) async {
    await _tickerSubscription?.cancel();
    emit(const CheckinLoading());
    final result = await stopMonitoringUseCase(const NoParams());
    result.fold(
      (failure) => emit(CheckinFailure(failure.message)),
      (_) => emit(CheckinIdle(intervalMinutes: _currentIntervalMinutes)),
    );
  }

  void _startTicker(DateTime deadline) {
    unawaited(_tickerSubscription?.cancel());
    _tickerSubscription = ticker.secondsUntil(deadline, clock: clock).listen((
      remaining,
    ) {
      add(
        CheckinTickReceived(
          remainingSeconds: remaining,
          nextDeadline: deadline,
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
      emit(CheckinAlertActive(expiredAt: event.nextDeadline));
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

    emit(
      CheckinMonitoring(
        remainingSeconds: event.remainingSeconds,
        totalSeconds: totalSec,
        nextDeadline: event.nextDeadline,
        vigiState: vigiState,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _tickerSubscription?.cancel();
    return super.close();
  }
}
