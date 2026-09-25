import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import 'notification_service.dart';

/// Canal 2 (ADR-001): push FCM para os familiares vinculados.
///
/// Registra o token FCM deste aparelho em `device_tokens` sempre que há sessão,
/// para que a Edge Function `notify-emergency-contacts` consiga alcançá-lo.
class PushService {
  PushService({
    required this.client,
    required this.notificationService,
  });

  final SupabaseClient client;
  final NotificationService notificationService;

  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (e) {
      AppLogger.error('Firebase não inicializado (google-services.json?)', e);
      return;
    }

    final messaging = FirebaseMessaging.instance;

    try {
      await messaging.requestPermission();
    } catch (_) {}

    // Com o app aberto o Android não exibe o push sozinho: exibimos no canal
    // de alerta de alta prioridade.
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      unawaited(
        notificationService.showTimeoutAlert(
          title: notification.title ?? 'ALERTA VIGI',
          body: notification.body ?? '',
        ),
      );
    });

    _tokenRefreshSub = messaging.onTokenRefresh.listen(_saveToken);

    _authSub = client.auth.onAuthStateChange.listen((data) async {
      if (data.session == null) return;
      try {
        final token = await messaging.getToken();
        if (token != null) await _saveToken(token);
      } catch (e) {
        AppLogger.warning('Falha ao obter token FCM', e);
      }
    });
  }

  Future<void> _saveToken(String token) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await client.from('device_tokens').upsert({
        'user_id': userId,
        'fcm_token': token,
        'platform': defaultTargetPlatform.name,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,fcm_token');
      AppLogger.info('Token FCM registrado para push de emergência.');
    } catch (e) {
      AppLogger.warning('Falha ao salvar token FCM', e);
    }
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
  }
}
