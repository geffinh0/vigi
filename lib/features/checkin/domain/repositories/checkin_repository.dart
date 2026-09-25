import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/monitoring_mode_entity.dart';
import '../entities/monitoring_status_entity.dart';

/// Contrato do dead man's switch: iniciar, confirmar, pausar e consultar o monitoramento.
abstract class CheckinRepository {
  Future<Either<Failure, void>> startMonitoring({
    required String modeId,
    int? intervalOverrideMinutes,
  });

  Future<Either<Failure, void>> saveMonitoringSettings({
    required String modeId,
    required int intervalMinutes,
  });

  Future<Either<Failure, List<MonitoringModeEntity>>> getAvailableModes();

  Future<Either<Failure, MonitoringModeEntity>> createCustomMode({
    required String name,
    required int defaultIntervalMinutes,
    String? iconKey,
  });

  Future<Either<Failure, void>> confirmCheckin({
    double? latitude,
    double? longitude,
  });

  Future<Either<Failure, void>> stopMonitoring();

  Future<Either<Failure, MonitoringStatusEntity>> getStatus();
}
