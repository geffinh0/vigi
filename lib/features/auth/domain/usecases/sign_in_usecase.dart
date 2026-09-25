import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// E-mail e senha para login.
class SignInParams extends Equatable {
  const SignInParams({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Autentica o usuário com e-mail e senha.
class SignInUseCase implements UseCase<UserEntity, SignInParams> {
  SignInUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, UserEntity>> call(SignInParams params) {
    if (params.email.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('E-mail não pode ser vazio')),
      );
    }
    if (params.password.isEmpty) {
      return Future.value(
        const Left(ValidationFailure('Senha não pode ser vazia')),
      );
    }
    return repository.signIn(
      email: params.email.trim(),
      password: params.password,
    );
  }
}
