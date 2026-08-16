import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import 'network_info.dart';

class SyncQueue {
  SyncQueue({
    required this.prefs,
    required this.networkInfo,
    required this.supabaseClient,
  }) {
    _initAutoDrain();
  }

  final SharedPreferences prefs;
  final NetworkInfo networkInfo;
  final SupabaseClient supabaseClient;

  static const _queueKey = 'guardiao_pending_events_queue';

  void _initAutoDrain() {
    networkInfo.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        drainQueue();
      }
    });
  }

  Future<void> enqueueEvent({
    required String eventType,
    double? latitude,
    double? longitude,
  }) async {
    final list = prefs.getStringList(_queueKey) ?? [];
    final eventMap = {
      'event_type': eventType,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    list.add(jsonEncode(eventMap));
    await prefs.setStringList(_queueKey, list);
    AppLogger.info('Evento enfileirado na fila offline: $eventType');
  }

  Future<int> drainQueue() async {
    final list = prefs.getStringList(_queueKey) ?? [];
    if (list.isEmpty) return 0;

    final user = supabaseClient.auth.currentUser;
    if (user == null) return 0;

    int drained = 0;
    final remaining = <String>[];

    for (final item in list) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        await supabaseClient.from('checkin_events').insert({
          'user_id': user.id,
          'event_type': map['event_type'],
          'latitude': map['latitude'],
          'longitude': map['longitude'],
          'created_at': map['created_at'],
        });
        drained++;
      } catch (e) {
        AppLogger.error('Falha ao descarregar item da fila offline', e);
        remaining.add(item);
      }
    }

    await prefs.setStringList(_queueKey, remaining);
    AppLogger.info('Fila offline descarregada: $drained eventos enviados.');
    return drained;
  }
}
