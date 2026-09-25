import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/errors/failures.dart';
import 'package:guardiao/features/contacts/domain/entities/emergency_contact_entity.dart';
import 'package:guardiao/features/contacts/domain/repositories/contacts_repository.dart';
import 'package:guardiao/features/contacts/domain/usecases/add_contact_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockContactsRepository extends Mock implements ContactsRepository {}

void main() {
  late AddContactUseCase useCase;
  late MockContactsRepository mockRepository;

  setUp(() {
    mockRepository = MockContactsRepository();
    useCase = AddContactUseCase(mockRepository);
  });

  const tContact = EmergencyContactEntity(
    id: 'contact-1',
    userId: 'user-1',
    name: 'Maria Silva',
    phone: '(11) 98765-4321',
    relationship: 'Filha',
  );

  const tValidParams = AddContactParams(
    name: 'Maria Silva',
    phone: '(11) 98765-4321',
    relationship: 'Filha',
  );

  group('AddContactUseCase', () {
    test('adiciona contato com telefone brasileiro válido', () async {
      when(
        () => mockRepository.addContact(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          relationship: any(named: 'relationship'),
        ),
      ).thenAnswer((_) async => const Right(tContact));

      final result = await useCase(tValidParams);

      expect(result, const Right(tContact));
      verify(
        () => mockRepository.addContact(
          name: tValidParams.name,
          phone: tValidParams.phone,
          relationship: tValidParams.relationship,
        ),
      ).called(1);
    });

    test(
      'rejeita telefone com formato inválido (menos de 10 dígitos)',
      () async {
        const invalidParams = AddContactParams(
          name: 'Maria',
          phone: '12345',
          relationship: 'Filha',
        );

        final result = await useCase(invalidParams);

        expect(result, isA<Left<Failure, EmergencyContactEntity>>());
        result.fold(
          (f) => expect(f, isA<ValidationFailure>()),
          (_) => fail('Deveria falhar'),
        );
      },
    );

    test('aceita telefone internacional (Portugal)', () async {
      when(
        () => mockRepository.addContact(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          relationship: any(named: 'relationship'),
        ),
      ).thenAnswer((_) async => const Right(tContact));

      final result = await useCase(
        const AddContactParams(name: 'Carla', phone: '+351 920 354 190'),
      );

      expect(result.isRight(), isTrue);
    });

    test('rejeita nome vazio', () async {
      const invalidParams = AddContactParams(
        name: '   ',
        phone: '(11) 98765-4321',
      );

      final result = await useCase(invalidParams);

      expect(result, isA<Left<Failure, EmergencyContactEntity>>());
    });

    test(
      'repassa erro quando telefone já existe (duplicidade tratada no repository)',
      () async {
        when(
          () => mockRepository.addContact(
            name: any(named: 'name'),
            phone: any(named: 'phone'),
            relationship: any(named: 'relationship'),
          ),
        ).thenAnswer(
          (_) async => const Left(ValidationFailure('Telefone já cadastrado')),
        );

        final result = await useCase(tValidParams);

        expect(result, const Left(ValidationFailure('Telefone já cadastrado')));
      },
    );
  });
}
