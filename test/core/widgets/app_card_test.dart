import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:guardiao/core/theme/app_theme.dart';
import 'package:guardiao/core/widgets/app_card.dart';

void main() {
  group('AppCard', () {
    Widget buildCard({VoidCallback? onTap}) {
      return MaterialApp(
        theme: appTheme,
        home: Scaffold(
          body: Center(
            child: AppCard(
              onTap: onTap,
              child: const Text('Conteúdo do Card'),
            ),
          ),
        ),
      );
    }

    testWidgets('renderiza child corretamente', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.text('Conteúdo do Card'), findsOneWidget);
    });

    testWidgets('responde a onTap quando fornecido', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildCard(onTap: () => tapped = true));
      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('não tem InkWell quando onTap é null', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.byType(InkWell), findsNothing);
    });

    testGoldens('golden — card padrão', (tester) async {
      await tester.pumpWidgetBuilder(
        buildCard(),
        surfaceSize: const Size(400, 120),
      );
      await screenMatchesGolden(tester, 'app_card_default');
    });
  });
}
