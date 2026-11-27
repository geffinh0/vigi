import 'package:flutter/material.dart';

/// Tipografia do Vigi (Guia de Design, seção 6).
///
/// - **Nunito** para títulos, números grandes e o logotipo.
/// - **Atkinson Hyperlegible** para todo o resto: foi desenhada pelo Braille
///   Institute para pessoas com baixa visão, com letras que não se confundem.
///
/// As fontes vão dentro do app (`assets/fonts`), então funcionam sem internet
/// desde a primeira abertura.
///
/// Os estilos não fixam cor: herdam a cor do tema (claro ou noturno). Nenhum
/// texto do app pode ficar abaixo de 14 sp ([caption]).
abstract final class AppTypography {
  static const String titleFamily = 'Nunito';
  static const String bodyFamily = 'Atkinson Hyperlegible';

  /// Algarismos tabulares: números que mudam (contador, horários) não
  /// "dançam" a cada segundo.
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  /// Tempo restante dentro do anel.
  static const TextStyle display = TextStyle(
    fontFamily: titleFamily,
    fontSize: 56,
    height: 60 / 56,
    fontWeight: FontWeight.w800,
    fontFeatures: tabular,
  );

  /// Pergunta principal ("Tudo bem por aí?").
  static const TextStyle h1 = TextStyle(
    fontFamily: titleFamily,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w800,
  );

  /// Título de tela.
  static const TextStyle h2 = TextStyle(
    fontFamily: titleFamily,
    fontSize: 26,
    height: 34 / 26,
    fontWeight: FontWeight.w700,
  );

  /// Título de card e seção.
  static const TextStyle h3 = TextStyle(
    fontFamily: titleFamily,
    fontSize: 21,
    height: 28 / 21,
    fontWeight: FontWeight.w700,
  );

  /// Texto padrão.
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 18,
    height: 28 / 18,
    fontWeight: FontWeight.w400,
  );

  /// Texto de apoio.
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
  );

  /// Botões.
  static const TextStyle label = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w700,
  );

  /// Mínimo absoluto: horários e metadados.
  static const TextStyle caption = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );

  /// Apelido de [label], mantido para o código anterior ao guia.
  static const TextStyle button = label;

  /// Tema de texto do Material montado a partir da escala acima.
  static TextTheme textTheme(Color color, Color muted) {
    TextStyle c(TextStyle s, [Color? override]) =>
        s.copyWith(color: override ?? color);
    return TextTheme(
      displayLarge: c(display),
      displayMedium: c(display),
      displaySmall: c(h1),
      headlineLarge: c(h1),
      headlineMedium: c(h2),
      headlineSmall: c(h3),
      titleLarge: c(h2),
      titleMedium: c(h3),
      titleSmall: c(label),
      bodyLarge: c(bodyLarge),
      bodyMedium: c(bodyMedium),
      bodySmall: c(caption, muted),
      labelLarge: c(label),
      labelMedium: c(caption),
      labelSmall: c(caption, muted),
    );
  }
}
