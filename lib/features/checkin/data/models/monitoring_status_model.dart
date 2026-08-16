import '../../domain/entities/monitoring_status_entity.dart';
import 'monitoring_mode_model.dart';

class MonitoringStatusModel extends MonitoringStatusEntity {
  const MonitoringStatusModel({
    required super.active,
    required super.intervalMinutes,
    super.nextDeadline,
    super.lastPing,
    super.activeModeId,
    super.activeMode,
  });

  factory MonitoringStatusModel.fromMap(Map<String, dynamic> map) {
    MonitoringModeModel? mode;
    if (map['monitoring_modes'] != null &&
        map['monitoring_modes'] is Map<String, dynamic>) {
      mode = MonitoringModeModel.fromMap(
        map['monitoring_modes'] as Map<String, dynamic>,
      );
    }

    return MonitoringStatusModel(
      active: (map['active'] as bool?) ?? false,
      intervalMinutes: (map['interval_minutes'] as int?) ?? 60,
      nextDeadline: map['next_deadline'] != null
          ? DateTime.tryParse(map['next_deadline'] as String)
          : null,
      lastPing: map['last_ping'] != null
          ? DateTime.tryParse(map['last_ping'] as String)
          : null,
      activeModeId: map['active_mode_id'] as String?,
      activeMode: mode,
    );
  }

  Map<String, dynamic> toMap(String userId) {
    return {
      'user_id': userId,
      'active': active,
      'interval_minutes': intervalMinutes,
      'active_mode_id': ?activeModeId,
      'next_deadline': ?nextDeadline?.toIso8601String(),
      'last_ping': ?lastPing?.toIso8601String(),
    };
  }
}
