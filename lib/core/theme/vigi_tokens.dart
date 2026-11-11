import 'package:flutter/animation.dart';

/// Grade de 4 dp (Guia de Design, seção 7).
abstract final class VigiSpace {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x12 = 48;
  static const double x16 = 64;

  /// Margem lateral das telas.
  static const double screen = 24;

  /// Espaço entre blocos de conteúdo.
  static const double block = 32;
}

/// Raios (Guia de Design, seção 7).
abstract final class VigiRadius {
  /// Campos, chips.
  static const double sm = 12;

  /// Cards, botões.
  static const double md = 20;

  /// Bottom sheets, telas modais.
  static const double lg = 28;
}

/// Tamanhos mínimos de toque. O mínimo do Material (48 dp) não basta para
/// mãos com tremor.
abstract final class VigiSizes {
  /// Qualquer alvo tocável.
  static const double touch = 56;

  /// Distância mínima entre alvos vizinhos.
  static const double touchGap = 12;

  /// Botão primário e campos de formulário.
  static const double button = 64;

  /// Botão "Estou bem" na tela de chamada.
  static const double callButton = 96;

  /// Diâmetro do botão de pânico.
  static const double panic = 200;

  /// Diâmetro do anel de vigília na tela inicial.
  static const double ring = 240;

  /// Traço do anel de vigília.
  static const double ringStroke = 14;

  /// Ponto que marca a posição atual do tempo no anel.
  static const double ringDot = 8;

  /// Ícones: tamanho padrão e mínimo.
  static const double icon = 28;
  static const double iconMin = 24;
}

/// Movimento (Guia de Design, seção 11). O pulso do mascote e do halo segue
/// o ritmo de uma respiração: a urgência acelera o ritmo, como acelera a nossa.
abstract final class VigiMotion {
  static const breathCalm = Duration(milliseconds: 4000);
  static const breathNight = Duration(milliseconds: 6000);
  static const breathAttention = Duration(milliseconds: 1400);
  static const breathAlert = Duration(milliseconds: 800);

  static const blinkClose = Duration(milliseconds: 180);
  static const blinkOpen = Duration(milliseconds: 220);

  static const stateChange = Duration(milliseconds: 450);
  static const tap = Duration(milliseconds: 120);

  /// Quanto tempo o estado "Aliviado" fica na tela antes de voltar a
  /// "Vigiando".
  static const relief = Duration(seconds: 3);

  static const Curve breathCurve = Curves.easeInOutSine;
  static const Curve alertCurve = Curves.easeInOutCubic;
  static const Curve stateCurve = Curves.easeInOutCubicEmphasized;
  static const Curve tapCurve = Curves.easeOut;
}
