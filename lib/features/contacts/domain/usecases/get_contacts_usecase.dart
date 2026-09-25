import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/emergency_contact_entity.dart';
import '../repositories/contacts_repository.dart';

/// Lista os contatos de emergência do usuário.
class GetContactsUseCase
    implements UseCase<List<EmergencyContactEntity>, NoParams> {
  GetContactsUseCase(this.repository);

  final ContactsRepository repository;

  @override
  Future<Either<Failure, List<EmergencyContactEntity>>> call(NoParams params) {
    return repository.getContacts();
  }
}
