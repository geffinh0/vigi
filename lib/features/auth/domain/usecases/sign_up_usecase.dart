import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Dados do cadastro (nome e telefone vão para o perfil).
class SignUpParams extends Equatable {
  const SignUpParams({
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

/// Cria a conta (o perfil e as configurações são criados por gatilho no banco).
class SignUpUseCase implements UseCase<UserEntity, SignUpParams> {
  SignUpUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, UserEntity>> call(SignUpParams params) {
    if (params.fullName.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('Nome completo é obrigatório')),
      );
    }
    if (params.email.trim().isEmpty || !params.email.contains('@')) {
      return Future.value(
        const Left(ValidationFailure('E-mail inválido')),
      );
    }
    if (params.password.length < 6) {
      return Future.value(
        const Left(
          ValidationFailure('A senha deve ter no mínimo 6 caracteres'),
        ),
      );
    }
    return repository.signUp(
      email: params.email.trim(),
      password: params.password,
      fullName: params.fullName.trim(),
      phone: params.phone?.trim(),
    );
  }
}
