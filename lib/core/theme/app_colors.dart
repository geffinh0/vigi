import 'package:flutter/material.dart';

/// Tokens de cor do Vigi (Guia de Design, seção 5).
///
/// Cada cor tem uma função e apenas uma:
/// - **Petróleo** é a vigília: texto, marca, navegação e o estado normal.
/// - **Âmbar** é a sua vez: a pessoa precisa fazer algo agora.
/// - **Sinal** é socorro: só aparece quando contatos estão sendo avisados.
/// - **Linho** é o chão: fundos e superfícies.
///
/// Nenhuma cor deve ser escrita à mão fora deste arquivo.
abstract final class VigiColors {
  // ── Petróleo: a vigília ──────────────────────────────────────────
  /// Fundo do tema noturno.
  static const petroleo900 = Color(0xFF0F2221);

  /// Petróleo base: texto, marca, anel normal.
  static const petroleo800 = Color(0xFF1F3D3B);

  /// Estado pressionado.
  static const petroleo700 = Color(0xFF2D5654);

  /// Ícones secundários, bordas ativas.
  static const petroleo500 = Color(0xFF4E7C79);

  /// Texto secundário no tema noturno.
  static const petroleo300 = Color(0xFF9DBAB7);

  /// Fundo de chips e seleção.
  static const petroleo100 = Color(0xFFDDE8E6);

  // ── Âmbar: a sua vez ─────────────────────────────────────────────
  /// Âmbar para texto sobre fundo claro (5.2:1 sobre Linho 100).
  static const ambar700 = Color(0xFF8A5A0F);

  /// Âmbar base: botão "Estou bem", anel "Sua vez".
  static const ambar500 = Color(0xFFE8A33D);

  /// Brilho, halos, âmbar no tema noturno.
  static const ambar300 = Color(0xFFF4CB8A);

  /// Fundo de avisos "sua vez".
  static const ambar100 = Color(0xFFFBEBD0);

  // ── Sinal: socorro (exclusivo) ───────────────────────────────────
  /// Texto vermelho sobre fundo claro.
  static const sinal700 = Color(0xFFA82B2A);

  /// Fundo de tela de alerta, com texto branco (5.3:1).
  static const sinal600 = Color(0xFFC23B3A);

  /// Vermelho base: anel de alerta, botão de pânico.
  static const sinal500 = Color(0xFFE24B4A);

  /// Fundo de faixa de alerta ativo.
  static const sinal100 = Color(0xFFFBE1E0);

  // ── Linho: o chão ────────────────────────────────────────────────
  /// Cards e campos.
  static const linho50 = Color(0xFFFAF8F4);

  /// Fundo base.
  static const linho100 = Color(0xFFF2EFE8);

  /// Trilho do anel, divisórias.
  static const linho200 = Color(0xFFE5E1D8);

  /// Bordas de campos, mascote descansando.
  static const linho400 = Color(0xFFB9B4A8);

  /// Texto secundário e erros de formulário (5.7:1 sobre Linho 100).
  static const cinzaTexto = Color(0xFF5F5E5A);

  /// Branco puro: só para texto sobre [sinal600] e brilho dos olhos.
  static const branco = Color(0xFFFFFFFF);
}

/// Apelidos de compatibilidade com o código anterior ao guia.
///
/// Código novo deve usar [VigiColors] ou a paleta do tema (`context.vigi`).
abstract final class AppColors {
  static const Color linho = VigiColors.linho100;
  static const Color linhoEscuro = VigiColors.linho200;
  static const Color petroleo = VigiColors.petroleo800;
  static const Color petrolClaro = VigiColors.petroleo700;
  static const Color ambar = VigiColors.ambar500;

  /// Reservado para pedido de socorro. Nunca usar em erro de formulário
  /// comum (use [cinzaTexto] para isso).
  static const Color panico = VigiColors.sinal500;
  static const Color cinzaTexto = VigiColors.cinzaTexto;
}
