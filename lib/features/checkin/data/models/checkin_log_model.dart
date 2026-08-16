import '../../domain/entities/checkin_log_entity.dart';

class CheckInLogModel extends CheckInLogEntity {
  const CheckInLogModel({
    required super.id,
    required super.userId,
    required super.checkedInAt,
    super.note,
    super.lat,
    super.lng,
  });

  factory CheckInLogModel.fromJson(Map<String, dynamic> json) {
    return CheckInLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      checkedInAt: DateTime.parse(json['checked_in_at'] as String),
      note: json['note'] as String?,
      lat: (json['location_lat'] as num?)?.toDouble(),
      lng: (json['location_lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'checked_in_at': checkedInAt.toIso8601String(),
      'note': note,
      'location_lat': lat,
      'location_lng': lng,
    };
  }
}
