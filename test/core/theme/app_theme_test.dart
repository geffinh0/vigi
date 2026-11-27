import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/core/theme/app_colors.dart';
import 'package:guardiao/core/theme/app_theme.dart';
import 'package:guardiao/core/theme/app_typography.dart';
import 'package:guardiao/core/theme/vigi_palette.dart';
import 'package:guardiao/core/theme/vigi_state.dart';
import 'package:guardiao/core/theme/vigi_tokens.dart';

/// Contraste pela fórmula da WCAG 2.2.
double contrast(Color a, Color b) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double luminance(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
  final la = luminance(a);
  final lb = luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('VigiColors', () {
    test('tokens têm os valores do guia', () {
      expect(VigiColors.petroleo900, const Color(0xFF0F2221));
      expect(VigiColors.petroleo800, const Color(0xFF1F3D3B));
      expect(VigiColors.petroleo700, const Color(0xFF2D5654));
      expect(VigiColors.petroleo500, const Color(0xFF4E7C79));
      expect(VigiColors.petroleo300, const Color(0xFF9DBAB7));
      expect(VigiColors.petroleo100, const Color(0xFFDDE8E6));
      expect(VigiColors.ambar700, const Color(0xFF8A5A0F));
      expect(VigiColors.ambar500, const Color(0xFFE8A33D));
      expect(VigiColors.ambar300, const Color(0xFFF4CB8A));
      expect(VigiColors.ambar100, const Color(0xFFFBEBD0));
      expect(VigiColors.sinal700, const Color(0xFFA82B2A));
      expect(VigiColors.sinal600, const Color(0xFFC23B3A));
      expect(VigiColors.sinal500, const Color(0xFFE24B4A));
      expect(VigiColors.sinal100, const Color(0xFFFBE1E0));
      expect(VigiColors.linho50, const Color(0xFFFAF8F4));
      expect(VigiColors.linho100, const Color(0xFFF2EFE8));
      expect(VigiColors.linho200, const Color(0xFFE5E1D8));
      expect(VigiColors.linho400, const Color(0xFFB9B4A8));
      expect(VigiColors.cinzaTexto, const Color(0xFF5F5E5A));
    });

    test('apelidos antigos continuam apontando para a mesma cor', () {
      expect(AppColors.linho, VigiColors.linho100);
      expect(AppColors.linhoEscuro, VigiColors.linho200);
      expect(AppColors.petroleo, VigiColors.petroleo800);
      expect(AppColors.petrolClaro, VigiColors.petroleo700);
      expect(AppColors.ambar, VigiColors.ambar500);
      expect(AppColors.panico, VigiColors.sinal500);
      expect(AppColors.cinzaTexto, VigiColors.cinzaTexto);
    });
  });

  group(
    'contraste (meta: 7:1 no texto principal, 4.5:1 em qualquer texto)',
    () {
      test('tabela de contraste do guia', () {
        expect(
          contrast(VigiColors.petroleo800, VigiColors.linho100),
          closeTo(10.2, 0.15),
        );
        expect(
          contrast(VigiColors.cinzaTexto, VigiColors.linho100),
          closeTo(5.7, 0.15),
        );
        expect(
          contrast(VigiColors.petroleo800, VigiColors.ambar500),
          closeTo(5.4, 0.15),
        );
        expect(
          contrast(VigiColors.ambar700, VigiColors.linho100),
          closeTo(5.2, 0.15),
        );
        expect(
          contrast(VigiColors.branco, VigiColors.sinal600),
          closeTo(5.3, 0.15),
        );
        expect(
          contrast(VigiColors.linho100, VigiColors.petroleo900),
          closeTo(14.4, 0.2),
        );
        expect(
          contrast(VigiColors.ambar500, VigiColors.petroleo900),
          closeTo(7.7, 0.15),
        );
      });

      test('combinações proibidas pelo guia realmente não passam', () {
        // Âmbar 500 nunca é cor de texto sobre Linho.
        expect(contrast(VigiColors.ambar500, VigiColors.linho100), lessThan(3));
        // Branco sobre Sinal 500 só serve para texto grande.
        expect(contrast(VigiColors.branco, VigiColors.sinal500), lessThan(4.5));
      });

      for (final (name, palette) in [
        ('claro', VigiPalette.light),
        ('noturno', VigiPalette.night),
      ]) {
        test('paleta $name: texto principal AAA, secundário AA', () {
          for (final surface in [palette.background, palette.surface]) {
            expect(contrast(palette.text, surface), greaterThanOrEqualTo(7));
            expect(
              contrast(palette.textMuted, surface),
              greaterThanOrEqualTo(4.5),
            );
          }
          expect(
            contrast(palette.amberText, palette.background),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrast(palette.onFill, palette.fill),
            greaterThanOrEqualTo(7),
          );
          expect(contrast(palette.text, palette.chip), greaterThanOrEqualTo(7));
        });
      }

      test('texto de cada estado passa em AA sobre o fundo do estado', () {
        for (final state in VigiState.values) {
          for (final brightness in Brightness.values) {
            final style = VigiStateStyle.of(state, brightness: brightness);
            expect(
              contrast(style.onBackground, style.background),
              greaterThanOrEqualTo(4.5),
              reason: '$state / $brightness',
            );
          }
        }
      });

      test('botões: texto legível sobre cada preenchimento', () {
        // "Estou bem": Petróleo 800 sobre Âmbar 500.
        expect(
          contrast(VigiColors.petroleo800, VigiColors.ambar500),
          greaterThanOrEqualTo(4.5),
        );
        // "Confirmado": Petróleo 800 sobre Âmbar 300.
        expect(
          contrast(VigiColors.petroleo800, VigiColors.ambar300),
          greaterThanOrEqualTo(7),
        );
        // "Estou seguro, cancelar o pedido": Sinal 700 sobre Linho 50.
        expect(
          contrast(VigiColors.sinal700, VigiColors.linho50),
          greaterThanOrEqualTo(4.5),
        );
        // Faixa de saúde: Petróleo 800 sobre Âmbar 100.
        expect(
          contrast(VigiColors.petroleo800, VigiColors.ambar100),
          greaterThanOrEqualTo(7),
        );
      });
    },
  );

  group('AppTheme', () {
    test('tema claro: Linho no fundo, Petróleo estrutura', () {
      expect(appTheme.useMaterial3, isTrue);
      expect(appTheme.brightness, Brightness.light);
      expect(appTheme.scaffoldBackgroundColor, VigiColors.linho100);
      expect(appTheme.colorScheme.primary, VigiColors.petroleo800);
      expect(appTheme.colorScheme.secondary, VigiColors.ambar500);
      expect(appTheme.extension<VigiPalette>(), VigiPalette.light);
    });

    test('tema noturno: Petróleo 900 no fundo, sem branco puro', () {
      expect(vigiNightTheme.brightness, Brightness.dark);
      expect(vigiNightTheme.scaffoldBackgroundColor, VigiColors.petroleo900);
      expect(vigiNightTheme.extension<VigiPalette>(), VigiPalette.night);
      const night = VigiPalette.night;
      for (final color in [night.text, night.textMuted, night.fill]) {
        expect(color, isNot(VigiColors.branco));
      }
    });

    test('erro de formulário nunca é vermelho', () {
      for (final theme in [appTheme, vigiNightTheme]) {
        final error = theme.colorScheme.error;
        expect(error, isNot(VigiColors.sinal500));
        expect(error, isNot(VigiColors.sinal600));
        expect(error, isNot(VigiColors.sinal700));
        expect(
          theme.inputDecorationTheme.errorStyle!.color,
          theme.extension<VigiPalette>()!.textMuted,
        );
      }
    });

    test('campos têm 64 dp de altura e raio de 12 dp', () {
      final input = appTheme.inputDecorationTheme;
      expect(input.constraints!.minHeight, VigiSizes.button);
      final border = input.enabledBorder! as OutlineInputBorder;
      expect(border.borderRadius, BorderRadius.circular(VigiRadius.sm));
      expect(border.borderSide.color, VigiColors.linho400);
      final focused = input.focusedBorder! as OutlineInputBorder;
      expect(focused.borderSide.color, VigiColors.petroleo800);
      expect(focused.borderSide.width, 2);
    });

    test('cards não usam sombra', () {
      expect(appTheme.cardTheme.elevation, 0);
      expect(vigiNightTheme.cardTheme.elevation, 0);
    });
  });

  group('AppTypography', () {
    const scale = {
      'display': (AppTypography.display, 56.0, 60.0, FontWeight.w800),
      'h1': (AppTypography.h1, 32.0, 40.0, FontWeight.w800),
      'h2': (AppTypography.h2, 26.0, 34.0, FontWeight.w700),
      'h3': (AppTypography.h3, 21.0, 28.0, FontWeight.w700),
      'bodyLarge': (AppTypography.bodyLarge, 18.0, 28.0, FontWeight.w400),
      'bodyMedium': (AppTypography.bodyMedium, 16.0, 24.0, FontWeight.w400),
      'label': (AppTypography.label, 18.0, 24.0, FontWeight.w700),
      'caption': (AppTypography.caption, 14.0, 20.0, FontWeight.w400),
    };

    test('escala do guia: tamanho, altura de linha e peso', () {
      for (final entry in scale.entries) {
        final (style, size, lineHeight, weight) = entry.value;
        expect(style.fontSize, size, reason: entry.key);
        expect(
          style.fontSize! * style.height!,
          closeTo(lineHeight, 0.01),
          reason: entry.key,
        );
        expect(style.fontWeight, weight, reason: entry.key);
      }
    });

    test('Nunito nos títulos e Atkinson Hyperlegible no resto', () {
      for (final style in [
        AppTypography.display,
        AppTypography.h1,
        AppTypography.h2,
        AppTypography.h3,
      ]) {
        expect(style.fontFamily, 'Nunito');
      }
      for (final style in [
        AppTypography.bodyLarge,
        AppTypography.bodyMedium,
        AppTypography.label,
        AppTypography.caption,
      ]) {
        expect(style.fontFamily, 'Atkinson Hyperlegible');
      }
    });

    test('nenhum estilo do tema fica abaixo de 14 sp', () {
      for (final theme in [appTheme, vigiNightTheme]) {
        final t = theme.textTheme;
        for (final style in [
          t.displayLarge,
          t.displayMedium,
          t.displaySmall,
          t.headlineLarge,
          t.headlineMedium,
          t.headlineSmall,
          t.titleLarge,
          t.titleMedium,
          t.titleSmall,
          t.bodyLarge,
          t.bodyMedium,
          t.bodySmall,
          t.labelLarge,
          t.labelMedium,
          t.labelSmall,
        ]) {
          expect(style!.fontSize, greaterThanOrEqualTo(14));
        }
      }
    });

    test('o contador usa algarismos tabulares', () {
      expect(
        AppTypography.display.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });

  group('VigiStateStyle', () {
    test('respiração de cada estado', () {
      Duration? breath(VigiState s) => VigiStateStyle.of(s).breath;
      expect(breath(VigiState.descansando), isNull);
      expect(breath(VigiState.vigiando), const Duration(milliseconds: 4000));
      expect(breath(VigiState.suaVez), const Duration(milliseconds: 1400));
      expect(breath(VigiState.alerta), const Duration(milliseconds: 800));
      expect(breath(VigiState.aliviado), isNull);
      expect(breath(VigiState.noturno), const Duration(milliseconds: 6000));
    });

    test('vermelho só aparece nos estados de socorro', () {
      final reds = <Color>{
        VigiColors.sinal100,
        VigiColors.sinal500,
        VigiColors.sinal600,
        VigiColors.sinal700,
      };
      for (final state in VigiState.values) {
        if (state == VigiState.alerta) continue;
        for (final brightness in Brightness.values) {
          final s = VigiStateStyle.of(state, brightness: brightness);
          for (final color in [s.ring, s.halo, s.background, s.eyeRing]) {
            expect(reds, isNot(contains(color)), reason: '$state');
          }
        }
      }
    });

    test('a tela de alerta usa Sinal 600 também no tema noturno', () {
      expect(
        VigiStateStyle.of(
          VigiState.alerta,
          brightness: Brightness.dark,
        ).background,
        VigiColors.sinal600,
      );
    });
  });

  group('tokens de toque', () {
    test('alvos mínimos para mãos com tremor', () {
      expect(VigiSizes.touch, 56);
      expect(VigiSizes.touchGap, 12);
      expect(VigiSizes.button, 64);
      expect(VigiSizes.callButton, 96);
      expect(VigiSizes.panic, 200);
    });

    test('raios', () {
      expect(VigiRadius.sm, 12);
      expect(VigiRadius.md, 20);
      expect(VigiRadius.lg, 28);
    });
  });
}
