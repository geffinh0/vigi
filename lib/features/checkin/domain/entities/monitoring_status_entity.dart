import 'package:equatable/equatable.dart';

/// Entidade representando o estado do Dead Man's Switch / Monitoramento do usuário.
class MonitoringStatusEntity extends Equatable {
  const MonitoringStatusEntity({
    required this.active,
    required this.intervalMinutes,
    this.nextDeadline,
    this.lastPing,
  });

  final bool active;
  final int intervalMinutes;
  final DateTime? nextDeadline;
  final DateTime? lastPing;

  @override
  List<Object?> get props => [active, intervalMinutes, nextDeadline, lastPing];
}
