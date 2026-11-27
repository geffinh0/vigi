import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:guardiao/app/permissions_page.dart';
import 'package:guardiao/core/services/system_health_service.dart';
import 'package:guardiao/core/theme/app_colors.dart';
import 'package:guardiao/core/theme/vigi_tokens.dart';
import 'package:guardiao/core/widgets/health_banner.dart';
import 'package:guardiao/core/widgets/vigi_mascot.dart';

import '../helpers/pump_app.dart';

void main() {
  const kinds = [
    HealthIssue.notificationsBlocked,
    HealthIssue.smsDenied,
    HealthIssue.locationDenied,
    HealthIssue.exactAlarmsDenied,
    HealthIssue.fullScreenDenied,
    HealthIssue.batteryOptimized,
  ];

  AppBlocs blocsWith(List<HealthIssue> missing) =>
      AppBlocs(health: missing, permissionKinds: kinds);

  group('PermissionsPage', () {
    testWidgets('explica cada permissão em linguagem clara, antes de pedir', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const PermissionsPage(),
        blocs: blocsWith(kinds),
        size: const Size(360, 2400),
      );

      expect(find.text('Para o Vigi cuidar de você'), findsOneWidget);
      for (final kind in kinds) {
        expect(find.text(kind.permissionName), findsOneWidget);
        expect(find.text(kind.permissionPurpose), findsOneWidget);
      }
      // O porquê, sem jargão.
      expect(
        find.text('Para o Vigi chamar você na hora do check-in.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Para dizer onde você está. Só é enviada em um pedido de ajuda.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('nada é pedido sem a pessoa tocar', (tester) async {
      final blocs = await pumpApp(
        tester,
        const PermissionsPage(),
        blocs: blocsWith(kinds),
      );
      expect(blocs.health.fixed, isEmpty);
    });

    testWidgets('"Permitir" pede só aquela permissão e o card vira '
        '"Permitido"', (tester) async {
      final blocs = await pumpApp(
        tester,
        const PermissionsPage(),
        blocs: blocsWith(const [HealthIssue.notificationsBlocked]),
        size: const Size(360, 2400),
      );

      expect(find.text('Permitido'), findsNWidgets(kinds.length - 1));
      await tapVisible(tester, find.text('Permitir notificações'));
      await tester.pump();

      expect(blocs.health.fixed, [HealthIssue.notificationsBlocked]);
      expect(find.text('Permitir notificações'), findsNothing);
      expect(find.text('Permitido'), findsNWidgets(kinds.length));
    });

    testWidgets('pendente é a vez da pessoa: âmbar, não vermelho', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const PermissionsPage(),
        blocs: blocsWith(const [HealthIssue.smsDenied]),
        size: const Size(360, 2400),
      );
      final card = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Mensagens SMS'),
              matching: find.byType(Container),
            )
            .first,
      );
      expect((card.decoration! as BoxDecoration).color, VigiColors.ambar100);
      expect(
        tester.widget<VigiMascot>(find.byType(VigiMascot)).state,
        VigiState.suaVez,
      );
    });

    testWidgets('com tudo permitido, a coruja vigia e a tela confirma', (
      tester,
    ) async {
      await pumpApp(tester, const PermissionsPage(), blocs: blocsWith([]));
      expect(
        find.text('Tudo certo: o Vigi tem o que precisa.'),
        findsOneWidget,
      );
      expect(
        tester.widget<VigiMascot>(find.byType(VigiMascot)).state,
        VigiState.vigiando,
      );
      expect(find.byType(FilledButton), findsOneWidget); // só "Continuar"
    });

    testWidgets('dá para continuar sem permitir tudo, e a tela diz o que '
        'acontece', (tester) async {
      await pumpApp(
        tester,
        const PermissionsPage(),
        blocs: blocsWith(const [HealthIssue.batteryOptimized]),
      );
      expect(
        find.textContaining('Você pode permitir depois.'),
        findsOneWidget,
      );
      final button = find.widgetWithText(FilledButton, 'Continuar');
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
      expect(
        tester.getSize(button).height,
        greaterThanOrEqualTo(VigiSizes.button),
      );
      // "Continuar" fica sempre à vista, fora da rolagem.
      expect(tester.getRect(button).bottom, lessThanOrEqualTo(kPhone.height));
    });

    testWidgets('botões de permitir têm pelo menos 56 dp', (tester) async {
      await pumpApp(
        tester,
        const PermissionsPage(),
        blocs: blocsWith(kinds),
        size: const Size(360, 2400),
      );
      for (final kind in kinds) {
        final label = kind.permissionAction;
        expect(
          tester.getSize(find.widgetWithText(FilledButton, label)).height,
          greaterThanOrEqualTo(VigiSizes.touch),
          reason: label,
        );
        // Verbo + objeto, sem caixa alta nem "OK".
        expect(label, isNot(label.toUpperCase()));
        expect(label.split(' ').length, greaterThanOrEqualTo(2));
      }
    });

    for (final scale in [1.0, 2.0]) {
      testGoldens('golden: permissões x$scale', (tester) async {
        await pumpApp(
          tester,
          const PermissionsPage(),
          blocs: blocsWith(const [
            HealthIssue.smsDenied,
            HealthIssue.batteryOptimized,
          ]),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        await expectGolden(tester, 'permissoes_${variant(textScale: scale)}');
      });
    }
  });

  group('textos de cada permissão', () {
    test('toda permissão tem nome, propósito e ícone', () {
      for (final kind in kinds) {
        expect(kind.isPermission, isTrue);
        expect(kind.permissionName, isNotEmpty);
        expect(kind.permissionPurpose, startsWith('Para '));
        expect(kind.permissionAction, isNotEmpty);
      }
      expect(HealthIssue.noContacts.isPermission, isFalse);
      expect(HealthIssue.offline.isPermission, isFalse);
    });
  });
}
