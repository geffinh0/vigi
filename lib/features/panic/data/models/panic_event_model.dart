import '../../domain/entities/panic_event_entity.dart';

class PanicEventModel extends PanicEventEntity {
  const PanicEventModel({
    required super.id,
    required super.userId,
    required super.lat,
    required super.lng,
    super.address,
    super.status = PanicStatus.active,
    required super.triggeredAt,
    super.resolvedAt,
  });

  factory PanicEventModel.fromJson(Map<String, dynamic> json) {
    return PanicEventModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      address: json['address'] as String?,
      status: _parseStatus(json['status'] as String?),
      triggeredAt: DateTime.parse(json['triggered_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'lat': lat,
      'lng': lng,
      'address': address,
      'status': status.name,
      'triggered_at': triggeredAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  static PanicStatus _parseStatus(String? status) {
    switch (status) {
      case 'resolved':
        return PanicStatus.resolved;
      case 'false_alarm':
        return PanicStatus.falseAlarm;
      default:
        return PanicStatus.active;
    }
  }
}
