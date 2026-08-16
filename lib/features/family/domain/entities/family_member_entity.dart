enum FamilyLinkStatus { pending, accepted, rejected }

enum MemberVigiStatus { safe, warning, danger }

class FamilyMemberEntity {
  final String linkId;
  final String guardianId;
  final String dependentId;
  final String dependentName;
  final String? dependentPhone;
  final FamilyLinkStatus linkStatus;
  final MemberVigiStatus vigiStatus;
  final DateTime? lastCheckinAt;
  final DateTime? nextCheckinDue;

  const FamilyMemberEntity({
    required this.linkId,
    required this.guardianId,
    required this.dependentId,
    required this.dependentName,
    this.dependentPhone,
    this.linkStatus = FamilyLinkStatus.pending,
    this.vigiStatus = MemberVigiStatus.safe,
    this.lastCheckinAt,
    this.nextCheckinDue,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyMemberEntity &&
          runtimeType == other.runtimeType &&
          linkId == other.linkId;

  @override
  int get hashCode => linkId.hashCode;
}
