import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/family_link_entity.dart';
import '../repositories/family_repository.dart';

class SendFamilyInviteParams extends Equatable {
  const SendFamilyInviteParams({required this.viewerUserId});

  final String viewerUserId;

  @override
  List<Object?> get props => [viewerUserId];
}

class SendFamilyInviteUseCase
    implements UseCase<FamilyLinkEntity, SendFamilyInviteParams> {
  SendFamilyInviteUseCase(this.repository);

  final FamilyRepository repository;

  @override
  Future<Either<Failure, FamilyLinkEntity>> call(
    SendFamilyInviteParams params,
  ) {
    if (params.viewerUserId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('ID do usuário familiar é obrigatório')),
      );
    }
    return repository.createInvite(viewerUserId: params.viewerUserId.trim());
  }
}
