enum CheckInStatus { safe, warning, expired, alerted }

class CheckInSettingsEntity {
  final String userId;
  final int intervalHours;
  final int graceMinutes;
  final DateTime lastCheckinAt;
  final DateTime nextCheckinDue;
  final CheckInStatus status;

  const CheckInSettingsEntity({
    required this.userId,
    this.intervalHours = 12,
    this.graceMinutes = 15,
    required this.lastCheckinAt,
    required this.nextCheckinDue,
    this.status = CheckInStatus.safe,
  });

  Duration get remainingDuration => nextCheckinDue.difference(DateTime.now());

  bool get isExpired => DateTime.now().isAfter(nextCheckinDue);

  bool get isWarning =>
      !isExpired && remainingDuration <= Duration(minutes: graceMinutes * 4);

  CheckInSettingsEntity copyWith({
    String? userId,
    int? intervalHours,
    int? graceMinutes,
    DateTime? lastCheckinAt,
    DateTime? nextCheckinDue,
    CheckInStatus? status,
  }) {
    return CheckInSettingsEntity(
      userId: userId ?? this.userId,
      intervalHours: intervalHours ?? this.intervalHours,
      graceMinutes: graceMinutes ?? this.graceMinutes,
      lastCheckinAt: lastCheckinAt ?? this.lastCheckinAt,
      nextCheckinDue: nextCheckinDue ?? this.nextCheckinDue,
      status: status ?? this.status,
    );
  }
}
