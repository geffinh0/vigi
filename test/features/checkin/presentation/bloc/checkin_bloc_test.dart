import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/services/alarm_service.dart';
import 'package:guardiao/core/services/notification_service.dart';
import 'package:guardiao/core/services/widget_sync_service.dart';
import 'package:guardiao/core/usecases/usecase.dart';
import 'package:guardiao/core/utils/clock.dart';
import 'package:guardiao/core/utils/ticker.dart';
import 'package:guardiao/features/checkin/domain/entities/monitoring_mode_entity.dart';
import 'package:guardiao/features/checkin/domain/entities/monitoring_status_entity.dart';
import 'package:guardiao/features/checkin/domain/usecases/confirm_checkin_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/create_custom_mode_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/get_available_modes_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/get_monitoring_status_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/save_monitoring_settings_usecase.dart';
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

class MockSaveMonitoringSettingsUseCase extends Mock
    implements SaveMonitoringSettingsUseCase {}

class MockAlarmService extends Mock implements AlarmService {}

class MockNotificationService extends Mock implements NotificationService {}

class MockWidgetSyncService extends Mock implements WidgetSyncService {}

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
  late MockSaveMonitoringSettingsUseCase mockSaveMonitoringSettingsUseCase;
  late MockAlarmService mockAlarmService;
  late MockNotificationService mockNotificationService;
  late MockWidgetSyncService mockWidgetSyncService;
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
      const SaveMonitoringSettingsParams(
        modeId: 'mode-routine',
        intervalMinutes: 35,
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
    mockSaveMonitoringSettingsUseCase = MockSaveMonitoringSettingsUseCase();
    mockAlarmService = MockAlarmService();
    mockNotificationService = MockNotificationService();
    mockWidgetSyncService = MockWidgetSyncService();
    fakeClock = FakeClock(baseTime);

    when(() => mockAlarmService.startAlert()).thenAnswer((_) async {});
    when(() => mockAlarmService.stopAlert()).thenAnswer((_) async {});
    when(
      () => mockNotificationService.showTimeoutAlert(),
    ).thenAnswer((_) async {});
    when(() => mockNotificationService.cancelAlert()).thenAnswer((_) async {});
    when(
      () => mockWidgetSyncService.updateWidgetData(
        vigiState: any(named: 'vigiState'),
        minutesRemaining: any(named: 'minutesRemaining'),
        modeName: any(named: 'modeName'),
        isMonitoring: any(named: 'isMonitoring'),
        timeDisplay: any(named: 'timeDisplay'),
        statusDisplay: any(named: 'statusDisplay'),
      ),
    ).thenAnswer((_) async {});
  });

  CheckinBloc buildBloc() => CheckinBloc(
    startMonitoringUseCase: mockStartMonitoringUseCase,
    confirmCheckinUseCase: mockConfirmCheckinUseCase,
    stopMonitoringUseCase: mockStopMonitoringUseCase,
    getMonitoringStatusUseCase: mockGetMonitoringStatusUseCase,
    getAvailableModesUseCase: mockGetAvailableModesUseCase,
    createCustomModeUseCase: mockCreateCustomModeUseCase,
    saveMonitoringSettingsUseCase: mockSaveMonitoringSettingsUseCase,
    ticker: fakeTicker,
    clock: fakeClock,
    alarmService: mockAlarmService,
    notificationService: mockNotificationService,
    widgetSyncService: mockWidgetSyncService,
  );

  group('CheckinBloc', () {
    test('estado inicial é CheckinInitial', () {
      expect(buildBloc().state, equals(const CheckinInitial()));
    });

    blocTest<CheckinBloc, CheckinState>(
      'carrega configuração persistida (35 min) e não o default estático do modo (60 min)',
      build: () {
        when(
          () => mockGetAvailableModesUseCase(any()),
        ).thenAnswer((_) async => const Right(tModes));
        when(() => mockGetMonitoringStatusUseCase(any())).thenAnswer(
          (_) async => const Right(
            MonitoringStatusEntity(
              active: false,
              intervalMinutes: 35,
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
          intervalMinutes: 35,
          availableModes: [
            MonitoringModeEntity(
              id: 'mode-routine',
              name: 'Rotina padrão',
              iconKey: 'routine',
              defaultIntervalMinutes: 35,
              isSystemDefault: true,
            ),
            tModeShower,
          ],
          selectedMode: MonitoringModeEntity(
            id: 'mode-routine',
            name: 'Rotina padrão',
            iconKey: 'routine',
            defaultIntervalMinutes: 35,
            isSystemDefault: true,
          ),
        ),
      ],
    );

    blocTest<CheckinBloc, CheckinState>(
      'aciona o AlarmService, NotificationService e WidgetSyncService quando o estado vira CheckinAlertActive',
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
        isA<CheckinMonitoring>(),
        isA<CheckinMonitoring>(),
        isA<CheckinAlertActive>(),
      ],
      verify: (_) {
        verify(() => mockAlarmService.startAlert()).called(1);
        verify(() => mockNotificationService.showTimeoutAlert()).called(1);
        verify(
          () => mockWidgetSyncService.updateWidgetData(
            vigiState: 'alerta',
            minutesRemaining: 0,
            modeName: any(named: 'modeName'),
            isMonitoring: true,
            timeDisplay: any(named: 'timeDisplay'),
            statusDisplay: any(named: 'statusDisplay'),
          ),
        ).called(1);
      },
    );

    blocTest<CheckinBloc, CheckinState>(
      'desativa o alarme sonoro e cancela notificação ao confirmar checkin',
      build: () {
        when(
          () => mockConfirmCheckinUseCase(any()),
        ).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ConfirmCheckinRequested()),
      verify: (_) {
        verify(
          () => mockAlarmService.stopAlert(),
        ).called(greaterThanOrEqualTo(1));
        verify(
          () => mockNotificationService.cancelAlert(),
        ).called(greaterThanOrEqualTo(1));
      },
    );

    blocTest<CheckinBloc, CheckinState>(
      'salvar configurações atualiza selectedMode e intervalMinutes no CheckinIdle',
      build: () {
        when(
          () => mockSaveMonitoringSettingsUseCase(any()),
        ).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      seed: () => const CheckinIdle(
        intervalMinutes: 60,
        availableModes: tModes,
        selectedMode: tModeRoutine,
      ),
      act: (bloc) => bloc.add(
        const SaveMonitoringSettingsRequested(
          modeId: 'mode-shower',
          intervalMinutes: 25,
        ),
      ),
      expect: () => [
        const CheckinLoading(),
        const CheckinIdle(
          intervalMinutes: 25,
          availableModes: [
            tModeRoutine,
            MonitoringModeEntity(
              id: 'mode-shower',
              name: 'Banho',
              iconKey: 'shower',
              defaultIntervalMinutes: 25,
              isSystemDefault: true,
            ),
          ],
          selectedMode: MonitoringModeEntity(
            id: 'mode-shower',
            name: 'Banho',
            iconKey: 'shower',
            defaultIntervalMinutes: 25,
            isSystemDefault: true,
          ),
        ),
      ],
    );

    blocTest<CheckinBloc, CheckinState>(
      'retorna automaticamente para Rotina padrão ao confirmar checkin em modo temporário (Banho)',
      build: () {
        when(
          () => mockStartMonitoringUseCase(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockConfirmCheckinUseCase(any()),
        ).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      seed: () => const CheckinIdle(
        intervalMinutes: 60,
        availableModes: tModes,
        selectedMode: tModeRoutine,
      ),
      act: (bloc) async {
        // Inicia banho
        bloc.add(
          const StartMonitoringRequested(
            modeId: 'mode-shower',
            intervalOverrideMinutes: 20,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        // Termina banho
        bloc.add(const ConfirmCheckinRequested());
      },
      expect: () => [
        const CheckinLoading(),
        isA<CheckinMonitoring>(), // Tick do Banho
        isA<CheckinMonitoring>(), // Tick do Banho
        isA<CheckinAlertActive>(), // Fim do Banho
        isA<CheckinMonitoring>(), // Retorno para Rotina padrão
        isA<CheckinMonitoring>(),
        isA<CheckinAlertActive>(),
      ],
    );
  });
}
