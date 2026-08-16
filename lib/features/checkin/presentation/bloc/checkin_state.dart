import 'package:equatable/equatable.dart';
import '../../../../core/widgets/vigi_mascot.dart';

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
  const CheckinIdle({this.intervalMinutes = 60});

  final int intervalMinutes;

  @override
  List<Object?> get props => [intervalMinutes];
}

class CheckinMonitoring extends CheckinState {
  const CheckinMonitoring({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.nextDeadline,
    required this.vigiState,
  });

  final int remainingSeconds;
  final int totalSeconds;
  final DateTime nextDeadline;
  final VigiState vigiState;

  double get progress =>
      totalSeconds > 0 ? (totalSeconds - remainingSeconds) / totalSeconds : 0.0;

  @override
  List<Object?> get props => [
    remainingSeconds,
    totalSeconds,
    nextDeadline,
    vigiState,
  ];
}

class CheckinAlertActive extends CheckinState {
  const CheckinAlertActive({required this.expiredAt});

  final DateTime expiredAt;

  @override
  List<Object?> get props => [expiredAt];
}

class CheckinFailure extends CheckinState {
  const CheckinFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
