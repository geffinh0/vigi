import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/core/theme/app_theme.dart';
import 'package:guardiao/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:guardiao/features/auth/presentation/bloc/auth_event.dart';
import 'package:guardiao/features/auth/presentation/bloc/auth_state.dart';
import 'package:guardiao/features/auth/presentation/pages/login_page.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

Widget makeTestableWidget({
  required Widget child,
  required AuthBloc authBloc,
}) {
  return MaterialApp(
    theme: appTheme,
    home: BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: child,
    ),
  );
}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUpAll(() {
    registerFallbackValue(const AuthCheckRequested());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  testWidgets('renderiza campos de login e botão de entrar', (tester) async {
    when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

    await tester.pumpWidget(
      makeTestableWidget(
        child: const LoginPage(),
        authBloc: mockAuthBloc,
      ),
    );

    expect(find.text('Entrar na sua conta'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('mostra SnackBar quando AuthBloc emite AuthFailure', (
    tester,
  ) async {
    when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
    whenListen(
      mockAuthBloc,
      Stream.fromIterable([
        const AuthFailure('Credenciais incorretas'),
      ]),
      initialState: const AuthInitial(),
    );

    await tester.pumpWidget(
      makeTestableWidget(
        child: const LoginPage(),
        authBloc: mockAuthBloc,
      ),
    );
    await tester.pump();

    expect(find.text('Credenciais incorretas'), findsOneWidget);
  });
}
