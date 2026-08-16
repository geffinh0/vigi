import 'package:equatable/equatable.dart';

/// Entidade de domínio representando um contato de emergência.
class EmergencyContactEntity extends Equatable {
  const EmergencyContactEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.relationship,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String phone;
  final String? relationship;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, userId, name, phone, relationship, createdAt];
}
