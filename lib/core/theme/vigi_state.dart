import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'vigi_tokens.dart';

/// A escada de estados (Guia de Design, seção 9).
///
/// Cada momento do app está em um destes degraus, e cada degrau define ao
/// mesmo tempo cor, mascote, anel, texto, som e vibração. Nenhuma tela inventa
/// um estado próprio.
enum VigiState {
  /// Monitoramento pausado. Fica fora da escada: é o estado sem vigília.
  descansando,

  /// Monitoramento ativo, prazo distante. Silêncio.
  vigiando,

  /// O prazo chegou: o Vigi pergunta se está tudo bem.
  suaVez,

  /// Minutos finais da tolerância: alarme crescente, tela cheia.
  ultimaChamada,

  /// Contatos avisados (pânico ou ausência de resposta).
  alerta,

  /// Logo após confirmar ou cancelar um alerta. Dura 3 segundos.
  aliviado,

  /// Modo Sono ativo.
  noturno,
}

/// Forma dos olhos da coruja. Nenhum estado é comunicado só por cor.
enum VigiEyes {
  /// Fechados, em arco para baixo.
  closed,

  /// Abertos, pupilas ao centro.
  open,

  /// Arregalados, pupilas maiores.
  wide,

  /// Abertos, pupilas pequenas, sobrolho erguido.
  alert,

  /// Arcos para cima: o sorriso nos olhos.
  happy,

  /// Abertos, com brilho âmbar.
  glow,
}

/// Tudo o que um estado define visualmente. Telas e widgets leem daqui;
/// nenhum widget decide cor ou animação por conta própria.
@immutable
class VigiStateStyle {
  const VigiStateStyle({
    required this.ring,
    required this.halo,
    required this.eyes,
    required this.breath,
    required this.background,
    required this.eyeRing,
    required this.pupil,
    required this.brow,
    required this.beak,
    required this.onBackground,
    this.breathCurve = VigiMotion.breathCurve,
  });

  /// Cor do anel de vigília.
  final Color ring;

  /// Brilho atrás do anel e do mascote.
  final Color halo;

  final VigiEyes eyes;

  /// Um ciclo completo de respiração. `null` = sem respiração.
  final Duration? breath;
  final Curve breathCurve;

  /// Fundo da tela quando o estado ocupa a tela inteira.
  final Color background;

  /// Contorno dos olhos da coruja.
  final Color eyeRing;
  final Color pupil;
  final Color brow;
  final Color beak;

  /// Texto principal sobre [background].
  final Color onBackground;

  static const _light = <VigiState, VigiStateStyle>{
    VigiState.descansando: VigiStateStyle(
      ring: VigiColors.linho400,
      halo: Colors.transparent,
      eyes: VigiEyes.closed,
      breath: null,
      background: VigiColors.linho100,
      eyeRing: VigiColors.linho400,
      pupil: VigiColors.linho400,
      brow: VigiColors.linho400,
      beak: VigiColors.linho400,
      onBackground: VigiColors.petroleo800,
    ),
    VigiState.vigiando: VigiStateStyle(
      ring: VigiColors.petroleo800,
      halo: VigiColors.petroleo300,
      eyes: VigiEyes.open,
      breath: VigiMotion.breathCalm,
      background: VigiColors.linho100,
      eyeRing: VigiColors.petroleo800,
      pupil: VigiColors.petroleo800,
      brow: VigiColors.petroleo800,
      beak: VigiColors.ambar500,
      onBackground: VigiColors.petroleo800,
    ),
    VigiState.suaVez: VigiStateStyle(
      ring: VigiColors.ambar500,
      halo: VigiColors.ambar300,
      eyes: VigiEyes.wide,
      breath: VigiMotion.breathAttention,
      background: VigiColors.ambar100,
      eyeRing: VigiColors.ambar500,
      pupil: VigiColors.petroleo800,
      brow: VigiColors.petroleo800,
      beak: VigiColors.ambar500,
      onBackground: VigiColors.petroleo800,
    ),
    VigiState.ultimaChamada: VigiStateStyle(
      ring: VigiColors.ambar500,
      halo: VigiColors.ambar500,
      eyes: VigiEyes.wide,
      breath: VigiMotion.breathAttention,
      background: VigiColors.ambar300,
      // Sobre Âmbar 300 o contorno precisa escurecer para continuar visível.
      eyeRing: VigiColors.ambar700,
      pupil: VigiColors.petroleo800,
      brow: VigiColors.petroleo800,
      beak: VigiColors.ambar700,
      onBackground: VigiColors.petroleo800,
    ),
    VigiState.alerta: VigiStateStyle(
      ring: VigiColors.sinal500,
      halo: VigiColors.sinal500,
      eyes: VigiEyes.alert,
      breath: VigiMotion.breathAlert,
      breathCurve: VigiMotion.alertCurve,
      // Sinal 600, e não 500, para o texto branco passar em AA (5.3:1).
      background: VigiColors.sinal600,
      eyeRing: VigiColors.sinal500,
      pupil: VigiColors.sinal500,
      brow: VigiColors.sinal500,
      beak: VigiColors.sinal500,
      onBackground: VigiColors.branco,
    ),
    VigiState.aliviado: VigiStateStyle(
      ring: VigiColors.petroleo800,
      halo: VigiColors.petroleo300,
      eyes: VigiEyes.happy,
      breath: null,
      background: VigiColors.linho100,
      eyeRing: VigiColors.petroleo800,
      pupil: VigiColors.petroleo800,
      brow: VigiColors.petroleo800,
      beak: VigiColors.ambar500,
      onBackground: VigiColors.petroleo800,
    ),
    VigiState.noturno: VigiStateStyle(
      ring: VigiColors.ambar300,
      halo: VigiColors.ambar500,
      eyes: VigiEyes.glow,
      breath: VigiMotion.breathNight,
      background: VigiColors.petroleo900,
      eyeRing: VigiColors.ambar500,
      pupil: VigiColors.linho100,
      brow: VigiColors.petroleo300,
      beak: VigiColors.ambar500,
      onBackground: VigiColors.linho100,
    ),
  };

