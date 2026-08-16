import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/monitoring_status_entity.dart';
import '../repositories/checkin_repository.dart';

class GetMonitoringStatusUseCase
    implements UseCase<MonitoringStatusEntity, NoParams> {
  GetMonitoringStatusUseCase(this.repository);

  final CheckinRepository repository;

  @override
  Future<Either<Failure, MonitoringStatusEntity>> call(NoParams params) {
    return repository.getStatus();
  }
}
