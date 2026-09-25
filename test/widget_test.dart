import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/app/app.dart';
import 'package:guardiao/core/services/alarm_service.dart';
import 'package:guardiao/core/services/notification_service.dart';
import 'package:guardiao/core/theme/app_theme.dart';
import 'package:guardiao/core/utils/clock.dart';
import 'package:guardiao/core/utils/ticker.dart';
import 'package:guardiao/core/widgets/status_ring.dart';
import 'package:guardiao/core/widgets/vigi_mascot.dart';
import 'package:guardiao/features/auth/domain/repositories/auth_repository.dart';
import 'package:guardiao/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:guardiao/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:guardiao/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:guardiao/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:guardiao/features/checkin/domain/entities/monitoring_mode_entity.dart';
import 'package:guardiao/features/checkin/domain/entities/monitoring_status_entity.dart';
import 'package:guardiao/features/checkin/domain/repositories/checkin_repository.dart';
import 'package:guardiao/features/checkin/domain/usecases/confirm_checkin_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/create_custom_mode_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/get_available_modes_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/get_monitoring_status_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/save_monitoring_settings_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/start_monitoring_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/stop_monitoring_usecase.dart';
import 'package:guardiao/features/checkin/presentation/bloc/checkin_bloc.dart';
import 'package:guardiao/features/contacts/domain/repositories/contacts_repository.dart';
import 'package:guardiao/features/contacts/domain/usecases/add_contact_usecase.dart';
import 'package:guardiao/features/contacts/domain/usecases/delete_contact_usecase.dart';
import 'package:guardiao/features/contacts/domain/usecases/get_contacts_usecase.dart';
import 'package:guardiao/features/contacts/presentation/bloc/contacts_bloc.dart';
import 'package:guardiao/features/family/domain/repositories/family_repository.dart';
import 'package:guardiao/features/family/domain/usecases/get_family_links_usecase.dart';
import 'package:guardiao/features/family/domain/usecases/get_my_link_code_usecase.dart';
import 'package:guardiao/features/family/domain/usecases/remove_family_link_usecase.dart';
import 'package:guardiao/features/family/domain/usecases/request_family_link_usecase.dart';
import 'package:guardiao/features/family/domain/usecases/respond_family_link_usecase.dart';
import 'package:guardiao/features/family/presentation/bloc/family_bloc.dart';
import 'package:guardiao/features/panic/domain/repositories/panic_repository.dart';
import 'package:guardiao/features/panic/domain/usecases/resolve_panic_usecase.dart';
import 'package:guardiao/features/panic/domain/usecases/trigger_panic_usecase.dart';
import 'package:guardiao/features/panic/presentation/bloc/panic_bloc.dart';
import 'package:guardiao/injection/injection_container.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCheckinRepository extends Mock implements CheckinRepository {}

class MockContactsRepository extends Mock implements ContactsRepository {}

class MockPanicRepository extends Mock implements PanicRepository {}

class MockFamilyRepository extends Mock implements FamilyRepository {}

