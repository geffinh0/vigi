import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/vigi_palette.dart';
import '../theme/vigi_tokens.dart';

/// Variantes do botão do Vigi. Cada cor tem um significado só.
enum AppButtonVariant {
  /// Petróleo: a ação principal de uma tela comum ("Entrar", "Salvar").
  primary,

  /// Âmbar: é a vez da pessoa. Reservado para "Estou bem" e para o que
  /// precisa de resposta agora.
  amber,

  /// Contorno: ação secundária ("Estou bem agora", "Cancelar").
  outline,

  /// Claro sobre o vermelho de alerta ("Estou seguro, cancelar o pedido").
  onSignal,
}

/// Altura mínima do botão.
enum AppButtonSize {
  /// 64 dp: o botão primário.
  regular(VigiSizes.button),

  /// 96 dp: o "Estou bem" na tela de chamada.
  call(VigiSizes.callButton),

  /// 56 dp: o menor alvo tocável permitido.
  compact(VigiSizes.touch)
  ;

  const AppButtonSize(this.minHeight);
  final double minHeight;
}

/// Botão do Vigi.
///
/// O texto nunca é cortado com reticências: quando a fonte do sistema cresce
/// (até 200%), o botão cresce junto e o texto quebra em mais linhas.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.isLoading = false,
    this.icon,
    this.width,
    this.semanticsHint,
  });

  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  /// Explica ao leitor de tela o que acontece ao tocar.
  final String? semanticsHint;

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;

    final (
      Color background,
      Color foreground,
      BorderSide side,
    ) = switch (variant) {
      AppButtonVariant.primary => (
        palette.fill,
        palette.onFill,
        BorderSide.none,
      ),
      AppButtonVariant.amber => (
        VigiColors.ambar500,
        VigiColors.petroleo800,
        BorderSide.none,
      ),
      AppButtonVariant.outline => (
        Colors.transparent,
        palette.text,
        BorderSide(color: palette.text, width: 2),
      ),
      AppButtonVariant.onSignal => (
        VigiColors.linho50,
        VigiColors.sinal700,
        BorderSide.none,
      ),
    };

    final textStyle = size == AppButtonSize.call
        ? AppTypography.h3.copyWith(fontWeight: FontWeight.w800)
        : AppTypography.label;

    final content = isLoading
        ? SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: VigiSizes.iconMin, color: foreground),
                const SizedBox(width: VigiSpace.x2),
              ],
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: textStyle.copyWith(color: foreground),
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      label: text,
      hint: semanticsHint,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: size.minHeight,
          minWidth: width ?? double.infinity,
          maxWidth: width ?? double.infinity,
        ),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            // Desabilitado continua legível: o Âmbar clareia para Âmbar 300
            // (é o "Confirmado" logo após o toque) e os demais esmaecem.
            disabledBackgroundColor: switch (variant) {
              AppButtonVariant.amber => VigiColors.ambar300,
              AppButtonVariant.outline => Colors.transparent,
              _ => background.withValues(alpha: 0.6),
            },
            disabledForegroundColor: variant == AppButtonVariant.amber
                ? foreground
                : foreground.withValues(alpha: 0.7),
            elevation: 0,
            minimumSize: Size(VigiSizes.touch, size.minHeight),
            padding: const EdgeInsets.symmetric(
              horizontal: VigiSpace.x6,
              vertical: VigiSpace.x4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VigiRadius.md),
              side: side,
            ),
          ),
          onPressed: isLoading ? null : onPressed,
          child: content,
        ),
      ),
    );
  }
}
