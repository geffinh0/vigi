import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

/// Eventos do `AuthBloc`.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Verifica se já existe sessão salva ao abrir o app.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Pedido de login.
class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Pedido de cadastro.
class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.fullName,
    this.phone,
  });

  final String email;
  final String password;
  final String fullName;
  final String? phone;

  @override
  List<Object?> get props => [email, password, fullName, phone];
}

/// Pedido de logout.
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Mudança de sessão vinda do Supabase (login, renovação, expiração).
class AuthStatusChanged extends AuthEvent {
  const AuthStatusChanged(this.user);

  final UserEntity? user;

  @override
  List<Object?> get props => [user];
}
