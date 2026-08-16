import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/monitoring_mode_entity.dart';
import '../repositories/checkin_repository.dart';

class GetAvailableModesUseCase
    implements UseCase<List<MonitoringModeEntity>, NoParams> {
  GetAvailableModesUseCase(this.repository);

  final CheckinRepository repository;

  @override
  Future<Either<Failure, List<MonitoringModeEntity>>> call(NoParams params) {
    return repository.getAvailableModes();
  }
}
