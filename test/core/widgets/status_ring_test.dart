import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:guardiao/core/theme/app_theme.dart';
import 'package:guardiao/core/widgets/status_ring.dart';
import 'package:guardiao/core/widgets/vigi_mascot.dart';

void main() {
  group('StatusRing', () {
    Widget buildRing({
      double progress = 0.5,
      VigiState state = VigiState.normal,
    }) {
      return MaterialApp(
        theme: appTheme,
        home: Scaffold(
          body: Center(
            child: StatusRing(
              progress: progress,
              state: state,
              size: 160,
              child: const Text('12:00:00'),
            ),
          ),
        ),
      );
    }

    testWidgets('renderiza com child', (tester) async {
      await tester.pumpWidget(buildRing());
      expect(find.byType(StatusRing), findsOneWidget);
      expect(find.text('12:00:00'), findsOneWidget);
    });

    testWidgets('renderiza sem child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: const Scaffold(
            body: Center(
              child: StatusRing(progress: 0.75),
            ),
          ),
        ),
      );
      expect(find.byType(StatusRing), findsOneWidget);
    });

    testWidgets('clamps progress entre 0 e 1', (tester) async {
      // Não deve lançar exceção com valores fora de range
      await tester.pumpWidget(buildRing(progress: -0.5));
      expect(find.byType(StatusRing), findsOneWidget);

      await tester.pumpWidget(buildRing(progress: 1.5));
      expect(find.byType(StatusRing), findsOneWidget);
    });

    testGoldens('golden — normal 50%', (tester) async {
      await tester.pumpWidgetBuilder(
        buildRing(),
        surfaceSize: const Size(200, 200),
      );
      await screenMatchesGolden(tester, 'status_ring_normal_50');
    });

    testGoldens('golden — atento 80%', (tester) async {
      await tester.pumpWidgetBuilder(
        buildRing(progress: 0.8, state: VigiState.atento),
        surfaceSize: const Size(200, 200),
      );
      await screenMatchesGolden(tester, 'status_ring_atento_80');
    });

    testGoldens('golden — alerta 95%', (tester) async {
      await tester.pumpWidgetBuilder(
        buildRing(progress: 0.95, state: VigiState.alerta),
        surfaceSize: const Size(200, 200),
      );
      await screenMatchesGolden(tester, 'status_ring_alerta_95');
    });
  });
}
