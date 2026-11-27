import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:guardiao/core/theme/app_colors.dart';
import 'package:guardiao/core/theme/vigi_tokens.dart';
import 'package:guardiao/core/widgets/contact_avatar.dart';
import 'package:guardiao/features/contacts/domain/entities/emergency_contact_entity.dart';
import 'package:guardiao/features/contacts/presentation/bloc/contacts_event.dart';
import 'package:guardiao/features/contacts/presentation/bloc/contacts_state.dart';
import 'package:guardiao/features/contacts/presentation/pages/contacts_page.dart';
import 'package:guardiao/features/contacts/presentation/widgets/contact_widgets.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(const LoadContactsRequested());
  });

  group('validateContactPhone', () {
    test('erro explica como corrigir', () {
      expect(
        validateContactPhone(''),
        'Digite o telefone com DDD. Exemplo: (11) 98765-4321.',
      );
      expect(
        validateContactPhone('98765-4321'),
        'Falta o DDD. Exemplo: (11) 98765-4321.',
      );
    });

    test('aceita telefone do Brasil com DDD e internacional', () {
      expect(validateContactPhone('(11) 98765-4321'), isNull);
      expect(validateContactPhone('+351 920 354 190'), isNull);
    });
  });

  group('ContactsPage', () {
    testWidgets('card com iniciais, nome, relação, telefone e status', (
      tester,
    ) async {
      await pumpApp(tester, const ContactsPage());

      expect(find.text('Maria Silva'), findsOneWidget);
      expect(find.text('Filha · (11) 98765-4321'), findsOneWidget);
      expect(find.text('Recebe alertas'), findsNWidgets(2));
      expect(find.text('MS'), findsOneWidget);
      expect(
        tester.getSize(find.byType(ContactAvatar).first),
        const Size(48, 48),
      );
    });

    testWidgets('telefone incompleto avisa em Cinza texto, não em vermelho', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const ContactsPage(),
        blocs: AppBlocs(
          contacts: const ContactsLoaded([
            EmergencyContactEntity(
              id: 'c9',
              userId: 'u1',
              name: 'Ana',
              phone: '98765',
            ),
          ]),
        ),
      );
      final warning = tester.widget<Text>(find.text('Telefone incompleto'));
      expect(warning.style!.color, VigiColors.cinzaTexto);
    });

    testWidgets('remover pede confirmação e não fica ao lado da ação '
        'principal', (tester) async {
      final blocs = await pumpApp(tester, const ContactsPage());

      // Na lista não há lixeira nem ícone vermelho.
      expect(find.byIcon(Icons.delete_outline), findsNothing);

      await tester.tap(find.text('Maria Silva'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover Maria'));
      await tester.pumpAndSettle();
      verifyNever(() => blocs.contacts.add(any()));

      expect(find.text('Remover Maria?'), findsOneWidget);
      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();
      verifyNever(() => blocs.contacts.add(any()));

      await tester.tap(find.text('Remover Maria'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover Maria').last);
      await tester.pumpAndSettle();
      verify(
        () => blocs.contacts.add(const DeleteContactRequested('c1')),
      ).called(1);
    });

    testWidgets('sem ninguém: pergunta humana no lugar de "Nenhum contato '
        'cadastrado"', (tester) async {
      await pumpApp(
        tester,
        const ContactsPage(),
        blocs: AppBlocs(contacts: const ContactsLoaded([])),
      );
      expect(
        find.text('Quem deve ser avisado se você não responder?'),
        findsOneWidget,
      );
      expect(
        find.text(
          'O Vigi só começa a vigiar depois que você escolher pelo menos '
          'uma pessoa.',
        ),
        findsOneWidget,
      );
      expect(find.text('Nenhum contato cadastrado'), findsNothing);
    });

    testWidgets('formulário: rótulo sempre visível, campo de 64 dp, erro '
        'que explica', (tester) async {
      final blocs = await pumpApp(tester, const ContactsPage());

      await tapVisible(tester, find.text('Adicionar pessoa'));
      await tester.pumpAndSettle();

      for (final label in [
        'Nome',
        'Telefone com DDD',
        'Quem é para você (opcional)',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      for (final field in tester.widgetList<TextFormField>(
        find.byType(TextFormField),
      )) {
        expect(
          tester.getSize(find.byWidget(field)).height,
          greaterThanOrEqualTo(VigiSizes.button),
        );
      }

      await tester.enterText(find.byType(TextFormField).at(0), 'Rui');
      await tester.enterText(find.byType(TextFormField).at(1), '98765-4321');
      await tapVisible(tester, find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(
        find.text('Falta o DDD. Exemplo: (11) 98765-4321.'),
        findsOneWidget,
      );
      verifyNever(() => blocs.contacts.add(any()));

      await tester.enterText(
        find.byType(TextFormField).at(1),
        '(11) 98765-4321',
      );
      await tapVisible(tester, find.text('Salvar'));
      await tester.pumpAndSettle();
      verify(
        () => blocs.contacts.add(
          const AddContactRequested(name: 'Rui', phone: '(11) 98765-4321'),
        ),
      ).called(1);
    });

    testWidgets('o teclado abre no tipo certo para o telefone', (tester) async {
      await pumpApp(tester, const ContactsPage());
      await tapVisible(tester, find.text('Adicionar pessoa'));
      await tester.pumpAndSettle();
      final phone = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(phone.keyboardType, TextInputType.phone);
    });

    for (final scale in [1.0, 2.0]) {
      testGoldens('golden: pessoas x$scale', (tester) async {
        await pumpApp(tester, const ContactsPage(), textScale: scale);
        expect(tester.takeException(), isNull);
        await expectGolden(tester, 'pessoas_${variant(textScale: scale)}');
      });
    }
  });
}
