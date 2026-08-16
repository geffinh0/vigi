import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/errors/failures.dart';
import 'package:guardiao/core/usecases/usecase.dart';
import 'package:guardiao/features/contacts/domain/entities/emergency_contact_entity.dart';
import 'package:guardiao/features/contacts/domain/repositories/contacts_repository.dart';
import 'package:guardiao/features/contacts/domain/usecases/get_contacts_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockContactsRepository extends Mock implements ContactsRepository {}

void main() {
  late GetContactsUseCase useCase;
  late MockContactsRepository mockRepository;

  setUp(() {
    mockRepository = MockContactsRepository();
    useCase = GetContactsUseCase(mockRepository);
  });

  const tContacts = [
    EmergencyContactEntity(
      id: '1',
      userId: 'user-1',
      name: 'Maria',
      phone: '(11) 98765-4321',
    ),
  ];

  group('GetContactsUseCase', () {
    test('retorna lista de contatos com sucesso', () async {
      when(
        () => mockRepository.getContacts(),
      ).thenAnswer((_) async => const Right(tContacts));

      final result = await useCase(const NoParams());

      expect(result, const Right(tContacts));
      verify(() => mockRepository.getContacts()).called(1);
    });

    test('retorna Failure quando repository falha', () async {
      when(
        () => mockRepository.getContacts(),
      ).thenAnswer((_) async => const Left(ServerFailure('Erro ao buscar')));

      final result = await useCase(const NoParams());

      expect(result, const Left(ServerFailure('Erro ao buscar')));
    });
  });
}
