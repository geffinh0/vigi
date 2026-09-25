import '../../domain/entities/panic_alert_entity.dart';

/// Modelo de um evento de `checkin_events` (pânico, alerta, check-in...).
class PanicAlertModel extends PanicAlertEntity {
  const PanicAlertModel({
    required super.id,
    required super.userId,
    required super.eventType,
    super.latitude,
    super.longitude,
    super.createdAt,
  });

  factory PanicAlertModel.fromMap(Map<String, dynamic> map) {
    return PanicAlertModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      eventType: map['event_type'] as String,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'event_type': eventType,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}
