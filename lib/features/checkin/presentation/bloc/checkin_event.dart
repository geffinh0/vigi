import 'package:equatable/equatable.dart';
import '../../domain/entities/monitoring_mode_entity.dart';

abstract class CheckinEvent extends Equatable {
  const CheckinEvent();

  @override
  List<Object?> get props => [];
}

class LoadCheckinStatusRequested extends CheckinEvent {
  const LoadCheckinStatusRequested();
}

class LoadAvailableModesRequested extends CheckinEvent {
  const LoadAvailableModesRequested();
}

class SelectModeRequested extends CheckinEvent {
  const SelectModeRequested(this.mode);

  final MonitoringModeEntity mode;

  @override
  List<Object?> get props => [mode];
}

class StartMonitoringRequested extends CheckinEvent {
  const StartMonitoringRequested({
    required this.modeId,
    this.intervalOverrideMinutes,
  });

  final String modeId;
  final int? intervalOverrideMinutes;

  @override
  List<Object?> get props => [modeId, intervalOverrideMinutes];
}

class CreateCustomModeRequested extends CheckinEvent {
  const CreateCustomModeRequested({
    required this.name,
    required this.defaultIntervalMinutes,
    this.iconKey,
  });

  final String name;
  final int defaultIntervalMinutes;
  final String? iconKey;

  @override
  List<Object?> get props => [name, defaultIntervalMinutes, iconKey];
}

class ConfirmCheckinRequested extends CheckinEvent {
  const ConfirmCheckinRequested({this.latitude, this.longitude});

  final double? latitude;
  final double? longitude;

  @override
  List<Object?> get props => [latitude, longitude];
}

class StopMonitoringRequested extends CheckinEvent {
  const StopMonitoringRequested();
}

class CheckinTickReceived extends CheckinEvent {
  const CheckinTickReceived({
    required this.remainingSeconds,
    required this.nextDeadline,
    this.activeMode,
  });

  final int remainingSeconds;
  final DateTime nextDeadline;
  final MonitoringModeEntity? activeMode;

  @override
  List<Object?> get props => [remainingSeconds, nextDeadline, activeMode];
}
