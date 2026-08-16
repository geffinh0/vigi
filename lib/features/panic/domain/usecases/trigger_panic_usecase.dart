import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/panic_alert_entity.dart';
import '../repositories/panic_repository.dart';

class TriggerPanicParams extends Equatable {
  const TriggerPanicParams({this.latitude, this.longitude});

  final double? latitude;
  final double? longitude;

  @override
  List<Object?> get props => [latitude, longitude];
}

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
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          final permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse) {
            final position =
                await Geolocator.getCurrentPosition(
                  locationSettings: const LocationSettings(
                    timeLimit: Duration(seconds: 3),
                  ),
                ).catchError((_) async {
                  return await Geolocator.getLastKnownPosition() ??
                      Position(
                        longitude: 0,
                        latitude: 0,
                        timestamp: DateTime.now(),
                        accuracy: 0,
                        altitude: 0,
                        altitudeAccuracy: 0,
                        heading: 0,
                        headingAccuracy: 0,
                        speed: 0,
                        speedAccuracy: 0,
                      );
                });

            lat = position.latitude;
            lng = position.longitude;
          }
        }
      } catch (_) {
        // Fallback resiliente: o envio do alerta nunca deve travar por falha no GPS
      }
    }

    return repository.triggerPanic(latitude: lat, longitude: lng);
  }
}
