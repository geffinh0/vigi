import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/app/app.dart';
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
import 'package:guardiao/features/checkin/domain/entities/monitoring_status_entity.dart';
import 'package:guardiao/features/checkin/domain/repositories/checkin_repository.dart';
import 'package:guardiao/features/checkin/domain/usecases/confirm_checkin_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/get_monitoring_status_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/start_monitoring_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/stop_monitoring_usecase.dart';
import 'package:guardiao/features/checkin/presentation/bloc/checkin_bloc.dart';
import 'package:guardiao/features/contacts/domain/repositories/contacts_repository.dart';
import 'package:guardiao/features/contacts/domain/usecases/add_contact_usecase.dart';
import 'package:guardiao/features/contacts/domain/usecases/delete_contact_usecase.dart';
import 'package:guardiao/features/contacts/domain/usecases/get_contacts_usecase.dart';
import 'package:guardiao/features/contacts/presentation/bloc/contacts_bloc.dart';
import 'package:guardiao/features/family/domain/repositories/family_repository.dart';
import 'package:guardiao/features/family/domain/usecases/accept_family_invite_usecase.dart';
import 'package:guardiao/features/family/domain/usecases/get_family_links_usecase.dart';
import 'package:guardiao/features/family/domain/usecases/send_family_invite_usecase.dart';
import 'package:guardiao/features/family/presentation/bloc/family_bloc.dart';
import 'package:guardiao/features/panic/domain/entities/panic_alert_entity.dart';
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

void main() {
  group('Critical Flow Test (Foreground E2E)', () {
    testWidgets('Fluxo crítico: inicialização -> tela inicial -> mascote e anel ativos', (tester) async {
      if (!sl.isRegistered<Clock>()) sl.registerSingleton<Clock>(const SystemClock());
      if (!sl.isRegistered<Ticker>()) sl.registerSingleton<Ticker>(const Ticker());

      final authRepo = MockAuthRepository();
      when(() => authRepo.authStateChanges).thenAnswer((_) => const Stream.empty());

      final contactsRepo = MockContactsRepository();
      final checkinRepo = MockCheckinRepository();
      when(() => checkinRepo.getStatus()).thenAnswer(
        (_) async => const Right(MonitoringStatusEntity(active: false, intervalMinutes: 60)),
      );

      final panicRepo = MockPanicRepository();
      final familyRepo = MockFamilyRepository();

      final authBloc = AuthBloc(
        signInUseCase: SignInUseCase(authRepo),
        signUpUseCase: SignUpUseCase(authRepo),
        signOutUseCase: SignOutUseCase(authRepo),
        authRepository: authRepo,
      );

      final checkinBloc = CheckinBloc(
        startMonitoringUseCase: StartMonitoringUseCase(checkinRepo, contactsRepo),
        confirmCheckinUseCase: ConfirmCheckinUseCase(checkinRepo),
        stopMonitoringUseCase: StopMonitoringUseCase(checkinRepo),
        getMonitoringStatusUseCase: GetMonitoringStatusUseCase(checkinRepo),
        ticker: sl(),
        clock: sl(),
      );

      final contactsBloc = ContactsBloc(
        getContactsUseCase: GetContactsUseCase(contactsRepo),
        addContactUseCase: AddContactUseCase(contactsRepo),
        deleteContactUseCase: DeleteContactUseCase(contactsRepo),
      );

      final panicBloc = PanicBloc(
        triggerPanicUseCase: TriggerPanicUseCase(panicRepo),
        resolvePanicUseCase: ResolvePanicUseCase(panicRepo),
      );

      final familyBloc = FamilyBloc(
        getFamilyLinksUseCase: GetFamilyLinksUseCase(familyRepo),
        sendFamilyInviteUseCase: SendFamilyInviteUseCase(familyRepo),
        acceptFamilyInviteUseCase: AcceptFamilyInviteUseCase(familyRepo),
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<CheckinBloc>.value(value: checkinBloc),
            BlocProvider<ContactsBloc>.value(value: contactsBloc),
            BlocProvider<PanicBloc>.value(value: panicBloc),
            BlocProvider<FamilyBloc>.value(value: familyBloc),
          ],
          child: MaterialApp(
            theme: appTheme,
            home: const GuardiaoHomePage(),
          ),
        ),
      );
      await tester.pump();

      // Verifica presença dos elementos visuais da Home
      expect(find.text('Guardião'), findsOneWidget);
      expect(find.byType(VigiMascot), findsOneWidget);
      expect(find.byType(StatusRing), findsOneWidget);
      expect(find.text('Você está protegido pelo Vigi'), findsOneWidget);
    });
  });
}
