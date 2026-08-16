import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tokens de tipografia centralizados.
///
/// - **Corpo/UI:** Atkinson Hyperlegible (legibilidade para baixa visão).
/// - **Títulos/Logo:** Nunito (arredondada, acolhedora).
abstract final class AppTypography {
  // ── Títulos — Nunito ─────────────────────────────────────────────
  static TextStyle get h1 => GoogleFonts.nunito(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.petroleo,
    height: 1.2,
  );

  static TextStyle get h2 => GoogleFonts.nunito(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.petroleo,
    height: 1.25,
  );

  static TextStyle get h3 => GoogleFonts.nunito(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.petroleo,
    height: 1.3,
  );

  // ── Corpo — Atkinson Hyperlegible ────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.atkinsonHyperlegible(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.petroleo,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.atkinsonHyperlegible(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.cinzaTexto,
    height: 1.4,
  );

  static TextStyle get bodySmall => GoogleFonts.atkinsonHyperlegible(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.cinzaTexto,
    height: 1.4,
  );

  // ── Componentes & Botões ─────────────────────────────────────────
  static TextStyle get button => GoogleFonts.atkinsonHyperlegible(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.petroleo,
    letterSpacing: 0.5,
  );

  static TextStyle get caption => GoogleFonts.atkinsonHyperlegible(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.cinzaTexto,
    letterSpacing: 0.3,
  );
}
