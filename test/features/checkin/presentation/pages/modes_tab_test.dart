import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:guardiao/core/theme/app_colors.dart';
import 'package:guardiao/core/theme/vigi_tokens.dart';
import 'package:guardiao/features/checkin/presentation/bloc/checkin_event.dart';
import 'package:guardiao/features/checkin/presentation/bloc/checkin_state.dart';
import 'package:guardiao/features/checkin/presentation/pages/modes_tab.dart';
import 'package:guardiao/features/checkin/presentation/widgets/mode_sheets.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(const StopMonitoringRequested());
  });

  final watching = CheckinMonitoring(
    remainingSeconds: 38 * 60,
    totalSeconds: 3600,
    nextDeadline: DateTime(2026, 9, 30, 15),
    activeMode: tRoutine,
    availableModes: tModes,
  );

  Widget tab() => const Scaffold(body: SafeArea(child: ModesTab()));

  group('stepInterval', () {
    test('passo cresce com o valor', () {
      expect(stepInterval(1, up: true), 2);
      expect(stepInterval(9, up: true), 10);
      expect(stepInterval(10, up: true), 15);
      expect(stepInterval(55, up: true), 60);
      expect(stepInterval(60, up: true), 75);
      expect(stepInterval(180, up: true), 210);
    });

    test('volta pelos mesmos degraus', () {
      expect(stepInterval(2, up: false), 1);
      expect(stepInterval(10, up: false), 9);
      expect(stepInterval(15, up: false), 10);
      expect(stepInterval(60, up: false), 55);
      expect(stepInterval(75, up: false), 60);
      expect(stepInterval(210, up: false), 180);
    });

    test('respeita os limites de 1 minuto e 12 horas', () {
      expect(stepInterval(1, up: false), 1);
      expect(stepInterval(720, up: true), 720);
    });
  });

  group('ModesTab', () {
    testWidgets('chips com ícone, nome e intervalo; o ativo em Petróleo', (
      tester,
    ) async {
      await pumpApp(tester, tab(), blocs: AppBlocs(checkin: watching));

      expect(find.text('Rotina'), findsOneWidget);
      expect(find.text('1 h · ativo'), findsOneWidget);
      expect(find.text('Banho'), findsOneWidget);
      expect(find.text('20 min'), findsOneWidget);
      expect(find.text('Sono'), findsOneWidget);
      expect(find.text('8 h'), findsOneWidget);
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.shower_rounded), findsOneWidget);
      expect(find.byIcon(Icons.bedtime_rounded), findsOneWidget);

      final active = tester.widget<Material>(
        find
            .ancestor(of: find.text('Rotina'), matching: find.byType(Material))
            .first,
      );
      expect(active.color, VigiColors.petroleo800);
      final other = tester.widget<Material>(
        find
            .ancestor(of: find.text('Banho'), matching: find.byType(Material))
            .first,
      );
      expect(other.color, VigiColors.linho50);
    });

    testWidgets('chips têm pelo menos 64 dp e "Criar modo" é o último', (
      tester,
    ) async {
      await pumpApp(tester, tab(), blocs: AppBlocs(checkin: watching));
      for (final chip in tester.widgetList<ModeChip>(find.byType(ModeChip))) {
        expect(
          tester.getSize(find.byWidget(chip)).height,
          greaterThanOrEqualTo(VigiSizes.button),
        );
      }
      expect(
        tester.getTopLeft(find.text('Criar modo')).dy,
        greaterThan(tester.getTopLeft(find.text('Sono')).dy),
      );
    });

    testWidgets('não há controle deslizante: nenhuma ação depende de '
        'arrastar', (tester) async {
      await pumpApp(tester, tab(), blocs: AppBlocs(checkin: watching));
      await tester.tap(find.text('Banho'));
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsNothing);
      expect(find.byType(IntervalStepper), findsOneWidget);
    });

    testWidgets('trocar de modo mostra o novo horário antes de confirmar', (
      tester,
    ) async {
      final blocs = await pumpApp(
        tester,
        tab(),
        blocs: AppBlocs(checkin: watching),
      );

      await tester.tap(find.text('Banho'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('O próximo check-in passa a ser às'),
        findsOneWidget,
      );
      verifyNever(() => blocs.checkin.add(any()));

      await tester.tap(find.text('Trocar para Banho'));
      await tester.pumpAndSettle();
      verify(
        () => blocs.checkin.add(
          const StartMonitoringRequested(
            modeId: 'mode-shower',
            intervalOverrideMinutes: 20,
          ),
        ),
      ).called(1);
    });

    testWidgets('"mais" e "menos" ajustam o intervalo com toques', (
      tester,
    ) async {
      final blocs = await pumpApp(
        tester,
        tab(),
        blocs: AppBlocs(checkin: watching),
      );
      await tester.tap(find.text('Banho'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_rounded).last);
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(IntervalStepper),
          matching: find.text('25 min'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(IntervalStepper),
          matching: find.text('15 min'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Trocar para Banho'));
      await tester.pumpAndSettle();
      verify(
        () => blocs.checkin.add(
          const StartMonitoringRequested(
            modeId: 'mode-shower',
            intervalOverrideMinutes: 15,
          ),
        ),
      ).called(1);
    });

    testWidgets('pausado: tocar em um modo oferece "Começar a vigiar"', (
      tester,
    ) async {
      final blocs = await pumpApp(tester, tab());
      expect(find.text('Pausar a vigília'), findsNothing);

      await tester.tap(find.text('Sono'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Começar a vigiar'));
      await tester.pumpAndSettle();
      verify(
        () => blocs.checkin.add(
          const StartMonitoringRequested(
            modeId: 'mode-sleep',
            intervalOverrideMinutes: 480,
          ),
        ),
      ).called(1);
    });

    testWidgets('pausar a vigília pede confirmação', (tester) async {
      final blocs = await pumpApp(
        tester,
        tab(),
        blocs: AppBlocs(checkin: watching),
      );
      await tapVisible(tester, find.text('Pausar a vigília'));
      await tester.pumpAndSettle();
      verifyNever(() => blocs.checkin.add(any()));
      expect(find.text('Pausar a vigília?'), findsOneWidget);

      await tester.tap(find.text('Continuar vigiando'));
      await tester.pumpAndSettle();
      verifyNever(() => blocs.checkin.add(any()));

      await tapVisible(tester, find.text('Pausar a vigília'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pausar a vigília').last);
      await tester.pumpAndSettle();
      verify(
        () => blocs.checkin.add(const StopMonitoringRequested()),
      ).called(1);
    });

    testWidgets('criar modo: nome com rótulo visível, 12 ícones e erro que '
        'explica', (tester) async {
      final blocs = await pumpApp(
        tester,
        tab(),
        blocs: AppBlocs(checkin: watching),
      );
      await tapVisible(tester, find.text('Criar modo'));
      await tester.pumpAndSettle();

      expect(find.text('Nome do modo'), findsOneWidget);
      expect(find.text('Ícone'), findsOneWidget);
      // Textos antigos em Title Case não existem mais.
      expect(find.text('Novo Modo Customizado'), findsNothing);
      expect(find.text('Criar Modo Customizado'), findsNothing);

      await tapVisible(tester, find.text('Criar modo').last);
      await tester.pumpAndSettle();
      expect(
        find.text('Dê um nome ao modo. Exemplo: Caminhada.'),
        findsOneWidget,
      );
      verifyNever(() => blocs.checkin.add(any()));

      await tester.enterText(find.byType(TextFormField), 'Caminhada');
      await tapVisible(tester, find.text('Criar modo').last);
      await tester.pumpAndSettle();
      verify(
        () => blocs.checkin.add(
          const CreateCustomModeRequested(
            name: 'Caminhada',
            defaultIntervalMinutes: 45,
            iconKey: 'walk',
          ),
        ),
      ).called(1);
    });

    for (final scale in [1.0, 2.0]) {
      testGoldens('golden: modos x$scale', (tester) async {
        await pumpApp(
          tester,
          tab(),
          blocs: AppBlocs(checkin: watching),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        await expectGolden(tester, 'modos_${variant(textScale: scale)}');
      });
    }
  });
}
