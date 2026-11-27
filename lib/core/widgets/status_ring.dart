import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/vigi_palette.dart';
import '../theme/vigi_state.dart';
import '../theme/vigi_tokens.dart';

/// Anel de vigília: mostra o tempo restante até o próximo check-in e envolve
/// a coruja. Também é o anel que se preenche em volta do botão de pânico.
///
/// O arco começa às 12h e segue no sentido horário, como um relógio. Na tela
/// inicial [progress] é a fração de tempo que ainda resta (1 = prazo inteiro);
/// no botão de pânico é o quanto do gesto de segurar já foi feito.
class StatusRing extends StatelessWidget {
  const StatusRing({
    super.key,
    required this.progress,
    this.state = VigiState.vigiando,
    this.color,
    this.trackColor,
    this.fillColor,
    this.size = VigiSizes.ring,
    this.strokeWidth = VigiSizes.ringStroke,
    this.showDot = true,
    this.showHalo = true,
    this.semanticsLabel,
    this.child,
  });

  /// Fração preenchida do anel, de 0.0 a 1.0.
  final double progress;

  /// Estado que determina a cor do anel e do halo.
  final VigiState state;

  /// Cor do arco, quando precisa ser diferente da cor do [state].
  final Color? color;

  /// Cor do trilho. Padrão: Linho 200 (ou o equivalente noturno).
  final Color? trackColor;

  /// Cor do disco interno. Padrão: a superfície do tema.
  final Color? fillColor;

  /// Diâmetro do anel.
  final double size;

  /// Espessura do traço.
  final double strokeWidth;

  /// Ponto que marca onde o tempo está agora.
  final bool showDot;

  /// Brilho na cor do estado atrás do anel.
  final bool showHalo;

  /// Texto lido pelo leitor de tela no lugar do conteúdo do anel, por
  /// extenso: "Próximo check-in às 15 horas, daqui a 38 minutos".
  final String? semanticsLabel;

  /// Conteúdo no centro do anel.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;
    final style = VigiStateStyle.of(
      state,
      brightness: Theme.of(context).brightness,
    );
    final arc = color ?? style.ring;
    final halo = showHalo ? style.halo : Colors.transparent;
    final duration = context.reduceMotion
        ? Duration.zero
        : VigiMotion.stateChange;

    final ring = TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: arc),
      duration: duration,
      curve: VigiMotion.stateCurve,
      builder: (context, animatedArc, child) => CustomPaint(
        size: Size.square(size),
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          arcColor: animatedArc ?? arc,
          trackColor: trackColor ?? palette.track,
          fillColor: fillColor ?? palette.surface,
          haloColor: halo,
          strokeWidth: strokeWidth,
          showDot: showDot,
        ),
        child: child,
      ),
      child: SizedBox.square(
        dimension: size,
        child: child == null ? null : Center(child: child),
      ),
    );

    if (semanticsLabel == null) return ring;
    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(child: ring),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.arcColor,
    required this.trackColor,
    required this.fillColor,
    required this.haloColor,
    required this.strokeWidth,
    required this.showDot,
  });

  final double progress;
  final Color arcColor;
  final Color trackColor;
  final Color fillColor;
  final Color haloColor;
  final double strokeWidth;
  final bool showDot;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final outer = size.shortestSide / 2;

    // Halo: sombra reservada para os estados, onde ela tem significado.
    // Desfoque de 24 dp e opacidade de 30%.
    if (haloColor.a > 0) {
      canvas.drawCircle(
        center,
        outer,
        Paint()
          ..color = haloColor.withValues(alpha: haloColor.a * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
      );
    }

    canvas
      ..drawCircle(center, outer, Paint()..color = fillColor)
      ..drawCircle(
        center,
        radius,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );

    if (progress <= 0) return;

    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (showDot && progress < 1) {
      final angle = start + sweep;
      final dot = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final dotRadius = math.min(VigiSizes.ringDot, strokeWidth * 0.6) / 2;
      canvas.drawCircle(dot, dotRadius, Paint()..color = fillColor);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      arcColor != oldDelegate.arcColor ||
      trackColor != oldDelegate.trackColor ||
      fillColor != oldDelegate.fillColor ||
      haloColor != oldDelegate.haloColor ||
      strokeWidth != oldDelegate.strokeWidth ||
      showDot != oldDelegate.showDot;
}
