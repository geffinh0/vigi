import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/usecases/usecase.dart';
import 'package:guardiao/core/utils/clock.dart';
import 'package:guardiao/core/utils/ticker.dart';
import 'package:guardiao/features/checkin/domain/entities/monitoring_status_entity.dart';
import 'package:guardiao/features/checkin/domain/usecases/confirm_checkin_usecase.dart';
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
  late FakeClock fakeClock;
  const fakeTicker = FakeTicker();

  final baseTime = DateTime(2026, 8, 15, 12, 0, 0);

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const StartMonitoringParams(intervalMinutes: 60));
    registerFallbackValue(const ConfirmCheckinParams());
  });

  setUp(() {
    mockStartMonitoringUseCase = MockStartMonitoringUseCase();
    mockConfirmCheckinUseCase = MockConfirmCheckinUseCase();
    mockStopMonitoringUseCase = MockStopMonitoringUseCase();
    mockGetMonitoringStatusUseCase = MockGetMonitoringStatusUseCase();
    fakeClock = FakeClock(baseTime);
  });

  CheckinBloc buildBloc() => CheckinBloc(
    startMonitoringUseCase: mockStartMonitoringUseCase,
    confirmCheckinUseCase: mockConfirmCheckinUseCase,
    stopMonitoringUseCase: mockStopMonitoringUseCase,
    getMonitoringStatusUseCase: mockGetMonitoringStatusUseCase,
    ticker: fakeTicker,
    clock: fakeClock,
  );

  group('CheckinBloc', () {
    test('estado inicial é CheckinInitial', () {
      expect(buildBloc().state, equals(const CheckinInitial()));
    });

    blocTest<CheckinBloc, CheckinState>(
      'carrega status idle quando não está monitorando',
      build: () {
        when(() => mockGetMonitoringStatusUseCase(any())).thenAnswer(
          (_) async => const Right(
            MonitoringStatusEntity(active: false, intervalMinutes: 60),
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadCheckinStatusRequested()),
      expect: () => [
        const CheckinLoading(),
        const CheckinIdle(intervalMinutes: 60),
      ],
    );

    blocTest<CheckinBloc, CheckinState>(
      'inicia monitoramento e emite sequências de ticks até AlertActive quando ticker chega a zero',
      build: () {
        when(
          () => mockStartMonitoringUseCase(any()),
        ).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const StartMonitoringRequested(intervalMinutes: 60)),
      expect: () => [
        const CheckinLoading(),
        isA<CheckinMonitoring>(),
        isA<CheckinMonitoring>(),
        isA<CheckinAlertActive>(),
      ],
    );
  });
}
