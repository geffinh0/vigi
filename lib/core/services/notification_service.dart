import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../utils/vigi_text.dart';
import 'checkin_messages.dart';

/// Ações que a pessoa pode tocar direto na notificação, sem abrir o app.
enum NotificationAction {
  /// "Estou bem": confirma o check-in.
  confirm('estou_bem'),

  /// "+10 min": estende o prazo, uma vez por ciclo.
  snooze('mais_10')
  ;

  const NotificationAction(this.id);
  final String id;

  static NotificationAction? fromId(String? id) {
    for (final action in values) {
      if (action.id == id) return action;
    }
    return null;
  }
}

/// Notificações locais do Vigi, uma por degrau da escada de estados:
///
/// - **Vigília**: notificação discreta e persistente enquanto o Vigi vigia.
/// - **Chamada** ("Sua vez"): pergunta gentil com o botão "Estou bem".
/// - **Última chamada**: alarme em tela cheia, que toca até ser respondido.
/// - **Alerta**: avisa que os contatos foram acionados.
///
/// A chamada e a última chamada são agendadas no sistema (AlarmManager), então
/// tocam mesmo com o app fechado ou o celular em suspensão profunda.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<NotificationAction> _actions =
      StreamController<NotificationAction>.broadcast();

  // ── Canais ────────────────────────────────────────────────────────
  static const String channelIdVigilia = 'lembrete_checkin';
  static const String channelNameVigilia = 'Vigília em andamento';
  static const String channelDescVigilia =
      'Aviso discreto enquanto o Vigi está de olho, com o horário do '
      'próximo check-in.';

  static const String channelIdChamada = 'vigi_chamada';
  static const String channelNameChamada = 'Chamada de check-in';
  static const String channelDescChamada =
      'O Vigi pergunta se está tudo bem quando chega a hora do check-in.';

  static const String channelIdUltimaChamada = 'vigi_ultima_chamada';
  static const String channelNameUltimaChamada = 'Última chamada';
  static const String channelDescUltimaChamada =
      'Alarme dos minutos finais antes de o Vigi avisar seus contatos.';

  /// "Está tudo bem": o push que fecha um pedido de ajuda. Chega sem alarme.
  static const String channelIdTudoBem = 'vigi_tudo_bem';
  static const String channelNameTudoBem = 'Está tudo bem';
  static const String channelDescTudoBem =
      'Avisa quando alguém que você acompanha cancelou um pedido de ajuda.';

  /// Mantém o identificador antigo: o push para familiares usa este canal.
  static const String channelIdAlerta = 'alerta_checkin';
  static const String channelNameAlerta = 'Pedidos de ajuda';
  static const String channelDescAlerta =
      'Avisa quando o Vigi pediu ajuda, por você ou por alguém que você '
      'acompanha.';

  // ── Identificadores ───────────────────────────────────────────────
  static const int notificationIdVigilia = 1000;
  static const int notificationIdChamada = 1001;
  static const int notificationIdUltimaChamada = 1003;
  static const int notificationIdAlerta = 1004;
  static const int notificationIdFamilia = 1005;

  /// Ícone pequeno da barra de status (silhueta dos olhos da coruja).
  static const String smallIcon = 'ic_stat_vigi';

  /// Cor de destaque de cada degrau (tinge o ícone e o nome do app).
  static const Color colorVigilia = Color(0xFF1F3D3B);
  static const Color colorChamada = Color(0xFF8A5A0F);
  static const Color colorAlerta = Color(0xFFC23B3A);

  /// Sons em `android/app/src/main/res/raw`.
  static const String soundChamada = 'vigi_chamada';
  static const String soundUltimaChamada = 'vigi_ultima_chamada';

  /// Sua vez: dois pulsos curtos (80 ms, pausa de 120 ms, 80 ms).
  static final Int64List vibrationChamada = Int64List.fromList([
    0,
    80,
    120,
    80,
  ]);

  /// Última chamada: pulsos longos (600 ms, pausa de 400 ms).
  static final Int64List vibrationUltimaChamada = Int64List.fromList([
    0,
    600,
    400,
    600,
    400,
    600,
  ]);

  /// `Notification.FLAG_INSISTENT`: o som repete até a pessoa responder.
  static const int _flagInsistent = 4;

  /// Toques nas ações das notificações ("Estou bem", "+10 min").
  Stream<NotificationAction> get actions => _actions.stream;

  /// Lógica pura para decidir se o prazo já venceu.
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

    const androidSettings = AndroidInitializationSettings(smallIcon);
    const darwinSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onResponse,
    );

    final androidPlugin = _android;
    if (androidPlugin == null) return;

    // As permissões não são pedidas aqui: a tela "Permissões" explica cada
    // uma, em linguagem clara, antes de o sistema perguntar.

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        channelIdVigilia,
        channelNameVigilia,
        description: channelDescVigilia,
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ),
    );
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        channelIdChamada,
        channelNameChamada,
        description: channelDescChamada,
        importance: Importance.high,
        sound: const RawResourceAndroidNotificationSound(soundChamada),
        vibrationPattern: vibrationChamada,
      ),
    );
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        channelIdUltimaChamada,
        channelNameUltimaChamada,
        description: channelDescUltimaChamada,
        importance: Importance.max,
        sound: const RawResourceAndroidNotificationSound(soundUltimaChamada),
        vibrationPattern: vibrationUltimaChamada,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        channelIdAlerta,
        channelNameAlerta,
        description: channelDescAlerta,
        importance: Importance.max,
      ),
    );
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        channelIdTudoBem,
        channelNameTudoBem,
        description: channelDescTudoBem,
      ),
    );
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  void _onResponse(NotificationResponse response) {
    final action = NotificationAction.fromId(response.actionId);
    if (action != null) _actions.add(action);
  }

  /// Ação que abriu o app a partir de uma notificação, quando ele estava
  /// fechado. Devolve `null` se o app foi aberto de outro jeito.
  Future<NotificationAction?> takeLaunchAction() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details == null || !details.didNotificationLaunchApp) return null;
      return NotificationAction.fromId(details.notificationResponse?.actionId);
    } catch (_) {
      return null;
    }
  }

  /// Sem notificações o Vigi não consegue chamar: isso vira um aviso no topo
  /// da tela inicial.
  Future<bool> areNotificationsEnabled() async {
    try {
      return await _android?.areNotificationsEnabled() ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> requestPermission() async {
    try {
      return await _android?.requestNotificationsPermission() ?? true;
    } catch (_) {
      return false;
    }
  }

  /// Sem alarmes exatos, o Android pode atrasar a chamada em vários minutos.
  Future<bool> canScheduleExactAlarms() async {
    try {
      return await _android?.canScheduleExactNotifications() ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Abre a tela do sistema que libera os alarmes exatos.
  Future<bool> requestExactAlarms() async {
    try {
      return await _android?.requestExactAlarmsPermission() ?? true;
    } catch (_) {
      return false;
    }
  }

  // ── Vigília ───────────────────────────────────────────────────────

  /// Notificação persistente enquanto o monitoramento está ativo. Informa ao
  /// Android que há uma proteção em andamento e mostra à pessoa o horário do
  /// próximo check-in.
  Future<void> showMonitoringOngoing({
    required String modeName,
    required DateTime nextDeadline,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelIdVigilia,
      channelNameVigilia,
      channelDescription: channelDescVigilia,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      when: nextDeadline.millisecondsSinceEpoch,
      usesChronometer: true,
      chronometerCountDown: true,
      icon: smallIcon,
      color: colorVigilia,
      visibility: NotificationVisibility.public,
    );

    try {
      await _plugin.show(
        notificationIdVigilia,
        'Vigi de olho · $modeName',
        CheckinMessages.nextCheckin(nextDeadline),
        NotificationDetails(android: androidDetails),
      );
    } catch (_) {}
  }

  Future<void> cancelMonitoringOngoing() async {
    try {
      await _plugin.cancel(notificationIdVigilia);
    } catch (_) {}
  }

  // ── Chamada e última chamada ──────────────────────────────────────

  List<AndroidNotificationAction> _callActions(bool canSnooze) => [
    const AndroidNotificationAction(
      'estou_bem',
      'Estou bem',
      showsUserInterface: true,
    ),
    if (canSnooze)
      const AndroidNotificationAction(
        'mais_10',
        '+10 min',
        showsUserInterface: true,
      ),
  ];

  NotificationDetails _callDetails(
    CheckinCallInfo info, {
    bool onlyAlertOnce = false,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelIdChamada,
        channelNameChamada,
        channelDescription: channelDescChamada,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        icon: smallIcon,
        color: colorChamada,
        sound: const RawResourceAndroidNotificationSound(soundChamada),
        vibrationPattern: vibrationChamada,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: onlyAlertOnce,
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(
          CheckinMessages.callBody(info.escalatesAt, info.contactNames),
        ),
        actions: _callActions(info.canSnooze),
        ticker: CheckinMessages.question(info.firstName),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  NotificationDetails _lastCallDetails(
    CheckinCallInfo info, {
    bool onlyAlertOnce = false,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelIdUltimaChamada,
        channelNameUltimaChamada,
        channelDescription: channelDescUltimaChamada,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        icon: smallIcon,
        color: colorChamada,
        // Depois de meia hora tocando sem resposta, o alarme se cala: a essa
        // altura os contatos já foram avisados.
        timeoutAfter: 30 * 60 * 1000,
        sound: const RawResourceAndroidNotificationSound(soundUltimaChamada),
        vibrationPattern: vibrationUltimaChamada,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        additionalFlags: Int32List.fromList([_flagInsistent]),
        // Ocupa a tela de bloqueio.
        fullScreenIntent: true,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: onlyAlertOnce,
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(
          CheckinMessages.lastCallBody(info.escalatesAt, info.contactNames),
        ),
        actions: _callActions(false),
        ticker: CheckinMessages.lastCallTitle(info.firstName),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      ),
    );
  }

  /// Agenda os dois degraus do próximo ciclo: a chamada no prazo e a última
  /// chamada nos minutos finais da tolerância.
  Future<void> scheduleCheckinCall(CheckinCallInfo info) async {
    await cancelScheduledAlarm();

    final now = tz.TZDateTime.now(tz.local);
    final callAt = tz.TZDateTime.from(info.deadline, tz.local);
    final lastCallAt = tz.TZDateTime.from(info.lastCallAt, tz.local);

    if (!callAt.isAfter(now)) {
      await showCheckinCall(info);
    } else {
      await _schedule(
        id: notificationIdChamada,
        title: CheckinMessages.question(info.firstName),
        body: CheckinMessages.callBody(info.escalatesAt, info.contactNames),
        at: callAt,
        details: _callDetails(info),
      );
    }

    if (lastCallAt.isAfter(now)) {
      await _schedule(
        id: notificationIdUltimaChamada,
        title: CheckinMessages.lastCallTitle(info.firstName),
        body: CheckinMessages.lastCallBody(
          info.escalatesAt,
          info.contactNames,
        ),
        at: lastCallAt,
        details: _lastCallDetails(info),
      );
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime at,
    required NotificationDetails details,
  }) async {
    // Alarme exato primeiro; se o sistema negar, cai para os modos que não
    // exigem a permissão.
    for (final mode in const [
      AndroidScheduleMode.alarmClock,
      AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ]) {
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          at,
          details,
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        return;
      } catch (_) {
        // tenta o próximo modo
      }
    }
  }

  /// Mostra a chamada agora (o prazo venceu com o app aberto).
  Future<void> showCheckinCall(CheckinCallInfo info) async {
    try {
      await _plugin.show(
        notificationIdChamada,
        CheckinMessages.question(info.firstName),
        CheckinMessages.callBody(info.escalatesAt, info.contactNames),
        // A notificação agendada pode ter tocado no mesmo instante: não
        // repete o som.
        _callDetails(info, onlyAlertOnce: true),
      );
    } catch (_) {}
  }

  /// Mostra a última chamada agora.
  Future<void> showLastCall(CheckinCallInfo info) async {
    try {
      await _plugin.cancel(notificationIdChamada);
      await _plugin.show(
        notificationIdUltimaChamada,
        CheckinMessages.lastCallTitle(info.firstName),
        CheckinMessages.lastCallBody(info.escalatesAt, info.contactNames),
        _lastCallDetails(info),
      );
    } catch (_) {}
  }

  Future<void> cancelScheduledAlarm() async {
    try {
      await _plugin.cancel(notificationIdChamada);
      await _plugin.cancel(notificationIdUltimaChamada);
    } catch (_) {}
  }

  // ── Alerta ────────────────────────────────────────────────────────

  /// Os contatos foram avisados: diz o que foi feito e como cancelar.
  Future<void> showContactsAlerted({
    required int notified,
    required DateTime at,
    required bool withLocation,
  }) async {
    final body =
        '${CheckinMessages.alertedBody(notified: notified, at: at, withLocation: withLocation)} '
        'Se está tudo bem, abra o Vigi e cancele o pedido.';
    try {
      await _plugin.cancel(notificationIdChamada);
      await _plugin.cancel(notificationIdUltimaChamada);
      await _plugin.show(
        notificationIdAlerta,
        CheckinMessages.alertedTitle,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelIdAlerta,
            channelNameAlerta,
            channelDescription: channelDescAlerta,
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.alarm,
            icon: smallIcon,
            color: colorAlerta,
            fullScreenIntent: true,
            ongoing: true,
            autoCancel: false,
            visibility: NotificationVisibility.public,
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.critical,
          ),
        ),
      );
    } catch (_) {}
  }

  /// Push recebido com o app aberto: alguém que a pessoa acompanha pediu
  /// ajuda (o Android não mostra o push sozinho nesse caso).
  ///
  /// Com [allClear], é o aviso de que o pedido foi cancelado: substitui o
  /// alerta anterior e chega sem alarme, na cor da vigília.
  Future<void> showFamilyAlert({
    required String title,
    required String body,
    bool allClear = false,
  }) async {
    try {
      await _plugin.show(
        notificationIdFamilia,
        title,
        body,
        NotificationDetails(
          android: allClear
              ? AndroidNotificationDetails(
                  channelIdTudoBem,
                  channelNameTudoBem,
                  channelDescription: channelDescTudoBem,
                  icon: smallIcon,
                  color: colorVigilia,
                  visibility: NotificationVisibility.public,
                  styleInformation: BigTextStyleInformation(body),
                )
              : AndroidNotificationDetails(
                  channelIdAlerta,
                  channelNameAlerta,
                  channelDescription: channelDescAlerta,
                  importance: Importance.max,
                  priority: Priority.max,
                  icon: smallIcon,
                  color: colorAlerta,
                  visibility: NotificationVisibility.public,
                  styleInformation: BigTextStyleInformation(body),
                ),
        ),
      );
    } catch (_) {}
  }

  /// Remove chamada, última chamada e alerta (a pessoa respondeu).
  Future<void> cancelAlert() async {
    try {
      await _plugin.cancel(notificationIdChamada);
      await _plugin.cancel(notificationIdUltimaChamada);
      await _plugin.cancel(notificationIdAlerta);
    } catch (_) {}
  }

  /// Texto do horário para outros serviços (ex.: widget).
  static String clock(DateTime time) => VigiText.clock(time);
}
