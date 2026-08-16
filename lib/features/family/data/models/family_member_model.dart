import '../../domain/entities/family_member_entity.dart';

class FamilyMemberModel extends FamilyMemberEntity {
  const FamilyMemberModel({
    required super.linkId,
    required super.guardianId,
    required super.dependentId,
    required super.dependentName,
    super.dependentPhone,
    super.linkStatus = FamilyLinkStatus.pending,
    super.vigiStatus = MemberVigiStatus.safe,
    super.lastCheckinAt,
    super.nextCheckinDue,
  });

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    final profile = json['dependent'] as Map<String, dynamic>?;
    final checkin = json['checkin_settings'] as Map<String, dynamic>?;

    return FamilyMemberModel(
      linkId: json['id'] as String,
      guardianId: json['guardian_id'] as String,
      dependentId: json['dependent_id'] as String,
      dependentName: profile?['full_name'] as String? ?? 'Familiar',
      dependentPhone: profile?['phone_number'] as String?,
      linkStatus: _parseLinkStatus(json['status'] as String?),
      vigiStatus: _parseVigiStatus(checkin?['status'] as String?),
      lastCheckinAt: checkin?['last_checkin_at'] != null
          ? DateTime.tryParse(checkin!['last_checkin_at'] as String)
          : null,
      nextCheckinDue: checkin?['next_checkin_due'] != null
          ? DateTime.tryParse(checkin!['next_checkin_due'] as String)
          : null,
    );
  }

  static FamilyLinkStatus _parseLinkStatus(String? status) {
    switch (status) {
      case 'accepted':
        return FamilyLinkStatus.accepted;
      case 'rejected':
        return FamilyLinkStatus.rejected;
      default:
        return FamilyLinkStatus.pending;
    }
  }

  static MemberVigiStatus _parseVigiStatus(String? status) {
    switch (status) {
      case 'warning':
        return MemberVigiStatus.warning;
      case 'expired':
      case 'alerted':
        return MemberVigiStatus.danger;
      default:
        return MemberVigiStatus.safe;
    }
  }
}
