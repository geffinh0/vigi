/// Regras de tempo da escada de estados (Guia de Design, seção 9).
///
/// ```text
/// 14:00 a 15:00   15:00      15:10            15:15
/// Vigiando    →   Sua vez →  Última chamada → Alerta
/// ```
///
/// Exemplo com o modo Rotina (1 h): a tolerância é de 15 minutos e os 5
/// minutos finais são a última chamada.
abstract final class CheckinSchedule {
  /// Tolerância máxima entre o prazo e o aviso aos contatos.
  static const Duration maxGrace = Duration(minutes: 15);

  /// Duração máxima da "Última chamada".
  static const Duration maxLastCall = Duration(minutes: 5);

  /// "Preciso de mais 10 minutos": estende o prazo, uma vez por ciclo.
  static const Duration snooze = Duration(minutes: 10);

  /// Margem que o servidor espera além da tolerância antes de agir sozinho
  /// (ele só age se o aparelho não agiu: desligado, sem bateria, sem sinal).
  static const Duration serverMargin = Duration(minutes: 2);

  /// Quem abre o app com o prazo já vencido há muito tempo ganha ao menos
  /// este tempo para responder antes de os contatos serem avisados.
  static const Duration minimumResponse = Duration(seconds: 60);

  /// Tolerância para um intervalo de check-in.
  ///
  /// São 15 minutos, mas nunca mais que o próprio intervalo: em um modo de
  /// 5 minutos, esperar outros 15 para pedir ajuda triplicaria o tempo sem
  /// socorro. O servidor usa a mesma regra (`least(interval_minutes, 15)`).
  static Duration graceFor(int intervalMinutes) {
    final minutes = intervalMinutes.clamp(1, maxGrace.inMinutes);
    return Duration(minutes: minutes);
  }

  /// Quanto da tolerância é "Última chamada": o terço final, até 5 minutos.
  static Duration lastCallWindow(Duration grace) {
    final third = Duration(seconds: grace.inSeconds ~/ 3);
    return third > maxLastCall ? maxLastCall : third;
  }

  /// Quando os contatos são avisados, para um prazo vencido em [deadline].
  static DateTime escalatesAt(DateTime deadline, Duration grace) =>
      deadline.add(grace);

  /// Quando começa a "Última chamada".
  static DateTime lastCallAt(DateTime deadline, Duration grace) =>
      deadline.add(grace).subtract(lastCallWindow(grace));
}
