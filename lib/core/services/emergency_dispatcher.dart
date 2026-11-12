import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/contacts/domain/repositories/contacts_repository.dart';
import '../utils/location_helper.dart';
import '../utils/logger.dart';
import '../utils/vigi_text.dart';
import 'address_resolver.dart';

/// Motivo do disparo de emergência.
enum EmergencyReason { panic, checkinTimeout }

/// O que aconteceu com a mensagem de um contato.
class ContactDelivery extends Equatable {
  const ContactDelivery({
    required this.name,
    required this.phone,
    required this.sent,
  });

  final String name;
  final String phone;

  /// A operadora aceitou o SMS. Não garante que a pessoa já leu.
  final bool sent;

  @override
  List<Object?> get props => [name, phone, sent];
}

/// Resultado do disparo, usado para dizer à pessoa, sem enfeite, o que foi
/// feito: quem foi avisado, a que horas e com qual localização.
class EmergencyDispatchResult extends Equatable {
  const EmergencyDispatchResult({
    required this.contactsFound,
    required this.smsSent,
    this.latitude,
    this.longitude,
    this.deliveries = const [],
    this.sentAt,
    this.address,
  });

  final int contactsFound;
  final int smsSent;
  final double? latitude;
  final double? longitude;

  /// Um item por contato, na ordem em que foram avisados.
  final List<ContactDelivery> deliveries;
  final DateTime? sentAt;

  /// Endereço aproximado ("Rua Augusta, 1200, Consolação"), se disponível.
  final String? address;

  bool get hasLocation => latitude != null && longitude != null;

  @override
  List<Object?> get props => [
    contactsFound,
    smsSent,
    latitude,
    longitude,
    deliveries,
    sentAt,
    address,
  ];
}

/// Envia o alerta de emergência a todos os contatos cadastrados (dead man's
/// switch e botão de pânico). O canal principal é SMS nativo, que funciona
/// sem internet.
abstract class EmergencyDispatcher {
  /// [eventId] é o evento já registrado no Supabase (ex.: pânico), usado para
  /// o push aos familiares; no timeout o próprio dispatcher registra o evento.
  /// [deadline] é o horário do check-in que ficou sem resposta.
  Future<EmergencyDispatchResult> dispatch({
    required EmergencyReason reason,
    double? latitude,
    double? longitude,
    String? eventId,
    DateTime? deadline,
  });

  /// Avisa os mesmos contatos de que a pessoa está bem e o pedido de ajuda
  /// foi cancelado. Devolve quantos SMS saíram.
  Future<int> dispatchAllClear();

  Future<void> ensurePermissions();

  /// Sem a permissão de SMS o Vigi não consegue avisar ninguém sozinho.
  Future<bool> hasSmsPermission();

  /// Pede só a permissão de SMS (a tela "Permissões" pede uma de cada vez,
  /// cada qual com a sua explicação).
  Future<void> requestSmsPermission();
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

/// Link de mapa para a localização, o formato que qualquer celular abre.
String mapsLink(double latitude, double longitude) =>
    'https://maps.google.com/?q=$latitude,$longitude';

/// A mensagem que o contato recebe é a peça de texto mais importante do
/// sistema, porque vai ser lida por alguém assustado. Ela sempre tem, nesta
/// ordem: quem, o que aconteceu, quando, onde, o que fazer.
///
/// Sem caixa alta: caixa alta é mais lenta de ler e soa como grito.
String buildEmergencySms({
  required EmergencyReason reason,
  required String name,
  required DateTime now,
  DateTime? deadline,
  double? latitude,
  double? longitude,
}) {
  final who = name.trim().isEmpty ? 'Seu contato' : name.trim();
  final at = VigiText.clock(now);
  final hasLocation = latitude != null && longitude != null;
  final link = hasLocation ? mapsLink(latitude, longitude) : null;

  switch (reason) {
    case EmergencyReason.panic:
      final where = link == null
          ? 'Localização indisponível.'
          : 'Onde está: $link';
      return 'Vigi: $who pediu ajuda às $at. $where '
          'Ligue para $who ou para o 192.';
    case EmergencyReason.checkinTimeout:
      final when = deadline == null
          ? 'não respondeu ao check-in'
          : 'não respondeu ao check-in das ${VigiText.clock(deadline)}';
      final where = link == null
          ? 'Localização indisponível.'
          : 'Última localização às $at: $link';
      return 'Vigi: $who $when. $where Tente ligar para $who. '
          'Se não conseguir, chame ajuda (SAMU 192).';
  }
}

/// Mensagem de cancelamento: quem recebeu o susto também recebe o alívio.
String buildAllClearSms({required String name, required DateTime now}) {
  final who = name.trim().isEmpty ? 'Seu contato' : name.trim();
  return 'Vigi: $who confirmou que está bem às ${VigiText.clock(now)}. '
      'O pedido de ajuda foi cancelado.';
}

/// Dispara SMS nativo (canal `guardiao/emergency_sms`), registra o alerta e
/// aciona o push FCM aos familiares.
class EmergencyDispatcherImpl implements EmergencyDispatcher {
  EmergencyDispatcherImpl({
    required this.contactsRepository,
    this.client,
    this.addressResolver,
    MethodChannel? channel,
    DateTime Function()? now,
  }) : _channel = channel ?? const MethodChannel('guardiao/emergency_sms'),
       _now = now ?? DateTime.now;

