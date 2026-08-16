import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/errors/failures.dart';
import 'package:guardiao/core/usecases/usecase.dart';
import 'package:guardiao/features/panic/domain/entities/panic_alert_entity.dart';
import 'package:guardiao/features/panic/domain/repositories/panic_repository.dart';
import 'package:guardiao/features/panic/domain/usecases/resolve_panic_usecase.dart';
import 'package:guardiao/features/panic/domain/usecases/trigger_panic_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockPanicRepository extends Mock implements PanicRepository {}

void main() {
  late MockPanicRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    mockRepository = MockPanicRepository();
  });

  const tAlert = PanicAlertEntity(
    id: 'alert-1',
    userId: 'u1',
    eventType: 'panic',
    latitude: -23.55,
    longitude: -46.63,
  );

  group('TriggerPanicUseCase', () {
    test('dispara alerta de pânico e retorna PanicAlertEntity', () async {
      final useCase = TriggerPanicUseCase(mockRepository);
      when(
        () => mockRepository.triggerPanic(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => const Right(tAlert));

      final result = await useCase(
        const TriggerPanicParams(latitude: -23.55, longitude: -46.63),
      );

      expect(result, const Right(tAlert));
      verify(
        () => mockRepository.triggerPanic(
          latitude: -23.55,
          longitude: -46.63,
        ),
      ).called(1);
    });

    test('repassa falha quando repository falha', () async {
      final useCase = TriggerPanicUseCase(mockRepository);
      when(
        () => mockRepository.triggerPanic(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => const Left(ServerFailure('Erro no servidor')));

      final result = await useCase(const TriggerPanicParams());

      expect(result, const Left(ServerFailure('Erro no servidor')));
    });
  });

  group('ResolvePanicUseCase', () {
    test('resolve pânico com sucesso', () async {
      final useCase = ResolvePanicUseCase(mockRepository);
      when(
        () => mockRepository.resolvePanic(),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase(const NoParams());

      expect(result, const Right(null));
      verify(() => mockRepository.resolvePanic()).called(1);
    });
  });
}
