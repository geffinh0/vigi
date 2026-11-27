import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/core/theme/app_colors.dart';
import 'package:guardiao/core/theme/app_theme.dart';
import 'package:guardiao/core/widgets/vigi_logo.dart';
import 'package:guardiao/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:guardiao/features/auth/presentation/bloc/auth_event.dart';
import 'package:guardiao/features/auth/presentation/bloc/auth_state.dart';
import 'package:guardiao/features/auth/presentation/pages/login_page.dart';
import 'package:guardiao/features/auth/presentation/pages/register_page.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

Widget makeTestableWidget({required Widget child, required AuthBloc authBloc}) {
  return MaterialApp(
    theme: appTheme,
    home: BlocProvider<AuthBloc>.value(value: authBloc, child: child),
  );
}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUpAll(() {
    registerFallbackValue(const AuthCheckRequested());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
  });

  group('LoginPage', () {
    testWidgets('mostra o logotipo, os campos e o botão de entrar', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const LoginPage(), authBloc: mockAuthBloc),
      );

      expect(find.byType(VigiLogo), findsOneWidget);
      expect(find.text('Entrar na sua conta'), findsOneWidget);
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Criar conta'), findsOneWidget);
      // O nome não aparece em caixa alta.
      expect(find.text('VIGI'), findsNothing);
    });

    testWidgets('o Vigi Família usa a mesma tela com a assinatura "Família"', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(
          child: const LoginPage(familyEdition: true),
          authBloc: mockAuthBloc,
        ),
      );
      expect(find.text('Família'), findsOneWidget);
    });

    testWidgets('erro de e-mail explica como corrigir, em Cinza texto', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const LoginPage(), authBloc: mockAuthBloc),
      );
      await tester.enterText(find.byType(TextFormField).first, 'maria');
      await tester.ensureVisible(find.text('Entrar'));
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      final error = tester.widget<Text>(
        find.text('Confira o e-mail. Exemplo: maria@email.com'),
      );
      expect(error.style!.color, VigiColors.cinzaTexto);
      expect(find.text('Digite a sua senha.'), findsOneWidget);
      verifyNever(() => mockAuthBloc.add(any()));
    });

    testWidgets('envia o login quando os campos estão preenchidos', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const LoginPage(), authBloc: mockAuthBloc),
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        ' lucia@email.com ',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'segredo1');
      await tester.ensureVisible(find.text('Entrar'));
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      verify(
        () => mockAuthBloc.add(
          const AuthSignInRequested(
            email: 'lucia@email.com',
            password: 'segredo1',
          ),
        ),
      ).called(1);
    });

    testWidgets('mostra o aviso quando o AuthBloc emite AuthFailure, sem '
        'vermelho', (tester) async {
      final stateController = StreamController<AuthState>.broadcast();
      when(() => mockAuthBloc.stream).thenAnswer((_) => stateController.stream);

      await tester.pumpWidget(
        makeTestableWidget(child: const LoginPage(), authBloc: mockAuthBloc),
      );
      await tester.pump();

      stateController.add(const AuthFailure('Credenciais incorretas'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.text('Credenciais incorretas'), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      // Erro comum não é socorro: usa a cor do tema, não o Sinal.
      expect(snackBar.backgroundColor, isNull);
      expect(appTheme.snackBarTheme.backgroundColor, VigiColors.petroleo800);
      // Nada some antes de a pessoa ler.
      expect(
        snackBar.duration,
        greaterThanOrEqualTo(const Duration(seconds: 60)),
      );
      await stateController.close();
    });
  });

  group('RegisterPage', () {
    testWidgets('título e senha seguem o texto do guia', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterPage(), authBloc: mockAuthBloc),
      );

      expect(find.text('Criar sua conta no Vigi'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      // A regra da senha é uma dica abaixo do campo, não parte do rótulo.
      expect(find.text('Pelo menos 6 caracteres'), findsOneWidget);
      expect(find.textContaining('Junte-se'), findsNothing);
      expect(find.text('Senha (mínimo 6 caracteres)'), findsNothing);
    });

    testWidgets('valida os campos com frases que explicam', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterPage(), authBloc: mockAuthBloc),
      );
      await tester.enterText(find.byType(TextFormField).at(3), '123');
      await tester.ensureVisible(find.text('Criar conta'));
      await tester.tap(find.text('Criar conta'));
      await tester.pump();

      expect(find.text('Digite o seu nome.'), findsOneWidget);
      expect(find.text('Digite o seu e-mail.'), findsOneWidget);
      expect(
        find.text('A senha precisa de pelo menos 6 caracteres.'),
        findsOneWidget,
      );
      verifyNever(() => mockAuthBloc.add(any()));
    });

    testWidgets('envia o cadastro', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterPage(), authBloc: mockAuthBloc),
      );
      await tester.enterText(find.byType(TextFormField).at(0), 'Lúcia Almeida');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'lucia@email.com',
      );
      await tester.enterText(find.byType(TextFormField).at(3), 'segredo1');
      await tester.ensureVisible(find.text('Criar conta'));
      await tester.tap(find.text('Criar conta'));
      await tester.pump();

      verify(
        () => mockAuthBloc.add(
          const AuthSignUpRequested(
            email: 'lucia@email.com',
            password: 'segredo1',
            fullName: 'Lúcia Almeida',
          ),
        ),
      ).called(1);
    });
  });
}
