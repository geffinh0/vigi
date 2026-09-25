import '../../domain/entities/family_link_entity.dart';

class FamilyLinkModel extends FamilyLinkEntity {
  const FamilyLinkModel({
    required super.id,
    required super.monitoredUserId,
    required super.viewerUserId,
    required super.status,
    super.monitoredUserName,
    super.viewerUserName,
    super.monitoredUserPhone,
    super.createdAt,
  });

  factory FamilyLinkModel.fromMap(Map<String, dynamic> map) {
    final monitoredUser = map['monitored_user'] is Map<String, dynamic>
        ? map['monitored_user'] as Map<String, dynamic>
        : null;
    final viewerUser = map['viewer_user'] is Map<String, dynamic>
        ? map['viewer_user'] as Map<String, dynamic>
        : null;

    return FamilyLinkModel(
      id: map['id'] as String,
      monitoredUserId: map['monitored_user_id'] as String,
      viewerUserId: map['viewer_user_id'] as String,
      status: map['status'] as String? ?? 'pending',
      monitoredUserName: monitoredUser?['full_name'] as String?,
      viewerUserName: viewerUser?['full_name'] as String?,
      monitoredUserPhone: monitoredUser?['phone'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'monitored_user_id': monitoredUserId,
      'viewer_user_id': viewerUserId,
      'status': status,
    };
  }
}
