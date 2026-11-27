import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/services/widget_background_handler.dart';
import 'package:guardiao/core/services/widget_sync_service.dart';
import 'package:guardiao/core/usecases/usecase.dart';
import 'package:guardiao/features/checkin/domain/entities/monitoring_mode_entity.dart';
import 'package:guardiao/features/checkin/domain/usecases/confirm_checkin_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/get_available_modes_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/start_monitoring_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockConfirmCheckinUseCase extends Mock implements ConfirmCheckinUseCase {}

class MockStartMonitoringUseCase extends Mock
    implements StartMonitoringUseCase {}

class MockGetAvailableModesUseCase extends Mock
    implements GetAvailableModesUseCase {}

class MockWidgetSyncService extends Mock implements WidgetSyncService {}

void main() {
  late MockConfirmCheckinUseCase mockConfirmCheckinUseCase;
  late MockStartMonitoringUseCase mockStartMonitoringUseCase;
  late MockGetAvailableModesUseCase mockGetAvailableModesUseCase;
  late MockWidgetSyncService mockWidgetSyncService;

  const tShowerMode = MonitoringModeEntity(
    id: 'mode-shower',
    name: 'Banho',
    iconKey: 'shower',
    defaultIntervalMinutes: 25,
    isSystemDefault: true,
  );

  const tSleepMode = MonitoringModeEntity(
    id: 'mode-sleep',
    name: 'Sono',
    iconKey: 'sleep',
    defaultIntervalMinutes: 480,
    isSystemDefault: true,
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const ConfirmCheckinParams());
    registerFallbackValue(
      const StartMonitoringParams(
        modeId: 'mode-shower',
        intervalOverrideMinutes: 25,
      ),
    );
  });

  setUp(() {
    mockConfirmCheckinUseCase = MockConfirmCheckinUseCase();
    mockStartMonitoringUseCase = MockStartMonitoringUseCase();
    mockGetAvailableModesUseCase = MockGetAvailableModesUseCase();
    mockWidgetSyncService = MockWidgetSyncService();

    when(
      () => mockConfirmCheckinUseCase(any()),
    ).thenAnswer((_) async => const Right(null));

    when(
      () => mockStartMonitoringUseCase(any()),
    ).thenAnswer((_) async => const Right(null));

    when(
      () => mockGetAvailableModesUseCase(any()),
    ).thenAnswer((_) async => const Right([tShowerMode, tSleepMode]));

    when(
      () => mockWidgetSyncService.updateWidgetData(
        vigiState: any(named: 'vigiState'),
        minutesRemaining: any(named: 'minutesRemaining'),
        modeName: any(named: 'modeName'),
        isMonitoring: any(named: 'isMonitoring'),
        timeDisplay: any(named: 'timeDisplay'),
        statusDisplay: any(named: 'statusDisplay'),
      ),
    ).thenAnswer((_) async {});
  });

  group('handleWidgetBackgroundUri', () {
    test(
      'ignora URI nulo ou com ação desconhecida',
      () async {
        final resNull = await handleWidgetBackgroundUri(
          null,
          confirmCheckinUseCase: mockConfirmCheckinUseCase,
          widgetSyncService: mockWidgetSyncService,
        );
        expect(resNull, isFalse);

        final resOther = await handleWidgetBackgroundUri(
          Uri.parse('guardiao://outra_acao'),
          confirmCheckinUseCase: mockConfirmCheckinUseCase,
          widgetSyncService: mockWidgetSyncService,
        );
        expect(resOther, isFalse);

        verifyNever(() => mockConfirmCheckinUseCase(any()));
        verifyNever(
          () => mockWidgetSyncService.updateWidgetData(
            vigiState: any(named: 'vigiState'),
            minutesRemaining: any(named: 'minutesRemaining'),
            modeName: any(named: 'modeName'),
            isMonitoring: any(named: 'isMonitoring'),
          ),
        );
      },
    );

    test(
      'executa ConfirmCheckinUseCase e atualiza widget quando URI é confirmar_checkin',
      () async {
        final uri = Uri.parse('guardiao://confirmar_checkin');

        final result = await handleWidgetBackgroundUri(
          uri,
          confirmCheckinUseCase: mockConfirmCheckinUseCase,
          widgetSyncService: mockWidgetSyncService,
        );

        expect(result, isTrue);
        verify(
          () =>
              mockConfirmCheckinUseCase(any(that: isA<ConfirmCheckinParams>())),
        ).called(1);
        verify(
          () => mockWidgetSyncService.updateWidgetData(
            vigiState: 'vigiando',
            minutesRemaining: 60,
            modeName: 'Rotina',
            isMonitoring: true,
            timeDisplay: any(named: 'timeDisplay'),
            statusDisplay: any(named: 'statusDisplay'),
          ),
        ).called(1);
      },
    );

    test(
      'executa StartMonitoringUseCase para Banho quando URI é iniciar_banho',
      () async {
        final uri = Uri.parse('guardiao://iniciar_banho');

        final result = await handleWidgetBackgroundUri(
          uri,
          confirmCheckinUseCase: mockConfirmCheckinUseCase,
          widgetSyncService: mockWidgetSyncService,
          startMonitoringUseCase: mockStartMonitoringUseCase,
          getAvailableModesUseCase: mockGetAvailableModesUseCase,
        );

        expect(result, isTrue);
        verify(
          () => mockStartMonitoringUseCase(
            any(
              that: isA<StartMonitoringParams>().having(
                (p) => p.modeId,
                'modeId',
                'mode-shower',
              ),
            ),
          ),
        ).called(1);
        verify(
          () => mockWidgetSyncService.updateWidgetData(
            vigiState: 'vigiando',
            minutesRemaining: 25,
            modeName: 'Banho',
            isMonitoring: true,
            timeDisplay: any(named: 'timeDisplay'),
            statusDisplay: any(named: 'statusDisplay'),
          ),
        ).called(1);
      },
    );

    test(
      'executa StartMonitoringUseCase para Sono quando URI é iniciar_sono',
      () async {
        final uri = Uri.parse('guardiao://iniciar_sono');

        final result = await handleWidgetBackgroundUri(
          uri,
          confirmCheckinUseCase: mockConfirmCheckinUseCase,
          widgetSyncService: mockWidgetSyncService,
          startMonitoringUseCase: mockStartMonitoringUseCase,
          getAvailableModesUseCase: mockGetAvailableModesUseCase,
        );

        expect(result, isTrue);
        verify(
          () => mockStartMonitoringUseCase(
            any(
              that: isA<StartMonitoringParams>().having(
                (p) => p.modeId,
                'modeId',
                'mode-sleep',
              ),
            ),
          ),
        ).called(1);
        verify(
          () => mockWidgetSyncService.updateWidgetData(
            vigiState: 'noturno',
            minutesRemaining: 480,
            modeName: 'Sono',
            isMonitoring: true,
            timeDisplay: any(named: 'timeDisplay'),
            statusDisplay: any(named: 'statusDisplay'),
          ),
        ).called(1);
      },
    );

    test(
      'pedir ajuda nunca sai por um toque no widget (nem em segundo plano)',
      () async {
        for (final action in ['disparar_panico', 'pedir_ajuda']) {
          final result = await handleWidgetBackgroundUri(
            Uri.parse('guardiao://$action'),
            confirmCheckinUseCase: mockConfirmCheckinUseCase,
            widgetSyncService: mockWidgetSyncService,
            startMonitoringUseCase: mockStartMonitoringUseCase,
            getAvailableModesUseCase: mockGetAvailableModesUseCase,
          );
          // A ação só abre a tela "Pedir ajuda" no app, onde a pessoa
          // segura o botão por 3 segundos.
          expect(result, isFalse);
        }
        verifyNever(() => mockConfirmCheckinUseCase(any()));
        verifyNever(() => mockStartMonitoringUseCase(any()));
      },
    );
  });
}
