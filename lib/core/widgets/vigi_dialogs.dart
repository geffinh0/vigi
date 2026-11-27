import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/vigi_palette.dart';
import '../theme/vigi_tokens.dart';
import 'app_primary_button.dart';

/// Confirmação do Vigi, em folha inferior.
///
/// Ações destrutivas ou irreversíveis (apagar contato, desvincular familiar,
/// cancelar um pedido de ajuda) sempre pedem confirmação. Os botões ficam
/// empilhados, com 12 dp entre eles, para mãos com tremor.
Future<bool> showVigiConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Voltar',
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final palette = sheetContext.vigi;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            VigiSpace.screen,
            0,
            VigiSpace.screen,
            VigiSpace.x6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: AppTypography.h2.copyWith(color: palette.text),
                ),
              ),
              const SizedBox(height: VigiSpace.x3),
              Text(
                message,
                style: AppTypography.bodyLarge.copyWith(color: palette.text),
              ),
              const SizedBox(height: VigiSpace.x6),
              AppPrimaryButton(
                text: confirmLabel,
                onPressed: () => Navigator.of(sheetContext).pop(true),
              ),
              const SizedBox(height: VigiSizes.touchGap),
              AppPrimaryButton(
                text: cancelLabel,
                variant: AppButtonVariant.outline,
                onPressed: () => Navigator.of(sheetContext).pop(false),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}

/// Aviso curto na base da tela, nas cores do tema (nunca vermelho: erro
/// comum não é socorro).
void showVigiMessage(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        // Nada some antes de a pessoa ler.
        duration: const Duration(seconds: 60),
        showCloseIcon: actionLabel == null,
        action: actionLabel == null || onAction == null
            ? null
            : SnackBarAction(label: actionLabel, onPressed: onAction),
      ),
    );
}
