import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/services/address_resolver.dart';
import 'package:guardiao/core/services/emergency_dispatcher.dart';
import 'package:guardiao/features/contacts/domain/entities/emergency_contact_entity.dart';
import 'package:guardiao/features/contacts/domain/repositories/contacts_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockContactsRepository extends Mock implements ContactsRepository {}

class FakeAddressResolver implements AddressResolver {
  @override
  Future<String?> near(double latitude, double longitude) async =>
      'Rua Augusta, 1200, Consolação';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('normalizePhone', () {
    test('celular com DDD vira formato internacional +55', () {
      expect(normalizePhone('(11) 98765-4321'), '+5511987654321');
    });

    test('fixo com DDD vira +55', () {
      expect(normalizePhone('11 3333-4444'), '+551133334444');
    });

    test('mantém número que já tem +', () {
      expect(normalizePhone('+55 11 98765-4321'), '+5511987654321');
    });

    test('remove zero de discagem à esquerda', () {
      expect(normalizePhone('011987654321'), '+5511987654321');
    });

    test('número de Portugal com código do país ganha o +', () {
      expect(normalizePhone('351920354190'), '+351920354190');
      expect(normalizePhone('+351 920 354 190'), '+351920354190');
    });

    test('aceita 55 sem o +', () {
      expect(normalizePhone('5511987654321'), '+5511987654321');
    });
  });

  group('mensagem para os contatos', () {
    final now = DateTime(2026, 9, 30, 14, 7);
    final shouting = RegExp(r'\b[A-ZÁÉÍÓÚÂÊÔÃÕÇ]{4,}\b');

    test('pânico: quem, o quê, quando, onde, o que fazer', () {
      final sms = buildEmergencySms(
        reason: EmergencyReason.panic,
        name: 'Lúcia',
        now: now,
        latitude: -23.55,
        longitude: -46.63,
      );
      expect(
        sms,
        'Vigi: Lúcia pediu ajuda às 14:07. '
        'Onde está: https://maps.google.com/?q=-23.55,-46.63 '
        'Ligue para Lúcia ou para o 192.',
      );
    });

    test('ausência de resposta: cita o check-in e o SAMU', () {
      final sms = buildEmergencySms(
        reason: EmergencyReason.checkinTimeout,
        name: 'Lúcia',
        now: DateTime(2026, 9, 30, 15, 15),
        deadline: DateTime(2026, 9, 30, 15),
        latitude: -23.55,
        longitude: -46.63,
      );
      expect(
        sms,
        'Vigi: Lúcia não respondeu ao check-in das 15:00. '
        'Última localização às 15:15: '
        'https://maps.google.com/?q=-23.55,-46.63 '
        'Tente ligar para Lúcia. Se não conseguir, chame ajuda (SAMU 192).',
      );
    });

    test('sem GPS, diz que a localização está indisponível', () {
      final sms = buildEmergencySms(
        reason: EmergencyReason.panic,
        name: 'Lúcia',
        now: now,
      );
      expect(sms, contains('Localização indisponível.'));
      expect(sms, isNot(contains('maps.google.com')));
    });

    test('cancelamento: quem recebeu o susto recebe o alívio', () {
      expect(
        buildAllClearSms(name: 'Lúcia', now: DateTime(2026, 9, 30, 14, 11)),
        'Vigi: Lúcia confirmou que está bem às 14:11. '
        'O pedido de ajuda foi cancelado.',
      );
    });

    test('nenhuma mensagem usa caixa alta nem o nome antigo', () {
      final messages = [
        buildEmergencySms(
          reason: EmergencyReason.panic,
          name: 'Lúcia',
          now: now,
          latitude: 1,
          longitude: 2,
        ),
        buildEmergencySms(
          reason: EmergencyReason.checkinTimeout,
          name: 'Lúcia',
          now: now,
          deadline: now,
        ),
        buildAllClearSms(name: 'Lúcia', now: now),
      ];
      for (final message in messages) {
        final text = message.replaceAll(RegExp(r'https?://\S+'), '');
        // "SAMU" é sigla, não grito.
        expect(
          shouting.allMatches(text).map((m) => m.group(0)).toSet()
            ..remove('SAMU'),
          isEmpty,
          reason: message,
        );
        expect(message.toLowerCase(), isNot(contains('guardi')));
        expect(message, startsWith('Vigi: '));
      }
    });

    test('sem nome, usa "Seu contato"', () {
      expect(
        buildEmergencySms(reason: EmergencyReason.panic, name: ' ', now: now),
        startsWith('Vigi: Seu contato pediu ajuda'),
      );
    });
  });

