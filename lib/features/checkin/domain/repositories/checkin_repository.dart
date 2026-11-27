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

  /// Confirma o check-in e renova o prazo. [intervalMinutes] e [modeId]
  /// definem o próximo ciclo (padrão: o que já está salvo). Com
  /// [resolvesAlert], registra também o fim do alerta.
  Future<Either<Failure, void>> confirmCheckin({
    double? latitude,
    double? longitude,
    int? intervalMinutes,
    String? modeId,
    bool resolvesAlert = false,
  });

  /// Adia o prazo do check-in atual para [newDeadline].
  Future<Either<Failure, void>> extendDeadline(DateTime newDeadline);

  Future<Either<Failure, void>> stopMonitoring();

  Future<Either<Failure, MonitoringStatusEntity>> getStatus();
}
