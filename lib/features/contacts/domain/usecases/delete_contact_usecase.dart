import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/contacts_repository.dart';

/// Contato a remover.
class DeleteContactParams extends Equatable {
  const DeleteContactParams(this.contactId);

  final String contactId;

  @override
  List<Object?> get props => [contactId];
}

/// Remove um contato de emergência.
class DeleteContactUseCase implements UseCase<void, DeleteContactParams> {
  DeleteContactUseCase(this.repository);

  final ContactsRepository repository;

  @override
  Future<Either<Failure, void>> call(DeleteContactParams params) {
    if (params.contactId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('ID do contato é obrigatório')),
      );
    }
    return repository.deleteContact(params.contactId);
  }
}
