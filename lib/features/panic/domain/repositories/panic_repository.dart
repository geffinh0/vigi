import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/panic_alert_entity.dart';

/// Contrato do botão de pânico.
abstract class PanicRepository {
  Future<Either<Failure, PanicAlertEntity>> triggerPanic({
    double? latitude,
    double? longitude,
  });

  Future<Either<Failure, void>> resolvePanic();
}
