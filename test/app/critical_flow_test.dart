import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:guardiao/app/app.dart';
import 'package:guardiao/app/system_health_cubit.dart';
import 'package:guardiao/core/services/alarm_service.dart';
import 'package:guardiao/core/services/checkin_messages.dart';
import 'package:guardiao/core/services/emergency_dispatcher.dart';
import 'package:guardiao/core/services/notification_service.dart';
import 'package:guardiao/core/services/widget_sync_service.dart';
import 'package:guardiao/core/theme/app_theme.dart';
import 'package:guardiao/core/utils/clock.dart';
import 'package:guardiao/core/utils/ticker.dart';
import 'package:guardiao/core/widgets/vigi_mascot.dart';
import 'package:guardiao/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:guardiao/features/checkin/domain/entities/monitoring_status_entity.dart';
import 'package:guardiao/features/checkin/domain/repositories/checkin_repository.dart';
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
import 'package:guardiao/features/checkin/presentation/pages/checkin_alert_page.dart';
import 'package:guardiao/features/contacts/domain/repositories/contacts_repository.dart';
import 'package:guardiao/features/contacts/presentation/bloc/contacts_bloc.dart';
import 'package:guardiao/features/family/presentation/bloc/family_bloc.dart';
import 'package:guardiao/features/panic/presentation/bloc/panic_bloc.dart';
import 'package:guardiao/features/panic/presentation/pages/panic_page.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/pump_app.dart';

class MockCheckinRepository extends Mock implements CheckinRepository {}

class MockContactsRepository extends Mock implements ContactsRepository {}

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

/// Contagem controlada pelo teste: cada chamada devolve um fluxo novo, e o
/// teste empurra os segundos restantes do mais recente.
class ManualTicker extends Ticker {
  ManualTicker();

  final List<StreamController<int>> _controllers = [];

  @override
  Stream<int> secondsUntil(DateTime deadline, {required Clock clock}) {
    final controller = StreamController<int>();
    _controllers.add(controller);
    return controller.stream;
  }

  void tick(int remainingSeconds) => _controllers.last.add(remainingSeconds);
}

