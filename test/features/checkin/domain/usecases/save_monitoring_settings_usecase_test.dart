import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/errors/failures.dart';
import 'package:guardiao/features/checkin/domain/repositories/checkin_repository.dart';
import 'package:guardiao/features/checkin/domain/usecases/save_monitoring_settings_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckinRepository extends Mock implements CheckinRepository {}

void main() {
  late SaveMonitoringSettingsUseCase useCase;
  late MockCheckinRepository mockRepository;

  setUp(() {
    mockRepository = MockCheckinRepository();
    useCase = SaveMonitoringSettingsUseCase(mockRepository);
  });

  const tModeId = 'mode-routine';
  const tInterval = 45;

  group('SaveMonitoringSettingsUseCase', () {
    test('salva configurações com sucesso no repository', () async {
      when(
        () => mockRepository.saveMonitoringSettings(
          modeId: tModeId,
          intervalMinutes: tInterval,
        ),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase(
        const SaveMonitoringSettingsParams(
          modeId: tModeId,
          intervalMinutes: tInterval,
        ),
      );

      expect(result, const Right(null));
      verify(
        () => mockRepository.saveMonitoringSettings(
          modeId: tModeId,
          intervalMinutes: tInterval,
        ),
      ).called(1);
    });

    test(
      'rejeita intervalo menor ou igual a zero com ValidationFailure',
      () async {
        final result = await useCase(
          const SaveMonitoringSettingsParams(
            modeId: tModeId,
            intervalMinutes: 0,
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('Deveria falhar'),
        );
        verifyZeroInteractions(mockRepository);
      },
    );

    test('rejeita modeId vazio com ValidationFailure', () async {
      final result = await useCase(
        const SaveMonitoringSettingsParams(
          modeId: '',
          intervalMinutes: 30,
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Deveria falhar'),
      );
      verifyZeroInteractions(mockRepository);
    });
  });
}
