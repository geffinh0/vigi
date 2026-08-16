import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:guardiao/core/theme/app_theme.dart';
import 'package:guardiao/core/widgets/vigi_mascot.dart';

void main() {
  group('VigiMascot', () {
    Widget buildMascot({
      VigiState state = VigiState.normal,
      bool animate = false,
    }) {
      return MaterialApp(
        theme: appTheme,
        home: Scaffold(
          body: Center(
            child: VigiMascot(
              state: state,
              size: 120,
              animate: animate,
            ),
          ),
        ),
      );
    }

    testWidgets('renderiza estado normal', (tester) async {
      await tester.pumpWidget(buildMascot());
      await tester.pump();
      expect(find.byType(VigiMascot), findsOneWidget);
      expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
    });

    testWidgets('renderiza estado atento', (tester) async {
      await tester.pumpWidget(buildMascot(state: VigiState.atento));
      await tester.pump();
      expect(find.byIcon(Icons.timer_rounded), findsOneWidget);
    });

    testWidgets('renderiza estado alerta', (tester) async {
      await tester.pumpWidget(buildMascot(state: VigiState.alerta));
      await tester.pump();
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('três estados usam ícones diferentes', (tester) async {
      // Normal
      await tester.pumpWidget(buildMascot());
      await tester.pump();
      expect(find.byIcon(Icons.shield_rounded), findsOneWidget);

      // Atento
      await tester.pumpWidget(buildMascot(state: VigiState.atento));
      await tester.pump();
      expect(find.byIcon(Icons.timer_rounded), findsOneWidget);

      // Alerta
      await tester.pumpWidget(buildMascot(state: VigiState.alerta));
      await tester.pump();
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testGoldens('golden — estado normal', (tester) async {
      await tester.pumpWidgetBuilder(
        buildMascot(),
        surfaceSize: const Size(200, 200),
      );
      await screenMatchesGolden(tester, 'vigi_mascot_normal');
    });

    testGoldens('golden — estado atento', (tester) async {
      await tester.pumpWidgetBuilder(
        buildMascot(state: VigiState.atento),
        surfaceSize: const Size(200, 200),
      );
      await screenMatchesGolden(tester, 'vigi_mascot_atento');
    });

    testGoldens('golden — estado alerta', (tester) async {
      await tester.pumpWidgetBuilder(
        buildMascot(state: VigiState.alerta),
        surfaceSize: const Size(200, 200),
      );
      await screenMatchesGolden(tester, 'vigi_mascot_alerta');
    });
  });
}
