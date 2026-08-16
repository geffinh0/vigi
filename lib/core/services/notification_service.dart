import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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
  static const int notificationIdOngoing = 1000;

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
    try {
      tz.initializeTimeZones();
    } catch (_) {}

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

    // Criação dos canais e solicitação de permissões no Android
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      try {
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      } catch (_) {}

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

  /// Exibe notificação persistente (Ongoing) enquanto o monitoramento está ativo.
  /// Isso informa o sistema operacional Android que o processo é um serviço de proteção em execução,
  /// impedindo que a bateria/sistema encerre o monitoramento quando fechado/minimizado.
  Future<void> showMonitoringOngoing({
    required String modeName,
    required DateTime nextDeadline,
  }) async {
    final formattedTime =
        '${nextDeadline.hour.toString().padLeft(2, '0')}:${nextDeadline.minute.toString().padLeft(2, '0')}';

    final androidDetails = AndroidNotificationDetails(
      channelIdLembrete,
      channelNameLembrete,
      channelDescription: channelDescLembrete,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      when: nextDeadline.millisecondsSinceEpoch,
      usesChronometer: true,
      chronometerCountDown: true,
      icon: '@mipmap/ic_launcher',
      visibility: NotificationVisibility.public,
    );

    try {
      await _plugin.show(
        notificationIdOngoing,
        'Guardião Ativo • $modeName',
        'Próximo check-in às $formattedTime (Proteção ativa)',
        NotificationDetails(android: androidDetails),
      );
    } catch (_) {}
  }

  Future<void> cancelMonitoringOngoing() async {
    try {
      await _plugin.cancel(notificationIdOngoing);
    } catch (_) {}
  }

  /// Agenda um alarme exato a nível de hardware/sistema operacional (AlarmManager).
  /// Mesmo que o app seja TOTALMENTE FECHADO ou o celular entre em suspensão profunda (Doze Mode),
  /// o Android acorda o dispositivo no exato segundo agendado para disparar o alarme.
  Future<void> scheduleTimeoutAlarm(DateTime nextDeadline) async {
    await cancelScheduledAlarm();

    final tzDeadline = tz.TZDateTime.from(nextDeadline, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (tzDeadline.isBefore(now) || tzDeadline.isAtSameMomentAs(now)) {
      await showTimeoutAlert();
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      channelIdAlerta,
      channelNameAlerta,
      channelDescription: channelDescAlerta,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      icon: '@mipmap/ic_launcher',
      fullScreenIntent: true,
      enableVibration: true,
      playSound: true,
      ongoing: true,
      autoCancel: false,
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      ticker: 'Alerta de Check-in Expirado',
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

    try {
      await _plugin.zonedSchedule(
        notificationIdAlerta,
        'ALERTA: CHECK-IN EXPIRADO!',
        'Você não confirmou sua presença a tempo. Abra o Guardião para desativar o alarme.',
        tzDeadline,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      try {
        await _plugin.zonedSchedule(
          notificationIdAlerta,
          'ALERTA: CHECK-IN EXPIRADO!',
          'Você não confirmou sua presença a tempo. Abra o Guardião para desativar o alarme.',
          tzDeadline,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {}
    }
  }

  Future<void> cancelScheduledAlarm() async {
    try {
      await _plugin.cancel(notificationIdAlerta);
    } catch (_) {}
  }

  Future<void> showTimeoutAlert({
    String title = 'ALERTA: CHECK-IN EXPIRADO!',
    String body =
        'Você não confirmou sua presença a tempo. Abra o Guardião para desativar o alarme.',
  }) async {
    const androidDetails = AndroidNotificationDetails(
      channelIdAlerta,
      channelNameAlerta,
      channelDescription: channelDescAlerta,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      icon: '@mipmap/ic_launcher',
      fullScreenIntent: true,
      enableVibration: true,
      playSound: true,
      ongoing: true,
      autoCancel: false,
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      ticker: 'Alerta de Check-in Expirado',
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

    try {
      await _plugin.show(
        notificationIdAlerta,
        title,
        body,
        notificationDetails,
      );
    } catch (_) {
      const fallbackAndroidDetails = AndroidNotificationDetails(
        channelIdAlerta,
        channelNameAlerta,
        channelDescription: channelDescAlerta,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        enableVibration: true,
        playSound: true,
        ongoing: true,
        autoCancel: false,
        visibility: NotificationVisibility.public,
      );
      await _plugin.show(
        notificationIdAlerta,
        title,
        body,
        const NotificationDetails(android: fallbackAndroidDetails),
      );
    }
  }

  Future<void> cancelAlert() async {
    try {
      await _plugin.cancel(notificationIdAlerta);
    } catch (_) {}
  }
}
