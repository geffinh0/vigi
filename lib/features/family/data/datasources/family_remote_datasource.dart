import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../panic/data/models/panic_alert_model.dart';
import '../models/family_link_model.dart';

abstract class FamilyRemoteDataSource {
  Future<List<FamilyLinkModel>> getFamilyLinks();

  Future<FamilyLinkModel> createInvite({required String viewerUserId});

  Future<void> acceptInvite({required String linkId});

  Stream<List<PanicAlertModel>> watchMonitoredEvents(String monitoredUserId);
}

class FamilyRemoteDataSourceImpl implements FamilyRemoteDataSource {
  FamilyRemoteDataSourceImpl(this.client);

  final SupabaseClient client;

  @override
  Future<List<FamilyLinkModel>> getFamilyLinks() async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Usuário não autenticado.');

    final response = await client
        .from('family_links')
        .select(
          '*, monitored_user:profiles!family_links_monitored_user_id_fkey(full_name), viewer_user:profiles!family_links_viewer_user_id_fkey(full_name)',
        )
        .or('monitored_user_id.eq.${user.id},viewer_user_id.eq.${user.id}');

    return (response as List<dynamic>)
        .map((json) => FamilyLinkModel.fromMap(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<FamilyLinkModel> createInvite({required String viewerUserId}) async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Usuário não autenticado.');

    final response = await client
        .from('family_links')
        .insert({
          'monitored_user_id': user.id,
          'viewer_user_id': viewerUserId,
          'status': 'pending',
        })
        .select()
        .single();

    return FamilyLinkModel.fromMap(response);
  }

  @override
  Future<void> acceptInvite({required String linkId}) async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Usuário não autenticado.');

    await client
        .from('family_links')
        .update({'status': 'accepted'})
        .eq('id', linkId)
        .eq('viewer_user_id', user.id);
  }

  @override
  Stream<List<PanicAlertModel>> watchMonitoredEvents(String monitoredUserId) {
    return client
        .from('checkin_events')
        .stream(primaryKey: ['id'])
        .eq('user_id', monitoredUserId)
        .order('created_at', ascending: false)
        .map(
          (rows) => rows.map((map) => PanicAlertModel.fromMap(map)).toList(),
        );
  }
}
