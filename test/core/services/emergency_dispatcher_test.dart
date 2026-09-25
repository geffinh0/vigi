import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/services/emergency_dispatcher.dart';
import 'package:guardiao/features/contacts/domain/entities/emergency_contact_entity.dart';
import 'package:guardiao/features/contacts/domain/repositories/contacts_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockContactsRepository extends Mock implements ContactsRepository {}

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

    test('aceita 55 sem o +', () {
      expect(normalizePhone('5511987654321'), '+5511987654321');
    });
  });

  group('EmergencyDispatcherImpl', () {
    const channel = MethodChannel('guardiao/emergency_sms');
    late MockContactsRepository contactsRepository;
    late List<MethodCall> calls;

    setUp(() {
      contactsRepository = MockContactsRepository();
      calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'send') {
              final args = call.arguments as Map<Object?, Object?>;
              return (args['phones']! as List).length;
            }
            return true;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('envia SMS a todos os contatos com o link da localização', () async {
      when(() => contactsRepository.getContacts()).thenAnswer(
        (_) async => const Right([
          EmergencyContactEntity(
            id: '1',
            userId: 'u',
            name: 'Maria',
            phone: '(11) 98765-4321',
          ),
          EmergencyContactEntity(
            id: '2',
            userId: 'u',
            name: 'João',
            phone: '21 91234-5678',
          ),
        ]),
      );

      final dispatcher = EmergencyDispatcherImpl(
        contactsRepository: contactsRepository,
      );
      final result = await dispatcher.dispatch(
        reason: EmergencyReason.panic,
        latitude: -23.55,
        longitude: -46.63,
      );

      expect(result.contactsFound, 2);
      expect(result.smsSent, 2);

      final send = calls.singleWhere((c) => c.method == 'send');
      final args = send.arguments as Map<Object?, Object?>;
      expect(args['phones'], ['+5511987654321', '+5521912345678']);
      final message = args['message']! as String;
      expect(message, contains('https://maps.google.com/?q=-23.55,-46.63'));
      expect(message, contains('BOTAO DE PANICO'));
    });

    test('sem contatos cadastrados não tenta enviar SMS', () async {
      when(
        () => contactsRepository.getContacts(),
      ).thenAnswer((_) async => const Right([]));

      final result =
          await EmergencyDispatcherImpl(
            contactsRepository: contactsRepository,
          ).dispatch(
            reason: EmergencyReason.checkinTimeout,
            latitude: 0,
            longitude: 0,
          );

      expect(result.contactsFound, 0);
      expect(result.smsSent, 0);
      expect(calls.where((c) => c.method == 'send'), isEmpty);
    });
  });
}
