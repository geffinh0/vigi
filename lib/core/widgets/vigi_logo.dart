import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/vigi_palette.dart';
import 'vigi_mascot.dart';

/// Logotipo do Vigi: "vigi" em Nunito Black, minúsculas, com os pingos dos
/// dois "i" em âmbar. Os pingos são os olhos da coruja, e por isso essa
/// assinatura não se repete em nenhum outro texto do app.
///
/// Sobre Petróleo as letras são Linho; sobre Linho, Petróleo. Nunca aplicar
/// sobre vermelho, esticado, com sombra ou contorno.
class VigiLogo extends StatelessWidget {
  const VigiLogo({
    super.key,
    this.height = 48,
    this.withSymbol = false,
    this.onPetroleo,
  }) : assert(height >= 24, 'Tamanho mínimo do logotipo: 24 px de altura');

  /// Altura das letras. Mínimo de 24 px na tela.
  final double height;

  /// Assinatura horizontal: o símbolo da coruja à esquerda.
  final bool withSymbol;

  /// `null` segue o tema.
  final bool? onPetroleo;

  @override
  Widget build(BuildContext context) {
    final dark = onPetroleo ?? context.isNight;
    final wordmark = CustomPaint(
      size: _WordmarkPainter.sizeFor(height),
      painter: _WordmarkPainter(
        height: height,
        color: dark ? VigiColors.linho100 : VigiColors.petroleo800,
      ),
    );

    return Semantics(
      label: 'Vigi',
      image: true,
      child: ExcludeSemantics(
        child: withSymbol
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VigiSymbol(size: height * 1.25, onPetroleo: dark),
                  SizedBox(width: height * 0.3),
                  wordmark,
                ],
              )
            : wordmark,
      ),
    );
  }
}

class _WordmarkPainter extends CustomPainter {
  _WordmarkPainter({required this.height, required this.color});

  final double height;
  final Color color;

  // Texto com "ı" sem pingo; os pingos são desenhados em âmbar por cima.
  static const _text = 'vıgı';

  static TextPainter _layout(double height, Color color) {
    return TextPainter(
      text: TextSpan(
        text: _text,
        style: TextStyle(
          fontFamily: AppTypography.titleFamily,
          fontWeight: FontWeight.w900,
          fontSize: height,
          height: 1,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  static Size sizeFor(double height) {
    final painter = _layout(height, const Color(0xFF000000));
    final size = Size(painter.width, painter.height * 1.15);
    painter.dispose();
    return size;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final painter = _layout(height, color);
    final top = size.height - painter.height;
    painter.paint(canvas, Offset(0, top));

    // Pingo com diâmetro igual à largura da haste do "i".
    final dot = Paint()..color = VigiColors.ambar500;
    for (final index in const [1, 3]) {
      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: index, extentOffset: index + 1),
      );
      if (boxes.isEmpty) continue;
      final box = boxes.first.toRect();
      canvas.drawCircle(
        Offset(box.center.dx, top + painter.height * 0.165),
        height * 0.112,
        dot,
      );
    }
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _WordmarkPainter oldDelegate) =>
      height != oldDelegate.height || color != oldDelegate.color;
}
