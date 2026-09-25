import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/contacts/domain/repositories/contacts_repository.dart';
import '../utils/location_helper.dart';
import '../utils/logger.dart';

enum EmergencyReason { panic, checkinTimeout }

/// Resultado do disparo, usado para dar feedback honesto ao usuário.
class EmergencyDispatchResult {
  const EmergencyDispatchResult({
    required this.contactsFound,
    required this.smsSent,
    this.latitude,
    this.longitude,
  });

  final int contactsFound;
  final int smsSent;
  final double? latitude;
  final double? longitude;
}

/// Envia o alerta de emergência a todos os contatos cadastrados (dead man's switch
/// e botão de pânico). O canal principal é SMS nativo, que funciona sem internet.
abstract class EmergencyDispatcher {
  /// [eventId] é o evento já registrado no Supabase (ex.: pânico), usado para
  /// o push aos familiares; no timeout o próprio dispatcher registra o evento.
  Future<EmergencyDispatchResult> dispatch({
    required EmergencyReason reason,
    double? latitude,
    double? longitude,
    String? eventId,
  });

  Future<void> ensurePermissions();
}

/// Converte telefones digitados livremente para o formato internacional
/// (+55...), que a operadora entrega de forma confiável.
String normalizePhone(String raw) {
  var p = raw.replaceAll(RegExp(r'[^\d+]'), '');
  if (p.startsWith('+')) return p;
  if (p.startsWith('00')) return '+${p.substring(2)}';
  p = p.replaceFirst(RegExp('^0+'), '');
  // Brasil sem o código do país (DDD + número)
  if (p.length == 10 || p.length == 11) return '+55$p';
  // Já contém o código do país (ex.: 5511..., 351920...)
  if (p.length >= 12) return '+$p';
  return p;
}

class EmergencyDispatcherImpl implements EmergencyDispatcher {
  EmergencyDispatcherImpl({
    required this.contactsRepository,
    this.client,
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel('guardiao/emergency_sms');

  final ContactsRepository contactsRepository;
  final SupabaseClient? client;
  final MethodChannel _channel;

  @override
  Future<void> ensurePermissions() async {
    try {
      // Solicita SMS + localização juntos no lado nativo.
      await _channel.invokeMethod<bool>('requestPermission');
    } catch (_) {
      // Plataformas sem o canal nativo (ex.: iOS/web): ao menos a localização.
      await LocationHelper.ensurePermission();
    }
  }

  @override
  Future<EmergencyDispatchResult> dispatch({
    required EmergencyReason reason,
    double? latitude,
    double? longitude,
    String? eventId,
  }) async {
    var lat = latitude;
    var lng = longitude;
    if (lat == null || lng == null) {
      final position = await LocationHelper.currentPositionOrNull();
      lat = position?.latitude;
      lng = position?.longitude;
    }

    var alertEventId = eventId;
    if (reason == EmergencyReason.checkinTimeout) {
      alertEventId = await _recordAlertEvent(lat: lat, lng: lng);
    }

    // Canal 2: push FCM aos familiares (em paralelo ao SMS). O gatilho do banco
    // já dispara o push; esta chamada é um reforço e a função evita duplicidade.
    final pushFuture = _notifyFamilyByPush(alertEventId);

    final contactsResult = await contactsRepository.getContacts();
    final phones = contactsResult.fold(
      (failure) {
        AppLogger.error('Falha ao carregar contatos: ${failure.message}');
        return <String>[];
      },
      (contacts) => contacts
          .map((c) => normalizePhone(c.phone))
          .where((p) => p.isNotEmpty)
          .toSet()
          .toList(),
    );

    if (phones.isEmpty) {
      AppLogger.warning('Nenhum contato de emergência cadastrado.');
      await pushFuture;
      return EmergencyDispatchResult(
        contactsFound: 0,
        smsSent: 0,
        latitude: lat,
        longitude: lng,
      );
    }

    final message = _buildMessage(reason: reason, lat: lat, lng: lng);

    var sent = 0;
    try {
      sent =
          await _channel.invokeMethod<int>('send', {
            'phones': phones,
            'message': message,
          }) ??
          0;
    } catch (e) {
      AppLogger.error('Erro no envio nativo de SMS', e);
    }

    // Sem permissão de SMS (ou plataforma sem suporte): abre o app de mensagens
    // já preenchido como última alternativa.
    if (sent == 0) {
      final uri = Uri.parse(
        'sms:${phones.join(',')}?body=${Uri.encodeComponent(message)}',
      );
      try {
        await launchUrl(uri);
      } catch (_) {}
    }

    await pushFuture;
    return EmergencyDispatchResult(
      contactsFound: phones.length,
      smsSent: sent,
      latitude: lat,
      longitude: lng,
    );
  }

  /// Chama a Edge Function que envia push FCM aos familiares vinculados.
  Future<void> _notifyFamilyByPush(String? eventId) async {
    if (eventId == null || client?.auth.currentSession == null) return;
    try {
      await client!.functions
          .invoke('notify-emergency-contacts', body: {'event_id': eventId})
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      AppLogger.warning('Falha ao enviar push aos familiares', e);
    }
  }

  /// Registra o alerta no histórico (visível ao painel da família). Falhas de
  /// rede não podem impedir o envio do SMS, por isso são apenas registradas.
  Future<String?> _recordAlertEvent({double? lat, double? lng}) async {
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return null;
    try {
      final row = await client!
          .from('checkin_events')
          .insert({
            'user_id': userId,
            'event_type': 'alert_triggered',
            'latitude': lat,
            'longitude': lng,
          })
          .select('id')
          .single();
      return row['id'] as String?;
    } catch (e) {
      AppLogger.warning('Não foi possível registrar o alerta no servidor', e);
      return null;
    }
  }

  String _buildMessage({
    required EmergencyReason reason,
    double? lat,
    double? lng,
  }) {
    final meta = client?.auth.currentUser?.userMetadata;
    final name = (meta?['full_name'] as String?)?.trim();
    final who = (name == null || name.isEmpty) ? 'Seu contato' : name;

    final now = DateTime.now();
    final hora =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final motivo = switch (reason) {
      EmergencyReason.panic => 'acionou o BOTAO DE PANICO',
      EmergencyReason.checkinTimeout =>
        'NAO confirmou que esta bem no prazo combinado',
    };

    final local = (lat != null && lng != null)
        ? 'Localizacao: https://maps.google.com/?q=$lat,$lng'
        : 'Localizacao indisponivel.';

    return 'ALERTA VIGI: $who $motivo ($hora). $local '
        'Tente contato imediatamente.';
  }
}
