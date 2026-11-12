import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:guardiao/core/services/emergency_dispatcher.dart';
import 'package:guardiao/core/theme/app_colors.dart';
import 'package:guardiao/features/contacts/presentation/bloc/contacts_state.dart';
import 'package:guardiao/features/panic/domain/entities/panic_alert_entity.dart';
import 'package:guardiao/features/panic/presentation/bloc/panic_event.dart';
import 'package:guardiao/features/panic/presentation/bloc/panic_state.dart';
import 'package:guardiao/features/panic/presentation/pages/panic_page.dart';
import 'package:guardiao/features/panic/presentation/widgets/panic_button.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(const PanicResolved());
  });

  final active = PanicActive(
    PanicAlertEntity(
      id: 'e1',
      userId: 'u1',
      eventType: 'panic',
      latitude: -23.5505,
      longitude: -46.6333,
      createdAt: DateTime(2026, 9, 30, 14, 7),
    ),
    contactsFound: 2,
    smsSent: 2,
    sentAt: DateTime(2026, 9, 30, 14, 7),
    address: 'Rua Augusta, 1200, Consolação',
    deliveries: const [
      ContactDelivery(name: 'Maria Silva', phone: '+5511', sent: true),
      ContactDelivery(name: 'João', phone: '+5521', sent: true),
    ],
  );

  group('Pedir ajuda (antes do gesto)', () {
    testWidgets('instrução, botão e a lista de quem será avisado', (
      tester,
    ) async {
      await pumpApp(tester, const PanicPage());

      expect(find.text('Pedir ajuda'), findsOneWidget);
      expect(find.text('Segure o botão por 3 segundos.'), findsOneWidget);
      expect(find.byType(PanicButton), findsOneWidget);
      // A pessoa sabe o que está prestes a acontecer.
      expect(find.text('Vamos avisar'), findsOneWidget);
      expect(find.text('Maria, filha'), findsOneWidget);
      expect(find.text('João, vizinho'), findsOneWidget);
      expect(find.text('Com a sua localização.'), findsOneWidget);

      // Textos antigos, em caixa alta, não existem mais.
      expect(find.text('PÂNICO'), findsNothing);
      expect(find.text('Botão de Emergência'), findsNothing);
    });

    testWidgets('sem contatos, avisa que ninguém será avisado', (tester) async {
      await pumpApp(
        tester,
        const PanicPage(),
        blocs: AppBlocs(contacts: const ContactsLoaded([])),
      );
      expect(find.textContaining('Ninguém será avisado'), findsOneWidget);
    });

    testWidgets('soltar antes mostra a explicação', (tester) async {
      await pumpApp(tester, const PanicPage(), reduceMotion: false);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PanicButton)),
      );
      // Um quadro para o gesto começar a contar.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        find.text('Você soltou antes. Segure por 3 segundos para pedir ajuda.'),
        findsOneWidget,
      );
    });
  });

  group('Alerta ativo (depois do gesto)', () {
    testWidgets('diz quem foi avisado, a que horas, e onde a pessoa está', (
      tester,
    ) async {
      await pumpApp(tester, const PanicPage(), blocs: AppBlocs(panic: active));

      expect(find.text('Pedimos ajuda por você'), findsOneWidget);
      expect(
        find.text('Avisamos 2 pessoas às 14:07 com a sua localização.'),
        findsOneWidget,
      );
      expect(find.text('SMS enviado'), findsNWidgets(2));
      expect(
        find.text('Perto de Rua Augusta, 1200, Consolação'),
        findsOneWidget,
      );

      // Nada de coordenadas nem de caixa alta.
      expect(find.textContaining('Lat:'), findsNothing);
      expect(find.textContaining('-23.5505'), findsNothing);
      expect(find.text('ALERTA DE PÂNICO ATIVO'), findsNothing);
    });

    testWidgets('fundo Sinal 600 com texto branco', (tester) async {
      await pumpApp(tester, const PanicPage(), blocs: AppBlocs(panic: active));
      final box = tester.widget<ColoredBox>(
        find
            .ancestor(
              of: find.text('Pedimos ajuda por você'),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(box.color, VigiColors.sinal600);
      final title = tester.widget<Text>(find.text('Pedimos ajuda por você'));
      expect(title.style!.color, VigiColors.branco);
    });

    testWidgets('cancelar pede confirmação', (tester) async {
      final blocs = await pumpApp(
        tester,
        const PanicPage(),
        blocs: AppBlocs(panic: active),
      );
      await tester.tap(find.text('Estou seguro, cancelar o pedido'));
      await tester.pumpAndSettle();
      verifyNever(() => blocs.panic.add(any()));

      await tester.tap(find.text('Estou seguro, cancelar'));
      await tester.pumpAndSettle();
      verify(() => blocs.panic.add(const PanicResolved())).called(1);
    });

    testWidgets('sem endereço, ainda confirma que a localização foi enviada', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const PanicPage(),
        blocs: AppBlocs(
          panic: PanicActive(
            active.alert,
            contactsFound: 2,
            smsSent: 2,
            sentAt: DateTime(2026, 9, 30, 14, 7),
          ),
        ),
      );
      expect(find.text('Sua localização foi enviada.'), findsOneWidget);
    });

    testWidgets('SMS não saiu: diz a verdade e o que fazer', (tester) async {
      await pumpApp(
        tester,
        const PanicPage(),
        blocs: AppBlocs(
          panic: PanicActive(active.alert, contactsFound: 2, smsSent: 0),
        ),
      );
      expect(
        find.textContaining('Não conseguimos enviar o SMS'),
        findsOneWidget,
      );
    });
  });

  for (final scale in [1.0, 2.0]) {
    testGoldens('golden: pedir ajuda x$scale', (tester) async {
      await pumpApp(tester, const PanicPage(), textScale: scale);
      expect(tester.takeException(), isNull);
      await expectGolden(tester, 'pedir_ajuda_${variant(textScale: scale)}');
    });
  }
}
