class CheckInLogEntity {
  final String id;
  final String userId;
  final DateTime checkedInAt;
  final String? note;
  final double? lat;
  final double? lng;

  const CheckInLogEntity({
    required this.id,
    required this.userId,
    required this.checkedInAt,
    this.note,
    this.lat,
    this.lng,
  });
}
