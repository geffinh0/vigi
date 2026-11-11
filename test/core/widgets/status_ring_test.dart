import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/core/theme/app_theme.dart';
import 'package:guardiao/core/theme/vigi_state.dart';
import 'package:guardiao/core/theme/vigi_tokens.dart';
import 'package:guardiao/core/widgets/status_ring.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('StatusRing', () {
    Widget buildRing({
      double progress = 0.5,
      VigiState state = VigiState.vigiando,
      bool night = false,
      Widget? child,
      String? semanticsLabel,
      double? size,
    }) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: night ? vigiNightTheme : appTheme,
        home: Scaffold(
          body: Center(
            child: StatusRing(
              progress: progress,
              state: state,
              size: size ?? VigiSizes.ring,
              semanticsLabel: semanticsLabel,
              child: child,
            ),
          ),
        ),
      );
    }

    testWidgets('tem 240 dp de diâmetro e traço de 14 dp por padrão', (
      tester,
    ) async {
      await tester.pumpWidget(buildRing());
      final ring = tester.widget<StatusRing>(find.byType(StatusRing));
      expect(ring.size, 240);
      expect(ring.strokeWidth, 14);
      expect(tester.getSize(find.byType(StatusRing)), const Size(240, 240));
    });

    testWidgets('renderiza o conteúdo no centro', (tester) async {
      await tester.pumpWidget(buildRing(child: const Text('38 min')));
      expect(find.text('38 min'), findsOneWidget);
      final ringCenter = tester.getCenter(find.byType(StatusRing));
      expect(tester.getCenter(find.text('38 min')), ringCenter);
    });

    testWidgets('renderiza sem conteúdo', (tester) async {
      await tester.pumpWidget(buildRing(progress: 0.75));
      expect(find.byType(StatusRing), findsOneWidget);
    });

    testWidgets('limita o progresso entre 0 e 1', (tester) async {
      await tester.pumpWidget(buildRing(progress: -0.5));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(buildRing(progress: 1.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('anuncia o tempo por extenso ao leitor de tela', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        buildRing(
          semanticsLabel: 'Próximo check-in às 15 horas, daqui a 38 minutos',
          child: const Text('38 min'),
        ),
      );
      expect(
        find.bySemanticsLabel(
          'Próximo check-in às 15 horas, daqui a 38 minutos',
        ),
        findsOneWidget,
      );
      // O texto abreviado de dentro do anel não é lido em duplicidade.
      expect(find.bySemanticsLabel('38 min'), findsNothing);
      handle.dispose();
    });

    const cases = <(String, double, VigiState, bool)>[
      ('vigiando_63', 0.63, VigiState.vigiando, false),
      ('sua_vez_cheio', 1, VigiState.suaVez, false),
      ('alerta_95', 0.95, VigiState.alerta, false),
      ('descansando_vazio', 0, VigiState.descansando, false),
      ('noturno_30', 0.3, VigiState.noturno, true),
    ];
    for (final (name, progress, state, night) in cases) {
      testWidgets('golden: $name', (tester) async {
        tester.view.physicalSize = const Size(300, 300);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          buildRing(progress: progress, state: state, night: night),
        );
        // Deixa a transição de cor terminar.
        await tester.pump(VigiMotion.stateChange);
        await expectGolden(tester, 'status_ring_$name');
      });
    }
  });
}
