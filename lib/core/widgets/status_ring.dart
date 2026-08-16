import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'vigi_mascot.dart';

/// Anel de progresso do timer de check-in e indicador de progresso do botão de pânico.
class StatusRing extends StatelessWidget {
  /// Progresso de 0.0 a 1.0.
  final double progress;

  /// Estado que determina a cor do anel.
  final VigiState state;

  /// Cor customizada opcional que sobrepõe o [state].
  final Color? color;

  /// Tamanho (diâmetro) do anel.
  final double size;

  /// Espessura do traço do anel.
  final double strokeWidth;

  /// Widget filho renderizado no centro do anel.
  final Widget? child;

  const StatusRing({
    super.key,
    required this.progress,
    this.state = VigiState.normal,
    this.color,
    this.size = 160,
    this.strokeWidth = 8,
    this.child,
  });

  Color get _activeColor {
    if (color != null) return color!;
    switch (state) {
      case VigiState.normal:
        return AppColors.petroleo;
      case VigiState.atento:
        return AppColors.ambar;
      case VigiState.alerta:
        return AppColors.panico;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress.clamp(0.0, 1.0),
              activeColor: _activeColor,
              trackColor: AppColors.linhoEscuro,
              strokeWidth: strokeWidth,
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track (fundo)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Arco de progresso
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // começa no topo (12h)
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      activeColor != oldDelegate.activeColor ||
      trackColor != oldDelegate.trackColor ||
      strokeWidth != oldDelegate.strokeWidth;
}