/// Fluxo crítico de ponta a ponta, na interface: os blocos são os reais e só
/// a borda (servidor, relógio, som, SMS) é simulada.
void main() {
  late MockCheckinRepository checkinRepo;
  late MockContactsRepository contactsRepo;
  late MockAlarmService alarm;
  late MockNotificationService notifications;
  late MockEmergencyDispatcher dispatcher;
  late MockWidgetSyncService widgetSync;
  late ManualTicker ticker;
  late FakeClock clock;
  late CheckinBloc checkinBloc;
  late AppBlocs blocs;

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(EmergencyReason.checkinTimeout);
    registerFallbackValue(
      CheckinCallInfo(
        deadline: DateTime(2026),
        lastCallAt: DateTime(2026),
        escalatesAt: DateTime(2026),
      ),
    );
  });

  setUp(() {
    checkinRepo = MockCheckinRepository();
    contactsRepo = MockContactsRepository();
    alarm = MockAlarmService();
    notifications = MockNotificationService();
    dispatcher = MockEmergencyDispatcher();
    widgetSync = MockWidgetSyncService();
    ticker = ManualTicker();
    // 14:00: o check-in da Rotina de 1 h vence às 15:00.
    clock = FakeClock(DateTime(2026, 9, 30, 14));

    when(
      () => checkinRepo.getAvailableModes(),
    ).thenAnswer((_) async => const Right(tModes));
    when(() => checkinRepo.getStatus()).thenAnswer(
      (_) async => const Right(
        MonitoringStatusEntity(
          active: false,
          intervalMinutes: 60,
          activeModeId: 'mode-routine',
        ),
      ),
    );
    when(
      () => checkinRepo.startMonitoring(
        modeId: any(named: 'modeId'),
        intervalOverrideMinutes: any(named: 'intervalOverrideMinutes'),
      ),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => checkinRepo.confirmCheckin(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        intervalMinutes: any(named: 'intervalMinutes'),
        modeId: any(named: 'modeId'),
        resolvesAlert: any(named: 'resolvesAlert'),
      ),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => checkinRepo.extendDeadline(any()),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => contactsRepo.getContacts(),
    ).thenAnswer((_) async => const Right(tContacts));

    when(() => alarm.startCall()).thenAnswer((_) async {});
    when(
      () => alarm.startLastCall(playSound: any(named: 'playSound')),
    ).thenAnswer((_) async {});
    when(() => alarm.playAlertConfirmed()).thenAnswer((_) async {});
    when(() => alarm.confirmFeedback()).thenAnswer((_) async {});
    when(() => alarm.stopAlert()).thenAnswer((_) async {});

    when(
      () => notifications.scheduleCheckinCall(any()),
    ).thenAnswer((_) async {});
    when(() => notifications.showCheckinCall(any())).thenAnswer((_) async {});
    when(() => notifications.showLastCall(any())).thenAnswer((_) async {});
    when(
      () => notifications.showContactsAlerted(
        notified: any(named: 'notified'),
        at: any(named: 'at'),
        withLocation: any(named: 'withLocation'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => notifications.areNotificationsEnabled(),
    ).thenAnswer((_) async => true);
    when(() => notifications.cancelAlert()).thenAnswer((_) async {});
    when(() => notifications.cancelScheduledAlarm()).thenAnswer((_) async {});
    when(
      () => notifications.showMonitoringOngoing(
        modeName: any(named: 'modeName'),
        nextDeadline: any(named: 'nextDeadline'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => notifications.cancelMonitoringOngoing(),
    ).thenAnswer((_) async {});

    when(
      () => widgetSync.updateWidgetData(
        vigiState: any(named: 'vigiState'),
        minutesRemaining: any(named: 'minutesRemaining'),
        modeName: any(named: 'modeName'),
        isMonitoring: any(named: 'isMonitoring'),
        timeDisplay: any(named: 'timeDisplay'),
        statusDisplay: any(named: 'statusDisplay'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => dispatcher.dispatch(
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
          ContactDelivery(name: 'Maria Silva', phone: '+5511', sent: true),
          ContactDelivery(name: 'João', phone: '+5521', sent: true),
        ],
      ),
    );
    when(() => dispatcher.dispatchAllClear()).thenAnswer((_) async => 2);

    blocs = AppBlocs();
  });

  Future<void> pumpVigi(WidgetTester tester) async {
    // O bloco nasce dentro do teste, para os seus fluxos andarem com o
    // relógio falso do `tester`.
    checkinBloc = CheckinBloc(
      startMonitoringUseCase: StartMonitoringUseCase(checkinRepo, contactsRepo),
      confirmCheckinUseCase: ConfirmCheckinUseCase(checkinRepo),
      stopMonitoringUseCase: StopMonitoringUseCase(checkinRepo),
      getMonitoringStatusUseCase: GetMonitoringStatusUseCase(checkinRepo),
      getAvailableModesUseCase: GetAvailableModesUseCase(checkinRepo),
      createCustomModeUseCase: CreateCustomModeUseCase(checkinRepo),
      saveMonitoringSettingsUseCase: SaveMonitoringSettingsUseCase(checkinRepo),
      extendDeadlineUseCase: ExtendDeadlineUseCase(checkinRepo),
      ticker: ticker,
      clock: clock,
      alarmService: alarm,
      notificationService: notifications,
      widgetSyncService: widgetSync,
      emergencyDispatcher: dispatcher,
      firstNameProvider: () => 'Lúcia Almeida',
      contactNamesProvider: () async => ['Maria Silva', 'João'],
    );
    addTearDown(checkinBloc.close);

    // Tela alta: o conteúdo cabe sem rolagem com a fonte larga dos testes.
    tester.view.physicalSize = const Size(400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) =>
              VigiHomePage(now: () => DateTime(2026, 9, 30, 14, 22)),
        ),
        GoRoute(
          path: '/checkin-alert',
          builder: (_, _) => CheckinAlertPage(now: clock.now),
        ),
        GoRoute(path: '/panic', builder: (_, _) => const PanicPage()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: blocs.auth),
          BlocProvider<CheckinBloc>.value(value: checkinBloc),
          BlocProvider<ContactsBloc>.value(value: blocs.contacts),
          BlocProvider<PanicBloc>.value(value: blocs.panic),
          BlocProvider<FamilyBloc>.value(value: blocs.family),
          BlocProvider<SystemHealthCubit>.value(value: blocs.health),
        ],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      ),
    );
    checkinBloc.add(const LoadCheckinStatusRequested());
    await settle(tester);
  }

  testWidgets('descansando → vigiando → sua vez → "Estou bem" → aliviado', (
    tester,
  ) async {
    await pumpVigi(tester);

    // Descansando: o Vigi diz que não está vigiando.
    expect(find.text('O Vigi está descansando'), findsOneWidget);
    expect(mascot(tester), VigiState.descansando);

    await tester.tap(find.text('Começar a vigiar'));
    await settle(tester);
    ticker.tick(38 * 60);
    await settle(tester);

    // Vigiando, em silêncio.
    expect(mascot(tester), VigiState.vigiando);
    expect(find.text('38 min'), findsOneWidget);
    expect(find.text('até 15:00'), findsOneWidget);
    verifyNever(() => alarm.startCall());

    // 15:00: o prazo chega e a tela inteira vira a chamada.
    clock.current = DateTime(2026, 9, 30, 15);
    ticker.tick(0);
    await settle(tester);

    expect(find.text('Tudo bem por aí, Lúcia?'), findsOneWidget);
    expect(
      find.text('Se você não responder até 15:15, vamos avisar Maria e João.'),
      findsOneWidget,
    );
    verify(() => alarm.startCall()).called(1);

    // Um toque basta.
    await tester.tap(find.text('Estou bem'));
    await settle(tester);
    ticker.tick(3599);
    await settle(tester);

    // De volta à tela inicial, aliviado, com o próximo horário.
    expect(find.text('Tudo bem por aí, Lúcia?'), findsNothing);
    expect(mascot(tester), VigiState.aliviado);
    expect(find.text('Obrigado. Próximo check-in às 16:00.'), findsOneWidget);
    verify(() => alarm.stopAlert()).called(greaterThanOrEqualTo(1));
    verifyNever(
      () => dispatcher.dispatch(
        reason: any(named: 'reason'),
        deadline: any(named: 'deadline'),
      ),
    );
  });

  testWidgets('sem resposta: última chamada → alerta → cancelar avisa os '
      'contatos', (tester) async {
    await pumpVigi(tester);
    await tester.tap(find.text('Começar a vigiar'));
    await settle(tester);

    clock.current = DateTime(2026, 9, 30, 15);
    ticker.tick(0);
    await settle(tester);
    expect(find.text('Tudo bem por aí, Lúcia?'), findsOneWidget);

    // 15:10: faltam 5 minutos da tolerância.
    clock.current = DateTime(2026, 9, 30, 15, 10);
    ticker.tick(300);
    await settle(tester);
    expect(find.text('Última chamada, Lúcia'), findsOneWidget);
    verify(() => alarm.startLastCall()).called(1);

    // 15:15: ninguém respondeu.
    clock.current = DateTime(2026, 9, 30, 15, 15);
    ticker.tick(0);
    await settle(tester);

    expect(find.text('Pedimos ajuda por você'), findsOneWidget);
    expect(
      find.text('Avisamos 2 pessoas às 15:15 com a sua localização.'),
      findsOneWidget,
    );
    expect(find.text('Perto de Rua Augusta, 1200, Consolação'), findsOneWidget);
    verify(
      () => dispatcher.dispatch(
        reason: EmergencyReason.checkinTimeout,
        deadline: DateTime(2026, 9, 30, 15),
      ),
    ).called(1);

    // A pessoa aparece e cancela, com confirmação.
    await tester.tap(find.text('Estou seguro, cancelar o pedido'));
    await settle(tester);
    verifyNever(() => dispatcher.dispatchAllClear());
    await tester.tap(find.text('Estou seguro, cancelar'));
    await settle(tester);
    ticker.tick(3599);
    await settle(tester);

    verify(() => dispatcher.dispatchAllClear()).called(1);
    expect(find.text('Pedimos ajuda por você'), findsNothing);
    expect(
      find.text(
        'Obrigado. Próximo check-in às 16:15. Avisamos seus contatos de que '
        'está tudo bem.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('"Preciso de mais 10 minutos" adia uma vez e some na chamada '
      'seguinte', (tester) async {
    await pumpVigi(tester);
    await tester.tap(find.text('Começar a vigiar'));
    await settle(tester);

    clock.current = DateTime(2026, 9, 30, 15);
    ticker.tick(0);
    await settle(tester);

    await tester.tap(find.text('Preciso de mais 10 minutos'));
    await settle(tester);
    ticker.tick(600);
    await settle(tester);

    // De volta a Vigiando, com o prazo adiado para 15:10.
    expect(find.text('10 min'), findsOneWidget);
    expect(find.text('até 15:10'), findsOneWidget);
    verify(
      () => checkinRepo.extendDeadline(DateTime(2026, 9, 30, 15, 10)),
    ).called(1);

    clock.current = DateTime(2026, 9, 30, 15, 10);
    ticker.tick(0);
    await settle(tester);
    expect(find.text('Tudo bem por aí, Lúcia?'), findsOneWidget);
    expect(find.text('Preciso de mais 10 minutos'), findsNothing);
  });
}

VigiState mascot(WidgetTester tester) =>
    tester.widget<VigiMascot>(find.byType(VigiMascot).first).state;

/// Deixa os blocos e a navegação assentarem, sem esperar animações
/// infinitas.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}
