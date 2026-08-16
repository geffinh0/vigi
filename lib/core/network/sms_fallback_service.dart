import 'package:url_launcher/url_launcher.dart';

class SmsFallbackService {
  /// Envia ou abre o aplicativo de SMS com a mensagem de emergência e localização GPS
  Future<bool> sendEmergencySms({
    required List<String> phoneNumbers,
    required double lat,
    required double lng,
    String? userName,
  }) async {
    if (phoneNumbers.isEmpty) return false;

    final name = userName ?? 'Seu familiar';
    final googleMapsUrl = 'https://maps.google.com/?q=$lat,$lng';
    final message =
        '🚨 ALERTA GUARDIÃO: $name acionou o Botão de Pânico em situação de emergência! Localização GPS: $googleMapsUrl';

    final recipients = phoneNumbers.join(',');
    final uri = Uri.parse(
      'sms:$recipients?body=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
    } catch (_) {}
    return false;
  }
}
