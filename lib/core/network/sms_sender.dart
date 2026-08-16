import 'package:url_launcher/url_launcher.dart';
import '../utils/logger.dart';

abstract final class SmsSender {
  /// Abre o disparador de SMS nativo com o número do contato e mensagem de socorro.
  static Future<bool> sendEmergencySms({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      } else {
        AppLogger.warning('Não foi possível abrir o aplicativo de SMS nativo.');
        return false;
      }
    } catch (e) {
      AppLogger.error('Erro ao disparar SMS de emergência', e);
      return false;
    }
  }
}
