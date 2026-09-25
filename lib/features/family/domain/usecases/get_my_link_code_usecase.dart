import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/family_repository.dart';

class GetMyLinkCodeUseCase implements UseCase<String, NoParams> {
  GetMyLinkCodeUseCase(this.repository);

  final FamilyRepository repository;

  @override
  Future<Either<Failure, String>> call(NoParams params) =>
      repository.getMyLinkCode();
}
