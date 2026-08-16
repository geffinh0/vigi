import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/errors/failures.dart';
import 'package:guardiao/features/contacts/data/datasources/contacts_remote_datasource.dart';
import 'package:guardiao/features/contacts/data/models/emergency_contact_model.dart';
import 'package:guardiao/features/contacts/data/repositories/contacts_repository_impl.dart';
import 'package:guardiao/features/contacts/domain/entities/emergency_contact_entity.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockContactsRemoteDataSource extends Mock
    implements ContactsRemoteDataSource {}

void main() {
  late ContactsRepositoryImpl repository;
  late MockContactsRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockContactsRemoteDataSource();
    repository = ContactsRepositoryImpl(mockDataSource);
  });

  const tContactModel = EmergencyContactModel(
    id: '1',
    userId: 'user-1',
    name: 'Maria',
    phone: '(11) 98765-4321',
  );

  group('ContactsRepositoryImpl', () {
    test('getContacts retorna Right com lista de modelos', () async {
      when(
        () => mockDataSource.getContacts(),
      ).thenAnswer((_) async => [tContactModel]);

      final result = await repository.getContacts();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Deveria ser Right'),
        (list) {
          expect(list, equals(<EmergencyContactEntity>[tContactModel]));
        },
      );
    });

    test(
      'addContact trata erro 23505 (duplicidade) convertendo para ValidationFailure',
      () async {
        when(
          () => mockDataSource.addContact(
            name: any(named: 'name'),
            phone: any(named: 'phone'),
            relationship: any(named: 'relationship'),
          ),
        ).thenThrow(
          const PostgrestException(message: 'duplicate key', code: '23505'),
        );

        final result = await repository.addContact(
          name: 'Maria',
          phone: '(11) 98765-4321',
        );

        expect(result, isA<Left<Failure, dynamic>>());
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('Deveria retornar Left'),
        );
      },
    );
  });
}
