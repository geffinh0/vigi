import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/panic_alert_model.dart';

abstract class PanicRemoteDataSource {
  Future<PanicAlertModel> triggerPanic({
    double? latitude,
    double? longitude,
  });

  Future<void> resolvePanic();
}

class PanicRemoteDataSourceImpl implements PanicRemoteDataSource {
  PanicRemoteDataSourceImpl(this.client);

  final SupabaseClient client;

  @override
  Future<PanicAlertModel> triggerPanic({
    double? latitude,
    double? longitude,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Usuário não autenticado.');

    final response = await client
        .from('checkin_events')
        .insert({
          'user_id': user.id,
          'event_type': 'panic',
          'latitude': latitude,
          'longitude': longitude,
        })
        .select()
        .single();

    return PanicAlertModel.fromMap(response);
  }

  @override
  Future<void> resolvePanic() async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Usuário não autenticado.');

    await client.from('checkin_events').insert({
      'user_id': user.id,
      'event_type': 'alert_resolved',
    });
  }
}
