import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/features/checkin/domain/entities/checkin_schedule.dart';

void main() {
  group('CheckinSchedule', () {
    test('tolerância de 15 minutos nos modos padrão', () {
      expect(CheckinSchedule.graceFor(60), const Duration(minutes: 15));
      expect(CheckinSchedule.graceFor(20), const Duration(minutes: 15));
      expect(CheckinSchedule.graceFor(480), const Duration(minutes: 15));
    });

    test('a tolerância nunca é maior que o próprio intervalo', () {
      expect(CheckinSchedule.graceFor(5), const Duration(minutes: 5));
      expect(CheckinSchedule.graceFor(1), const Duration(minutes: 1));
      expect(CheckinSchedule.graceFor(0), const Duration(minutes: 1));
    });

    test('última chamada: 5 minutos finais da tolerância de 15', () {
      expect(
        CheckinSchedule.lastCallWindow(const Duration(minutes: 15)),
        const Duration(minutes: 5),
      );
      // Em tolerâncias curtas, o terço final.
      expect(
        CheckinSchedule.lastCallWindow(const Duration(minutes: 1)),
        const Duration(seconds: 20),
      );
    });

    test('exemplo do guia: Rotina de 1 h, prazo às 15:00', () {
      final deadline = DateTime(2026, 9, 30, 15);
      final grace = CheckinSchedule.graceFor(60);
      // Última chamada às 15:10, alerta às 15:15.
      expect(
        CheckinSchedule.lastCallAt(deadline, grace),
        DateTime(2026, 9, 30, 15, 10),
      );
      expect(
        CheckinSchedule.escalatesAt(deadline, grace),
        DateTime(2026, 9, 30, 15, 15),
      );
    });

    test('"Preciso de mais 10 minutos"', () {
      expect(CheckinSchedule.snooze, const Duration(minutes: 10));
    });
  });
}
