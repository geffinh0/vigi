import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/core/theme/app_theme.dart';
import 'package:guardiao/features/checkin/domain/entities/monitoring_mode_entity.dart';
import 'package:guardiao/features/checkin/presentation/bloc/checkin_bloc.dart';
import 'package:guardiao/features/checkin/presentation/bloc/checkin_event.dart';
import 'package:guardiao/features/checkin/presentation/bloc/checkin_state.dart';
import 'package:guardiao/features/checkin/presentation/pages/monitoring_settings_page.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckinBloc extends MockBloc<CheckinEvent, CheckinState>
    implements CheckinBloc {}

void main() {
  late MockCheckinBloc mockCheckinBloc;

  const tModeRoutine = MonitoringModeEntity(
    id: 'mode-routine',
    name: 'Rotina padrão',
    iconKey: 'routine',
    defaultIntervalMinutes: 60,
    isSystemDefault: true,
  );

  const tModeShower = MonitoringModeEntity(
    id: 'mode-shower',
    name: 'Banho',
    iconKey: 'shower',
    defaultIntervalMinutes: 20,
    isSystemDefault: true,
  );

  setUp(() {
    mockCheckinBloc = MockCheckinBloc();
  });

  testWidgets(
    'MonitoringSettingsPage renderiza modos, slider e botão salvar',
    (tester) async {
      when(() => mockCheckinBloc.state).thenReturn(
        const CheckinIdle(
          intervalMinutes: 60,
          availableModes: [tModeRoutine, tModeShower],
          selectedMode: tModeRoutine,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: BlocProvider<CheckinBloc>.value(
            value: mockCheckinBloc,
            child: const MonitoringSettingsPage(),
          ),
        ),
      );

      expect(find.text('Configurações de Rotina'), findsOneWidget);
      expect(find.text('Rotina padrão'), findsOneWidget);
      expect(find.text('Banho'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Salvar Configuração'), findsOneWidget);
    },
  );
}
