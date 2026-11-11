import '../utils/vigi_text.dart';

/// O que o Vigi precisa saber para chamar a pessoa: quem é, quem será
/// avisado e a que horas cada degrau acontece.
class CheckinCallInfo {
  const CheckinCallInfo({
    required this.deadline,
    required this.lastCallAt,
    required this.escalatesAt,
    this.firstName = '',
    this.contactNames = const [],
    this.canSnooze = true,
  });

  /// Quando o check-in vence ("Sua vez").
  final DateTime deadline;

  /// Quando a tolerância entra nos minutos finais ("Última chamada").
  final DateTime lastCallAt;

  /// Quando os contatos serão avisados ("Alerta").
  final DateTime escalatesAt;

  final String firstName;
  final List<String> contactNames;

  /// "Preciso de mais 10 minutos" só pode ser usado uma vez por ciclo.
  final bool canSnooze;
}

/// Textos da escada de estados (Guia de Design, seções 9 e 13).
///
/// Regra de tom: em "Vigiando" o texto é quase invisível e informativo; em
/// "Sua vez" é uma pergunta gentil; em "Alerta" é concreto e tranquilizador
/// (o que foi feito, quem foi avisado, o que acontece agora). A tela sempre
/// diz o que vem a seguir, quando, e como evitar.
abstract final class CheckinMessages {
  /// A pergunta humana no lugar de "check-in expirado".
  static String question(String firstName) {
    final name = firstName.trim();
    return name.isEmpty ? 'Tudo bem por aí?' : 'Tudo bem por aí, $name?';
  }

  /// O próximo degrau, por extenso, na tela de chamada.
  static String consequence(DateTime escalatesAt, List<String> contactNames) =>
      'Se você não responder até ${VigiText.clock(escalatesAt)}, '
      'vamos avisar ${VigiText.joinNames(contactNames)}.';

  /// Corpo da notificação de chamada.
  static String callBody(DateTime escalatesAt, List<String> contactNames) =>
      'Toque em Estou bem. Se não responder até '
      '${VigiText.clock(escalatesAt)}, avisamos '
      '${VigiText.joinNames(contactNames)}.';

  static String lastCallTitle(String firstName) {
    final name = firstName.trim();
    return name.isEmpty ? 'Última chamada' : 'Última chamada, $name';
  }

  static String lastCallBody(
    DateTime escalatesAt,
    List<String> contactNames,
  ) =>
      'Às ${VigiText.clock(escalatesAt)} vamos avisar '
      '${VigiText.joinNames(contactNames)}. Toque em Estou bem.';

  static const String alertedTitle = 'Pedimos ajuda por você';

  /// O que foi feito, para quem e quando.
  static String alertedBody({
    required int notified,
    required DateTime at,
    required bool withLocation,
  }) {
    if (notified == 0) {
      return 'Não conseguimos avisar ninguém por SMS. '
          'Se puder, ligue para alguém de confiança ou para o 192.';
    }
    final who = notified == 1
        ? 'Avisamos 1 pessoa'
        : 'Avisamos $notified pessoas';
    final where = withLocation ? ' com a sua localização' : '';
    return '$who às ${VigiText.clock(at)}$where.';
  }

  /// "Obrigado. Próximo check-in às 16:00."
  static String relief(DateTime nextDeadline, {bool afterAlert = false}) {
    final base =
        'Obrigado. Próximo check-in às ${VigiText.clock(nextDeadline)}.';
    return afterAlert
        ? '$base Avisamos seus contatos de que está tudo bem.'
        : base;
  }

  static String nextCheckin(DateTime deadline) =>
      'Próximo check-in às ${VigiText.clock(deadline)}.';

  /// Quem está de vigília: "Maria e João estão de vigília com você".
  static String watching(List<String> contactNames) {
    final names = contactNames
        .map(VigiText.firstName)
        .where((n) => n.isNotEmpty);
    if (names.isEmpty) return 'Ninguém está de vigília com você ainda';
    final verb = names.length == 1 ? 'está' : 'estão';
    return '${VigiText.joinNames(contactNames)} $verb de vigília com você';
  }

  /// Texto do modo ativo: "Rotina, a cada 1 h", "Sono, até 7:00".
  static String modeChip({
    required String modeName,
    required int intervalMinutes,
    required bool isSleep,
    DateTime? deadline,
  }) {
    if (isSleep && deadline != null) {
      return '$modeName, até ${VigiText.clock(deadline)}';
    }
    return '$modeName, a cada ${VigiText.interval(intervalMinutes)}';
  }
}
