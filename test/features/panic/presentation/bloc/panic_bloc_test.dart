import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
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

void main() {
  late MockTriggerPanicUseCase mockTriggerPanicUseCase;
  late MockResolvePanicUseCase mockResolvePanicUseCase;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const TriggerPanicParams());
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
  });
}
