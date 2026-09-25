import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/emergency_contact_entity.dart';
import '../repositories/contacts_repository.dart';

/// Nome, telefone e parentesco do contato.
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

/// Valida (Brasil ou internacional) e cadastra um contato de emergência.
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
    final trimmed = params.phone.trim();
    final hasCountryPrefix =
        trimmed.startsWith('+') || trimmed.startsWith('00');
    // Brasil: DDD + 8/9 dígitos (10-11) ou com o 55 (12-13).
    // Internacional: com "+"/"00" ou já com o código do país (ex.: +351 Portugal).
    final isValidBrPhone =
        digits.length == 10 ||
        digits.length == 11 ||
        (digits.length >= 12 && digits.length <= 15) ||
        (hasCountryPrefix && digits.length >= 8 && digits.length <= 15);

    if (!isValidBrPhone) {
      return Future.value(
        const Left(
          ValidationFailure(
            'Telefone inválido. Informe o DDD (ou o código do país) e o número completo.',
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
