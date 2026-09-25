import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/family_repository.dart';

/// Obtém o código VIGI de 6 caracteres do usuário.
class GetMyLinkCodeUseCase implements UseCase<String, NoParams> {
  GetMyLinkCodeUseCase(this.repository);

  final FamilyRepository repository;

  @override
  Future<Either<Failure, String>> call(NoParams params) =>
      repository.getMyLinkCode();
}
