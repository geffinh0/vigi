import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/family_repository.dart';

/// Pedido a responder e a decisão.
class RespondFamilyLinkParams extends Equatable {
  const RespondFamilyLinkParams({required this.linkId, required this.accept});

  final String linkId;
  final bool accept;

  @override
  List<Object?> get props => [linkId, accept];
}

/// A pessoa acompanhada autoriza (ou recusa) quem pode ver seu bem-estar.
class RespondFamilyLinkUseCase
    implements UseCase<void, RespondFamilyLinkParams> {
  RespondFamilyLinkUseCase(this.repository);

  final FamilyRepository repository;

  @override
  Future<Either<Failure, void>> call(RespondFamilyLinkParams params) =>
      repository.respondToLink(linkId: params.linkId, accept: params.accept);
}
