import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Cores que mudam entre o tema claro e o noturno.
///
/// Telas e widgets leem daqui (`context.vigi`) em vez de usar [VigiColors]
/// direto, para que o modo Sono e o tema escuro do sistema funcionem sem
/// exceções espalhadas pelo código.
@immutable
class VigiPalette extends ThemeExtension<VigiPalette> {
  const VigiPalette({
    required this.background,
    required this.surface,
    required this.border,
    required this.track,
    required this.text,
    required this.textMuted,
    required this.fieldBorder,
    required this.chip,
    required this.fill,
    required this.onFill,
    required this.amberText,
    required this.icon,
  });

  /// Fundo das telas.
  final Color background;

  /// Cards e campos.
  final Color surface;

  /// Borda de cards e divisórias.
  final Color border;

  /// Trilho do anel.
  final Color track;

  /// Texto principal (7:1 ou mais sobre [background]).
  final Color text;

  /// Texto secundário e erros de formulário (4.5:1 ou mais).
  final Color textMuted;

  /// Borda de campos em repouso.
  final Color fieldBorder;

  /// Fundo de chips, avatares e seleção.
  final Color chip;

  /// Preenchimento de botões e itens ativos.
  final Color fill;

  /// Texto e ícones sobre [fill].
  final Color onFill;

  /// Âmbar legível como texto sobre [background].
  final Color amberText;

  /// Ícones secundários.
  final Color icon;

  static const light = VigiPalette(
    background: VigiColors.linho100,
    surface: VigiColors.linho50,
    border: VigiColors.linho200,
    track: VigiColors.linho200,
    text: VigiColors.petroleo800,
    textMuted: VigiColors.cinzaTexto,
    fieldBorder: VigiColors.linho400,
    chip: VigiColors.petroleo100,
    fill: VigiColors.petroleo800,
    onFill: VigiColors.linho100,
    amberText: VigiColors.ambar700,
    icon: VigiColors.petroleo500,
  );

  /// Tema noturno: a coruja no habitat dela. Sem branco puro, para quem
  /// acordar de madrugada e olhar o celular não ser ofuscado.
  static const night = VigiPalette(
    background: VigiColors.petroleo900,
    surface: VigiColors.petroleo800,
    border: VigiColors.petroleo700,
    track: VigiColors.petroleo700,
    text: VigiColors.linho100,
    textMuted: VigiColors.petroleo300,
    fieldBorder: VigiColors.petroleo500,
    chip: VigiColors.petroleo700,
    fill: VigiColors.linho100,
    onFill: VigiColors.petroleo900,
    amberText: VigiColors.ambar500,
    icon: VigiColors.petroleo300,
  );

  @override
  VigiPalette copyWith({
    Color? background,
    Color? surface,
    Color? border,
    Color? track,
    Color? text,
    Color? textMuted,
    Color? fieldBorder,
    Color? chip,
    Color? fill,
    Color? onFill,
    Color? amberText,
    Color? icon,
  }) {
    return VigiPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      track: track ?? this.track,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      fieldBorder: fieldBorder ?? this.fieldBorder,
      chip: chip ?? this.chip,
      fill: fill ?? this.fill,
      onFill: onFill ?? this.onFill,
      amberText: amberText ?? this.amberText,
      icon: icon ?? this.icon,
    );
  }

  @override
  VigiPalette lerp(ThemeExtension<VigiPalette>? other, double t) {
    if (other is! VigiPalette) return this;
    return VigiPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      track: Color.lerp(track, other.track, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      fieldBorder: Color.lerp(fieldBorder, other.fieldBorder, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
      fill: Color.lerp(fill, other.fill, t)!,
      onFill: Color.lerp(onFill, other.onFill, t)!,
      amberText: Color.lerp(amberText, other.amberText, t)!,
      icon: Color.lerp(icon, other.icon, t)!,
    );
  }
}

/// Atalhos para ler a paleta e saber em que tema a tela está.
extension VigiThemeContext on BuildContext {
  VigiPalette get vigi =>
      Theme.of(this).extension<VigiPalette>() ?? VigiPalette.light;

  bool get isNight => Theme.of(this).brightness == Brightness.dark;

  /// "Remover animações" ligado no sistema: a respiração para, o halo fica
  /// estático e a troca de estado vira um corte simples.
  bool get reduceMotion => MediaQuery.maybeOf(this)?.disableAnimations ?? false;
}
