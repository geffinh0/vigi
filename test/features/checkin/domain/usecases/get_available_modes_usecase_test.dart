import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/errors/failures.dart';
import 'package:guardiao/core/usecases/usecase.dart';
import 'package:guardiao/features/checkin/domain/entities/monitoring_mode_entity.dart';
import 'package:guardiao/features/checkin/domain/repositories/checkin_repository.dart';
import 'package:guardiao/features/checkin/domain/usecases/get_available_modes_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckinRepository extends Mock implements CheckinRepository {}

void main() {
  late GetAvailableModesUseCase useCase;
  late MockCheckinRepository mockCheckinRepository;

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    mockCheckinRepository = MockCheckinRepository();
    useCase = GetAvailableModesUseCase(mockCheckinRepository);
  });

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
    MonitoringModeEntity(
      id: '4',
      name: 'Caminhada',
      iconKey: 'walk',
      defaultIntervalMinutes: 45,
      isSystemDefault: false,
    ),
  ];

  group('GetAvailableModesUseCase', () {
    test(
      'retorna lista de modos de sistema e modos próprios do usuário com sucesso',
      () async {
        when(
          () => mockCheckinRepository.getAvailableModes(),
        ).thenAnswer((_) async => const Right(tModes));

        final result = await useCase(const NoParams());

        expect(result, const Right(tModes));
        verify(() => mockCheckinRepository.getAvailableModes()).called(1);
      },
    );

    test('repassa Failure quando o repositório falhar', () async {
      when(
        () => mockCheckinRepository.getAvailableModes(),
      ).thenAnswer((_) async => const Left(ServerFailure('Erro no servidor')));

      final result = await useCase(const NoParams());

      expect(result, const Left(ServerFailure('Erro no servidor')));
      verify(() => mockCheckinRepository.getAvailableModes()).called(1);
    });
  });
}
