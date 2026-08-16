import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/monitoring_mode_model.dart';
import '../models/monitoring_status_model.dart';

abstract class CheckinRemoteDataSource {
  Future<void> startMonitoring({
    required String modeId,
    required int intervalMinutes,
    required DateTime nextDeadline,
  });

  Future<void> saveSettings({
    required String modeId,
    required int intervalMinutes,
  });

  Future<List<MonitoringModeModel>> getAvailableModes();

  Future<MonitoringModeModel> createCustomMode({
    required String name,
    required int defaultIntervalMinutes,
    String? iconKey,
  });

  Future<void> confirmCheckin({
    required DateTime nextDeadline,
    double? latitude,
    double? longitude,
  });

  Future<void> stopMonitoring();

  Future<MonitoringStatusModel> getStatus();
}

class CheckinRemoteDataSourceImpl implements CheckinRemoteDataSource {
  CheckinRemoteDataSourceImpl(this.client);

  final SupabaseClient client;

  static const List<MonitoringModeModel> _defaultSystemModes = [
    MonitoringModeModel(
      id: 'system-default-routine',
      name: 'Rotina padrão',
      iconKey: 'routine',
      defaultIntervalMinutes: 60,
      isSystemDefault: true,
    ),
    MonitoringModeModel(
      id: 'system-default-shower',
      name: 'Banho',
      iconKey: 'shower',
      defaultIntervalMinutes: 20,
      isSystemDefault: true,
    ),
    MonitoringModeModel(
      id: 'system-default-sleep',
      name: 'Sono',
      iconKey: 'sleep',
      defaultIntervalMinutes: 480,
      isSystemDefault: true,
    ),
  ];

  @override
  Future<void> saveSettings({
    required String modeId,
    required int intervalMinutes,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Usuário não autenticado.');

    final now = DateTime.now().toUtc();

    final payload = <String, dynamic>{
      'user_id': user.id,
      'interval_minutes': intervalMinutes,
      'updated_at': now.toIso8601String(),
    };

    if (!modeId.startsWith('system-default')) {
      payload['active_mode_id'] = modeId;
    }

    try {
      await client.from('monitoring_settings').upsert(payload);
    } catch (_) {
      payload.remove('active_mode_id');
      await client.from('monitoring_settings').upsert(payload);
    }
  }

  @override
  Future<void> startMonitoring({
    required String modeId,
    required int intervalMinutes,
    required DateTime nextDeadline,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Usuário não autenticado.');

    final now = DateTime.now().toUtc();

    final payload = <String, dynamic>{
      'user_id': user.id,
      'interval_minutes': intervalMinutes,
      'active': true,
      'next_deadline': nextDeadline.toUtc().toIso8601String(),
      'last_ping': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    if (!modeId.startsWith('system-default')) {
      payload['active_mode_id'] = modeId;
    }

    try {
      await client.from('monitoring_settings').upsert(payload);
    } catch (_) {
      // Se a coluna active_mode_id ainda não existir no banco remoto
      payload.remove('active_mode_id');
      await client.from('monitoring_settings').upsert(payload);
    }

    try {
      await client.from('checkin_events').insert({
        'user_id': user.id,
        'event_type': 'routine_start',
        'created_at': now.toIso8601String(),
      });
    } catch (_) {}
  }

  @override
  Future<List<MonitoringModeModel>> getAvailableModes() async {
    try {
      final response = await client
          .from('monitoring_modes')
          .select()
          .order('is_system_default', ascending: false)
          .order('created_at', ascending: true);

      final list = (response as List)
          .map((e) => MonitoringModeModel.fromMap(e as Map<String, dynamic>))
          .toList();

      if (list.isNotEmpty) return list;
    } catch (_) {
      // Fallback para os modos do sistema se a tabela ainda não estiver populada
    }

    return _defaultSystemModes;
  }

  @override
  Future<MonitoringModeModel> createCustomMode({
    required String name,
    required int defaultIntervalMinutes,
    String? iconKey,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Usuário não autenticado.');

    final response = await client
        .from('monitoring_modes')
        .insert({
          'user_id': user.id,
          'name': name,
          'default_interval_minutes': defaultIntervalMinutes,
          'icon_key': iconKey,
          'is_system_default': false,
        })
        .select()
        .single();

    return MonitoringModeModel.fromMap(response);
  }

  @override
  Future<void> confirmCheckin({
    required DateTime nextDeadline,
    double? latitude,
    double? longitude,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Usuário não autenticado.');

    final now = DateTime.now().toUtc();

    await client
        .from('monitoring_settings')
        .update({
          'next_deadline': nextDeadline.toUtc().toIso8601String(),
          'last_ping': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        })
        .eq('user_id', user.id);

    await client.from('checkin_events').insert({
      'user_id': user.id,
      'event_type': 'checkin',
      'latitude': latitude,
      'longitude': longitude,
      'created_at': now.toIso8601String(),
    });
  }

  @override
  Future<void> stopMonitoring() async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Usuário não autenticado.');

    await client
        .from('monitoring_settings')
        .update({
          'active': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', user.id);
  }

  @override
  Future<MonitoringStatusModel> getStatus() async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Usuário não autenticado.');

    Map<String, dynamic>? response;
    try {
      response = await client
          .from('monitoring_settings')
          .select('*, monitoring_modes(*)')
          .eq('user_id', user.id)
          .maybeSingle();
    } catch (_) {
      try {
        response = await client
            .from('monitoring_settings')
            .select('*')
            .eq('user_id', user.id)
            .maybeSingle();
      } catch (_) {
        response = null;
      }
    }

    if (response == null) {
      return const MonitoringStatusModel(
        active: false,
        intervalMinutes: 60,
        activeModeId: 'system-default-routine',
      );
    }

    return MonitoringStatusModel.fromMap(response);
  }
}
