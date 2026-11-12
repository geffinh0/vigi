import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:guardiao/app/app.dart';
import 'package:guardiao/core/services/system_health_service.dart';
import 'package:guardiao/core/theme/vigi_tokens.dart';
import 'package:guardiao/core/widgets/app_primary_button.dart';
import 'package:guardiao/core/widgets/health_banner.dart';
import 'package:guardiao/core/widgets/status_ring.dart';
import 'package:guardiao/core/widgets/vigi_mascot.dart';
import 'package:guardiao/features/checkin/presentation/bloc/checkin_event.dart';
import 'package:guardiao/features/checkin/presentation/bloc/checkin_state.dart';
import 'package:guardiao/features/contacts/presentation/bloc/contacts_state.dart';
import 'package:guardiao/features/panic/presentation/widgets/panic_button.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/pump_app.dart';

void main() {
  // 14:22, como nas telas do guia.
  DateTime now() => DateTime(2026, 9, 30, 14, 22);
  final deadline = DateTime(2026, 9, 30, 15);

  Widget home() => VigiHomePage(now: now);

  final watching = CheckinMonitoring(
    remainingSeconds: 38 * 60,
    totalSeconds: 3600,
    nextDeadline: deadline,
    activeMode: tRoutine,
    availableModes: tModes,
  );

  final relieved = CheckinMonitoring(
    remainingSeconds: 3598,
    totalSeconds: 3600,
    nextDeadline: DateTime(2026, 9, 30, 16),
    activeMode: tRoutine,
    availableModes: tModes,
    relieved: true,
  );

  final sleeping = CheckinMonitoring(
    remainingSeconds: 6 * 3600,
    totalSeconds: 8 * 3600,
    nextDeadline: DateTime(2026, 10, 1, 7),
    activeMode: tSleep,
    availableModes: tModes,
  );

  setUpAll(() {
    registerFallbackValue(const ConfirmCheckinRequested());
  });

  VigiState mascotState(WidgetTester tester) =>
      tester.widget<VigiMascot>(find.byType(VigiMascot).first).state;

  group('Descansando (monitoramento pausado)', () {
    testWidgets('o Vigi não finge estar protegendo quando não está', (
      tester,
    ) async {
      await pumpApp(tester, home());

      expect(find.text('O Vigi está descansando'), findsOneWidget);
      expect(find.textContaining('ninguém será avisado'), findsOneWidget);
      expect(mascotState(tester), VigiState.descansando);
      // Sem anel de vigília enquanto não há vigília.
      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(StatusRing),
        ),
        findsNothing,
      );
      expect(find.textContaining('protegido'), findsNothing);
      expect(find.text('Vigília pausada'), findsOneWidget);
    });

    testWidgets('um único botão grande: "Começar a vigiar"', (tester) async {
      final blocs = await pumpApp(tester, home());

      final button = find.widgetWithText(AppPrimaryButton, 'Começar a vigiar');
      expect(
        tester.getSize(button).height,
        greaterThanOrEqualTo(VigiSizes.button),
      );
      await tapVisible(tester, button);
      verify(
        () => blocs.checkin.add(
          const StartMonitoringRequested(
            modeId: 'mode-routine',
            intervalOverrideMinutes: 60,
          ),
        ),
      ).called(1);
    });
  });

  group('Vigiando', () {
    testWidgets('hierarquia: saudação, modo, anel com a coruja, botão, '
        'pessoas', (tester) async {
      await pumpApp(tester, home(), blocs: AppBlocs(checkin: watching));

      expect(find.text('Boa tarde, Lúcia'), findsOneWidget);
      expect(find.text('Rotina, a cada 1 h'), findsOneWidget);
      expect(mascotState(tester), VigiState.vigiando);
      // Tempo relativo em destaque e horário absoluto logo abaixo.
      expect(find.text('38 min'), findsOneWidget);
      expect(find.text('até 15:00'), findsOneWidget);
      expect(find.text('Estou bem agora'), findsOneWidget);
      expect(
        find.text('Maria e João estão de vigília com você'),
        findsOneWidget,
      );

      // De cima para baixo.
      double y(Finder f) => tester.getTopLeft(f).dy;
      expect(
        y(find.text('Boa tarde, Lúcia')),
        lessThan(y(find.text('38 min'))),
      );
      expect(y(find.text('38 min')), lessThan(y(find.text('Estou bem agora'))));
      expect(
        y(find.text('Estou bem agora')),
        lessThan(y(find.text('Maria e João estão de vigília com você'))),
      );
    });

    testWidgets('o anel tem 240 dp, traço de 14 dp e mostra o tempo que '
        'resta', (tester) async {
      await pumpApp(tester, home(), blocs: AppBlocs(checkin: watching));
      final ring = tester.widget<StatusRing>(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(StatusRing),
        ),
      );
      expect(ring.size, 240);
      expect(ring.strokeWidth, 14);
      expect(ring.progress, closeTo(38 / 60, 0.001));
      expect(ring.state, VigiState.vigiando);
    });

    testWidgets('o anel anuncia o tempo por extenso', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, home(), blocs: AppBlocs(checkin: watching));
      expect(
        find.bySemanticsLabel(
          'Próximo check-in às 15 horas, daqui a 38 minutos',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('"Estou bem agora" confirma com um toque', (tester) async {
      final blocs = await pumpApp(
        tester,
        home(),
        blocs: AppBlocs(checkin: watching),
      );
      await tapVisible(tester, find.text('Estou bem agora'));
      verify(
        () => blocs.checkin.add(const ConfirmCheckinRequested()),
      ).called(1);
    });

    testWidgets('Aliviado: a coruja sorri, agradece e o botão vira '
        '"Confirmado"', (tester) async {
      await pumpApp(tester, home(), blocs: AppBlocs(checkin: relieved));
      expect(mascotState(tester), VigiState.aliviado);
      expect(
        find.text('Obrigado. Próximo check-in às 16:00.'),
        findsOneWidget,
      );
      expect(find.text('Confirmado'), findsOneWidget);
      expect(find.text('Estou bem agora'), findsNothing);
    });

    testWidgets('Noturno: no modo Sono mostra o horário de acordar', (
      tester,
    ) async {
      await pumpApp(
        tester,
        home(),
        blocs: AppBlocs(checkin: sleeping),
        night: true,
      );
      expect(mascotState(tester), VigiState.noturno);
      expect(find.text('Sono, até 7:00'), findsOneWidget);
      expect(find.text('7:00'), findsOneWidget);
      expect(find.text('próximo check-in'), findsOneWidget);
      expect(find.text('Vou vigiar enquanto você dorme.'), findsOneWidget);
    });
  });

  group('navegação', () {
    testWidgets('barra inferior com três itens, com ícone e texto', (
      tester,
    ) async {
      await pumpApp(tester, home(), blocs: AppBlocs(checkin: watching));

      expect(find.byType(NavigationDestination), findsNWidgets(3));
      for (final label in ['Início', 'Modos', 'Pessoas']) {
        expect(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(label),
          ),
          findsOneWidget,
        );
      }
      // Sem menu hambúrguer e sem ícones soltos de configuração.
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(Drawer), findsNothing);
      expect(find.byIcon(Icons.menu), findsNothing);
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
      expect(find.byIcon(Icons.shield_rounded), findsNothing);
    });

    testWidgets('abre Modos e Pessoas pela barra', (tester) async {
      await pumpApp(tester, home(), blocs: AppBlocs(checkin: watching));

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Modos'),
        ),
      );
      await tester.pump();
      expect(find.text('Banho').hitTestable(), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Pessoas'),
        ),
      );
      await tester.pump();
      expect(find.text('Pessoas de vigília').hitTestable(), findsOneWidget);
    });

    testWidgets('"Pedir ajuda" fica no rodapé, sempre visível, nas três '
        'abas', (tester) async {
      await pumpApp(tester, home(), blocs: AppBlocs(checkin: watching));

      for (final tab in ['Início', 'Modos', 'Pessoas']) {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(tab),
          ),
        );
        await tester.pump();
        final panic = find.byType(PanicButton);
        expect(panic.hitTestable(), findsOneWidget, reason: tab);
        expect(find.text('Pedir ajuda'), findsOneWidget, reason: tab);
        expect(find.text('segure 3 s'), findsOneWidget, reason: tab);
        expect(
          tester.getSize(panic).height,
          greaterThanOrEqualTo(VigiSizes.button),
        );
        // Acima da barra de navegação, dentro da tela.
        expect(
          tester.getBottomLeft(panic).dy,
          lessThanOrEqualTo(tester.getTopLeft(find.byType(NavigationBar)).dy),
        );
      }
    });

    testWidgets('o chip do modo leva à aba Modos', (tester) async {
      await pumpApp(tester, home(), blocs: AppBlocs(checkin: watching));
      await tapVisible(tester, find.text('Rotina, a cada 1 h'));
      expect(find.text('Banho').hitTestable(), findsOneWidget);
    });
  });

  group('faixa de saúde do sistema (falhar alto)', () {
    testWidgets('não aparece quando está tudo certo', (tester) async {
      await pumpApp(tester, home(), blocs: AppBlocs(checkin: watching));
      expect(find.byType(HealthBanner), findsNothing);
    });

    testWidgets('sem contatos: avisa no topo e leva a Pessoas', (tester) async {
      await pumpApp(
        tester,
        home(),
        blocs: AppBlocs(contacts: const ContactsLoaded([])),
      );
      expect(find.text('Escolher'), findsOneWidget);
      expect(
        find.textContaining('Ninguém será avisado.', findRichText: true),
        findsOneWidget,
      );
      // No topo da tela, logo abaixo da saudação e do modo.
      expect(
        tester.getTopLeft(find.byType(HealthBanner)).dy,
        lessThan(kPhone.height / 2),
      );

      await tapVisible(tester, find.text('Escolher'));
      expect(find.text('Pessoas de vigília').hitTestable(), findsOneWidget);
    });

    testWidgets('notificações bloqueadas: botão "Permitir"', (tester) async {
      await pumpApp(
        tester,
        home(),
        blocs: AppBlocs(
          checkin: watching,
          health: const [HealthIssue.notificationsBlocked],
        ),
      );
      expect(
        find.textContaining(
          'As notificações estão bloqueadas.',
          findRichText: true,
        ),
        findsOneWidget,
      );
      final button = find.widgetWithText(FilledButton, 'Permitir');
      expect(
        tester.getSize(button).height,
        greaterThanOrEqualTo(VigiSizes.touch),
      );
    });

    testWidgets('sem internet: informa, sem botão', (tester) async {
      await pumpApp(
        tester,
        home(),
        blocs: AppBlocs(checkin: watching, health: const [HealthIssue.offline]),
      );
      expect(
        find.textContaining('Sem internet.', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(HealthBanner),
          matching: find.byType(FilledButton),
        ),
        findsNothing,
      );
    });
  });

  group('critérios de aceite do guia', () {
    final cases = <String, CheckinState>{
      'descansando': const CheckinIdle(
        availableModes: tModes,
        selectedMode: tRoutine,
      ),
      'vigiando': watching,
      'aliviado': relieved,
      'noturno': sleeping,
    };

    for (final entry in cases.entries) {
      for (final scale in [1.0, 1.5, 2.0]) {
        testWidgets('${entry.key} a ${scale}x: sem estouro de layout', (
          tester,
        ) async {
          await pumpApp(
            tester,
            home(),
            blocs: AppBlocs(
              checkin: entry.value,
              health: const [HealthIssue.notificationsBlocked],
            ),
            textScale: scale,
            night: entry.key == 'noturno',
          );
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('nenhum texto abaixo de 14 sp', (tester) async {
      for (final state in cases.values) {
        await pumpApp(
          tester,
          home(),
          blocs: AppBlocs(
            checkin: state,
            health: const [HealthIssue.notificationsBlocked],
          ),
        );
        for (final text in tester.widgetList<RichText>(find.byType(RichText))) {
          final size = text.text.style?.fontSize;
          if (size == null) continue;
          expect(
            size,
            greaterThanOrEqualTo(14),
            reason: '"${text.text.toPlainText()}"',
          );
        }
      }
    });

    testWidgets('nenhum texto em caixa alta', (tester) async {
      final shouting = RegExp(r'\b[A-ZÁÉÍÓÚÂÊÔÃÕÇ]{3,}\b');
      for (final state in cases.values) {
        await pumpApp(tester, home(), blocs: AppBlocs(checkin: state));
        for (final text in tester.widgetList<RichText>(find.byType(RichText))) {
          final plain = text.text.toPlainText();
          // Iniciais dos avatares ("MS") não são frases.
          if (plain.length <= 2) continue;
          expect(shouting.hasMatch(plain), isFalse, reason: plain);
        }
      }
    });

    testWidgets('alvos de toque com pelo menos 56 dp', (tester) async {
      await pumpApp(tester, home(), blocs: AppBlocs(checkin: watching));
      final targets = [
        find.text('Rotina, a cada 1 h'),
        find.text('Estou bem agora'),
        find.text('Maria e João estão de vigília com você'),
      ];
      for (final target in targets) {
        final tappable = find.ancestor(
          of: target,
          matching: find.byWidgetPredicate(
            (w) => w is InkWell || w is FilledButton,
          ),
        );
        expect(
          tester.getSize(tappable.first).height,
          greaterThanOrEqualTo(VigiSizes.touch),
          reason: '$target',
        );
      }
      for (final destination in tester.widgetList<NavigationDestination>(
        find.byType(NavigationDestination),
      )) {
        expect(
          tester.getSize(find.byWidget(destination)).height,
          greaterThanOrEqualTo(VigiSizes.touch),
        );
      }
    });

    for (final entry in cases.entries) {
      for (final scale in [1.0, 2.0]) {
        final night = entry.key == 'noturno';
        testGoldens('golden: ${entry.key} x$scale', (tester) async {
          await pumpApp(
            tester,
            home(),
            blocs: AppBlocs(checkin: entry.value),
            textScale: scale,
            night: night,
          );
          await expectGolden(
            tester,
            'inicio_${entry.key}_${variant(textScale: scale, night: night)}',
          );
        });
      }
    }

    testGoldens('golden: vigiando no tema noturno do sistema', (tester) async {
      await pumpApp(
        tester,
        home(),
        blocs: AppBlocs(checkin: watching),
        night: true,
      );
      await expectGolden(tester, 'inicio_vigiando_noturno_x1');
    });
  });
}
