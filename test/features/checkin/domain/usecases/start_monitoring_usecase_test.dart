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
            modeId: any(named: 'modeId'),
            intervalOverrideMinutes: any(named: 'intervalOverrideMinutes'),
          ),
        ).thenAnswer((_) async => const Right(null));

        final result = await useCase(
          const StartMonitoringParams(
            modeId: 'mode-123',
            intervalOverrideMinutes: 20,
          ),
        );

        expect(result, const Right(null));
        verify(
          () => mockCheckinRepository.startMonitoring(
            modeId: 'mode-123',
            intervalOverrideMinutes: 20,
          ),
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
          const StartMonitoringParams(modeId: 'mode-123'),
        );

        expect(result, isA<Left<Failure, void>>());
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('Deveria ter falhado'),
        );
        verifyNever(
          () => mockCheckinRepository.startMonitoring(
            modeId: any(named: 'modeId'),
            intervalOverrideMinutes: any(named: 'intervalOverrideMinutes'),
          ),
        );
      },
    );

    test('rejeita modeId vazio', () async {
      final result = await useCase(
        const StartMonitoringParams(modeId: '   '),
      );
      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (failure) => expect(failure.message, 'Modo de monitoramento inválido'),
        (_) => fail('Deveria ter falhado'),
      );
    });

    test('rejeita intervalOverrideMinutes menor ou igual a zero', () async {
      final result = await useCase(
        const StartMonitoringParams(
          modeId: 'mode-123',
          intervalOverrideMinutes: 0,
        ),
      );
      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (failure) =>
            expect(failure.message, 'Intervalo deve ser maior que 0 minutos'),
        (_) => fail('Deveria ter falhado'),
      );
    });
  });
}
