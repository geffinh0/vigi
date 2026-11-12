import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:guardiao/core/services/emergency_dispatcher.dart';
import 'package:guardiao/core/theme/app_colors.dart';
import 'package:guardiao/core/theme/vigi_tokens.dart';
import 'package:guardiao/core/widgets/app_primary_button.dart';
import 'package:guardiao/core/widgets/status_ring.dart';
import 'package:guardiao/core/widgets/vigi_mascot.dart';
import 'package:guardiao/features/checkin/presentation/bloc/checkin_event.dart';
import 'package:guardiao/features/checkin/presentation/bloc/checkin_state.dart';
import 'package:guardiao/features/checkin/presentation/pages/checkin_alert_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  final deadline = DateTime(2026, 9, 30, 15);
  final escalatesAt = DateTime(2026, 9, 30, 15, 15);
  // 15:02: no meio da chamada, longe do último minuto.
  DateTime now() => DateTime(2026, 9, 30, 15, 2);

  CheckinCalling calling({bool lastCall = false, bool canSnooze = true}) =>
      CheckinCalling(
        deadline: deadline,
        lastCallAt: DateTime(2026, 9, 30, 15, 10),
        escalatesAt: escalatesAt,
        lastCall: lastCall,
        canSnooze: canSnooze,
        activeMode: tRoutine,
      );

  final alerted = CheckinAlertActive(
    expiredAt: deadline,
    alertedAt: escalatesAt,
    contactsFound: 2,
    smsSent: 2,
    latitude: -23.55,
    longitude: -46.63,
    address: 'Rua Augusta, 1200, Consolação',
    deliveries: const [
      ContactDelivery(name: 'Maria Silva', phone: '+5511', sent: true),
      ContactDelivery(name: 'João', phone: '+5521', sent: true),
    ],
  );

  Widget page() => CheckinAlertPage(now: now);

  setUpAll(() {
    registerFallbackValue(const ConfirmCheckinRequested());
  });

  group('Sua vez', () {
    testWidgets('pergunta pelo nome e diz o que vem a seguir', (tester) async {
      await pumpApp(tester, page(), blocs: AppBlocs(checkin: calling()));

      expect(find.text('Tudo bem por aí, Lúcia?'), findsOneWidget);
      expect(
        find.text(
          'Se você não responder até 15:15, vamos avisar Maria e João.',
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<VigiMascot>(find.byType(VigiMascot)).state,
        VigiState.suaVez,
      );
      // Sem gritos e sem os textos antigos.
      expect(find.text('ALERTA DE CHECK-IN!'), findsNothing);
      expect(find.text('ESTOU BEM'), findsNothing);
      expect(find.text('DISPARAR PÂNICO'), findsNothing);
    });

    testWidgets('fundo Âmbar 100 e anel Âmbar', (tester) async {
      await pumpApp(tester, page(), blocs: AppBlocs(checkin: calling()));
      final background = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      expect(
        (background.decoration! as BoxDecoration).color,
        VigiColors.ambar100,
      );
      final ring = tester.widget<StatusRing>(find.byType(StatusRing));
      expect(ring.state, VigiState.suaVez);
      expect(ring.color, isNull);
    });

    testWidgets('"Estou bem" tem 96 dp, largura total e um toque basta', (
      tester,
    ) async {
      final blocs = await pumpApp(
        tester,
        page(),
        blocs: AppBlocs(checkin: calling()),
      );

      final button = find.widgetWithText(AppPrimaryButton, 'Estou bem');
      final size = tester.getSize(button);
      expect(size.height, greaterThanOrEqualTo(VigiSizes.callButton));
      expect(size.width, kPhone.width - 2 * VigiSpace.screen);
      // Na metade inferior da tela, onde o polegar alcança.
      expect(tester.getCenter(button).dy, greaterThan(kPhone.height / 2));

      await tester.tap(button);
      await tester.pump();
      // Sem diálogo de confirmação: dizer que está bem nunca pode ser difícil.
      verify(
        () => blocs.checkin.add(const ConfirmCheckinRequested()),
      ).called(1);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('"Preciso de mais 10 minutos" adia a chamada', (tester) async {
      final blocs = await pumpApp(
        tester,
        page(),
        blocs: AppBlocs(checkin: calling()),
      );
      await tester.tap(find.text('Preciso de mais 10 minutos'));
      verify(
        () => blocs.checkin.add(const SnoozeCheckinRequested()),
      ).called(1);
    });

    testWidgets('depois de usado, "mais 10 minutos" some', (tester) async {
      await pumpApp(
        tester,
        page(),
        blocs: AppBlocs(checkin: calling(canSnooze: false)),
      );
      expect(find.text('Preciso de mais 10 minutos'), findsNothing);
      expect(find.text('Estou bem'), findsOneWidget);
    });

    testWidgets('sem contatos carregados, fala em "seus contatos"', (
      tester,
    ) async {
      await pumpApp(
        tester,
        page(),
        blocs: AppBlocs(
          checkin: calling(),
          contacts: const ContactsInitialForTest(),
        ),
      );
      expect(
        find.text(
          'Se você não responder até 15:15, vamos avisar seus contatos.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('o botão de voltar não esconde a chamada', (tester) async {
      await pumpApp(tester, page(), blocs: AppBlocs(checkin: calling()));
      final scope =
          tester.widget(find.byWidgetPredicate((w) => w is PopScope))
              as PopScope;
      expect(scope.canPop, isFalse);
    });
  });

  group('Última chamada', () {
    testWidgets('muda o texto, o fundo e o mascote', (tester) async {
      await pumpApp(
        tester,
        page(),
        blocs: AppBlocs(checkin: calling(lastCall: true, canSnooze: false)),
      );

      expect(find.text('Última chamada, Lúcia'), findsOneWidget);
      expect(
        tester.widget<VigiMascot>(find.byType(VigiMascot)).state,
        VigiState.ultimaChamada,
      );
      final background = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      expect(
        (background.decoration! as BoxDecoration).color,
        VigiColors.ambar300,
      );
      expect(find.text('Estou bem'), findsOneWidget);
    });

    testWidgets('no último minuto o anel ganha a borda Sinal', (tester) async {
      await pumpApp(
        tester,
        // 15:14:30: faltam 30 segundos para avisar os contatos.
        CheckinAlertPage(now: () => DateTime(2026, 9, 30, 15, 14, 30)),
        blocs: AppBlocs(checkin: calling(lastCall: true, canSnooze: false)),
      );
      expect(
        tester.widget<StatusRing>(find.byType(StatusRing)).color,
        VigiColors.sinal500,
      );
    });
  });

  group('Alerta', () {
    testWidgets('diz o que foi feito, quem foi avisado e onde', (tester) async {
      await pumpApp(tester, page(), blocs: AppBlocs(checkin: alerted));

      expect(find.text('Pedimos ajuda por você'), findsOneWidget);
      expect(
        find.text('Avisamos 2 pessoas às 15:15 com a sua localização.'),
        findsOneWidget,
      );
      expect(find.text('Maria'), findsOneWidget);
      expect(find.text('João'), findsOneWidget);
      expect(find.text('SMS enviado'), findsNWidgets(2));
      // Endereço aproximado, não coordenadas.
      expect(
        find.text('Perto de Rua Augusta, 1200, Consolação'),
        findsOneWidget,
      );
      expect(find.textContaining('Lat:'), findsNothing);
      expect(find.textContaining('-23.55'), findsNothing);
    });

    testWidgets('fundo Sinal 600, também no tema noturno', (tester) async {
      for (final night in [false, true]) {
        await pumpApp(
          tester,
          page(),
          blocs: AppBlocs(checkin: alerted),
          night: night,
        );
        final box = tester.widget<ColoredBox>(
          find
              .ancestor(
                of: find.text('Pedimos ajuda por você'),
                matching: find.byType(ColoredBox),
              )
              .first,
        );
        expect(box.color, VigiColors.sinal600, reason: 'noturno: $night');
      }
    });

    testWidgets('cancelar pede confirmação antes de avisar os contatos', (
      tester,
    ) async {
      final blocs = await pumpApp(
        tester,
        page(),
        blocs: AppBlocs(checkin: alerted),
      );

      await tester.tap(find.text('Estou seguro, cancelar o pedido'));
      await tester.pumpAndSettle();
      verifyNever(() => blocs.checkin.add(any()));

      expect(find.text('Cancelar o pedido de ajuda?'), findsOneWidget);
      expect(
        find.text(
          'Vamos avisar Maria e João de que está tudo bem com você.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Estou seguro, cancelar'));
      await tester.pumpAndSettle();
      verify(
        () => blocs.checkin.add(const ConfirmCheckinRequested()),
      ).called(1);
    });

    testWidgets('"Voltar" na confirmação mantém o pedido ativo', (
      tester,
    ) async {
      final blocs = await pumpApp(
        tester,
        page(),
        blocs: AppBlocs(checkin: alerted),
      );
      await tester.tap(find.text('Estou seguro, cancelar o pedido'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();
      verifyNever(() => blocs.checkin.add(any()));
      expect(find.text('Pedimos ajuda por você'), findsOneWidget);
    });

    testWidgets('sem ninguém cadastrado, orienta a ligar para alguém', (
      tester,
    ) async {
      await pumpApp(
        tester,
        page(),
        blocs: AppBlocs(
          checkin: CheckinAlertActive(
            expiredAt: deadline,
            alertedAt: escalatesAt,
          ),
        ),
      );
      expect(find.textContaining('ligue para alguém'), findsOneWidget);
      expect(find.textContaining('192'), findsOneWidget);
    });
  });

  group('fonte do sistema e temas (critério de aceite do guia)', () {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('chamada a ${scale}x: sem estouro e com o botão à vista', (
        tester,
      ) async {
        await pumpApp(
          tester,
          page(),
          blocs: AppBlocs(checkin: calling()),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        final button = tester.getRect(
          find.widgetWithText(AppPrimaryButton, 'Estou bem'),
        );
        expect(button.bottom, lessThanOrEqualTo(kPhone.height));
        expect(button.top, greaterThanOrEqualTo(0));
      });

      testWidgets('alerta a ${scale}x: sem estouro e com o botão à vista', (
        tester,
      ) async {
        await pumpApp(
          tester,
          page(),
          blocs: AppBlocs(checkin: alerted),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        final button = tester.getRect(
          find.widgetWithText(
            AppPrimaryButton,
            'Estou seguro, cancelar o pedido',
          ),
        );
        expect(button.bottom, lessThanOrEqualTo(kPhone.height));
      });
    }

    for (final scale in [1.0, 2.0]) {
      testGoldens('golden: sua vez x$scale', (tester) async {
        await pumpApp(
          tester,
          page(),
          blocs: AppBlocs(checkin: calling()),
          textScale: scale,
        );
        await expectGolden(
          tester,
          'chamada_sua_vez_${variant(textScale: scale)}',
        );
      });

      testGoldens('golden: última chamada x$scale', (tester) async {
        await pumpApp(
          tester,
          page(),
          blocs: AppBlocs(checkin: calling(lastCall: true, canSnooze: false)),
          textScale: scale,
        );
        await expectGolden(
          tester,
          'chamada_ultima_${variant(textScale: scale)}',
        );
      });

      testGoldens('golden: alerta x$scale', (tester) async {
        await pumpApp(
          tester,
          page(),
          blocs: AppBlocs(checkin: alerted),
          textScale: scale,
        );
        await expectGolden(tester, 'alerta_${variant(textScale: scale)}');
      });
    }
  });
}
