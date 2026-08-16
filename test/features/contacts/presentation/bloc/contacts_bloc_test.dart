import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/errors/failures.dart';
import 'package:guardiao/core/usecases/usecase.dart';
import 'package:guardiao/features/contacts/domain/entities/emergency_contact_entity.dart';
import 'package:guardiao/features/contacts/domain/usecases/add_contact_usecase.dart';
import 'package:guardiao/features/contacts/domain/usecases/delete_contact_usecase.dart';
import 'package:guardiao/features/contacts/domain/usecases/get_contacts_usecase.dart';
import 'package:guardiao/features/contacts/presentation/bloc/contacts_bloc.dart';
import 'package:guardiao/features/contacts/presentation/bloc/contacts_event.dart';
import 'package:guardiao/features/contacts/presentation/bloc/contacts_state.dart';
import 'package:mocktail/mocktail.dart';

class MockGetContactsUseCase extends Mock implements GetContactsUseCase {}

class MockAddContactUseCase extends Mock implements AddContactUseCase {}

class MockDeleteContactUseCase extends Mock implements DeleteContactUseCase {}

void main() {
  late MockGetContactsUseCase mockGetContactsUseCase;
  late MockAddContactUseCase mockAddContactUseCase;
  late MockDeleteContactUseCase mockDeleteContactUseCase;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      const AddContactParams(name: '', phone: ''),
    );
    registerFallbackValue(const DeleteContactParams(''));
  });

  setUp(() {
    mockGetContactsUseCase = MockGetContactsUseCase();
    mockAddContactUseCase = MockAddContactUseCase();
    mockDeleteContactUseCase = MockDeleteContactUseCase();
  });

  const tContacts = [
    EmergencyContactEntity(
      id: '1',
      userId: 'u1',
      name: 'Maria',
      phone: '(11) 98765-4321',
    ),
  ];

  ContactsBloc buildBloc() => ContactsBloc(
    getContactsUseCase: mockGetContactsUseCase,
    addContactUseCase: mockAddContactUseCase,
    deleteContactUseCase: mockDeleteContactUseCase,
  );

  group('ContactsBloc', () {
    test('estado inicial é ContactsInitial', () {
      expect(buildBloc().state, equals(const ContactsInitial()));
    });

    blocTest<ContactsBloc, ContactsState>(
      'emite [ContactsLoading, ContactsLoaded] quando busca contatos com sucesso',
      build: () {
        when(
          () => mockGetContactsUseCase(any()),
        ).thenAnswer((_) async => const Right(tContacts));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadContactsRequested()),
      expect: () => [
        const ContactsLoading(),
        const ContactsLoaded(tContacts),
      ],
    );

    blocTest<ContactsBloc, ContactsState>(
      'emite [ContactsLoading, ContactsFailure] quando falha ao buscar contatos',
      build: () {
        when(() => mockGetContactsUseCase(any())).thenAnswer(
          (_) async => const Left(ServerFailure('Erro no servidor')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadContactsRequested()),
      expect: () => [
        const ContactsLoading(),
        const ContactsFailure('Erro no servidor'),
      ],
    );
  });
}
