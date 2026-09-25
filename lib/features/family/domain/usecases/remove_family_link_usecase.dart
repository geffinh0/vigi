import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/family_repository.dart';

/// Remove um vínculo (qualquer uma das partes pode remover).
class RemoveFamilyLinkUseCase implements UseCase<void, String> {
  RemoveFamilyLinkUseCase(this.repository);

  final FamilyRepository repository;

  @override
  Future<Either<Failure, void>> call(String linkId) =>
      repository.removeLink(linkId);
}
