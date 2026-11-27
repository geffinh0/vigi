import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/checkin_repository.dart';

/// "Preciso de mais 10 minutos": adia o prazo do check-in atual, sem
/// registrar uma confirmação. Resolve o caso de quem está no banho ou ao
/// telefone sem abrir brecha para ignorar o sistema: só vale uma vez por ciclo.
class ExtendDeadlineUseCase implements UseCase<void, DateTime> {
  ExtendDeadlineUseCase(this.repository);

  final CheckinRepository repository;

  @override
  Future<Either<Failure, void>> call(DateTime newDeadline) {
    return repository.extendDeadline(newDeadline);
  }
}
