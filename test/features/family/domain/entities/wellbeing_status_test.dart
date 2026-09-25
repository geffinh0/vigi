import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/features/family/domain/entities/monitoring_snapshot_entity.dart';
import 'package:guardiao/features/family/domain/entities/wellbeing_status.dart';
import 'package:guardiao/features/panic/domain/entities/panic_alert_entity.dart';

void main() {
  final now = DateTime(2026, 9, 26, 15);

  MonitoringSnapshotEntity snapshot({
    bool active = true,
    DateTime? deadline,
    DateTime? lastPing,
  }) => MonitoringSnapshotEntity(
    userId: 'u1',
    active: active,
    intervalMinutes: 60,
    nextDeadline: deadline,
    lastPing: lastPing,
  );

  PanicAlertEntity event(String type, DateTime at) => PanicAlertEntity(
    id: '$type-${at.millisecondsSinceEpoch}',
    userId: 'u1',
    eventType: type,
    latitude: -23.5,
    longitude: -46.6,
    createdAt: at,
  );

  group('WellbeingStatus.evaluate', () {
    test('monitoramento ativo dentro do prazo => está tudo bem', () {
      final s = WellbeingStatus.evaluate(
        snapshot: snapshot(
          deadline: now.add(const Duration(minutes: 30)),
          lastPing: now.subtract(const Duration(minutes: 30)),
        ),
        events: const [],
        now: now,
      );
      expect(s.level, WellbeingLevel.ok);
      expect(s.lastSignal, now.subtract(const Duration(minutes: 30)));
    });

    test('prazo vencido sem alerta ainda => check-in atrasado', () {
      final s = WellbeingStatus.evaluate(
        snapshot: snapshot(deadline: now.subtract(const Duration(minutes: 1))),
        events: const [],
        now: now,
      );
      expect(s.level, WellbeingLevel.late);
    });

    test('pânico sem confirmação posterior => emergência com localização', () {
      final s = WellbeingStatus.evaluate(
        snapshot: snapshot(deadline: now.add(const Duration(minutes: 30))),
        events: [
          event('checkin', now.subtract(const Duration(minutes: 20))),
          event('panic', now.subtract(const Duration(minutes: 5))),
        ],
        now: now,
      );
      expect(s.level, WellbeingLevel.emergency);
      expect(s.isPanic, isTrue);
      expect(s.alertEvent?.latitude, -23.5);
    });

    test('check-in depois do alerta => emergência encerrada', () {
      final s = WellbeingStatus.evaluate(
        snapshot: snapshot(deadline: now.add(const Duration(minutes: 50))),
        events: [
          event('alert_triggered', now.subtract(const Duration(minutes: 15))),
          event('checkin', now.subtract(const Duration(minutes: 10))),
        ],
        now: now,
      );
      expect(s.level, WellbeingLevel.ok);
    });

    test('alerta com mais de 24 h não fica preso como emergência', () {
      final s = WellbeingStatus.evaluate(
        snapshot: snapshot(active: false),
        events: [event('panic', now.subtract(const Duration(days: 2)))],
        now: now,
      );
      expect(s.level, WellbeingLevel.paused);
    });

    test('monitoramento desligado => pausado', () {
      final s = WellbeingStatus.evaluate(
        snapshot: snapshot(active: false),
        events: const [],
        now: now,
      );
      expect(s.level, WellbeingLevel.paused);
    });
  });
}
