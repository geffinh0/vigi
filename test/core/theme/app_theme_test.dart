import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/core/theme/app_colors.dart';
import 'package:guardiao/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('colorScheme.primary é AppColors.petroleo', () {
      expect(appTheme.colorScheme.primary, equals(AppColors.petroleo));
    });

    test('colorScheme.secondary é AppColors.ambar', () {
      expect(appTheme.colorScheme.secondary, equals(AppColors.ambar));
    });

    test('colorScheme.error é AppColors.panico', () {
      expect(appTheme.colorScheme.error, equals(AppColors.panico));
    });

    test('scaffoldBackgroundColor é AppColors.linho', () {
      expect(appTheme.scaffoldBackgroundColor, equals(AppColors.linho));
    });

    test('brightness é light', () {
      expect(appTheme.colorScheme.brightness, equals(Brightness.light));
    });

    test('usa Material 3', () {
      expect(appTheme.useMaterial3, isTrue);
    });
  });

  group('AppColors', () {
    test('paleta 60/30/10 com hex corretos', () {
      expect(AppColors.linho, equals(const Color(0xFFF2EFE8)));
      expect(AppColors.petroleo, equals(const Color(0xFF1F3D3B)));
      expect(AppColors.ambar, equals(const Color(0xFFE8A33D)));
      expect(AppColors.panico, equals(const Color(0xFFE24B4A)));
      expect(AppColors.cinzaTexto, equals(const Color(0xFF5F5E5A)));
    });
  });
}
