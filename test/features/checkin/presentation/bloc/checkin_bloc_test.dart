import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/usecases/usecase.dart';
import 'package:guardiao/core/utils/clock.dart';
import 'package:guardiao/core/utils/ticker.dart';
import 'package:guardiao/features/checkin/domain/entities/monitoring_mode_entity.dart';
import 'package:guardiao/features/checkin/domain/entities/monitoring_status_entity.dart';
import 'package:guardiao/features/checkin/domain/usecases/confirm_checkin_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/create_custom_mode_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/get_available_modes_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/get_monitoring_status_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/start_monitoring_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/stop_monitoring_usecase.dart';
import 'package:guardiao/features/checkin/presentation/bloc/checkin_bloc.dart';
import 'package:guardiao/features/checkin/presentation/bloc/checkin_event.dart';
import 'package:guardiao/features/checkin/presentation/bloc/checkin_state.dart';
import 'package:mocktail/mocktail.dart';

class MockStartMonitoringUseCase extends Mock
    implements StartMonitoringUseCase {}

class MockConfirmCheckinUseCase extends Mock implements ConfirmCheckinUseCase {}

class MockStopMonitoringUseCase extends Mock implements StopMonitoringUseCase {}

class MockGetMonitoringStatusUseCase extends Mock
    implements GetMonitoringStatusUseCase {}

class MockGetAvailableModesUseCase extends Mock
    implements GetAvailableModesUseCase {}

class MockCreateCustomModeUseCase extends Mock
    implements CreateCustomModeUseCase {}

class FakeClock implements Clock {
  FakeClock(this._now);
  final DateTime _now;

  @override
  DateTime now() => _now;
}

class FakeTicker extends Ticker {
  const FakeTicker();

  @override
  Stream<int> secondsUntil(DateTime deadline, {required Clock clock}) {
    return Stream.fromIterable([2, 1, 0]);
  }
}