  group('EmergencyDispatcherImpl', () {
    const channel = MethodChannel('guardiao/emergency_sms');
    late MockContactsRepository contactsRepository;
    late List<MethodCall> calls;
    late Set<String> failingPhones;
    final now = DateTime(2026, 9, 30, 14, 7);

    const maria = EmergencyContactEntity(
      id: '1',
      userId: 'u',
      name: 'Maria',
      phone: '(11) 98765-4321',
    );
    const joao = EmergencyContactEntity(
      id: '2',
      userId: 'u',
      name: 'João',
      phone: '21 91234-5678',
    );

    EmergencyDispatcherImpl buildDispatcher() => EmergencyDispatcherImpl(
      contactsRepository: contactsRepository,
      addressResolver: FakeAddressResolver(),
      now: () => now,
    );

    setUp(() {
      contactsRepository = MockContactsRepository();
      calls = [];
      failingPhones = {};
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'send') {
              final args = call.arguments as Map<Object?, Object?>;
              final phones = (args['phones']! as List).cast<String>();
              return phones.where((p) => !failingPhones.contains(p)).length;
            }
            return true;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    List<String> sentPhones() => calls
        .where((c) => c.method == 'send')
        .expand(
          (c) => ((c.arguments as Map<Object?, Object?>)['phones']! as List)
              .cast<String>(),
        )
        .toList();

    test('envia SMS a cada contato, com o link da localização', () async {
      when(
        () => contactsRepository.getContacts(),
      ).thenAnswer((_) async => const Right([maria, joao]));

      final result = await buildDispatcher().dispatch(
        reason: EmergencyReason.panic,
        latitude: -23.55,
        longitude: -46.63,
      );

      expect(result.contactsFound, 2);
      expect(result.smsSent, 2);
      expect(result.sentAt, now);
      expect(result.address, 'Rua Augusta, 1200, Consolação');
      expect(sentPhones(), ['+5511987654321', '+5521912345678']);

      final message =
          (calls.firstWhere((c) => c.method == 'send').arguments
                  as Map<Object?, Object?>)['message']!
              as String;
      expect(message, contains('https://maps.google.com/?q=-23.55,-46.63'));
      expect(message, contains('pediu ajuda às 14:07'));
    });

    test('informa, contato a contato, se a mensagem saiu', () async {
      when(
        () => contactsRepository.getContacts(),
      ).thenAnswer((_) async => const Right([maria, joao]));
      failingPhones.add('+5521912345678');

      final result = await buildDispatcher().dispatch(
        reason: EmergencyReason.panic,
        latitude: -23.55,
        longitude: -46.63,
      );

      expect(result.smsSent, 1);
      expect(result.deliveries, const [
        ContactDelivery(name: 'Maria', phone: '+5511987654321', sent: true),
        ContactDelivery(name: 'João', phone: '+5521912345678', sent: false),
      ]);
    });

    test('não envia duas vezes para o mesmo número', () async {
      when(() => contactsRepository.getContacts()).thenAnswer(
        (_) async => const Right([
          maria,
          EmergencyContactEntity(
            id: '3',
            userId: 'u',
            name: 'Maria (celular)',
            phone: '+55 11 98765-4321',
          ),
        ]),
      );

      final result = await buildDispatcher().dispatch(
        reason: EmergencyReason.panic,
        latitude: 0,
        longitude: 0,
      );

      expect(result.contactsFound, 1);
      expect(sentPhones(), ['+5511987654321']);
    });

    test('sem contatos cadastrados não tenta enviar SMS', () async {
      when(
        () => contactsRepository.getContacts(),
      ).thenAnswer((_) async => const Right([]));

      final result = await buildDispatcher().dispatch(
        reason: EmergencyReason.checkinTimeout,
        latitude: 0,
        longitude: 0,
      );

      expect(result.contactsFound, 0);
      expect(result.smsSent, 0);
      expect(calls.where((c) => c.method == 'send'), isEmpty);
    });

    test(
      'dispatchAllClear avisa os mesmos contatos de que está tudo bem',
      () async {
        when(
          () => contactsRepository.getContacts(),
        ).thenAnswer((_) async => const Right([maria, joao]));

        final sent = await buildDispatcher().dispatchAllClear();

        expect(sent, 2);
        expect(sentPhones(), ['+5511987654321', '+5521912345678']);
        final message =
            (calls.firstWhere((c) => c.method == 'send').arguments
                    as Map<Object?, Object?>)['message']!
                as String;
        expect(message, contains('confirmou que está bem às 14:07'));
        expect(message, contains('O pedido de ajuda foi cancelado.'));
      },
    );

    test('hasSmsPermission consulta o lado nativo', () async {
      expect(await buildDispatcher().hasSmsPermission(), isTrue);
      expect(calls.single.method, 'hasPermission');
    });
  });

  group('GeocodingAddressResolver.formatPlacemark', () {
    test('rua, número e bairro', () {
      expect(
        GeocodingAddressResolver.formatPlacemark(
          street: 'Rua Augusta',
          number: '1200',
          neighborhood: 'Consolação',
          city: 'São Paulo',
        ),
        'Rua Augusta, 1200, Consolação',
      );
    });

    test('sem rua, usa o bairro e a cidade', () {
      expect(
        GeocodingAddressResolver.formatPlacemark(
          neighborhood: 'Consolação',
          city: 'São Paulo',
        ),
        'Consolação, São Paulo',
      );
    });

    test('sem nada útil, devolve nulo', () {
      expect(GeocodingAddressResolver.formatPlacemark(street: ' '), isNull);
    });
  });
}