  final ContactsRepository contactsRepository;
  final SupabaseClient? client;
  final AddressResolver? addressResolver;
  final MethodChannel _channel;
  final DateTime Function() _now;

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
  Future<void> requestSmsPermission() async {
    try {
      await _channel.invokeMethod<bool>('requestSmsPermission');
    } catch (_) {
      // Versão nativa antiga ou plataforma sem SMS: usa o pedido conjunto.
      await ensurePermissions();
    }
  }

  @override
  Future<bool> hasSmsPermission() async {
    try {
      return await _channel.invokeMethod<bool>('hasPermission') ?? false;
    } catch (_) {
      // Sem o canal nativo não há como saber; não acusa um problema que o
      // app não consegue resolver.
      return true;
    }
  }

  String get _firstName {
    final meta = client?.auth.currentUser?.userMetadata;
    return VigiText.firstName(meta?['full_name'] as String?);
  }

  Future<List<({String name, String phone})>> _recipients() async {
    final contactsResult = await contactsRepository.getContacts();
    return contactsResult.fold(
      (failure) {
        AppLogger.error('Falha ao carregar contatos: ${failure.message}');
        return <({String name, String phone})>[];
      },
      (contacts) {
        final seen = <String>{};
        final list = <({String name, String phone})>[];
        for (final c in contacts) {
          final phone = normalizePhone(c.phone);
          if (phone.isEmpty || !seen.add(phone)) continue;
          list.add((name: c.name, phone: phone));
        }
        return list;
      },
    );
  }

  /// Envia [message] a cada destinatário, um por vez, para saber exatamente
  /// quem foi avisado.
  Future<List<ContactDelivery>> _sendToAll(
    List<({String name, String phone})> recipients,
    String message,
  ) async {
    final deliveries = <ContactDelivery>[];
    for (final r in recipients) {
      var sent = false;
      try {
        final count =
            await _channel.invokeMethod<int>('send', {
              'phones': [r.phone],
              'message': message,
            }) ??
            0;
        sent = count > 0;
      } catch (e) {
        AppLogger.error('Erro no envio nativo de SMS', e);
      }
      deliveries.add(ContactDelivery(name: r.name, phone: r.phone, sent: sent));
    }
    return deliveries;
  }

  @override
  Future<EmergencyDispatchResult> dispatch({
    required EmergencyReason reason,
    double? latitude,
    double? longitude,
    String? eventId,
    DateTime? deadline,
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

    final recipients = await _recipients();
    final sentAt = _now();

    if (recipients.isEmpty) {
      AppLogger.warning('Nenhum contato de emergência cadastrado.');
      await pushFuture;
      return EmergencyDispatchResult(
        contactsFound: 0,
        smsSent: 0,
        latitude: lat,
        longitude: lng,
        sentAt: sentAt,
      );
    }

    final message = buildEmergencySms(
      reason: reason,
      name: _firstName,
      now: sentAt,
      deadline: deadline,
      latitude: lat,
      longitude: lng,
    );

    final deliveries = await _sendToAll(recipients, message);
    final sent = deliveries.where((d) => d.sent).length;

    // Sem permissão de SMS (ou plataforma sem suporte): abre o app de mensagens
    // já preenchido como última alternativa.
    if (sent == 0) {
      final phones = recipients.map((r) => r.phone).join(',');
      final uri = Uri.parse('sms:$phones?body=${Uri.encodeComponent(message)}');
      try {
        await launchUrl(uri);
      } catch (_) {}
    }

    // O endereço é só para a tela: vem depois, para nunca atrasar o SMS.
    String? address;
    if (lat != null && lng != null) {
      address = await addressResolver?.near(lat, lng);
    }

    await pushFuture;
    return EmergencyDispatchResult(
      contactsFound: recipients.length,
      smsSent: sent,
      latitude: lat,
      longitude: lng,
      deliveries: deliveries,
      sentAt: sentAt,
      address: address,
    );
  }

  @override
  Future<int> dispatchAllClear() async {
    final recipients = await _recipients();
    if (recipients.isEmpty) return 0;
    final message = buildAllClearSms(name: _firstName, now: _now());
    final deliveries = await _sendToAll(recipients, message);
    return deliveries.where((d) => d.sent).length;
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
}
