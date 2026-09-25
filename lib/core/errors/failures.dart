import 'package:equatable/equatable.dart';

/// Classe base selada para representação de falhas em camadas de domínio e dados.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Erro vindo do Supabase/servidor.
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Erro de leitura/escrita no armazenamento local.
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Sem conexão com a internet.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com a internet.']);
}

/// Dado de entrada inválido (mensagem pronta para o usuário).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Sessão ausente ou expirada.
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}
