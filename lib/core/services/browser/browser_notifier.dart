import 'browser_notifier_stub.dart'
    if (dart.library.js_interop) 'browser_notifier_web.dart'
    as impl;

/// Notificação do sistema no navegador (painel web da família). No app
/// Android não faz nada: lá o aviso chega por push FCM.
abstract final class BrowserNotifier {
  static Future<void> requestPermission() => impl.requestPermission();

  static void show(String title, String body) => impl.show(title, body);
}
