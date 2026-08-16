import '../../domain/entities/monitoring_status_entity.dart';

class MonitoringStatusModel extends MonitoringStatusEntity {
  const MonitoringStatusModel({
    required super.active,
    required super.intervalMinutes,
    super.nextDeadline,
    super.lastPing,
  });

  factory MonitoringStatusModel.fromMap(Map<String, dynamic> map) {
    return MonitoringStatusModel(
      active: (map['active'] as bool?) ?? false,
      intervalMinutes: (map['interval_minutes'] as int?) ?? 60,
      nextDeadline: map['next_deadline'] != null
          ? DateTime.tryParse(map['next_deadline'] as String)
          : null,
      lastPing: map['last_ping'] != null
          ? DateTime.tryParse(map['last_ping'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap(String userId) {
    return {
      'user_id': userId,
      'active': active,
      'interval_minutes': intervalMinutes,
      if (nextDeadline != null)
        'next_deadline': nextDeadline!.toIso8601String(),
      if (lastPing != null) 'last_ping': lastPing!.toIso8601String(),
    };
  }
}
