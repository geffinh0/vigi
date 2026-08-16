import 'package:equatable/equatable.dart';
import '../../../../core/widgets/vigi_mascot.dart';
import '../../domain/entities/monitoring_mode_entity.dart';

abstract class CheckinState extends Equatable {
  const CheckinState();

  @override
  List<Object?> get props => [];
}

class CheckinInitial extends CheckinState {
  const CheckinInitial();
}

class CheckinLoading extends CheckinState {
  const CheckinLoading();
}

class CheckinIdle extends CheckinState {
  const CheckinIdle({
    this.intervalMinutes = 60,
    this.availableModes = const [],
    this.selectedMode,
  });

  final int intervalMinutes;
  final List<MonitoringModeEntity> availableModes;
  final MonitoringModeEntity? selectedMode;

  CheckinIdle copyWith({
    int? intervalMinutes,
    List<MonitoringModeEntity>? availableModes,
    MonitoringModeEntity? selectedMode,
  }) {
    return CheckinIdle(
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      availableModes: availableModes ?? this.availableModes,
      selectedMode: selectedMode ?? this.selectedMode,
    );
  }

  @override
  List<Object?> get props => [intervalMinutes, availableModes, selectedMode];
}

class CheckinMonitoring extends CheckinState {
  const CheckinMonitoring({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.nextDeadline,
    required this.vigiState,
    this.activeMode,
  });

  final int remainingSeconds;
  final int totalSeconds;
  final DateTime nextDeadline;
  final VigiState vigiState;
  final MonitoringModeEntity? activeMode;

  double get progress =>
      totalSeconds > 0 ? (totalSeconds - remainingSeconds) / totalSeconds : 0.0;

  @override
  List<Object?> get props => [
    remainingSeconds,
    totalSeconds,
    nextDeadline,
    vigiState,
    activeMode,
  ];
}

class CheckinAlertActive extends CheckinState {
  const CheckinAlertActive({
    required this.expiredAt,
    this.activeMode,
  });

  final DateTime expiredAt;
  final MonitoringModeEntity? activeMode;

  @override
  List<Object?> get props => [expiredAt, activeMode];
}

class CheckinFailure extends CheckinState {
  const CheckinFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
