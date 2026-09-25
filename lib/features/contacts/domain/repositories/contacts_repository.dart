import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/emergency_contact_entity.dart';

/// Contrato dos contatos de emergência (quem recebe o SMS).
abstract class ContactsRepository {
  Future<Either<Failure, List<EmergencyContactEntity>>> getContacts();

  Future<Either<Failure, EmergencyContactEntity>> addContact({
    required String name,
    required String phone,
    String? relationship,
  });

  Future<Either<Failure, void>> deleteContact(String contactId);
}
