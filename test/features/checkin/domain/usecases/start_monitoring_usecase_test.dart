import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/errors/failures.dart';
import 'package:guardiao/core/usecases/usecase.dart';
import 'package:guardiao/features/checkin/domain/repositories/checkin_repository.dart';
import 'package:guardiao/features/checkin/domain/usecases/start_monitoring_usecase.dart';
import 'package:guardiao/features/contacts/domain/entities/emergency_contact_entity.dart';
import 'package:guardiao/features/contacts/domain/repositories/contacts_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckinRepository extends Mock implements CheckinRepository {}

class MockContactsRepository extends Mock implements ContactsRepository {}

void main() {
  late StartMonitoringUseCase useCase;
  late MockCheckinRepository mockCheckinRepository;
  late MockContactsRepository mockContactsRepository;

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    mockCheckinRepository = MockCheckinRepository();
    mockContactsRepository = MockContactsRepository();
    useCase = StartMonitoringUseCase(
      mockCheckinRepository,
      mockContactsRepository,
    );
  });

  const tContact = EmergencyContactEntity(
    id: '1',
    userId: 'u1',
    name: 'Maria',
    phone: '(11) 98765-4321',
  );

  group('StartMonitoringUseCase', () {
    test(
      'inicia monitoramento com sucesso quando há ao menos um contato',
      () async {
        when(
          () => mockContactsRepository.getContacts(),
        ).thenAnswer((_) async => const Right([tContact]));
        when(
          () => mockCheckinRepository.startMonitoring(
            intervalMinutes: any(named: 'intervalMinutes'),
          ),
        ).thenAnswer((_) async => const Right(null));

        final result = await useCase(
          const StartMonitoringParams(intervalMinutes: 60),
        );

        expect(result, const Right(null));
        verify(
          () => mockCheckinRepository.startMonitoring(intervalMinutes: 60),
        ).called(1);
      },
    );

    test(
      'bloqueia início de monitoramento quando a lista de contatos estiver vazia (regra de negócio)',
      () async {
        when(
          () => mockContactsRepository.getContacts(),
        ).thenAnswer((_) async => const Right([]));

        final result = await useCase(
          const StartMonitoringParams(intervalMinutes: 60),
        );

        expect(result, isA<Left<Failure, void>>());
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('Deveria ter falhado'),
        );
        verifyNever(
          () => mockCheckinRepository.startMonitoring(
            intervalMinutes: any(named: 'intervalMinutes'),
          ),
        );
      },
    );

    test('rejeita intervalo menor ou igual a zero', () async {
      final result = await useCase(
        const StartMonitoringParams(intervalMinutes: 0),
      );
      expect(result, isA<Left<Failure, void>>());
    });
  });
}
