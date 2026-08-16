enum PanicStatus { active, resolved, falseAlarm }

class PanicEventEntity {
  final String id;
  final String userId;
  final double lat;
  final double lng;
  final String? address;
  final PanicStatus status;
  final DateTime triggeredAt;
  final DateTime? resolvedAt;

  const PanicEventEntity({
    required this.id,
    required this.userId,
    required this.lat,
    required this.lng,
    this.address,
    this.status = PanicStatus.active,
    required this.triggeredAt,
    this.resolvedAt,
  });
}
