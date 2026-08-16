import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Serviço responsável pelo gerenciamento dos canais de notificação local
/// do Guardião (Canal 1: Lembrete gentil / Canal 2: Alerta de emergência).
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const String channelIdLembrete = 'lembrete_checkin';
  static const String channelNameLembrete = 'Lembretes de Check-in';
  static const String channelDescLembrete =
      'Avisos prévios para confirmação de presença na rotina.';

  static const String channelIdAlerta = 'alerta_checkin';
  static const String channelNameAlerta = 'Alerta de Check-in Expirado';
  static const String channelDescAlerta =
      'Alarme de alta prioridade quando o tempo de monitoramento é esgotado.';

  static const int notificationIdAlerta = 1001;
  static const int notificationIdLembrete = 1002;

  /// Lógica pura para decisão de expiração em background / timeout.
  /// Testável de forma determinística sem plugins nativos.
  static bool shouldTriggerAlert({
    required DateTime nextDeadline,
    required DateTime currentTime,
  }) {
    return currentTime.isAfter(nextDeadline) ||
        currentTime.isAtSameMomentAs(nextDeadline);
  }

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);

    // Criação dos canais no Android
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          channelIdLembrete,
          channelNameLembrete,
          description: channelDescLembrete,
          importance: Importance.defaultImportance,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          channelIdAlerta,
          channelNameAlerta,
          description: channelDescAlerta,
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        ),
      );
    }
  }

  Future<void> showTimeoutAlert({
    String title = 'Alerta: Check-in Expirado!',
    String body =
        'Você não confirmou seu check-in a tempo. Abra o app agora para desativar o alerta.',
  }) async {
    const androidDetails = AndroidNotificationDetails(
      channelIdAlerta,
      channelNameAlerta,
      channelDescription: channelDescAlerta,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      enableVibration: true,
      playSound: true,
      ongoing: true,
      autoCancel: false,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      ),
    );

    await _plugin.show(
      notificationIdAlerta,
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> cancelAlert() async {
    await _plugin.cancel(notificationIdAlerta);
  }
}
