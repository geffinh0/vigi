import 'package:equatable/equatable.dart';

/// Estado do dead man's switch de uma pessoa acompanhada, como visto pela
/// família (linha de `monitoring_settings`).
class MonitoringSnapshotEntity extends Equatable {
  const MonitoringSnapshotEntity({
    required this.userId,
    required this.active,
    required this.intervalMinutes,
    this.nextDeadline,
    this.lastPing,
    this.activeModeId,
  });

  final String userId;
  final bool active;
  final int intervalMinutes;
  final DateTime? nextDeadline;
  final DateTime? lastPing;
  final String? activeModeId;

  @override
  List<Object?> get props => [
    userId,
    active,
    intervalMinutes,
    nextDeadline,
    lastPing,
    activeModeId,
  ];
}
