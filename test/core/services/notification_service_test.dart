import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/core/services/notification_service.dart';

void main() {
  group('NotificationService — Decisão Pura de Timeout em Background', () {
    final deadline = DateTime(2026, 8, 16, 14, 0, 0);

    test('retorna true quando o horário atual é exatamente o deadline', () {
      final currentTime = DateTime(2026, 8, 16, 14, 0, 0);
      final shouldTrigger = NotificationService.shouldTriggerAlert(
        nextDeadline: deadline,
        currentTime: currentTime,
      );

      expect(shouldTrigger, isTrue);
    });

    test('retorna true quando o horário atual já passou do deadline', () {
      final currentTime = DateTime(2026, 8, 16, 14, 0, 1);
      final shouldTrigger = NotificationService.shouldTriggerAlert(
        nextDeadline: deadline,
        currentTime: currentTime,
      );

      expect(shouldTrigger, isTrue);
    });

    test(
      'retorna false quando o horário atual ainda não atingiu o deadline',
      () {
        final currentTime = DateTime(2026, 8, 16, 13, 59, 59);
        final shouldTrigger = NotificationService.shouldTriggerAlert(
          nextDeadline: deadline,
          currentTime: currentTime,
        );

        expect(shouldTrigger, isFalse);
      },
    );

    test('canais possuem IDs e nomes corretos', () {
      expect(NotificationService.channelIdAlerta, equals('alerta_checkin'));
      expect(NotificationService.channelIdLembrete, equals('lembrete_checkin'));
    });
  });
}
