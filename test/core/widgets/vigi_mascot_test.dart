import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/core/theme/app_colors.dart';
import 'package:guardiao/core/theme/app_theme.dart';
import 'package:guardiao/core/theme/vigi_state.dart';
import 'package:guardiao/core/theme/vigi_tokens.dart';
import 'package:guardiao/core/widgets/vigi_mascot.dart';

import '../../helpers/pump_app.dart';

void main() {
  Widget buildMascot({
    VigiState state = VigiState.vigiando,
    bool animate = false,
    bool night = false,
    double size = 120,
    bool reduceMotion = false,
  }) {
    final style = VigiStateStyle.of(
      state,
      brightness: night ? Brightness.dark : Brightness.light,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: night ? vigiNightTheme : appTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduceMotion,
        ),
        child: child!,
      ),
      home: Scaffold(
        // A coruja de alerta é vermelha sobre fundo claro, ou branca sobre
        // o vermelho de tela cheia.
        backgroundColor: state == VigiState.alerta
            ? VigiColors.sinal100
            : style.background,
        body: Center(
          child: VigiMascot(state: state, size: size, animate: animate),
        ),
      ),
    );
  }

  OwlPainter painterOf(WidgetTester tester) {
    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(VigiMascot),
        matching: find.byType(CustomPaint),
      ),
    );
    return paint.painter! as OwlPainter;
  }

  group('VigiMascot', () {
    testWidgets('cada estado tem a sua forma de olhos (não só a cor)', (
      tester,
    ) async {
      const expected = {
        VigiState.descansando: VigiEyes.closed,
        VigiState.vigiando: VigiEyes.open,
        VigiState.suaVez: VigiEyes.wide,
        VigiState.ultimaChamada: VigiEyes.wide,
        VigiState.alerta: VigiEyes.alert,
        VigiState.aliviado: VigiEyes.happy,
        VigiState.noturno: VigiEyes.glow,
      };
      for (final entry in expected.entries) {
        await tester.pumpWidget(buildMascot(state: entry.key));
        await tester.pump();
        expect(painterOf(tester).eyes, entry.value, reason: '${entry.key}');
      }
    });

    testWidgets('não desenha mais o escudo, o cronômetro ou o aviso', (
      tester,
    ) async {
      for (final state in VigiState.values) {
        await tester.pumpWidget(buildMascot(state: state));
        expect(find.byType(Icon), findsNothing, reason: '$state');
      }
    });

    testWidgets('anuncia o estado ao leitor de tela', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(buildMascot(state: VigiState.suaVez));
      expect(find.bySemanticsLabel('Vigi: sua vez'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('em alerta o sobrolho fica erguido', (tester) async {
      await tester.pumpWidget(buildMascot(state: VigiState.alerta));
      expect(painterOf(tester).raisedBrow, isTrue);
      await tester.pumpWidget(buildMascot());
      expect(painterOf(tester).raisedBrow, isFalse);
    });

    testWidgets('respira no ritmo do estado: 4 s vigiando, 1,4 s na vez', (
      tester,
    ) async {
      Transform scaleOf() => tester.widget<Transform>(
        find.descendant(
          of: find.byType(VigiMascot),
          matching: find.byType(Transform),
        ),
      );
      double scale() => scaleOf().transform.getMaxScaleOnAxis();

      await tester.pumpWidget(buildMascot(animate: true));
      expect(scale(), closeTo(1, 0.001));
      // Meio ciclo de 4 s: a coruja está no ponto mais cheio da respiração.
      await tester.pump(VigiMotion.breathCalm ~/ 2);
      expect(scale(), closeTo(1.04, 0.002));
      await tester.pump(VigiMotion.breathCalm ~/ 2);
      expect(scale(), closeTo(1, 0.002));

      await tester.pumpWidget(
        buildMascot(state: VigiState.suaVez, animate: true),
      );
      await tester.pump();
      await tester.pump(VigiMotion.breathAttention ~/ 2);
      expect(scale(), greaterThan(1.02));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('descansando não respira', (tester) async {
      await tester.pumpWidget(
        buildMascot(state: VigiState.descansando, animate: true),
      );
      await tester.pump(const Duration(seconds: 2));
      // Sem animação pendente: pumpAndSettle termina.
      await tester.pumpAndSettle();
      expect(painterOf(tester).eyes, VigiEyes.closed);
    });

    testWidgets('"Remover animações" para a respiração', (tester) async {
      await tester.pumpWidget(buildMascot(animate: true, reduceMotion: true));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      final transform = tester.widget<Transform>(
        find.descendant(
          of: find.byType(VigiMascot),
          matching: find.byType(Transform),
        ),
      );
      expect(transform.transform.getMaxScaleOnAxis(), closeTo(1, 0.001));
    });

    testWidgets('pisca ao confirmar: fecha os olhos e abre no sorriso', (
      tester,
    ) async {
      await tester.pumpWidget(buildMascot(animate: true));
      await tester.pumpWidget(
        buildMascot(state: VigiState.aliviado, animate: true),
      );
      // Durante a piscada ainda são os olhos abertos, se fechando.
      await tester.pump(VigiMotion.blinkClose ~/ 2);
      expect(painterOf(tester).eyes, VigiEyes.open);
      expect(painterOf(tester).closed, greaterThan(0));

      await tester.pump(VigiMotion.blinkClose);
      await tester.pump();
      expect(painterOf(tester).eyes, VigiEyes.happy);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('abaixo de 48 dp ocupa só o espaço pedido', (tester) async {
      await tester.pumpWidget(buildMascot(size: 24));
      expect(tester.getSize(find.byType(VigiMascot)), const Size(24, 24));
    });

    for (final state in VigiState.values) {
      testWidgets('golden: ${state.name}', (tester) async {
        tester.view.physicalSize = const Size(200, 200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildMascot(state: state));
        await expectGolden(tester, 'vigi_mascot_${state.name}');
      });
    }

    for (final state in const [
      VigiState.descansando,
      VigiState.vigiando,
      VigiState.aliviado,
    ]) {
      testWidgets('golden noturno: ${state.name}', (tester) async {
        tester.view.physicalSize = const Size(200, 200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildMascot(state: state, night: true));
        await expectGolden(tester, 'vigi_mascot_${state.name}_noturno');
      });
    }
  });

  group('VigiSymbol', () {
    testWidgets('usa o âmbar só nos olhos e no bico', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: const Scaffold(body: Center(child: VigiSymbol(size: 96))),
        ),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(VigiSymbol),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as OwlPainter;
      expect(painter.colors.ring, VigiColors.petroleo800);
      expect(painter.colors.pupil, VigiColors.ambar500);
      expect(painter.colors.beak, VigiColors.ambar500);
    });
  });
}
