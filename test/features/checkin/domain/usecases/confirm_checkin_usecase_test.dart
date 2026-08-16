import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/usecases/usecase.dart';
import 'package:guardiao/features/checkin/domain/repositories/checkin_repository.dart';
import 'package:guardiao/features/checkin/domain/usecases/confirm_checkin_usecase.dart';
import 'package:guardiao/features/checkin/domain/usecases/stop_monitoring_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckinRepository extends Mock implements CheckinRepository {}

void main() {
  late MockCheckinRepository mockCheckinRepository;

  setUp(() {
    mockCheckinRepository = MockCheckinRepository();
  });

  group('ConfirmCheckinUseCase', () {
    test('confirma checkin no repository com sucesso', () async {
      final useCase = ConfirmCheckinUseCase(mockCheckinRepository);
      when(
        () => mockCheckinRepository.confirmCheckin(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase(
        const ConfirmCheckinParams(latitude: -23.55, longitude: -46.63),
      );

      expect(result, const Right(null));
      verify(
        () => mockCheckinRepository.confirmCheckin(
          latitude: -23.55,
          longitude: -46.63,
        ),
      ).called(1);
    });
  });

  group('StopMonitoringUseCase', () {
    test('para monitoramento com sucesso', () async {
      final useCase = StopMonitoringUseCase(mockCheckinRepository);
      when(
        () => mockCheckinRepository.stopMonitoring(),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase(const NoParams());

      expect(result, const Right(null));
      verify(() => mockCheckinRepository.stopMonitoring()).called(1);
    });
  });
}
