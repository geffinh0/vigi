import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/errors/failures.dart';
import 'package:guardiao/core/services/alarm_service.dart';
import 'package:guardiao/core/services/checkin_messages.dart';
import 'package:guardiao/core/services/emergency_dispatcher.dart';
import 'package:guardiao/core/services/notification_service.dart';
import 'package:guardiao/core/services/widget_sync_service.dart';
import 'package:guardiao/core/theme/vigi_state.dart';
import 'package:guardiao/core/usecases/usecase.dart';
import 'package:guardiao/core/utils/clock.dart';
import 'package:guardiao/core/utils/ticker.dart';
import 'package:guardiao/features/checkin/domain/entities/checkin_schedule.dart';
import 'package:guardiao/features/checkin/domain/entities/monitoring_mode_entity.dart';
import 'package:guardiao/features/checkin/domain/entities/monitoring_status_entity.dart';
import 'package:guardiao/features/checkin/domain/usecases/confirm_checkin_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/create_custom_mode_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/extend_deadline_usecase.dart';
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

class MockExtendDeadlineUseCase extends Mock implements ExtendDeadlineUseCase {}

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

class MockEmergencyDispatcher extends Mock implements EmergencyDispatcher {}

class FakeClock implements Clock {
  FakeClock(this.current);
  DateTime current;

  @override
  DateTime now() => current;
}

/// Cada contagem (a do prazo e a da tolerância) emite 2, 1 e 0.
class FakeTicker extends Ticker {
  const FakeTicker();

  @override
  Stream<int> secondsUntil(DateTime deadline, {required Clock clock}) {
    return Stream.fromIterable([2, 1, 0]);
  }
}

/// Só a primeira contagem vence; as seguintes ficam longe do fim.
class OneShotTicker extends Ticker {
  OneShotTicker();

  int _calls = 0;

  @override
  Stream<int> secondsUntil(DateTime deadline, {required Clock clock}) {
    _calls++;
    return _calls == 1 ? Stream.fromIterable([1, 0]) : Stream.value(600);
  }
}

/// Nenhuma contagem vence: o estado fica onde o teste o colocou.
class IdleTicker extends Ticker {
  const IdleTicker();

  @override
  Stream<int> secondsUntil(DateTime deadline, {required Clock clock}) {
    return Stream.value(600);
  }
}

