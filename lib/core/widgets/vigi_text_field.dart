import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_typography.dart';
import '../theme/vigi_palette.dart';
import '../theme/vigi_tokens.dart';

/// Campo de formulário do Vigi.
///
/// O rótulo fica sempre visível acima do campo (nunca só como placeholder),
/// o campo tem 64 dp de altura e os erros aparecem em Cinza texto, com uma
/// frase que explica como corrigir: "Falta o DDD. Exemplo: (11) 98765-4321."
class VigiTextField extends StatelessWidget {
  const VigiTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onFieldSubmitted,
    this.autofocus = false,
    this.maxLength,
    this.style,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;

  /// Dica abaixo do campo ("Pelo menos 6 caracteres").
  final String? helper;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onFieldSubmitted;
  final bool autofocus;
  final int? maxLength;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;
    // Rótulo e campo viram um só item para o leitor de tela: "Nome, caixa
    // de edição".
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: VigiSpace.x2),
            child: Text(
              label,
              style: AppTypography.label.copyWith(color: palette.text),
            ),
          ),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            obscureText: obscureText,
            autofillHints: autofillHints,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            onFieldSubmitted: onFieldSubmitted,
            autofocus: autofocus,
            maxLength: maxLength,
            style:
                style ?? AppTypography.bodyLarge.copyWith(color: palette.text),
            cursorColor: palette.text,
            decoration: InputDecoration(
              hintText: hint,
              helperText: helper,
              suffixIcon: suffixIcon,
              counterText: '',
              errorStyle: AppTypography.caption.copyWith(
                color: palette.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
