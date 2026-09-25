import 'package:flutter/material.dart';

/// Tokens centrais de cor do VIGI.
///
/// Paleta 60/30/10 definida no Stage 2 do design system.
/// Nenhuma cor deve ser usada hardcoded fora deste arquivo.
abstract final class AppColors {
  // ── 60 % Dominante — Fundo, superfícies ──────────────────────────
  static const linho = Color(0xFFF2EFE8);

  // ── 30 % Secundária — Texto, marca, navegação, mascote ──────────
  static const petroleo = Color(0xFF1F3D3B);

  // ── 10 % Destaque — Ações positivas, confirmações ───────────────
  static const ambar = Color(0xFFE8A33D);

  // ── Reservado — EXCLUSIVO de pânico / alerta ativo ──────────────
  /// Nunca usar em erro de formulário comum (use [cinzaTexto] pra isso).
  static const panico = Color(0xFFE24B4A);

  // ── Neutro — erros de form, texto secundário ────────────────────
  static const cinzaTexto = Color(0xFF5F5E5A);

  // ── Derivados ───────────────────────────────────────────────────
  /// Cards e superfícies sutilmente elevadas sobre [linho].
  static const linhoEscuro = Color(0xFFE5E1D8);

  /// Hover / estados intermediários do petróleo.
  static const petrolClaro = Color(0xFF2D5654);
}
