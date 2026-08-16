import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/utils/clock.dart';
import 'package:guardiao/features/checkin/data/datasources/checkin_remote_datasource.dart';
import 'package:guardiao/features/checkin/data/models/monitoring_status_model.dart';
import 'package:guardiao/features/checkin/data/repositories/checkin_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckinRemoteDataSource extends Mock
    implements CheckinRemoteDataSource {}

class FakeClock implements Clock {
  FakeClock(this._time);
  final DateTime _time;

  @override
  DateTime now() => _time;
}

void main() {
  late CheckinRepositoryImpl repository;
  late MockCheckinRemoteDataSource mockDataSource;
  late FakeClock fakeClock;

  final fixedTime = DateTime(2026, 8, 15, 14, 0, 0);

  setUpAll(() {
    registerFallbackValue(DateTime(2026, 8, 15));
  });

  setUp(() {
    mockDataSource = MockCheckinRemoteDataSource();
    fakeClock = FakeClock(fixedTime);
    repository = CheckinRepositoryImpl(
      remoteDataSource: mockDataSource,
      clock: fakeClock,
    );
  });

  group('CheckinRepositoryImpl', () {
    test(
      'startMonitoring calcula nextDeadline absoluto a partir do Clock injetado',
      () async {
        when(
          () => mockDataSource.startMonitoring(
            intervalMinutes: any(named: 'intervalMinutes'),
            nextDeadline: any(named: 'nextDeadline'),
          ),
        ).thenAnswer((_) async {});

        final result = await repository.startMonitoring(intervalMinutes: 60);

        expect(result, const Right(null));
        verify(
          () => mockDataSource.startMonitoring(
            intervalMinutes: 60,
            nextDeadline: fixedTime.add(const Duration(minutes: 60)),
          ),
        ).called(1);
      },
    );

    test('getStatus retorna status do datasource', () async {
      const tStatus = MonitoringStatusModel(
        active: true,
        intervalMinutes: 60,
      );

      when(() => mockDataSource.getStatus()).thenAnswer((_) async => tStatus);

      final result = await repository.getStatus();

      expect(result, const Right(tStatus));
    });
  });
}
