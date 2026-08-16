import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/errors/failures.dart';
import 'package:guardiao/features/contacts/domain/repositories/contacts_repository.dart';
import 'package:guardiao/features/contacts/domain/usecases/delete_contact_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockContactsRepository extends Mock implements ContactsRepository {}

void main() {
  late DeleteContactUseCase useCase;
  late MockContactsRepository mockRepository;

  setUp(() {
    mockRepository = MockContactsRepository();
    useCase = DeleteContactUseCase(mockRepository);
  });

  group('DeleteContactUseCase', () {
    test('remove contato com sucesso', () async {
      when(
        () => mockRepository.deleteContact(any()),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase(const DeleteContactParams('contact-1'));

      expect(result, const Right(null));
      verify(() => mockRepository.deleteContact('contact-1')).called(1);
    });

    test('rejeita ID vazio', () async {
      final result = await useCase(const DeleteContactParams(''));
      expect(result, isA<Left<Failure, void>>());
    });
  });
}
