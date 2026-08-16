import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/family_link_entity.dart';
import '../repositories/family_repository.dart';

class GetFamilyLinksUseCase
    implements UseCase<List<FamilyLinkEntity>, NoParams> {
  GetFamilyLinksUseCase(this.repository);

  final FamilyRepository repository;

  @override
  Future<Either<Failure, List<FamilyLinkEntity>>> call(NoParams params) {
    return repository.getFamilyLinks();
  }
}
