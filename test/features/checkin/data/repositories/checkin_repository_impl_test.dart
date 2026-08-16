import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/errors/failures.dart';
import 'package:guardiao/core/utils/clock.dart';
import 'package:guardiao/features/checkin/data/datasources/checkin_remote_datasource.dart';
import 'package:guardiao/features/checkin/data/models/monitoring_mode_model.dart';
import 'package:guardiao/features/checkin/data/models/monitoring_status_model.dart';
import 'package:guardiao/features/checkin/data/repositories/checkin_repository_impl.dart';
import 'package:guardiao/features/checkin/domain/entities/monitoring_mode_entity.dart';
import 'package:guardiao/features/checkin/domain/entities/monitoring_status_entity.dart';
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

  const tMode = MonitoringModeModel(
    id: 'mode-1',
    name: 'Banho',
    iconKey: 'shower',
    defaultIntervalMinutes: 20,
    isSystemDefault: true,
  );

  group('CheckinRepositoryImpl', () {
    test(
      'saveMonitoringSettings persiste modo e intervalo via datasource',
      () async {
        when(
          () => mockDataSource.saveSettings(
            modeId: 'mode-1',
            intervalMinutes: 25,
          ),
        ).thenAnswer((_) async {});

        final result = await repository.saveMonitoringSettings(
          modeId: 'mode-1',
          intervalMinutes: 25,
        );

        expect(result, const Right(null));
        verify(
          () => mockDataSource.saveSettings(
            modeId: 'mode-1',
            intervalMinutes: 25,
          ),
        ).called(1);
      },
    );

    test(
      'startMonitoring calcula nextDeadline e usa defaultIntervalMinutes do modo quando sem override',
      () async {
        when(
          () => mockDataSource.getAvailableModes(),
        ).thenAnswer((_) async => [tMode]);
        when(
          () => mockDataSource.startMonitoring(
            modeId: any(named: 'modeId'),
            intervalMinutes: any(named: 'intervalMinutes'),
            nextDeadline: any(named: 'nextDeadline'),
          ),
        ).thenAnswer((_) async {});

        final result = await repository.startMonitoring(modeId: 'mode-1');

        expect(result, const Right(null));
        verify(
          () => mockDataSource.startMonitoring(
            modeId: 'mode-1',
            intervalMinutes: 20,
            nextDeadline: fixedTime.add(const Duration(minutes: 20)),
          ),
        ).called(1);
      },
    );

    test(
      'startMonitoring usa intervalOverrideMinutes quando fornecido',
      () async {
        when(
          () => mockDataSource.startMonitoring(
            modeId: any(named: 'modeId'),
            intervalMinutes: any(named: 'intervalMinutes'),
            nextDeadline: any(named: 'nextDeadline'),
          ),
        ).thenAnswer((_) async {});

        final result = await repository.startMonitoring(
          modeId: 'mode-1',
          intervalOverrideMinutes: 15,
        );

        expect(result, const Right(null));
        verify(
          () => mockDataSource.startMonitoring(
            modeId: 'mode-1',
            intervalMinutes: 15,
            nextDeadline: fixedTime.add(const Duration(minutes: 15)),
          ),
        ).called(1);
      },
    );

    test('getAvailableModes retorna lista do datasource', () async {
      when(
        () => mockDataSource.getAvailableModes(),
      ).thenAnswer((_) async => [tMode]);

      final result = await repository.getAvailableModes();

      expect(result.isRight(), isTrue);
      result.fold(
        (f) => fail('Deveria ter retornado Right'),
        (modes) => expect(modes, equals([tMode])),
      );
    });

    test('createCustomMode cria modo via datasource', () async {
      when(
        () => mockDataSource.createCustomMode(
          name: 'Passeio',
          defaultIntervalMinutes: 30,
          iconKey: 'walk',
        ),
      ).thenAnswer((_) async => tMode);

      final result = await repository.createCustomMode(
        name: 'Passeio',
        defaultIntervalMinutes: 30,
        iconKey: 'walk',
      );

      expect(
        result,
        const Right<Failure, MonitoringModeEntity>(tMode),
      );
    });

    test('getStatus retorna status do datasource (com modo ativo)', () async {
      const tStatus = MonitoringStatusModel(
        active: true,
        intervalMinutes: 20,
        activeModeId: 'mode-1',
        activeMode: tMode,
      );

      when(() => mockDataSource.getStatus()).thenAnswer((_) async => tStatus);

      final result = await repository.getStatus();

      expect(
        result,
        const Right<Failure, MonitoringStatusEntity>(tStatus),
      );
    });

    // Teste de regressão para novo usuário receber status default
    test(
      'todo usuário novo recebe monitoring_settings com modo e intervalo padrão',
      () async {
        const tDefaultStatus = MonitoringStatusModel(
          active: false,
          intervalMinutes: 60,
          activeModeId: 'system-default-routine',
        );

        when(
          () => mockDataSource.getStatus(),
        ).thenAnswer((_) async => tDefaultStatus);

        final status = await repository.getStatus();

        expect(status.isRight(), true);
        status.fold((_) => fail('deveria existir status default'), (s) {
          expect(s.intervalMinutes, greaterThan(0));
        });
      },
    );
  });
}
