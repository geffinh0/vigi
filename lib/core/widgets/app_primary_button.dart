import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Variantes do botão principal do design system.
enum AppButtonVariant { primary, danger, outline }

/// Botão reutilizável do Guardião — usa [AppColors.ambar] como padrão,
/// alto contraste, alvo de toque ≥ 48 dp (acessibilidade).
class AppPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const AppPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  Color _getBackgroundColor() {
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.ambar;
      case AppButtonVariant.danger:
        return AppColors.panico;
      case AppButtonVariant.outline:
        return Colors.transparent;
    }
  }

  Color _getTextColor() {
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.petroleo;
      case AppButtonVariant.danger:
        return AppColors.linho;
      case AppButtonVariant.outline:
        return AppColors.petroleo;
    }
  }

  BorderSide? _getBorderSide() {
    if (variant == AppButtonVariant.outline) {
      return const BorderSide(color: AppColors.petroleo, width: 1.5);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBackgroundColor();
    final textColor = _getTextColor();

    return SizedBox(
      width: width ?? double.infinity,
      // Mínimo 48 dp conforme requisito de acessibilidade
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: _getBorderSide() ?? BorderSide.none,
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: textColor),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      style: AppTypography.button.copyWith(color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
