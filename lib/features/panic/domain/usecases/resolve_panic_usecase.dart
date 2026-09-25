import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/panic_repository.dart';

/// Marca o alerta como resolvido ("Estou seguro").
class ResolvePanicUseCase implements UseCase<void, NoParams> {
  ResolvePanicUseCase(this.repository);

  final PanicRepository repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.resolvePanic();
  }
}
