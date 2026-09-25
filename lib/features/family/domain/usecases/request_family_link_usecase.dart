import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/family_repository.dart';

/// Familiar pede para acompanhar alguém usando o código VIGI dessa pessoa.
/// Retorna o nome de quem precisa autorizar.
class RequestFamilyLinkUseCase implements UseCase<String, String> {
  RequestFamilyLinkUseCase(this.repository);

  final FamilyRepository repository;

  @override
  Future<Either<Failure, String>> call(String code) async {
    final normalized = code.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    if (normalized.length != 6) {
      return const Left(
        ValidationFailure('O código VIGI tem 6 letras e números.'),
      );
    }
    return repository.requestLinkByCode(normalized);
  }
}
