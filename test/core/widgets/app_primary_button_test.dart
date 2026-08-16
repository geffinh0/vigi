import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:guardiao/core/theme/app_theme.dart';
import 'package:guardiao/core/widgets/app_primary_button.dart';

void main() {
  group('AppPrimaryButton', () {
    Widget buildButton({
      AppButtonVariant variant = AppButtonVariant.primary,
      bool isLoading = false,
      IconData? icon,
    }) {
      return MaterialApp(
        theme: appTheme,
        home: Scaffold(
          body: Center(
            child: AppPrimaryButton(
              text: 'Teste',
              variant: variant,
              isLoading: isLoading,
              icon: icon,
              onPressed: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('renderiza texto corretamente', (tester) async {
      await tester.pumpWidget(buildButton());
      expect(find.text('Teste'), findsOneWidget);
    });

    testWidgets('mostra indicador de loading', (tester) async {
      await tester.pumpWidget(buildButton(isLoading: true));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Teste'), findsNothing);
    });

    testWidgets('mostra ícone quando fornecido', (tester) async {
      await tester.pumpWidget(buildButton(icon: Icons.check));
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('responde a tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: Scaffold(
            body: Center(
              child: AppPrimaryButton(
                text: 'Tap',
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Tap'));
      expect(tapped, isTrue);
    });

    testWidgets('não responde a tap quando loading', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: Scaffold(
            body: Center(
              child: AppPrimaryButton(
                text: 'Tap',
                isLoading: true,
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isFalse);
    });

    testGoldens('golden — variante primary', (tester) async {
      await tester.pumpWidgetBuilder(
        buildButton(),
        surfaceSize: const Size(400, 80),
      );
      await screenMatchesGolden(tester, 'app_primary_button_primary');
    });

    testGoldens('golden — variante danger', (tester) async {
      await tester.pumpWidgetBuilder(
        buildButton(variant: AppButtonVariant.danger, icon: Icons.emergency),
        surfaceSize: const Size(400, 80),
      );
      await screenMatchesGolden(tester, 'app_primary_button_danger');
    });

    testGoldens('golden — variante outline', (tester) async {
      await tester.pumpWidgetBuilder(
        buildButton(variant: AppButtonVariant.outline),
        surfaceSize: const Size(400, 80),
      );
      await screenMatchesGolden(tester, 'app_primary_button_outline');
    });
  });
}
