import 'package:equatable/equatable.dart';

/// Entidade de domínio para o Usuário autenticado no Guardião.
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;

  @override
  List<Object?> get props => [id, email, fullName, phone];
}