  /// Variações para o tema noturno. Chamada e alerta não mudam: uma
  /// emergência não respeita o modo escuro.
  static const _night = <VigiState, VigiStateStyle>{
    VigiState.descansando: VigiStateStyle(
      ring: VigiColors.petroleo500,
      halo: Colors.transparent,
      eyes: VigiEyes.closed,
      breath: null,
      background: VigiColors.petroleo900,
      eyeRing: VigiColors.petroleo500,
      pupil: VigiColors.petroleo500,
      brow: VigiColors.petroleo500,
      beak: VigiColors.petroleo500,
      onBackground: VigiColors.linho100,
    ),
    VigiState.vigiando: VigiStateStyle(
      ring: VigiColors.ambar300,
      halo: VigiColors.ambar500,
      eyes: VigiEyes.glow,
      breath: VigiMotion.breathCalm,
      background: VigiColors.petroleo900,
      eyeRing: VigiColors.ambar500,
      pupil: VigiColors.linho100,
      brow: VigiColors.petroleo300,
      beak: VigiColors.ambar500,
      onBackground: VigiColors.linho100,
    ),
    VigiState.aliviado: VigiStateStyle(
      ring: VigiColors.ambar300,
      halo: VigiColors.ambar500,
      eyes: VigiEyes.happy,
      breath: null,
      background: VigiColors.petroleo900,
      eyeRing: VigiColors.ambar500,
      pupil: VigiColors.linho100,
      brow: VigiColors.petroleo300,
      beak: VigiColors.ambar500,
      onBackground: VigiColors.linho100,
    ),
  };

  /// Estilo do estado [state] para o tema em uso.
  static VigiStateStyle of(
    VigiState state, {
    Brightness brightness = Brightness.light,
  }) {
    if (brightness == Brightness.dark) {
      return _night[state] ?? _light[state]!;
    }
    return _light[state]!;
  }
}

/// Nome do estado como a pessoa lê e como o leitor de tela anuncia.
extension VigiStateLabel on VigiState {
  String get label => switch (this) {
    VigiState.descansando => 'Descansando',
    VigiState.vigiando => 'Vigiando',
    VigiState.suaVez => 'Sua vez',
    VigiState.ultimaChamada => 'Última chamada',
    VigiState.alerta => 'Alerta',
    VigiState.aliviado => 'Aliviado',
    VigiState.noturno => 'Noturno',
  };

  /// Estados em que a tela inteira é tomada pela chamada ou pelo alerta.
  bool get isUrgent =>
      this == VigiState.suaVez ||
      this == VigiState.ultimaChamada ||
      this == VigiState.alerta;
}
