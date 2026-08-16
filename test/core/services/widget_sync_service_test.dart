import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/services/widget_background_handler.dart';
import 'package:guardiao/core/services/widget_sync_service.dart';
import 'package:guardiao/features/checkin/domain/usecases/confirm_checkin_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockConfirmCheckinUseCase extends Mock implements ConfirmCheckinUseCase {}

class MockWidgetSyncService extends Mock implements WidgetSyncService {}

void main() {
  late MockConfirmCheckinUseCase mockConfirmCheckinUseCase;
  late MockWidgetSyncService mockWidgetSyncService;

  setUpAll(() {
    registerFallbackValue(const ConfirmCheckinParams());
  });

  setUp(() {
    mockConfirmCheckinUseCase = MockConfirmCheckinUseCase();
    mockWidgetSyncService = MockWidgetSyncService();

    when(
      () => mockConfirmCheckinUseCase(any()),
    ).thenAnswer((_) async => const Right(null));

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
      'ignora URI nulo ou com host diferente de confirmar_checkin',
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
            vigiState: 'normal',
            minutesRemaining: 60,
            modeName: 'Rotina padrão',
            isMonitoring: true,
          ),
        ).called(1);
      },
    );
  });
}
