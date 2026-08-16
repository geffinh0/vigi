import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/monitoring_status_entity.dart';

abstract class CheckinRepository {
  Future<Either<Failure, void>> startMonitoring({required int intervalMinutes});

  Future<Either<Failure, void>> confirmCheckin({
    double? latitude,
    double? longitude,
  });

  Future<Either<Failure, void>> stopMonitoring();

  Future<Either<Failure, MonitoringStatusEntity>> getStatus();
}
