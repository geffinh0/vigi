import 'package:equatable/equatable.dart';
import 'monitoring_mode_entity.dart';

/// Entidade representando o estado do Dead Man's Switch / Monitoramento do usuário.
class MonitoringStatusEntity extends Equatable {
  const MonitoringStatusEntity({
    required this.active,
    required this.intervalMinutes,
    this.nextDeadline,
    this.lastPing,
    this.activeModeId,
    this.activeMode,
  });

  final bool active;
  final int intervalMinutes;
  final DateTime? nextDeadline;
  final DateTime? lastPing;
  final String? activeModeId;
  final MonitoringModeEntity? activeMode;

  @override
  List<Object?> get props => [
    active,
    intervalMinutes,
    nextDeadline,
    lastPing,
    activeModeId,
    activeMode,
  ];
}
