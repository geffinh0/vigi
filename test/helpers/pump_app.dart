import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:guardiao/app/system_health_cubit.dart';
import 'package:guardiao/core/services/system_health_service.dart';
import 'package:guardiao/core/theme/app_theme.dart';
import 'package:guardiao/features/auth/domain/entities/user_entity.dart';
import 'package:guardiao/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:guardiao/features/auth/presentation/bloc/auth_event.dart';
import 'package:guardiao/features/auth/presentation/bloc/auth_state.dart';
import 'package:guardiao/features/checkin/domain/entities/monitoring_mode_entity.dart';
import 'package:guardiao/features/checkin/presentation/bloc/checkin_bloc.dart';
import 'package:guardiao/features/checkin/presentation/bloc/checkin_event.dart';
import 'package:guardiao/features/checkin/presentation/bloc/checkin_state.dart';
import 'package:guardiao/features/contacts/domain/entities/emergency_contact_entity.dart';
import 'package:guardiao/features/contacts/presentation/bloc/contacts_bloc.dart';
import 'package:guardiao/features/contacts/presentation/bloc/contacts_event.dart';
import 'package:guardiao/features/contacts/presentation/bloc/contacts_state.dart';
import 'package:guardiao/features/family/presentation/bloc/family_bloc.dart';
import 'package:guardiao/features/family/presentation/bloc/family_event.dart';
import 'package:guardiao/features/family/presentation/bloc/family_state.dart';
import 'package:guardiao/features/panic/presentation/bloc/panic_bloc.dart';
import 'package:guardiao/features/panic/presentation/bloc/panic_event.dart';
import 'package:guardiao/features/panic/presentation/bloc/panic_state.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockCheckinBloc extends MockBloc<CheckinEvent, CheckinState>
    implements CheckinBloc {}

class MockContactsBloc extends MockBloc<ContactsEvent, ContactsState>
    implements ContactsBloc {}

class MockPanicBloc extends MockBloc<PanicEvent, PanicState>
    implements PanicBloc {}

class MockFamilyBloc extends MockBloc<FamilyEvent, FamilyState>
    implements FamilyBloc {}

/// Faixa de saúde com problemas fixos, sem tocar em plugins.
class FakeHealthCubit extends SystemHealthCubit {
  FakeHealthCubit([List<HealthIssue> issues = const []]) {
    emit(issues);
  }
}

// ── Dados da persona de referência: Dona Lúcia, 74 anos ──────────────────

const tLucia = UserEntity(
  id: 'u1',
  email: 'lucia@email.com',
  fullName: 'Lúcia Almeida',
);

const tRoutine = MonitoringModeEntity(
  id: 'mode-routine',
  name: 'Rotina padrão',
  iconKey: 'routine',
  defaultIntervalMinutes: 60,
  isSystemDefault: true,
);

const tShower = MonitoringModeEntity(
  id: 'mode-shower',
  name: 'Banho',
  iconKey: 'shower',
  defaultIntervalMinutes: 20,
  isSystemDefault: true,
);

const tSleep = MonitoringModeEntity(
  id: 'mode-sleep',
  name: 'Sono',
  iconKey: 'sleep',
  defaultIntervalMinutes: 480,
  isSystemDefault: true,
);

const tModes = [tRoutine, tShower, tSleep];

const tContacts = [
  EmergencyContactEntity(
    id: 'c1',
    userId: 'u1',
    name: 'Maria Silva',
    phone: '(11) 98765-4321',
    relationship: 'Filha',
  ),
  EmergencyContactEntity(
    id: 'c2',
    userId: 'u1',
    name: 'João',
    phone: '(11) 91234-5678',
    relationship: 'Vizinho',
  ),
];

/// Blocos falsos de uma tela, para o teste inspecionar eventos enviados.
class AppBlocs {
  AppBlocs({
    AuthState auth = const AuthAuthenticated(tLucia),
    CheckinState checkin = const CheckinIdle(
      availableModes: tModes,
      selectedMode: tRoutine,
    ),
    ContactsState contacts = const ContactsLoaded(tContacts),
    PanicState panic = const PanicInitial(),
    FamilyState family = const FamilyLoaded([], myCode: 'K7P2QX'),
    List<HealthIssue> health = const [],
  }) : this.health = FakeHealthCubit(health) {
    whenListen(
      this.auth,
      const Stream<AuthState>.empty(),
      initialState: auth,
    );
    whenListen(
      this.checkin,
      const Stream<CheckinState>.empty(),
      initialState: checkin,
    );
    whenListen(
      this.contacts,
      const Stream<ContactsState>.empty(),
      initialState: contacts,
    );
    whenListen(
      this.panic,
      const Stream<PanicState>.empty(),
      initialState: panic,
    );
    whenListen(
      this.family,
      const Stream<FamilyState>.empty(),
      initialState: family,
    );
  }

  final MockAuthBloc auth = MockAuthBloc();
  final MockCheckinBloc checkin = MockCheckinBloc();
  final MockContactsBloc contacts = MockContactsBloc();
  final MockPanicBloc panic = MockPanicBloc();
  final MockFamilyBloc family = MockFamilyBloc();
  final FakeHealthCubit health;
}

/// Tamanho de um Android de entrada, o aparelho da Dona Lúcia.
const Size kPhone = Size(360, 760);

/// Monta [child] com o tema do Vigi e os blocos falsos.
///
/// [textScale] simula a fonte do sistema (o guia pede 1.0, 1.5 e 2.0);
/// [night] usa o tema noturno; [reduceMotion] simula "Remover animações".
Future<AppBlocs> pumpApp(
  WidgetTester tester,
  Widget child, {
  AppBlocs? blocs,
  double textScale = 1,
  bool night = false,
  bool reduceMotion = true,
  Size size = kPhone,
}) async {
  final b = blocs ?? AppBlocs();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: b.auth),
        BlocProvider<CheckinBloc>.value(value: b.checkin),
        BlocProvider<ContactsBloc>.value(value: b.contacts),
        BlocProvider<PanicBloc>.value(value: b.panic),
        BlocProvider<FamilyBloc>.value(value: b.family),
        BlocProvider<SystemHealthCubit>.value(value: b.health),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: night ? vigiNightTheme : appTheme,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: app!,
        ),
        home: child,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
  return b;
}

/// Compara com a imagem de referência sem esperar animações infinitas.
Future<void> expectGolden(WidgetTester tester, String name) =>
    screenMatchesGolden(
      tester,
      name,
      customPump: (t) => t.pump(const Duration(milliseconds: 100)),
    );

/// Sufixo do nome da imagem para a combinação de fonte e tema.
String variant({double textScale = 1, bool night = false}) =>
    '${night ? 'noturno' : 'claro'}_x${textScale == 1 ? '1' : '2'}';
