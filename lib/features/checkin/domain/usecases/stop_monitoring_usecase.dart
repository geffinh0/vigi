import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/checkin_repository.dart';

class StopMonitoringUseCase implements UseCase<void, NoParams> {
  StopMonitoringUseCase(this.repository);

  final CheckinRepository repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.stopMonitoring();
  }
}
