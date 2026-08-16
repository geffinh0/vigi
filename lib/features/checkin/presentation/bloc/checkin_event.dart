import 'package:equatable/equatable.dart';

abstract class CheckinEvent extends Equatable {
  const CheckinEvent();

  @override
  List<Object?> get props => [];
}

class LoadCheckinStatusRequested extends CheckinEvent {
  const LoadCheckinStatusRequested();
}

class StartMonitoringRequested extends CheckinEvent {
  const StartMonitoringRequested({required this.intervalMinutes});

  final int intervalMinutes;

  @override
  List<Object?> get props => [intervalMinutes];
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
  });

  final int remainingSeconds;
  final DateTime nextDeadline;

  @override
  List<Object?> get props => [remainingSeconds, nextDeadline];
}
