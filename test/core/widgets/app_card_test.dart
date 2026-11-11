import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/core/theme/app_colors.dart';
import 'package:guardiao/core/theme/app_theme.dart';
import 'package:guardiao/core/theme/vigi_tokens.dart';
import 'package:guardiao/core/widgets/app_card.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('AppCard', () {
    Widget buildCard({VoidCallback? onTap, bool night = false}) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: night ? vigiNightTheme : appTheme,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AppCard(
                onTap: onTap,
                child: const Text('Conteúdo do card'),
              ),
            ),
          ),
        ),
      );
    }

    BoxDecoration decorationOf(WidgetTester tester) =>
        tester.widget<Ink>(find.byType(Ink)).decoration! as BoxDecoration;

    testWidgets('renderiza o conteúdo', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.text('Conteúdo do card'), findsOneWidget);
    });

    testWidgets('responde ao toque quando recebe onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildCard(onTap: () => tapped = true));
      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('não é tocável sem onTap', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('é Linho 50 com borda Linho 200, raio 20 e sem sombra', (
      tester,
    ) async {
      await tester.pumpWidget(buildCard());
      final decoration = decorationOf(tester);
      expect(decoration.color, VigiColors.linho50);
      expect(
        decoration.border,
        Border.all(color: VigiColors.linho200),
      );
      expect(
        decoration.borderRadius,
        BorderRadius.circular(VigiRadius.md),
      );
      // Elevação é feita por cor: a sombra fica reservada para os estados.
      expect(decoration.boxShadow, isNull);
    });

    testWidgets('no tema noturno é Petróleo 800 sobre Petróleo 900', (
      tester,
    ) async {
      await tester.pumpWidget(buildCard(night: true));
      expect(decorationOf(tester).color, VigiColors.petroleo800);
    });

    testWidgets('golden: card padrão', (tester) async {
      tester.view.physicalSize = const Size(400, 120);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(buildCard());
      await expectGolden(tester, 'app_card_default');
    });
  });
}
