import 'clock.dart';

/// Utilitário injetável para geração de pulsos de contagem regressiva em Stream.
class Ticker {
  const Ticker();

  /// Emite os segundos restantes até [deadline] a cada 1 segundo.
  Stream<int> secondsUntil(DateTime deadline, {required Clock clock}) {
    return Stream.periodic(const Duration(seconds: 1), (_) {
      final remaining = deadline.difference(clock.now()).inSeconds;
      return remaining < 0 ? 0 : remaining;
    }).takeWhile((seconds) => seconds >= 0);
  }
}
