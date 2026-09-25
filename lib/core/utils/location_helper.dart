import 'package:geolocator/geolocator.dart';

/// Obtém a posição atual para anexar aos alertas de emergência.
/// Nunca lança exceção: sem GPS/permissão, retorna null e o alerta segue sem localização.
abstract final class LocationHelper {
  static Future<Position?> currentPositionOrNull() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return await Geolocator.getLastKnownPosition();
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return null;
      }

      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        return await Geolocator.getLastKnownPosition();
      }
    } catch (_) {
      return null;
    }
  }

  /// Solicita a permissão de localização antecipadamente (ex.: na abertura do app),
  /// para que no momento da emergência não seja preciso interagir com diálogos.
  static Future<void> ensurePermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (_) {}
  }
}
