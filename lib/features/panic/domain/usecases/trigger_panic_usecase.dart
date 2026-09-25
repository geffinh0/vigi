import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/location_helper.dart';
import '../entities/panic_alert_entity.dart';
import '../repositories/panic_repository.dart';

/// Localização opcional (obtida automaticamente se ausente).
class TriggerPanicParams extends Equatable {
  const TriggerPanicParams({this.latitude, this.longitude});

  final double? latitude;
  final double? longitude;

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Registra o pânico com a localização atual.
class TriggerPanicUseCase
    implements UseCase<PanicAlertEntity, TriggerPanicParams> {
  TriggerPanicUseCase(this.repository);

  final PanicRepository repository;

  @override
  Future<Either<Failure, PanicAlertEntity>> call(
    TriggerPanicParams params,
  ) async {
    double? lat = params.latitude;
    double? lng = params.longitude;

    if (lat == null || lng == null) {
      // O envio do alerta nunca deve travar por falha no GPS
      final position = await LocationHelper.currentPositionOrNull();
      lat = position?.latitude;
      lng = position?.longitude;
    }

    return repository.triggerPanic(latitude: lat, longitude: lng);
  }
}
