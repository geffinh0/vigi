import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> requestPermission() async {
  try {
    if (web.Notification.permission == 'default') {
      await web.Notification.requestPermission().toDart;
    }
  } catch (_) {}
}

void show(String title, String body) {
  try {
    if (web.Notification.permission == 'granted') {
      web.Notification(
        title,
        web.NotificationOptions(
          body: body,
          icon: 'icons/Icon-192.png',
          requireInteraction: true,
        ),
      );
    }
  } catch (_) {}
}
