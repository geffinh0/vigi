import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/monitoring_mode_model.dart';
import '../models/monitoring_status_model.dart';

abstract class CheckinRemoteDataSource {
  Future<void> startMonitoring({
    required String modeId,
    required int intervalMinutes,
    required DateTime nextDeadline,
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

  @override
  Future<void> startMonitoring({
    required String modeId,
    required int intervalMinutes,
    required DateTime nextDeadline,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Usuário não autenticado.');

    final now = DateTime.now().toUtc();

    await client.from('monitoring_settings').upsert({
      'user_id': user.id,
      'active_mode_id': modeId,
      'interval_minutes': intervalMinutes,
      'active': true,
      'next_deadline': nextDeadline.toUtc().toIso8601String(),
      'last_ping': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    await client.from('checkin_events').insert({
      'user_id': user.id,
      'event_type': 'routine_start',
      'created_at': now.toIso8601String(),
    });
  }

  @override
  Future<List<MonitoringModeModel>> getAvailableModes() async {
    final response = await client
        .from('monitoring_modes')
        .select()
        .order('is_system_default', ascending: false)
        .order('created_at', ascending: true);

    return (response as List)
        .map((e) => MonitoringModeModel.fromMap(e as Map<String, dynamic>))
        .toList();
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

    final response = await client
        .from('monitoring_settings')
        .select('*, monitoring_modes(*)')
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) {
      return const MonitoringStatusModel(
        active: false,
        intervalMinutes: 60,
      );
    }

    return MonitoringStatusModel.fromMap(response);
  }
}
