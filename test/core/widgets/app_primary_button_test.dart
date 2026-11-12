import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:guardiao/core/theme/app_colors.dart';
import 'package:guardiao/core/theme/app_theme.dart';
import 'package:guardiao/core/theme/vigi_tokens.dart';
import 'package:guardiao/core/widgets/app_primary_button.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('AppPrimaryButton', () {
    Widget buildButton({
      String text = 'Estou bem',
      AppButtonVariant variant = AppButtonVariant.primary,
      AppButtonSize size = AppButtonSize.regular,
      bool isLoading = false,
      IconData? icon,
      VoidCallback? onPressed,
      double textScale = 1,
      double width = 360,
    }) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: Scaffold(
          backgroundColor: variant == AppButtonVariant.onSignal
              ? VigiColors.sinal600
              : null,
          body: Center(
            child: SizedBox(
              width: width,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppPrimaryButton(
                  text: text,
                  variant: variant,
                  size: size,
                  isLoading: isLoading,
                  icon: icon,
                  onPressed: onPressed ?? () {},
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renderiza o texto', (tester) async {
      await tester.pumpWidget(buildButton());
      expect(find.text('Estou bem'), findsOneWidget);
    });

    testWidgets('mostra o indicador de espera e esconde o texto', (
      tester,
    ) async {
      await tester.pumpWidget(buildButton(isLoading: true));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Estou bem'), findsNothing);
    });

    testWidgets('mostra o ícone junto do texto', (tester) async {
      await tester.pumpWidget(buildButton(icon: Icons.check_rounded));
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('Estou bem'), findsOneWidget);
    });

    testWidgets('responde ao toque', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildButton(onPressed: () => tapped = true));
      await tester.tap(find.text('Estou bem'));
      expect(tapped, isTrue);
    });

    testWidgets('não responde ao toque enquanto espera', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildButton(isLoading: true, onPressed: () => tapped = true),
      );
      await tester.tap(find.byType(FilledButton));
      expect(tapped, isFalse);
    });

    testWidgets('alturas mínimas: 64 dp o primário, 96 dp o da chamada', (
      tester,
    ) async {
      await tester.pumpWidget(buildButton());
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(VigiSizes.button),
      );

      await tester.pumpWidget(buildButton(size: AppButtonSize.call));
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(VigiSizes.callButton),
      );

      await tester.pumpWidget(buildButton(size: AppButtonSize.compact));
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(VigiSizes.touch),
      );
    });

    testWidgets('com a fonte a 200% o botão cresce e o texto não é cortado', (
      tester,
    ) async {
      const long = 'Estou seguro, cancelar o pedido de ajuda';
      await tester.pumpWidget(
        buildButton(text: long, textScale: 2, width: 320),
      );
      expect(tester.takeException(), isNull);

      final text = tester.widget<Text>(find.text(long));
      // Nada de reticências: o texto quebra em mais linhas.
      expect(text.overflow, isNull);
      expect(text.maxLines, isNull);
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThan(VigiSizes.button),
      );
    });

    testWidgets('é anunciado como botão, com o próprio texto', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(buildButton());
      expect(
        tester.getSemantics(find.bySemanticsLabel('Estou bem')),
        matchesSemantics(
          label: 'Estou bem',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
      );
      handle.dispose();
    });

    const variants = <(String, AppButtonVariant, AppButtonSize)>[
      ('primary', AppButtonVariant.primary, AppButtonSize.regular),
      ('amber_call', AppButtonVariant.amber, AppButtonSize.call),
      ('outline', AppButtonVariant.outline, AppButtonSize.regular),
      ('on_signal', AppButtonVariant.onSignal, AppButtonSize.regular),
    ];
    for (final (name, variant, size) in variants) {
      testGoldens('golden: $name', (tester) async {
        tester.view.physicalSize = const Size(400, 160);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildButton(variant: variant, size: size));
        await expectGolden(tester, 'app_primary_button_$name');
      });
    }
  });
}