void main() {
  late MockStartMonitoringUseCase mockStartMonitoringUseCase;
  late MockConfirmCheckinUseCase mockConfirmCheckinUseCase;
  late MockStopMonitoringUseCase mockStopMonitoringUseCase;
  late MockGetMonitoringStatusUseCase mockGetMonitoringStatusUseCase;
  late MockGetAvailableModesUseCase mockGetAvailableModesUseCase;
  late MockCreateCustomModeUseCase mockCreateCustomModeUseCase;
  late FakeClock fakeClock;
  const fakeTicker = FakeTicker();

  final baseTime = DateTime(2026, 8, 15, 12, 0, 0);

  const tModeRoutine = MonitoringModeEntity(
    id: 'mode-routine',
    name: 'Rotina padrão',
    iconKey: 'routine',
    defaultIntervalMinutes: 60,
    isSystemDefault: true,
  );

  const tModeShower = MonitoringModeEntity(
    id: 'mode-shower',
    name: 'Banho',
    iconKey: 'shower',
    defaultIntervalMinutes: 20,
    isSystemDefault: true,
  );

  const tModes = [tModeRoutine, tModeShower];

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      const StartMonitoringParams(
        modeId: 'mode-routine',
        intervalOverrideMinutes: 60,
      ),
    );
    registerFallbackValue(
      const CreateCustomModeParams(
        name: 'Passeio',
        defaultIntervalMinutes: 30,
      ),
    );
    registerFallbackValue(const ConfirmCheckinParams());
  });

  setUp(() {
    mockStartMonitoringUseCase = MockStartMonitoringUseCase();
    mockConfirmCheckinUseCase = MockConfirmCheckinUseCase();
    mockStopMonitoringUseCase = MockStopMonitoringUseCase();
    mockGetMonitoringStatusUseCase = MockGetMonitoringStatusUseCase();
    mockGetAvailableModesUseCase = MockGetAvailableModesUseCase();
    mockCreateCustomModeUseCase = MockCreateCustomModeUseCase();
    fakeClock = FakeClock(baseTime);
  });

  CheckinBloc buildBloc() => CheckinBloc(
    startMonitoringUseCase: mockStartMonitoringUseCase,
    confirmCheckinUseCase: mockConfirmCheckinUseCase,
    stopMonitoringUseCase: mockStopMonitoringUseCase,
    getMonitoringStatusUseCase: mockGetMonitoringStatusUseCase,
    getAvailableModesUseCase: mockGetAvailableModesUseCase,
    createCustomModeUseCase: mockCreateCustomModeUseCase,
    ticker: fakeTicker,
    clock: fakeClock,
  );

  group('CheckinBloc', () {
    test('estado inicial é CheckinInitial', () {
      expect(buildBloc().state, equals(const CheckinInitial()));
    });

    blocTest<CheckinBloc, CheckinState>(
      'carrega modos disponíveis e status idle quando não está monitorando',
      build: () {
        when(
          () => mockGetAvailableModesUseCase(any()),
        ).thenAnswer((_) async => const Right(tModes));
        when(() => mockGetMonitoringStatusUseCase(any())).thenAnswer(
          (_) async => const Right(
            MonitoringStatusEntity(
              active: false,
              intervalMinutes: 60,
              activeModeId: 'mode-routine',
            ),
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadCheckinStatusRequested()),
      expect: () => [
        const CheckinLoading(),
        const CheckinIdle(
          intervalMinutes: 60,
          availableModes: tModes,
          selectedMode: tModeRoutine,
        ),
      ],
    );

    blocTest<CheckinBloc, CheckinState>(
      'selecionar modo atualiza selectedMode e intervalMinutes no CheckinIdle',
      build: () => buildBloc(),
      seed: () => const CheckinIdle(
        intervalMinutes: 60,
        availableModes: tModes,
        selectedMode: tModeRoutine,
      ),
      act: (bloc) => bloc.add(const SelectModeRequested(tModeShower)),
      expect: () => [
        const CheckinIdle(
          intervalMinutes: 20,
          availableModes: tModes,
          selectedMode: tModeShower,
        ),
      ],
    );

    blocTest<CheckinBloc, CheckinState>(
      'selecionar Banho e iniciar monitoramento emite sequências de ticks com activeMode até AlertActive',
      build: () {
        when(
          () => mockStartMonitoringUseCase(any()),
        ).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      seed: () => const CheckinIdle(
        intervalMinutes: 20,
        availableModes: tModes,
        selectedMode: tModeShower,
      ),
      act: (bloc) => bloc.add(
        const StartMonitoringRequested(
          modeId: 'mode-shower',
          intervalOverrideMinutes: 20,
        ),
      ),
      expect: () => [
        const CheckinLoading(),
        isA<CheckinMonitoring>().having(
          (s) => s.activeMode?.name,
          'activeMode.name',
          'Banho',
        ),
        isA<CheckinMonitoring>(),
        isA<CheckinAlertActive>().having(
          (s) => s.activeMode?.name,
          'activeMode.name',
          'Banho',
        ),
      ],
    );

    blocTest<CheckinBloc, CheckinState>(
      'criar modo customizado adiciona à lista de disponíveis e seleciona-o',
      build: () {
        const createdMode = MonitoringModeEntity(
          id: 'custom-1',
          name: 'Caminhada',
          iconKey: 'walk',
          defaultIntervalMinutes: 45,
          isSystemDefault: false,
        );
        when(
          () => mockCreateCustomModeUseCase(any()),
        ).thenAnswer((_) async => const Right(createdMode));
        return buildBloc();
      },
      seed: () => const CheckinIdle(
        intervalMinutes: 60,
        availableModes: tModes,
        selectedMode: tModeRoutine,
      ),
      act: (bloc) => bloc.add(
        const CreateCustomModeRequested(
          name: 'Caminhada',
          defaultIntervalMinutes: 45,
          iconKey: 'walk',
        ),
      ),
      expect: () => [
        const CheckinLoading(),
        isA<CheckinIdle>()
            .having((s) => s.availableModes.length, 'availableModes.length', 3)
            .having(
              (s) => s.selectedMode?.name,
              'selectedMode.name',
              'Caminhada',
            )
            .having((s) => s.intervalMinutes, 'intervalMinutes', 45),
      ],
    );
  });
}
