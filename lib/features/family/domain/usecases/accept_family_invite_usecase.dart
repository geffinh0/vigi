import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/family_repository.dart';

class AcceptFamilyInviteParams extends Equatable {
  const AcceptFamilyInviteParams({required this.linkId});

  final String linkId;

  @override
  List<Object?> get props => [linkId];
}

class AcceptFamilyInviteUseCase
    implements UseCase<void, AcceptFamilyInviteParams> {
  AcceptFamilyInviteUseCase(this.repository);

  final FamilyRepository repository;

  @override
  Future<Either<Failure, void>> call(AcceptFamilyInviteParams params) {
    if (params.linkId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('ID do convite é obrigatório')),
      );
    }
    return repository.acceptInvite(linkId: params.linkId.trim());
  }
}
