import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/core/utils/clock.dart';
import 'package:guardiao/core/utils/ticker.dart';

class FakeClock implements Clock {
  FakeClock(this.time);
  DateTime time;

  @override
  DateTime now() => time;
}

void main() {
  group('Ticker', () {
    test('Ticker instancia corretamente e gera Stream', () {
      const ticker = Ticker();
      final clock = FakeClock(DateTime(2026, 8, 15, 12));
      final deadline = DateTime(2026, 8, 15, 12, 0, 10);

      final stream = ticker.secondsUntil(deadline, clock: clock);
      expect(stream, isA<Stream<int>>());
    });
  });
}
