import 'package:geolocator/geolocator.dart';

/// Obtém a posição atual para anexar aos pedidos de ajuda.
///
/// Nunca lança exceção e nunca abre um diálogo: sem GPS ou sem permissão,
/// devolve `null` e o pedido de ajuda segue sem a localização.
abstract final class LocationHelper {
  /// Teto para a busca da posição. O pedido de ajuda não espera mais que isso.
  static const Duration limit = Duration(seconds: 10);

  static Future<Position?> currentPositionOrNull() async {
    try {
      return await _lookup().timeout(limit, onTimeout: () => null);
    } catch (_) {
      return null;
    }
  }

  static Future<Position?> _lookup() async {
    // A permissão não é pedida aqui. Esta busca roda no meio de um pedido de
    // ajuda, muitas vezes porque a pessoa não respondeu: um diálogo do
    // sistema esperando resposta seguraria o aviso aos contatos.
    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return null;
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      return Geolocator.getLastKnownPosition();
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      return Geolocator.getLastKnownPosition();
    }
  }

  /// Pede a permissão de localização. Só é chamado quando a pessoa toca em
  /// "Permitir localização", depois de o Vigi explicar para que serve.
  static Future<void> ensurePermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (_) {}
  }
}
