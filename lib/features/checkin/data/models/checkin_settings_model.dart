import '../../domain/entities/checkin_settings_entity.dart';

class CheckInSettingsModel extends CheckInSettingsEntity {
  const CheckInSettingsModel({
    required super.userId,
    super.intervalHours = 12,
    super.graceMinutes = 15,
    required super.lastCheckinAt,
    required super.nextCheckinDue,
    super.status = CheckInStatus.safe,
  });

  factory CheckInSettingsModel.fromJson(Map<String, dynamic> json) {
    return CheckInSettingsModel(
      userId: json['user_id'] as String,
      intervalHours: json['interval_hours'] as int? ?? 12,
      graceMinutes: json['grace_minutes'] as int? ?? 15,
      lastCheckinAt: json['last_checkin_at'] != null
          ? DateTime.parse(json['last_checkin_at'] as String)
          : DateTime.now(),
      nextCheckinDue: json['next_checkin_due'] != null
          ? DateTime.parse(json['next_checkin_due'] as String)
          : DateTime.now().add(
              Duration(hours: json['interval_hours'] as int? ?? 12),
            ),
      status: _parseStatus(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'interval_hours': intervalHours,
      'grace_minutes': graceMinutes,
      'last_checkin_at': lastCheckinAt.toIso8601String(),
      'next_checkin_due': nextCheckinDue.toIso8601String(),
      'status': status.name,
    };
  }

  static CheckInStatus _parseStatus(String? status) {
    switch (status) {
      case 'warning':
        return CheckInStatus.warning;
      case 'expired':
        return CheckInStatus.expired;
      case 'alerted':
        return CheckInStatus.alerted;
      default:
        return CheckInStatus.safe;
    }
  }

  factory CheckInSettingsModel.fromEntity(CheckInSettingsEntity entity) {
    return CheckInSettingsModel(
      userId: entity.userId,
      intervalHours: entity.intervalHours,
      graceMinutes: entity.graceMinutes,
      lastCheckinAt: entity.lastCheckinAt,
      nextCheckinDue: entity.nextCheckinDue,
      status: entity.status,
    );
  }
}
