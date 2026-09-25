import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/errors/failures.dart';
import 'package:guardiao/core/services/emergency_dispatcher.dart';
import 'package:guardiao/core/usecases/usecase.dart';
import 'package:guardiao/features/panic/domain/entities/panic_alert_entity.dart';
import 'package:guardiao/features/panic/domain/usecases/resolve_panic_usecase.dart';
import 'package:guardiao/features/panic/domain/usecases/trigger_panic_usecase.dart';
import 'package:guardiao/features/panic/presentation/bloc/panic_bloc.dart';
import 'package:guardiao/features/panic/presentation/bloc/panic_event.dart';
import 'package:guardiao/features/panic/presentation/bloc/panic_state.dart';
import 'package:mocktail/mocktail.dart';

class MockTriggerPanicUseCase extends Mock implements TriggerPanicUseCase {}

class MockResolvePanicUseCase extends Mock implements ResolvePanicUseCase {}

class MockEmergencyDispatcher extends Mock implements EmergencyDispatcher {}

void main() {
  late MockTriggerPanicUseCase mockTriggerPanicUseCase;
  late MockResolvePanicUseCase mockResolvePanicUseCase;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const TriggerPanicParams());
    registerFallbackValue(EmergencyReason.panic);
  });

  setUp(() {
    mockTriggerPanicUseCase = MockTriggerPanicUseCase();
    mockResolvePanicUseCase = MockResolvePanicUseCase();
  });

  const tAlert = PanicAlertEntity(
    id: '1',
    userId: 'u1',
    eventType: 'panic',
  );

  PanicBloc buildBloc() => PanicBloc(
    triggerPanicUseCase: mockTriggerPanicUseCase,
    resolvePanicUseCase: mockResolvePanicUseCase,
  );

  group('PanicBloc', () {
    test('estado inicial é PanicInitial', () {
      expect(buildBloc().state, equals(const PanicInitial()));
    });

    blocTest<PanicBloc, PanicState>(
      'emite [PanicLoading, PanicActive] quando dispara pânico',
      build: () {
        when(
          () => mockTriggerPanicUseCase(any()),
        ).thenAnswer((_) async => const Right(tAlert));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const PanicTriggered()),
      expect: () => [
        const PanicLoading(),
        const PanicActive(tAlert),
      ],
    );

    blocTest<PanicBloc, PanicState>(
      'emite [PanicLoading, PanicResolvedState] quando resolve pânico',
      build: () {
        when(
          () => mockResolvePanicUseCase(any()),
        ).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const PanicResolved()),
      expect: () => [
        const PanicLoading(),
        const PanicResolvedState(),
      ],
    );

    group('com EmergencyDispatcher', () {
      late MockEmergencyDispatcher mockDispatcher;

      setUp(() {
        mockDispatcher = MockEmergencyDispatcher();
        when(
          () => mockDispatcher.dispatch(
            reason: any(named: 'reason'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            eventId: any(named: 'eventId'),
          ),
        ).thenAnswer(
          (_) async =>
              const EmergencyDispatchResult(contactsFound: 3, smsSent: 3),
        );
      });

      PanicBloc buildWithDispatcher() => PanicBloc(
        triggerPanicUseCase: mockTriggerPanicUseCase,
        resolvePanicUseCase: mockResolvePanicUseCase,
        emergencyDispatcher: mockDispatcher,
      );

      blocTest<PanicBloc, PanicState>(
        'envia SMS aos contatos com a localização do alerta',
        build: () {
          when(() => mockTriggerPanicUseCase(any())).thenAnswer(
            (_) async => const Right(
              PanicAlertEntity(
                id: '1',
                userId: 'u1',
                eventType: 'panic',
                latitude: -23.5,
                longitude: -46.6,
              ),
            ),
          );
          return buildWithDispatcher();
        },
        act: (bloc) => bloc.add(const PanicTriggered()),
        expect: () => [
          const PanicLoading(),
          isA<PanicActive>()
              .having((s) => s.smsSent, 'smsSent', 3)
              .having((s) => s.contactsFound, 'contactsFound', 3),
        ],
        verify: (_) {
          verify(
            () => mockDispatcher.dispatch(
              reason: EmergencyReason.panic,
              latitude: -23.5,
              longitude: -46.6,
              eventId: '1',
            ),
          ).called(1);
        },
      );

      blocTest<PanicBloc, PanicState>(
        'ainda avisa os contatos por SMS quando o servidor está fora do ar',
        build: () {
          when(
            () => mockTriggerPanicUseCase(any()),
          ).thenAnswer((_) async => const Left(ServerFailure('offline')));
          return buildWithDispatcher();
        },
        act: (bloc) => bloc.add(const PanicTriggered()),
        expect: () => [
          const PanicLoading(),
          isA<PanicActive>().having((s) => s.smsSent, 'smsSent', 3),
        ],
      );
    });
  });
}