class MockAlarmService extends Mock implements AlarmService {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  setUpAll(() {
    final authRepo = MockAuthRepository();
    final checkinRepo = MockCheckinRepository();
    final contactsRepo = MockContactsRepository();
    final panicRepo = MockPanicRepository();
    final familyRepo = MockFamilyRepository();
    final alarmService = MockAlarmService();
    final notificationService = MockNotificationService();

    when(
      () => authRepo.authStateChanges,
    ).thenAnswer((_) => const Stream.empty());

    when(
      () => checkinRepo.getAvailableModes(),
    ).thenAnswer(
      (_) async => const Right([
        MonitoringModeEntity(
          id: 'mode-1',
          name: 'Rotina padrão',
          iconKey: 'routine',
          defaultIntervalMinutes: 60,
          isSystemDefault: true,
        ),
        MonitoringModeEntity(
          id: 'mode-2',
          name: 'Banho',
          iconKey: 'shower',
          defaultIntervalMinutes: 20,
          isSystemDefault: true,
        ),
        MonitoringModeEntity(
          id: 'mode-3',
          name: 'Sono',
          iconKey: 'sleep',
          defaultIntervalMinutes: 480,
          isSystemDefault: true,
        ),
      ]),
    );

    when(
      () => checkinRepo.getStatus(),
    ).thenAnswer(
      (_) async => const Right(
        MonitoringStatusEntity(
          active: false,
          intervalMinutes: 60,
        ),
      ),
    );

    when(() => alarmService.startAlert()).thenAnswer((_) async {});
    when(() => alarmService.stopAlert()).thenAnswer((_) async {});
    when(() => notificationService.showTimeoutAlert()).thenAnswer((_) async {});
    when(() => notificationService.cancelAlert()).thenAnswer((_) async {});
    when(
      () => notificationService.scheduleTimeoutAlarm(any()),
    ).thenAnswer((_) async {});
    when(
      () => notificationService.cancelScheduledAlarm(),
    ).thenAnswer((_) async {});
    when(
      () => notificationService.showMonitoringOngoing(
        modeName: any(named: 'modeName'),
        nextDeadline: any(named: 'nextDeadline'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => notificationService.cancelMonitoringOngoing(),
    ).thenAnswer((_) async {});

    if (!sl.isRegistered<Clock>()) {
      sl.registerLazySingleton<Clock>(SystemClock.new);
    }
    if (!sl.isRegistered<Ticker>()) {
      sl.registerLazySingleton<Ticker>(Ticker.new);
    }
    if (!sl.isRegistered<AlarmService>()) {
      sl.registerLazySingleton<AlarmService>(() => alarmService);
    }
    if (!sl.isRegistered<NotificationService>()) {
      sl.registerLazySingleton<NotificationService>(() => notificationService);
    }

    if (!sl.isRegistered<AuthBloc>()) {
      sl.registerFactory(
        () => AuthBloc(
          signInUseCase: SignInUseCase(authRepo),
          signUpUseCase: SignUpUseCase(authRepo),
          signOutUseCase: SignOutUseCase(authRepo),
          authRepository: authRepo,
        ),
      );
    }

    if (!sl.isRegistered<CheckinBloc>()) {
      sl.registerFactory(
        () => CheckinBloc(
          startMonitoringUseCase: StartMonitoringUseCase(
            checkinRepo,
            contactsRepo,
          ),
          confirmCheckinUseCase: ConfirmCheckinUseCase(checkinRepo),
          stopMonitoringUseCase: StopMonitoringUseCase(checkinRepo),
          getMonitoringStatusUseCase: GetMonitoringStatusUseCase(checkinRepo),
          getAvailableModesUseCase: GetAvailableModesUseCase(checkinRepo),
          createCustomModeUseCase: CreateCustomModeUseCase(checkinRepo),
          saveMonitoringSettingsUseCase: SaveMonitoringSettingsUseCase(
            checkinRepo,
          ),
          ticker: sl(),
          clock: sl(),
          alarmService: sl(),
          notificationService: sl(),
        ),
      );
    }

    if (!sl.isRegistered<ContactsBloc>()) {
      sl.registerFactory(
        () => ContactsBloc(
          getContactsUseCase: GetContactsUseCase(contactsRepo),
          addContactUseCase: AddContactUseCase(contactsRepo),
          deleteContactUseCase: DeleteContactUseCase(contactsRepo),
        ),
      );
    }

    if (!sl.isRegistered<PanicBloc>()) {
      sl.registerFactory(
        () => PanicBloc(
          triggerPanicUseCase: TriggerPanicUseCase(panicRepo),
          resolvePanicUseCase: ResolvePanicUseCase(panicRepo),
        ),
      );
    }

    if (!sl.isRegistered<FamilyBloc>()) {
      sl.registerFactory(
        () => FamilyBloc(
          getFamilyLinksUseCase: GetFamilyLinksUseCase(familyRepo),
          getMyLinkCodeUseCase: GetMyLinkCodeUseCase(familyRepo),
          requestFamilyLinkUseCase: RequestFamilyLinkUseCase(familyRepo),
          respondFamilyLinkUseCase: RespondFamilyLinkUseCase(familyRepo),
          removeFamilyLinkUseCase: RemoveFamilyLinkUseCase(familyRepo),
          currentUserId: () => 'u1',
        ),
      );
    }
  });

  testWidgets('GuardiaoHomePage renderiza Mascote Vigi, StatusRing e botões', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: sl<AuthBloc>()),
          BlocProvider<CheckinBloc>.value(value: sl<CheckinBloc>()),
          BlocProvider<ContactsBloc>.value(value: sl<ContactsBloc>()),
          BlocProvider<PanicBloc>.value(value: sl<PanicBloc>()),
          BlocProvider<FamilyBloc>.value(value: sl<FamilyBloc>()),
        ],
        child: MaterialApp(
          theme: appTheme,
          home: const GuardiaoHomePage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('VIGI'), findsOneWidget);
    expect(find.byType(VigiMascot), findsOneWidget);
    expect(find.byType(StatusRing), findsOneWidget);
    expect(find.text('Você está protegido pelo VIGI'), findsOneWidget);
    expect(find.textContaining('Vou tomar banho'), findsOneWidget);
    expect(find.textContaining('Vou dormir'), findsOneWidget);
    expect(find.text('Abrir Botão de Pânico'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
