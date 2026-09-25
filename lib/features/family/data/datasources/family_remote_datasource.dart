import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../panic/data/models/panic_alert_model.dart';
import '../models/family_link_model.dart';
import '../models/monitoring_snapshot_model.dart';

abstract class FamilyRemoteDataSource {
  Future<List<FamilyLinkModel>> getFamilyLinks();

  /// Código VIGI curto do usuário logado (gerado na primeira consulta).
  Future<String> getMyLinkCode();

  /// Familiar pede para acompanhar a dona do código. Retorna o nome dela.
  Future<String> requestLinkByCode(String code);

  /// Somente a pessoa acompanhada autoriza ou recusa o pedido.
  Future<void> respondToLink({required String linkId, required bool accept});

  Future<void> removeLink(String linkId);

  /// Emite sempre que um vínculo do usuário muda (Realtime).
  Stream<void> watchLinksChanges();

  Stream<MonitoringSnapshotModel?> watchMonitoringSnapshot(String userId);

  Stream<List<PanicAlertModel>> watchMonitoredEvents(String monitoredUserId);

  /// Nomes dos modos de monitoramento visíveis (id -> nome).
  Future<Map<String, String>> getModeNames();
}

class FamilyRemoteDataSourceImpl implements FamilyRemoteDataSource {
  FamilyRemoteDataSourceImpl(this.client);

  final SupabaseClient client;

  User _requireUser() {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Usuário não autenticado.');
    return user;
  }

  @override
  Future<List<FamilyLinkModel>> getFamilyLinks() async {
    final user = _requireUser();

    final response = await client
        .from('family_links')
        .select(
          '*, monitored_user:profiles!family_links_monitored_user_id_fkey(full_name, phone), viewer_user:profiles!family_links_viewer_user_id_fkey(full_name)',
        )
        .or('monitored_user_id.eq.${user.id},viewer_user_id.eq.${user.id}')
        .neq('status', 'rejected')
        .order('created_at');

    return (response as List<dynamic>)
        .map((json) => FamilyLinkModel.fromMap(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<String> getMyLinkCode() async {
    _requireUser();
    final code = await client.rpc<String>('get_my_link_code');
    return code;
  }

  @override
  Future<String> requestLinkByCode(String code) async {
    _requireUser();
    final result = await client.rpc<Map<String, dynamic>>(
      'request_family_link',
      params: {'p_code': code},
    );
    return (result['monitored_name'] as String?)?.trim() ?? '';
  }

  @override
  Future<void> respondToLink({
    required String linkId,
    required bool accept,
  }) async {
    _requireUser();
    await client.rpc<void>(
      'respond_family_link',
      params: {'p_link_id': linkId, 'p_accept': accept},
    );
  }

  @override
  Future<void> removeLink(String linkId) async {
    _requireUser();
    await client.from('family_links').delete().eq('id', linkId);
  }

  @override
  Stream<void> watchLinksChanges() {
    return client.from('family_links').stream(primaryKey: ['id']).map((_) {});
  }

  @override
  Stream<MonitoringSnapshotModel?> watchMonitoringSnapshot(String userId) {
    return client
        .from('monitoring_settings')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map(
          (rows) =>
              rows.isEmpty ? null : MonitoringSnapshotModel.fromMap(rows.first),
        );
  }

  @override
  Stream<List<PanicAlertModel>> watchMonitoredEvents(String monitoredUserId) {
    return client
        .from('checkin_events')
        .stream(primaryKey: ['id'])
        .eq('user_id', monitoredUserId)
        .order('created_at', ascending: false)
        .limit(20)
        .map(
          (rows) => rows.map(PanicAlertModel.fromMap).toList(),
        );
  }

  @override
  Future<Map<String, String>> getModeNames() async {
    final rows = await client.from('monitoring_modes').select('id, name');
    return {
      for (final row in rows) row['id'] as String: row['name'] as String,
    };
  }
}
