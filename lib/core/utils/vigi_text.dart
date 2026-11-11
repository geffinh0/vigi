/// Textos e formatos do Vigi (Guia de Design, seção 13).
///
/// O Vigi fala como um vizinho atento: próximo, calmo e direto. Trata a pessoa
/// pelo primeiro nome, usa frases curtas e mostra horário absoluto sempre que
/// pode: "38 min" exige cálculo, "até 15:00" não.
abstract final class VigiText {
  /// Primeiro nome, para tratar a pessoa como um vizinho trataria.
  static String firstName(String? fullName) {
    final name = (fullName ?? '').trim();
    if (name.isEmpty) return '';
    return name.split(RegExp(r'\s+')).first;
  }

  /// Iniciais para avatares: "Maria Silva" vira "MS", "João" vira "J".
  static String initials(String? name) {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  /// Lista de nomes como se fala: "Maria", "Maria e João",
  /// "Maria, João e Ana", "Maria, João e mais 2 pessoas".
  ///
  /// Sem nomes, usa [empty] ("seus contatos").
  static String joinNames(
    Iterable<String> names, {
    String empty = 'seus contatos',
  }) {
    final list = names
        .map(firstName)
        .where((n) => n.isNotEmpty)
        .toList(growable: false);
    switch (list.length) {
      case 0:
        return empty;
      case 1:
        return list.first;
      case 2:
        return '${list[0]} e ${list[1]}';
      case 3:
        return '${list[0]}, ${list[1]} e ${list[2]}';
      default:
        return '${list[0]}, ${list[1]} e mais ${list.length - 2} pessoas';
    }
  }

  /// Saudação pela hora do dia.
  static String greeting(DateTime now, [String? firstName]) {
    final hello = switch (now.hour) {
      >= 5 && < 12 => 'Bom dia',
      >= 12 && < 18 => 'Boa tarde',
      _ => 'Boa noite',
    };
    final name = (firstName ?? '').trim();
    return name.isEmpty ? hello : '$hello, $name';
  }

  /// Horário absoluto: "15:00", "7:05".
  static String clock(DateTime time) {
    final t = time.toLocal();
    return '${t.hour}:${t.minute.toString().padLeft(2, '0')}';
  }

  /// Horário alinhado em coluna, para linhas do tempo: "08:10".
  static String clockPadded(DateTime time) {
    final t = time.toLocal();
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  /// Horário por extenso, para o leitor de tela: "15 horas",
  /// "15 horas e 5 minutos".
  static String clockSpoken(DateTime time) {
    final t = time.toLocal();
    final hours = t.hour == 1 ? '1 hora' : '${t.hour} horas';
    if (t.minute == 0) return hours;
    final minutes = t.minute == 1 ? '1 minuto' : '${t.minute} minutos';
    return '$hours e $minutes';
  }

  /// Tempo restante dentro do anel: "38 min", "1 h 20", "45 s".
  static String remaining(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    if (s < 60) return '$s s';
    // Arredonda para cima: enquanto faltar tempo, nunca mostra "0 min".
    final minutes = (s / 60).ceil();
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')}';
  }

  /// Tempo restante por extenso: "38 minutos", "1 hora e 20 minutos".
  static String remainingSpoken(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    if (s < 60) return s == 1 ? '1 segundo' : '$s segundos';
    final minutes = (s / 60).ceil();
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final hours = h == 1 ? '1 hora' : '$h horas';
    final mins = m == 1 ? '1 minuto' : '$m minutos';
    if (h == 0) return mins;
    return m == 0 ? hours : '$hours e $mins';
  }

  /// Intervalo de um modo: "20 min", "1 h", "8 h", "1 h 30".
  static String interval(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')}';
  }

  /// Frase do anel para o leitor de tela.
  static String ringSpoken(DateTime deadline, int remainingSeconds) =>
      'Próximo check-in às ${clockSpoken(deadline)}, '
      'daqui a ${remainingSpoken(remainingSeconds)}';

  /// "1 pessoa" ou "3 pessoas".
  static String people(int count) => count == 1 ? '1 pessoa' : '$count pessoas';
}
