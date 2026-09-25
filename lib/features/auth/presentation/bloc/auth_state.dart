import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

/// Estados do `AuthBloc`.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Sessão ainda não verificada.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Operação de autenticação em andamento.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Usuário autenticado.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

/// Sem sessão: o roteador leva ao login.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Sessão ausente ou expirada.
class AuthFailure extends AuthState {
  const AuthFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
