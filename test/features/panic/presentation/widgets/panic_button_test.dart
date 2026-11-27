import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/core/theme/vigi_tokens.dart';
import 'package:guardiao/core/widgets/status_ring.dart';
import 'package:guardiao/features/panic/presentation/bloc/panic_event.dart';
import 'package:guardiao/features/panic/presentation/widgets/panic_button.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(const PanicTriggered());
  });

  Future<(AppBlocs, List<String>)> pumpButton(
    WidgetTester tester, {
    PanicButtonStyle style = PanicButtonStyle.large,
  }) async {
    final log = <String>[];
    final blocs = await pumpApp(
      tester,
      Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: PanicButton(
              style: style,
              onTap: () => log.add('tap'),
              onReleasedEarly: () => log.add('early'),
              onPanicTriggered: () => log.add('triggered'),
            ),
          ),
        ),
      ),
      reduceMotion: false,
    );
    return (blocs, log);
  }

  double progress(WidgetTester tester) =>
      tester.widget<StatusRing>(find.byType(StatusRing)).progress;

  group('PanicButton', () {
    testWidgets('tem 200 dp de diâmetro', (tester) async {
      await pumpButton(tester);
      final button = tester.widget<PanicButton>(find.byType(PanicButton));
      expect(button.size, VigiSizes.panic);
      expect(
        tester.getSize(find.byType(PanicButton)).shortestSide,
        greaterThanOrEqualTo(200),
      );
    });

    testWidgets('segurar por 3 segundos pede ajuda', (tester) async {
      final (blocs, log) = await pumpButton(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PanicButton)),
      );
      // Um quadro para o gesto começar a contar.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2900));
      verifyNever(() => blocs.panic.add(any()));

      await tester.pump(const Duration(milliseconds: 200));
      verify(() => blocs.panic.add(const PanicTriggered())).called(1);
      expect(log, ['triggered']);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('durante o gesto: o anel enche e o número muda a cada '
        'segundo', (tester) async {
      await pumpButton(tester);
      expect(find.text('Segure para\npedir ajuda'), findsOneWidget);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PanicButton)),
      );
      // Um quadro para o gesto começar a contar.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Segure…'), findsOneWidget);
      expect(progress(tester), closeTo(0.5 / 3, 0.02));

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('2'), findsOneWidget);
      expect(progress(tester), closeTo(0.5, 0.02));

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('1'), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('soltar antes não pede ajuda: o anel volta e a pessoa é '
        'avisada', (tester) async {
      final (blocs, log) = await pumpButton(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PanicButton)),
      );
      // Um quadro para o gesto começar a contar.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));
      await gesture.up();
      await tester.pumpAndSettle();

      verifyNever(() => blocs.panic.add(any()));
      expect(log, ['early']);
      expect(progress(tester), 0);
      expect(find.text('Segure para\npedir ajuda'), findsOneWidget);
    });

    testWidgets('um toque rápido nunca pede ajuda', (tester) async {
      final (blocs, log) = await pumpButton(tester);
      await tester.tap(find.byType(PanicButton));
      await tester.pumpAndSettle();
      verifyNever(() => blocs.panic.add(any()));
      expect(log, ['tap']);
    });

    testWidgets('é anunciado com a instrução de segurar', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpButton(tester);
      final node = tester.getSemantics(find.bySemanticsLabel('Pedir ajuda'));
      expect(node.hint, contains('Segure por 3 segundos'));
      handle.dispose();
    });

    testWidgets('rodapé: "Pedir ajuda, segure 3 s", também com segurar', (
      tester,
    ) async {
      final (blocs, log) = await pumpButton(
        tester,
        style: PanicButtonStyle.footer,
      );
      expect(find.text('Pedir ajuda'), findsOneWidget);
      expect(find.text('segure 3 s'), findsOneWidget);
      expect(
        tester.getSize(find.byType(PanicButton)).height,
        greaterThanOrEqualTo(VigiSizes.button),
      );

      await tester.tap(find.byType(PanicButton));
      await tester.pumpAndSettle();
      expect(log, ['tap']);
      verifyNever(() => blocs.panic.add(any()));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PanicButton)),
      );
      // Um quadro para o gesto começar a contar.
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.textContaining('Segure…'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1100));
      verify(() => blocs.panic.add(const PanicTriggered())).called(1);
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
