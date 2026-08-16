import '../../domain/entities/user_entity.dart';

/// Modelo de dados de usuário com serialização para o Supabase.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    super.phone,
  });

  factory UserModel.fromMap(
    Map<String, dynamic> map, {
    required String email,
  }) {
    return UserModel(
      id: map['id'] as String,
      email: email,
      fullName: (map['full_name'] as String?) ?? '',
      phone: map['phone'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      if (phone != null) 'phone': phone,
    };
  }
}
