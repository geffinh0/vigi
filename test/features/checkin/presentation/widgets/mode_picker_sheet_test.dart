import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/core/theme/app_theme.dart';
import 'package:guardiao/core/utils/clock.dart';
import 'package:guardiao/core/utils/ticker.dart';
import 'package:guardiao/features/checkin/domain/entities/monitoring_mode_entity.dart';
import 'package:guardiao/features/checkin/domain/usecases/confirm_checkin_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/create_custom_mode_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/get_available_modes_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/get_monitoring_status_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/start_monitoring_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/stop_monitoring_usecase.dart';
import 'package:guardiao/features/checkin/presentation/bloc/checkin_bloc.dart';
import 'package:guardiao/features/checkin/presentation/widgets/mode_picker_sheet.dart';
import 'package:mocktail/mocktail.dart';

class MockStartMonitoringUseCase extends Mock
    implements StartMonitoringUseCase {}

class MockConfirmCheckinUseCase extends Mock implements ConfirmCheckinUseCase {}

class MockStopMonitoringUseCase extends Mock implements StopMonitoringUseCase {}

class MockGetMonitoringStatusUseCase extends Mock
    implements GetMonitoringStatusUseCase {}

class MockGetAvailableModesUseCase extends Mock
    implements GetAvailableModesUseCase {}

class MockCreateCustomModeUseCase extends Mock
    implements CreateCustomModeUseCase {}

void main() {
  late CheckinBloc checkinBloc;
  late MockStartMonitoringUseCase mockStartMonitoringUseCase;
  late MockConfirmCheckinUseCase mockConfirmCheckinUseCase;
  late MockStopMonitoringUseCase mockStopMonitoringUseCase;
  late MockGetMonitoringStatusUseCase mockGetMonitoringStatusUseCase;
  late MockGetAvailableModesUseCase mockGetAvailableModesUseCase;
  late MockCreateCustomModeUseCase mockCreateCustomModeUseCase;

  const tModes = [
    MonitoringModeEntity(
      id: '1',
      name: 'Rotina padrão',
      iconKey: 'routine',
      defaultIntervalMinutes: 60,
      isSystemDefault: true,
    ),
    MonitoringModeEntity(
      id: '2',
      name: 'Banho',
      iconKey: 'shower',
      defaultIntervalMinutes: 20,
      isSystemDefault: true,
    ),
    MonitoringModeEntity(
      id: '3',
      name: 'Sono',
      iconKey: 'sleep',
      defaultIntervalMinutes: 480,
      isSystemDefault: true,
    ),
  ];

  setUp(() {
    mockStartMonitoringUseCase = MockStartMonitoringUseCase();
    mockConfirmCheckinUseCase = MockConfirmCheckinUseCase();
    mockStopMonitoringUseCase = MockStopMonitoringUseCase();
    mockGetMonitoringStatusUseCase = MockGetMonitoringStatusUseCase();
    mockGetAvailableModesUseCase = MockGetAvailableModesUseCase();
    mockCreateCustomModeUseCase = MockCreateCustomModeUseCase();

    checkinBloc = CheckinBloc(
      startMonitoringUseCase: mockStartMonitoringUseCase,
      confirmCheckinUseCase: mockConfirmCheckinUseCase,
      stopMonitoringUseCase: mockStopMonitoringUseCase,
      getMonitoringStatusUseCase: mockGetMonitoringStatusUseCase,
      getAvailableModesUseCase: mockGetAvailableModesUseCase,
      createCustomModeUseCase: mockCreateCustomModeUseCase,
      ticker: const Ticker(),
      clock: const SystemClock(),
    );
  });

  tearDown(() {
    checkinBloc.close();
  });

  testWidgets(
    'ModePickerSheet renderiza os 3 modos padrão e pré-preenche intervalo ao selecionar Banho',
    (tester) async {
      MonitoringModeEntity? selectedModeParam;
      int? intervalParam;

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BlocProvider<CheckinBloc>.value(
                value: checkinBloc,
                child: ModePickerSheet(
                  modes: tModes,
                  initialMode: tModes.first,
                  onStartMonitoring: (mode, interval) {
                    selectedModeParam = mode;
                    intervalParam = interval;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Modos de Monitoramento'), findsOneWidget);
      expect(find.text('Rotina padrão'), findsOneWidget);
      expect(find.text('Banho'), findsOneWidget);
      expect(find.text('Sono'), findsOneWidget);

      // Toca no modo "Banho"
      await tester.tap(find.text('Banho'));
      await tester.pumpAndSettle();

      // Confirma que o botão principal e o texto mostram 20 min
      expect(find.text('Iniciar Banho (20 min)'), findsOneWidget);

      // Toca no botão de iniciar
      await tester.tap(find.text('Iniciar Banho (20 min)'));
      await tester.pump();

      expect(selectedModeParam?.name, equals('Banho'));
      expect(intervalParam, equals(20));
    },
  );
}
