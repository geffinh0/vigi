import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/errors/failures.dart';
import 'package:guardiao/features/checkin/domain/entities/monitoring_mode_entity.dart';
import 'package:guardiao/features/checkin/domain/repositories/checkin_repository.dart';
import 'package:guardiao/features/checkin/domain/usecases/create_custom_mode_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckinRepository extends Mock implements CheckinRepository {}

void main() {
  late CreateCustomModeUseCase useCase;
  late MockCheckinRepository mockCheckinRepository;

  setUp(() {
    mockCheckinRepository = MockCheckinRepository();
    useCase = CreateCustomModeUseCase(mockCheckinRepository);
  });

  const tCreatedMode = MonitoringModeEntity(
    id: 'mode-custom-1',
    name: 'Caminhada',
    iconKey: 'walk',
    defaultIntervalMinutes: 45,
    isSystemDefault: false,
  );

  group('CreateCustomModeUseCase', () {
    test(
      'cria modo customizado com sucesso quando dados são válidos',
      () async {
        when(
          () => mockCheckinRepository.createCustomMode(
            name: any(named: 'name'),
            defaultIntervalMinutes: any(named: 'defaultIntervalMinutes'),
            iconKey: any(named: 'iconKey'),
          ),
        ).thenAnswer((_) async => const Right(tCreatedMode));

        final result = await useCase(
          const CreateCustomModeParams(
            name: 'Caminhada',
            defaultIntervalMinutes: 45,
            iconKey: 'walk',
          ),
        );

        expect(result, const Right(tCreatedMode));
        verify(
          () => mockCheckinRepository.createCustomMode(
            name: 'Caminhada',
            defaultIntervalMinutes: 45,
            iconKey: 'walk',
          ),
        ).called(1);
      },
    );

    test(
      'rejeita intervalo menor ou igual a zero com ValidationFailure',
      () async {
        final result = await useCase(
          const CreateCustomModeParams(
            name: 'Caminhada',
            defaultIntervalMinutes: 0,
          ),
        );

        expect(result, isA<Left<Failure, MonitoringModeEntity>>());
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, 'Intervalo deve ser maior que 0 minutos');
          },
          (_) => fail('Deveria ter falhado'),
        );
        verifyZeroInteractions(mockCheckinRepository);
      },
    );

    test('rejeita nome vazio com ValidationFailure', () async {
      final result = await useCase(
        const CreateCustomModeParams(
          name: '   ',
          defaultIntervalMinutes: 30,
        ),
      );

      expect(result, isA<Left<Failure, MonitoringModeEntity>>());
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, 'Nome do modo não pode ser vazio');
        },
        (_) => fail('Deveria ter falhado'),
      );
      verifyZeroInteractions(mockCheckinRepository);
    });
  });
}