void main() {
  late MockStartMonitoringUseCase mockStartMonitoringUseCase;
  late MockConfirmCheckinUseCase mockConfirmCheckinUseCase;
  late MockExtendDeadlineUseCase mockExtendDeadlineUseCase;
  late MockStopMonitoringUseCase mockStopMonitoringUseCase;
  late MockGetMonitoringStatusUseCase mockGetMonitoringStatusUseCase;
  late MockGetAvailableModesUseCase mockGetAvailableModesUseCase;
  late MockCreateCustomModeUseCase mockCreateCustomModeUseCase;
  late MockSaveMonitoringSettingsUseCase mockSaveMonitoringSettingsUseCase;
  late MockAlarmService mockAlarmService;
  late MockNotificationService mockNotificationService;
  late MockWidgetSyncService mockWidgetSyncService;
  late MockEmergencyDispatcher mockDispatcher;
  late FakeClock fakeClock;
  const fakeTicker = FakeTicker();

  // Exemplo do guia: Rotina de 1 h, com o prazo às 15:00.
  final baseTime = DateTime(2026, 9, 30, 14);
  final deadline = DateTime(2026, 9, 30, 15);

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

  CheckinCalling callingState({bool lastCall = false, bool canSnooze = true}) =>
      CheckinCalling(
        deadline: deadline,
        lastCallAt: DateTime(2026, 9, 30, 15, 10),
        escalatesAt: DateTime(2026, 9, 30, 15, 15),
        lastCall: lastCall,
        canSnooze: canSnooze,
        activeMode: tModeRoutine,
      );

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
    registerFallbackValue(EmergencyReason.checkinTimeout);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(
      CheckinCallInfo(
        deadline: DateTime(2026),
        lastCallAt: DateTime(2026),
        escalatesAt: DateTime(2026),
      ),
    );
  });

  setUp(() {
    mockStartMonitoringUseCase = MockStartMonitoringUseCase();
    mockConfirmCheckinUseCase = MockConfirmCheckinUseCase();
    mockExtendDeadlineUseCase = MockExtendDeadlineUseCase();
    mockStopMonitoringUseCase = MockStopMonitoringUseCase();
    mockGetMonitoringStatusUseCase = MockGetMonitoringStatusUseCase();
    mockGetAvailableModesUseCase = MockGetAvailableModesUseCase();
    mockCreateCustomModeUseCase = MockCreateCustomModeUseCase();
    mockSaveMonitoringSettingsUseCase = MockSaveMonitoringSettingsUseCase();
    mockAlarmService = MockAlarmService();
    mockNotificationService = MockNotificationService();
    mockWidgetSyncService = MockWidgetSyncService();
    mockDispatcher = MockEmergencyDispatcher();
    fakeClock = FakeClock(baseTime);

    when(() => mockAlarmService.startCall()).thenAnswer((_) async {});
    when(
      () => mockAlarmService.startLastCall(
        playSound: any(named: 'playSound'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockAlarmService.playAlertConfirmed()).thenAnswer((_) async {});
    when(() => mockAlarmService.confirmFeedback()).thenAnswer((_) async {});
    when(() => mockAlarmService.stopAlert()).thenAnswer((_) async {});

    when(
      () => mockNotificationService.scheduleCheckinCall(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.showCheckinCall(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.showLastCall(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.showContactsAlerted(
        notified: any(named: 'notified'),
        at: any(named: 'at'),
        withLocation: any(named: 'withLocation'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.areNotificationsEnabled(),
    ).thenAnswer((_) async => true);
    when(() => mockNotificationService.cancelAlert()).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelScheduledAlarm(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.showMonitoringOngoing(
        modeName: any(named: 'modeName'),
        nextDeadline: any(named: 'nextDeadline'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelMonitoringOngoing(),
    ).thenAnswer((_) async {});

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

    when(
      () => mockStartMonitoringUseCase(any()),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => mockConfirmCheckinUseCase(any()),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => mockExtendDeadlineUseCase(any()),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => mockStopMonitoringUseCase(any()),
    ).thenAnswer((_) async => const Right(null));

    when(
      () => mockDispatcher.dispatch(
        reason: any(named: 'reason'),
        deadline: any(named: 'deadline'),
      ),
    ).thenAnswer(
      (_) async => EmergencyDispatchResult(
        contactsFound: 2,
        smsSent: 2,
        latitude: -23.55,
        longitude: -46.63,
        sentAt: DateTime(2026, 9, 30, 15, 15),
        address: 'Rua Augusta, 1200, Consolação',
        deliveries: const [
          ContactDelivery(name: 'Maria', phone: '+5511', sent: true),
          ContactDelivery(name: 'João', phone: '+5521', sent: true),
        ],
      ),
    );
    when(() => mockDispatcher.dispatchAllClear()).thenAnswer((_) async => 2);
  });

  CheckinBloc buildBloc({
    Ticker ticker = fakeTicker,
    bool withDispatcher = false,
    Duration? escalationDelay,
  }) => CheckinBloc(
    startMonitoringUseCase: mockStartMonitoringUseCase,
    confirmCheckinUseCase: mockConfirmCheckinUseCase,
    stopMonitoringUseCase: mockStopMonitoringUseCase,
    getMonitoringStatusUseCase: mockGetMonitoringStatusUseCase,
    getAvailableModesUseCase: mockGetAvailableModesUseCase,
    createCustomModeUseCase: mockCreateCustomModeUseCase,
    saveMonitoringSettingsUseCase: mockSaveMonitoringSettingsUseCase,
    extendDeadlineUseCase: mockExtendDeadlineUseCase,
    ticker: ticker,
    clock: fakeClock,
    alarmService: mockAlarmService,
    notificationService: mockNotificationService,
    widgetSyncService: mockWidgetSyncService,
    emergencyDispatcher: withDispatcher ? mockDispatcher : null,
    escalationDelay: escalationDelay,
    firstNameProvider: () => 'Lúcia Almeida',
    contactNamesProvider: () async => ['Maria Silva', 'João'],
  );

  const idleRoutine = CheckinIdle(
    intervalMinutes: 60,
    availableModes: tModes,
    selectedMode: tModeRoutine,
  );

  const startRoutine = StartMonitoringRequested(
    modeId: 'mode-routine',
    intervalOverrideMinutes: 60,
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
      verify: (_) {
        // Pausado é pausado: o widget não finge que há vigília.
        verify(
          () => mockWidgetSyncService.updateWidgetData(
            vigiState: 'descansando',
            minutesRemaining: any(named: 'minutesRemaining'),
            modeName: any(named: 'modeName'),
            isMonitoring: false,
            timeDisplay: any(named: 'timeDisplay'),
            statusDisplay: any(named: 'statusDisplay'),
          ),
        ).called(1);
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
      seed: () => idleRoutine,
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
  });

  group('escada de estados', () {
    blocTest<CheckinBloc, CheckinState>(
      'Vigiando: agenda a chamada e a última chamada do exemplo do guia '
      '(15:00, 15:10, 15:15), em silêncio',
      build: () => buildBloc(ticker: const IdleTicker()),
      seed: () => idleRoutine,
      act: (bloc) => bloc.add(startRoutine),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        const CheckinLoading(),
        isA<CheckinMonitoring>()
            .having((s) => s.vigiState, 'vigiState', VigiState.vigiando)
            .having((s) => s.nextDeadline, 'nextDeadline', deadline)
            .having((s) => s.remainingFraction, 'fração', closeTo(1 / 6, 0.01))
            .having((s) => s.availableModes, 'modos', tModes),
      ],
      verify: (_) {
        final info =
            verify(
                  () => mockNotificationService.scheduleCheckinCall(
                    captureAny(),
                  ),
                ).captured.single
                as CheckinCallInfo;
        expect(info.deadline, deadline);
        expect(info.lastCallAt, DateTime(2026, 9, 30, 15, 10));
        expect(info.escalatesAt, DateTime(2026, 9, 30, 15, 15));
        expect(info.firstName, 'Lúcia');
        expect(info.contactNames, ['Maria Silva', 'João']);
        expect(info.canSnooze, isTrue);

        verifyNever(() => mockAlarmService.startCall());
        verifyNever(
          () => mockAlarmService.startLastCall(
            playSound: any(named: 'playSound'),
          ),
        );
        verify(
          () => mockWidgetSyncService.updateWidgetData(
            vigiState: 'vigiando',
            minutesRemaining: 60,
            modeName: 'Rotina',
            isMonitoring: true,
            timeDisplay: '15:00',
            statusDisplay: any(named: 'statusDisplay'),
          ),
        ).called(1);
      },
    );

    blocTest<CheckinBloc, CheckinState>(
      'Sua vez e Última chamada: o prazo chega, o Vigi chama e depois toca '
      'o alarme',
      build: buildBloc,
      seed: () => idleRoutine,
      act: (bloc) => bloc.add(startRoutine),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        const CheckinLoading(),
        isA<CheckinMonitoring>(),
        isA<CheckinMonitoring>(),
        isA<CheckinCalling>()
            .having((s) => s.vigiState, 'vigiState', VigiState.suaVez)
            .having((s) => s.deadline, 'deadline', deadline)
            .having(
              (s) => s.escalatesAt,
              'escalatesAt',
              DateTime(2026, 9, 30, 15, 15),
            )
            .having((s) => s.canSnooze, 'canSnooze', true),
        isA<CheckinCalling>().having(
          (s) => s.vigiState,
          'vigiState',
          VigiState.ultimaChamada,
        ),
      ],
      verify: (_) {
        verify(() => mockAlarmService.startCall()).called(1);
        verify(() => mockNotificationService.showCheckinCall(any())).called(1);
        // Com as notificações ligadas, o alarme vem da notificação.
        verify(
          () => mockAlarmService.startLastCall(),
        ).called(1);
        verify(() => mockNotificationService.showLastCall(any())).called(1);
        verify(
          () => mockWidgetSyncService.updateWidgetData(
            vigiState: 'suaVez',
            minutesRemaining: any(named: 'minutesRemaining'),
            modeName: any(named: 'modeName'),
            isMonitoring: true,
            timeDisplay: '15:15',
            statusDisplay: any(named: 'statusDisplay'),
          ),
        ).called(1);
        verify(
          () => mockWidgetSyncService.updateWidgetData(
            vigiState: 'ultimaChamada',
            minutesRemaining: any(named: 'minutesRemaining'),
            modeName: any(named: 'modeName'),
            isMonitoring: true,
            timeDisplay: '15:15',
            statusDisplay: any(named: 'statusDisplay'),
          ),
        ).called(1);
        // Ninguém foi avisado: não há quem acionar neste teste.
        verifyNever(
          () => mockNotificationService.showContactsAlerted(
            notified: any(named: 'notified'),
            at: any(named: 'at'),
            withLocation: any(named: 'withLocation'),
          ),
        );
      },
    );

    blocTest<CheckinBloc, CheckinState>(
      'sem notificações, o próprio app toca o alarme da última chamada',
      build: () {
        when(
          () => mockNotificationService.areNotificationsEnabled(),
        ).thenAnswer((_) async => false);
        return buildBloc();
      },
      seed: () => idleRoutine,
      act: (bloc) => bloc.add(startRoutine),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(
          () => mockAlarmService.startLastCall(playSound: true),
        ).called(1);
      },
    );

    blocTest<CheckinBloc, CheckinState>(
      'Aliviado: confirmar silencia tudo, agradece e recomeça o ciclo',
      build: () => buildBloc(ticker: const IdleTicker()),
      seed: callingState,
      act: (bloc) => bloc.add(const ConfirmCheckinRequested()),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<CheckinMonitoring>()
            .having((s) => s.vigiState, 'vigiState', VigiState.aliviado)
            .having((s) => s.relieved, 'relieved', true)
            .having((s) => s.reliefAfterAlert, 'reliefAfterAlert', false)
            .having((s) => s.nextDeadline, 'nextDeadline', deadline),
      ],
      verify: (_) {
        verify(
          () => mockAlarmService.stopAlert(),
        ).called(greaterThanOrEqualTo(1));
        verify(
          () => mockNotificationService.cancelAlert(),
        ).called(greaterThanOrEqualTo(1));
        // Uma vibração única e suave; nenhum som.
        verify(() => mockAlarmService.confirmFeedback()).called(1);
        verifyNever(() => mockDispatcher.dispatchAllClear());
      },
    );

    blocTest<CheckinBloc, CheckinState>(
      'o estado Aliviado dura 3 segundos e volta a Vigiando',
      build: () => buildBloc(ticker: const IdleTicker()),
      seed: callingState,
      act: (bloc) async {
        bloc.add(const ConfirmCheckinRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        fakeClock.current = baseTime.add(const Duration(seconds: 4));
        bloc.add(
          CheckinTickReceived(
            remainingSeconds: 3596,
            nextDeadline: deadline,
            activeMode: tModeRoutine,
          ),
        );
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<CheckinMonitoring>().having((s) => s.relieved, 'relieved', true),
        isA<CheckinMonitoring>()
            .having((s) => s.relieved, 'relieved', false)
            .having((s) => s.vigiState, 'vigiState', VigiState.vigiando),
      ],
    );

    blocTest<CheckinBloc, CheckinState>(
      'desativa o alarme e cancela a notificação mesmo sem vigília ativa',
      build: buildBloc,
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
      'modo Sono fica no estado Noturno',
      build: () => buildBloc(ticker: const IdleTicker()),
      seed: () => const CheckinIdle(
        intervalMinutes: 480,
        availableModes: [
          tModeRoutine,
          MonitoringModeEntity(
            id: 'mode-sleep',
            name: 'Sono',
            iconKey: 'sleep',
            defaultIntervalMinutes: 480,
            isSystemDefault: true,
          ),
        ],
      ),
      act: (bloc) => bloc.add(
        const StartMonitoringRequested(
          modeId: 'mode-sleep',
          intervalOverrideMinutes: 480,
        ),
      ),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        const CheckinLoading(),
        isA<CheckinMonitoring>()
            .having((s) => s.vigiState, 'vigiState', VigiState.noturno)
            .having((s) => s.isSleep, 'isSleep', true),
      ],
      verify: (_) {
        verify(
          () => mockWidgetSyncService.updateWidgetData(
            vigiState: 'noturno',
            minutesRemaining: 480,
            modeName: 'Sono',
            isMonitoring: true,
            timeDisplay: '22:00',
            statusDisplay: any(named: 'statusDisplay'),
          ),
        ).called(1);
      },
    );

    blocTest<CheckinBloc, CheckinState>(
      'ao confirmar em modo temporário (Banho) volta para a Rotina e avisa '
      'o servidor do novo intervalo',
      build: () => buildBloc(ticker: OneShotTicker()),
      seed: () => idleRoutine,
      act: (bloc) async {
        bloc.add(
          const StartMonitoringRequested(
            modeId: 'mode-shower',
            intervalOverrideMinutes: 20,
          ),
        );
        await bloc.stream.firstWhere((s) => s is CheckinCalling);
        bloc.add(const ConfirmCheckinRequested());
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        const CheckinLoading(),
        isA<CheckinMonitoring>().having(
          (s) => s.activeMode?.id,
          'modo',
          'mode-shower',
        ),
        isA<CheckinCalling>(),
        isA<CheckinMonitoring>()
            .having((s) => s.activeMode?.id, 'modo', 'mode-routine')
            .having((s) => s.totalSeconds, 'total', 3600),
      ],
      verify: (_) {
        final params =
            verify(
                  () => mockConfirmCheckinUseCase(captureAny()),
                ).captured.single
                as ConfirmCheckinParams;
        // Sem isso o servidor esperaria o próximo check-in em 20 minutos e
        // alertaria a família por engano.
        expect(params.intervalMinutes, 60);
        expect(params.modeId, 'mode-routine');
        expect(params.resolvesAlert, isFalse);
      },
    );

    blocTest<CheckinBloc, CheckinState>(
      'falha ao trocar de modo não derruba a vigília que já estava ativa',
      build: () {
        when(() => mockStartMonitoringUseCase(any())).thenAnswer(
          (_) async => const Left(NetworkFailure('Sem conexão')),
        );
        return buildBloc(ticker: const IdleTicker());
      },
      seed: () => CheckinMonitoring(
        remainingSeconds: 1800,
        totalSeconds: 3600,
        nextDeadline: deadline,
        activeMode: tModeRoutine,
        availableModes: tModes,
      ),
      act: (bloc) => bloc.add(
        const StartMonitoringRequested(
          modeId: 'mode-shower',
          intervalOverrideMinutes: 20,
        ),
      ),
      expect: () => [
        const CheckinLoading(),
        const CheckinFailure('Sem conexão'),
        isA<CheckinMonitoring>().having(
          (s) => s.activeMode?.id,
          'modo',
          'mode-routine',
        ),
      ],
    );

    blocTest<CheckinBloc, CheckinState>(
      'pausar volta a Descansando e cancela o que estava agendado',
      build: () => buildBloc(ticker: const IdleTicker()),
      seed: () => CheckinMonitoring(
        remainingSeconds: 1800,
        totalSeconds: 3600,
        nextDeadline: deadline,
        activeMode: tModeRoutine,
        availableModes: tModes,
      ),
      act: (bloc) => bloc.add(const StopMonitoringRequested()),
      expect: () => [
        const CheckinLoading(),
        isA<CheckinIdle>().having(
          (s) => s.vigiState,
          'vigiState',
          VigiState.descansando,
        ),
      ],
      verify: (_) {
        verify(
          () => mockNotificationService.cancelScheduledAlarm(),
        ).called(greaterThanOrEqualTo(1));
        verify(
          () => mockNotificationService.cancelMonitoringOngoing(),
        ).called(greaterThanOrEqualTo(1));
        verify(
          () => mockWidgetSyncService.updateWidgetData(
            vigiState: 'descansando',
            minutesRemaining: any(named: 'minutesRemaining'),
            modeName: any(named: 'modeName'),
            isMonitoring: false,
            timeDisplay: any(named: 'timeDisplay'),
            statusDisplay: any(named: 'statusDisplay'),
          ),
        ).called(1);
      },
    );
  });

  group('"Preciso de mais 10 minutos"', () {
    blocTest<CheckinBloc, CheckinState>(
      'adia o prazo em 10 minutos, no aparelho e no servidor',
      build: () => buildBloc(ticker: const IdleTicker()),
      seed: callingState,
      act: (bloc) => bloc.add(const SnoozeCheckinRequested()),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<CheckinMonitoring>().having(
          (s) => s.nextDeadline,
          'nextDeadline',
          baseTime.add(CheckinSchedule.snooze),
        ),
      ],
      verify: (_) {
        verify(
          () => mockExtendDeadlineUseCase(baseTime.add(CheckinSchedule.snooze)),
        ).called(1);
        verify(
          () => mockAlarmService.stopAlert(),
        ).called(greaterThanOrEqualTo(1));
        // Adiar não é confirmar: o servidor não registra um check-in.
        verifyNever(() => mockConfirmCheckinUseCase(any()));
      },
    );

    blocTest<CheckinBloc, CheckinState>(
      'só pode ser usado uma vez por ciclo',
      build: buildBloc,
      seed: callingState,
      act: (bloc) async {
        bloc.add(const SnoozeCheckinRequested());
        // O prazo adiado vence de novo: a nova chamada não oferece adiar.
        final again = await bloc.stream.firstWhere((s) => s is CheckinCalling);
        expect((again as CheckinCalling).canSnooze, isFalse);
        bloc.add(const SnoozeCheckinRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => mockExtendDeadlineUseCase(any())).called(1);
      },
    );

    blocTest<CheckinBloc, CheckinState>(
      'confirmar libera o adiamento para o ciclo seguinte',
      build: () => buildBloc(ticker: OneShotTicker()),
      seed: () => callingState(canSnooze: false),
      act: (bloc) async {
        bloc.add(const ConfirmCheckinRequested());
        await bloc.stream.firstWhere((s) => s is CheckinMonitoring);
        bloc.add(
          CheckinTickReceived(
            remainingSeconds: 0,
            nextDeadline: deadline,
            activeMode: tModeRoutine,
          ),
        );
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state, isA<CheckinCalling>());
        expect((bloc.state as CheckinCalling).canSnooze, isTrue);
      },
    );

    blocTest<CheckinBloc, CheckinState>(
      'fora da chamada é ignorado',
      build: () => buildBloc(ticker: const IdleTicker()),
      seed: () => idleRoutine,
      act: (bloc) => bloc.add(const SnoozeCheckinRequested()),
      expect: () => <CheckinState>[],
      verify: (_) {
        verifyNever(() => mockExtendDeadlineUseCase(any()));
      },
    );
  });

  group("dead man's switch (acionamento dos contatos)", () {
    blocTest<CheckinBloc, CheckinState>(
      'Alerta: avisa os contatos quando a chamada não é respondida',
      build: () => buildBloc(withDispatcher: true),
      seed: () => idleRoutine,
      act: (bloc) => bloc.add(startRoutine),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        const CheckinLoading(),
        isA<CheckinMonitoring>(),
        isA<CheckinMonitoring>(),
        isA<CheckinCalling>().having((s) => s.lastCall, 'lastCall', false),
        isA<CheckinCalling>().having((s) => s.lastCall, 'lastCall', true),
        isA<CheckinAlertActive>()
            .having((s) => s.vigiState, 'vigiState', VigiState.alerta)
            .having((s) => s.contactsFound, 'contactsFound', 2)
            .having((s) => s.smsSent, 'smsSent', 2)
            .having((s) => s.deliveries.length, 'deliveries', 2)
            .having((s) => s.hasLocation, 'hasLocation', true)
            .having((s) => s.address, 'address', contains('Rua Augusta'))
            .having((s) => s.expiredAt, 'expiredAt', deadline)
            .having(
              (s) => s.alertedAt,
              'alertedAt',
              DateTime(2026, 9, 30, 15, 15),
            ),
      ],
      verify: (_) {
        verify(
          () => mockDispatcher.dispatch(
            reason: EmergencyReason.checkinTimeout,
            deadline: deadline,
          ),
        ).called(1);
        verify(() => mockAlarmService.playAlertConfirmed()).called(1);
        verify(
          () => mockNotificationService.showContactsAlerted(
            notified: 2,
            at: DateTime(2026, 9, 30, 15, 15),
            withLocation: true,
          ),
        ).called(1);
        verify(
          () => mockWidgetSyncService.updateWidgetData(
            vigiState: 'alerta',
            minutesRemaining: any(named: 'minutesRemaining'),
            modeName: any(named: 'modeName'),
            isMonitoring: true,
            timeDisplay: any(named: 'timeDisplay'),
            statusDisplay: any(named: 'statusDisplay'),
          ),
        ).called(1);
      },
    );

    blocTest<CheckinBloc, CheckinState>(
      'NÃO avisa os contatos se a pessoa confirma antes do fim da tolerância',
      build: () => buildBloc(ticker: OneShotTicker(), withDispatcher: true),
      seed: () => idleRoutine,
      act: (bloc) async {
        bloc.add(startRoutine);
        await bloc.stream.firstWhere((s) => s is CheckinCalling);
        bloc.add(const ConfirmCheckinRequested());
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state, isA<CheckinMonitoring>());
        verifyNever(
          () => mockDispatcher.dispatch(
            reason: any(named: 'reason'),
            deadline: any(named: 'deadline'),
          ),
        );
        verifyNever(() => mockDispatcher.dispatchAllClear());
      },
    );

    blocTest<CheckinBloc, CheckinState>(
      'cancelar o alerta avisa os contatos de que está tudo bem',
      build: () => buildBloc(ticker: const IdleTicker(), withDispatcher: true),
      seed: () => CheckinAlertActive(
        expiredAt: deadline,
        alertedAt: DateTime(2026, 9, 30, 15, 15),
        activeMode: tModeRoutine,
        contactsFound: 2,
        smsSent: 2,
      ),
      act: (bloc) => bloc.add(const ConfirmCheckinRequested()),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<CheckinMonitoring>()
            .having((s) => s.relieved, 'relieved', true)
            .having((s) => s.reliefAfterAlert, 'reliefAfterAlert', true),
      ],
      verify: (_) {
        verify(() => mockDispatcher.dispatchAllClear()).called(1);
        final params =
            verify(
                  () => mockConfirmCheckinUseCase(captureAny()),
                ).captured.single
                as ConfirmCheckinParams;
        // O servidor registra o fim do alerta e avisa a família pelo app.
        expect(params.resolvesAlert, isTrue);
      },
    );

    blocTest<CheckinBloc, CheckinState>(
      'se a pessoa confirma enquanto o SMS está saindo, quem recebeu o '
      'alerta recebe também o "está tudo bem"',
      build: () {
        final sending = Completer<EmergencyDispatchResult>();
        when(
          () => mockDispatcher.dispatch(
            reason: any(named: 'reason'),
            deadline: any(named: 'deadline'),
          ),
        ).thenAnswer((_) {
          // O envio termina depois da confirmação.
          Future<void>.delayed(const Duration(milliseconds: 60), () {
            sending.complete(
              const EmergencyDispatchResult(contactsFound: 2, smsSent: 2),
            );
          });
          return sending.future;
        });
        return buildBloc(ticker: const IdleTicker(), withDispatcher: true);
      },
      seed: () => callingState(lastCall: true),
      act: (bloc) async {
        bloc.add(const CheckinEscalationRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const ConfirmCheckinRequested());
      },
      wait: const Duration(milliseconds: 150),
      verify: (bloc) {
        // A tela não vira alerta depois de a pessoa já ter respondido.
        expect(bloc.state, isA<CheckinMonitoring>());
        verify(() => mockDispatcher.dispatchAllClear()).called(1);
        verifyNever(() => mockAlarmService.playAlertConfirmed());
      },
    );
  });

  group('abrindo o app com o prazo já vencido', () {
    blocTest<CheckinBloc, CheckinState>(
      'vencido há horas: ainda dá um minuto para responder antes de avisar',
      build: () {
        when(
          () => mockGetAvailableModesUseCase(any()),
        ).thenAnswer((_) async => const Right(tModes));
        when(() => mockGetMonitoringStatusUseCase(any())).thenAnswer(
          (_) async => Right(
            MonitoringStatusEntity(
              active: true,
              intervalMinutes: 60,
              activeModeId: 'mode-routine',
              // Prazo de três horas atrás.
              nextDeadline: baseTime.subtract(const Duration(hours: 3)),
            ),
          ),
        );
        return buildBloc(ticker: OneShotTicker(), withDispatcher: true);
      },
      act: (bloc) => bloc.add(const LoadCheckinStatusRequested()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final state = bloc.state;
        expect(state, isA<CheckinCalling>());
        final calling = state as CheckinCalling;
        expect(calling.lastCall, isTrue);
        expect(
          calling.escalatesAt,
          baseTime.add(CheckinSchedule.minimumResponse),
        );
        verifyNever(
          () => mockDispatcher.dispatch(
            reason: any(named: 'reason'),
            deadline: any(named: 'deadline'),
          ),
        );
      },
    );
  });

  group('check-in sem internet', () {
    blocTest<CheckinBloc, CheckinState>(
      'confirmação offline não deixa a pessoa presa na chamada: o ciclo '
      'local recomeça',
      build: () {
        when(() => mockConfirmCheckinUseCase(any())).thenAnswer(
          (_) async => const Left(NetworkFailure('Sem conexão')),
        );
        return buildBloc(ticker: const IdleTicker());
      },
      seed: callingState,
      act: (bloc) => bloc.add(const ConfirmCheckinRequested()),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<CheckinFailure>().having(
          (s) => s.message,
          'message',
          contains('Sem conexão'),
        ),
        isA<CheckinMonitoring>(),
      ],
      verify: (_) {
        verify(() => mockAlarmService.stopAlert()).called(greaterThan(0));
        verify(
          () => mockNotificationService.scheduleCheckinCall(any()),
        ).called(1);
      },
    );

    blocTest<CheckinBloc, CheckinState>(
      '"Estou bem" sem monitoramento ativo (ex.: pelo widget) é ignorado',
      build: buildBloc,
      seed: () => idleRoutine,
      act: (bloc) => bloc.add(const ConfirmCheckinRequested()),
      expect: () => <CheckinState>[],
      verify: (_) {
        verifyNever(() => mockConfirmCheckinUseCase(any()));
      },
    );
  });
}
