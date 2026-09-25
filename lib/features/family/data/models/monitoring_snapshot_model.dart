import '../../domain/entities/monitoring_snapshot_entity.dart';

class MonitoringSnapshotModel extends MonitoringSnapshotEntity {
  const MonitoringSnapshotModel({
    required super.userId,
    required super.active,
    required super.intervalMinutes,
    super.nextDeadline,
    super.lastPing,
    super.activeModeId,
  });

  factory MonitoringSnapshotModel.fromMap(Map<String, dynamic> map) {
    DateTime? parse(Object? v) =>
        v is String ? DateTime.tryParse(v)?.toLocal() : null;

    return MonitoringSnapshotModel(
      userId: map['user_id'] as String,
      active: map['active'] as bool? ?? false,
      intervalMinutes: (map['interval_minutes'] as num?)?.toInt() ?? 60,
      nextDeadline: parse(map['next_deadline']),
      lastPing: parse(map['last_ping']),
      activeModeId: map['active_mode_id'] as String?,
    );
  }
}
