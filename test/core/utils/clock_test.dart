import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/core/utils/clock.dart';

class FakeClock implements Clock {
  FakeClock(this._now);
  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration duration) {
    _now = _now.add(duration);
  }
}

void main() {
  group('Clock', () {
    test('SystemClock retorna o horário atual do sistema', () {
      const clock = SystemClock();
      final before = DateTime.now();
      final now = clock.now();
      final after = DateTime.now();

      expect(
        now.isAfter(before.subtract(const Duration(milliseconds: 50))),
        isTrue,
      );
      expect(now.isBefore(after.add(const Duration(milliseconds: 50))), isTrue);
    });

    test('FakeClock permite controle determinístico do tempo em testes', () {
      final baseTime = DateTime(2026, 8, 15, 12);
      final fakeClock = FakeClock(baseTime);

      expect(fakeClock.now(), baseTime);
      fakeClock.advance(const Duration(minutes: 15));
      expect(fakeClock.now(), baseTime.add(const Duration(minutes: 15)));
    });
  });
}
