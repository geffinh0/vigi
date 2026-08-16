import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/emergency_contact_entity.dart';
import '../repositories/contacts_repository.dart';

class AddContactParams extends Equatable {
  const AddContactParams({
    required this.name,
    required this.phone,
    this.relationship,
  });

  final String name;
  final String phone;
  final String? relationship;

  @override
  List<Object?> get props => [name, phone, relationship];
}

class AddContactUseCase
    implements UseCase<EmergencyContactEntity, AddContactParams> {
  AddContactUseCase(this.repository);

  final ContactsRepository repository;

  @override
  Future<Either<Failure, EmergencyContactEntity>> call(
    AddContactParams params,
  ) {
    final cleanName = params.name.trim();
    if (cleanName.isEmpty) {
      return Future.value(
        const Left(ValidationFailure('Nome do contato é obrigatório')),
      );
    }

    final digits = params.phone.replaceAll(RegExp(r'\D'), '');
    // Validação de telefone brasileiro (DDD + 8 ou 9 dígitos: 10 ou 11 dígitos, ou 12-13 com código 55)
    final isValidBrPhone =
        (digits.length == 10 || digits.length == 11) ||
        (digits.length >= 12 &&
            digits.startsWith('55') &&
            (digits.length == 12 || digits.length == 13));

    if (!isValidBrPhone) {
      return Future.value(
        const Left(
          ValidationFailure(
            'Telefone inválido. Informe o DDD e o número completo.',
          ),
        ),
      );
    }

    return repository.addContact(
      name: cleanName,
      phone: params.phone.trim(),
      relationship: params.relationship?.trim(),
    );
  }
}
