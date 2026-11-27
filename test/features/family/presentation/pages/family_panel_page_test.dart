import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/core/theme/app_colors.dart';
import 'package:guardiao/features/family/domain/entities/family_link_entity.dart';
import 'package:guardiao/features/family/presentation/bloc/family_event.dart';
import 'package:guardiao/features/family/presentation/bloc/family_state.dart';
import 'package:guardiao/features/family/presentation/pages/family_panel_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(const LoadFamilyLinksRequested());
  });

  const pending = FamilyLinkEntity(
    id: 'l1',
    monitoredUserId: 'u1',
    viewerUserId: 'v1',
    status: 'pending',
    viewerUserName: 'Carla',
  );
  const follower = FamilyLinkEntity(
    id: 'l2',
    monitoredUserId: 'u1',
    viewerUserId: 'v2',
    status: 'accepted',
    viewerUserName: 'Maria Silva',
  );

  AppBlocs blocsWith(List<FamilyLinkEntity> links) => AppBlocs(
    family: FamilyLoaded(links, myCode: 'K7P2QX', myUserId: 'u1'),
  );

  test('formatLinkCode separa o código em dois grupos', () {
    expect(formatLinkCode('K7P2QX'), 'K7P-2QX');
    expect(formatLinkCode('ABC'), 'ABC');
  });

  group('FamilyPanelPage', () {
    testWidgets('mostra o código de convite, sem termos técnicos', (
      tester,
    ) async {
      await pumpApp(tester, const FamilyPanelPage(), blocs: blocsWith([]));

      expect(find.text('Seu código de convite'), findsOneWidget);
      expect(find.text('K7P-2QX'), findsOneWidget);
      expect(find.textContaining('UUID'), findsNothing);
      expect(find.textContaining('PENDING'), findsNothing);
      expect(find.text('Enviar pelo WhatsApp'), findsOneWidget);
    });

    testWidgets('pedido pendente é a vez da pessoa: âmbar, com Permitir e '
        'Recusar', (tester) async {
      final blocs = await pumpApp(
        tester,
        const FamilyPanelPage(),
        blocs: blocsWith([pending]),
      );

      expect(find.text('Carla quer acompanhar você'), findsOneWidget);
      final card = tester.widget<Ink>(
        find
            .ancestor(
              of: find.text('Carla quer acompanhar você'),
              matching: find.byType(Ink),
            )
            .first,
      );
      expect((card.decoration! as BoxDecoration).color, VigiColors.ambar100);

      await tester.tap(find.text('Permitir'));
      verify(
        () => blocs.family.add(
          const RespondFamilyLinkRequested(linkId: 'l1', accept: true),
        ),
      ).called(1);

      await tester.tap(find.text('Recusar'));
      verify(
        () => blocs.family.add(
          const RespondFamilyLinkRequested(linkId: 'l1', accept: false),
        ),
      ).called(1);
    });

    testWidgets('desvincular alguém pede confirmação', (tester) async {
      final blocs = await pumpApp(
        tester,
        const FamilyPanelPage(),
        blocs: blocsWith([follower]),
      );
      clearInteractions(blocs.family);

      await tapVisible(tester, find.text('Maria Silva'));
      await tester.pumpAndSettle();
      expect(find.text('Remover Maria?'), findsOneWidget);
      verifyNever(() => blocs.family.add(any()));

      await tester.tap(find.text('Remover Maria'));
      await tester.pumpAndSettle();
      verify(
        () => blocs.family.add(const RemoveFamilyLinkRequested('l2')),
      ).called(1);
    });

    testWidgets('não usa verde nem vermelho', (tester) async {
      await pumpApp(
        tester,
        const FamilyPanelPage(),
        blocs: blocsWith([pending, follower]),
      );
      expect(find.byIcon(Icons.verified_user), findsNothing);
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        expect(text.style?.color, isNot(VigiColors.sinal500));
        expect(text.style?.color, isNot(Colors.green));
      }
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('a ${scale}x: sem estouro de layout', (tester) async {
        await pumpApp(
          tester,
          const FamilyPanelPage(),
          blocs: blocsWith([pending, follower]),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
