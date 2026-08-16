import '../../domain/entities/monitoring_mode_entity.dart';

class MonitoringModeModel extends MonitoringModeEntity {
  const MonitoringModeModel({
    required super.id,
    required super.name,
    super.iconKey,
    required super.defaultIntervalMinutes,
    required super.isSystemDefault,
  });

  factory MonitoringModeModel.fromMap(Map<String, dynamic> map) {
    return MonitoringModeModel(
      id: map['id'] as String,
      name: map['name'] as String,
      iconKey: map['icon_key'] as String?,
      defaultIntervalMinutes:
          (map['default_interval_minutes'] as num?)?.toInt() ?? 60,
      isSystemDefault: (map['is_system_default'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap({String? userId}) {
    return {
      'id': id,
      'user_id': ?userId,
      'name': name,
      'icon_key': ?iconKey,
      'default_interval_minutes': defaultIntervalMinutes,
      'is_system_default': isSystemDefault,
    };
  }
}
