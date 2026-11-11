import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/vigi_palette.dart';
import '../theme/vigi_state.dart';
import '../theme/vigi_tokens.dart';

export '../theme/vigi_state.dart' show VigiEyes, VigiState, VigiStateLabel;

/// A coruja Vigi: o indicador de estado principal do app.
///
/// Ela não é uma ilustração que aparece para enfeitar. Cada expressão
/// corresponde a um estado do sistema, e os olhos são os anéis de tempo:
/// abertos quando vigia, arregalados quando é a vez da pessoa, fechados
/// quando o monitoramento está pausado.
///
/// Regras: nunca aparece em um estado diferente do estado real do sistema e
/// nunca pisca sem que a pessoa tenha feito alguma coisa. A piscada é a
/// confirmação; se acontecer à toa, perde o valor.
class VigiMascot extends StatefulWidget {
  const VigiMascot({
    super.key,
    this.state = VigiState.vigiando,
    this.size = 120,
    this.animate = true,
    this.onSignal = false,
  });

  final VigiState state;

  /// Lado do quadrado ocupado. Tamanhos do guia: 160 na tela inicial, 120 nas
  /// telas de chamada e alerta, 48 em listas e cabeçalhos, 24 como ícone de
  /// estado. Abaixo de 48 só os olhos são desenhados.
  final double size;

  /// Liga a respiração e a piscada. "Remover animações" do sistema também
  /// desliga a respiração, mesmo com `animate: true`.
  final bool animate;

  /// Desenha a coruja em branco, para uso sobre o fundo vermelho de alerta.
  final bool onSignal;

  @override
  State<VigiMascot> createState() => _VigiMascotState();
}

class _VigiMascotState extends State<VigiMascot> with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _blink;

  /// Estado que está sendo desenhado. Pode ficar um instante atrás de
  /// `widget.state` enquanto a coruja fecha os olhos para confirmar.
  late VigiState _shown;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _shown = widget.state;
    _breath = AnimationController(vsync: this);
    _blink = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = context.reduceMotion;
    _syncBreath();
  }

  @override
  void didUpdateWidget(covariant VigiMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _changeState(widget.state);
    } else if (oldWidget.animate != widget.animate) {
      _syncBreath();
    }
  }

  Future<void> _changeState(VigiState next) async {
    final previous = _shown;
    if (!widget.animate) {
      setState(() => _shown = next);
      _syncBreath();
      return;
    }

    // Com "Remover animações" a piscada é mantida, com duração mínima,
    // porque é informação e não enfeite.
    final close = _reduceMotion
        ? const Duration(milliseconds: 60)
        : VigiMotion.blinkClose;
    final open = _reduceMotion
        ? const Duration(milliseconds: 60)
        : VigiMotion.blinkOpen;

    if (next == VigiState.aliviado && previous != VigiState.aliviado) {
      // A coruja pisca: fecha os olhos e abre no sorriso.
      await _blink.animateTo(
        1,
        duration: close,
        curve: VigiMotion.tapCurve,
      );
      if (!mounted) return;
      setState(() => _shown = next);
      _blink.value = 0;
    } else if (previous == VigiState.aliviado) {
      setState(() => _shown = next);
      _blink.value = 1;
      await _blink.animateTo(0, duration: open, curve: VigiMotion.tapCurve);
    } else {
      setState(() => _shown = next);
    }
    if (mounted) _syncBreath();
  }

  VigiStateStyle get _style => VigiStateStyle.of(
    _shown,
    brightness: Theme.of(context).brightness,
  );

  void _syncBreath() {
    final cycle = _style.breath;
    final shouldBreathe = widget.animate && !_reduceMotion && cycle != null;
    if (!shouldBreathe) {
      _breath
        ..stop()
        ..value = 0;
      return;
    }
    // O ciclo completo (inspirar e expirar) dura `cycle`.
    final half = Duration(microseconds: cycle.inMicroseconds ~/ 2);
    if (_breath.duration != half || !_breath.isAnimating) {
      _breath
        ..duration = half
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final colors = widget.onSignal
        ? const OwlColors.all(VigiColors.branco)
        : OwlColors(
            ring: style.eyeRing,
            pupil: style.pupil,
            brow: style.brow,
            beak: style.beak,
            glow: style.halo,
          );

    return Semantics(
      image: true,
      label: 'Vigi: ${_shown.label.toLowerCase()}',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: Listenable.merge([_breath, _blink]),
          builder: (context, _) {
            final breath = style.breathCurve.transform(_breath.value);
            return Transform.scale(
              scale: 1 + 0.04 * breath,
              child: CustomPaint(
                size: Size.square(widget.size),
                painter: OwlPainter(
                  eyes: style.eyes,
                  colors: colors,
                  closed: _blink.value,
                  raisedBrow: style.eyes == VigiEyes.alert,
                  glowStrength: 0.55 + 0.45 * breath,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Cores de cada parte do rosto da coruja.
@immutable
class OwlColors {
  const OwlColors({
    required this.ring,
    required this.pupil,
    required this.brow,
    required this.beak,
    this.glow = Colors.transparent,
    this.highlight = VigiColors.branco,
  });

  const OwlColors.all(Color color)
    : ring = color,
      pupil = color,
      brow = color,
      beak = color,
      glow = Colors.transparent,
      highlight = Colors.transparent;

  final Color ring;
  final Color pupil;
  final Color brow;
  final Color beak;
  final Color glow;
  final Color highlight;

  @override
  bool operator ==(Object other) =>
      other is OwlColors &&
      other.ring == ring &&
      other.pupil == pupil &&
      other.brow == brow &&
      other.beak == beak &&
      other.glow == glow &&
      other.highlight == highlight;

  @override
  int get hashCode => Object.hash(ring, pupil, brow, beak, glow, highlight);
}

/// Desenha o rosto do Vigi reduzido ao essencial: dois anéis (os olhos, que
/// também são os anéis de tempo), um sobrolho em V e um bico pequeno. Não tem
/// contorno de cabeça; o espaço vazio completa a forma.
///
/// Construção (Guia de Design, seção 3): os dois olhos têm o mesmo diâmetro,
/// a distância entre os centros é 2,3 vezes o raio e a espessura do anel é
/// 22% do raio.
class OwlPainter extends CustomPainter {
  const OwlPainter({
    required this.eyes,
    required this.colors,
    this.closed = 0,
    this.raisedBrow = false,
    this.glowStrength = 1,
  });

  final VigiEyes eyes;
  final OwlColors colors;

  /// 0 = olhos abertos, 1 = fechados (usado na piscada).
  final double closed;
  final bool raisedBrow;
  final double glowStrength;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cx = size.width / 2;

    // Abaixo de 48 dp, só os olhos, sem sobrolho.
    final eyesOnly = s < 48;
    final r = eyesOnly ? s / 4.3 : s * 0.2;
    final stroke = r * 0.22;
    final cy = eyesOnly ? size.height / 2 : size.height * 0.57;
    final dx = r * 1.15;

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final ex in [cx - dx, cx + dx]) {
      _paintEye(canvas, Offset(ex, cy), r, stroke, line);
    }

    if (eyesOnly) return;

    // Sobrolho em V: forma a inicial do nome.
    final lift = raisedBrow ? r * 0.2 : 0.0;
    final brow = Path()
      ..moveTo(cx - r * 2.25, cy - r * 1.74 - lift)
      ..lineTo(cx, cy - r * 1.22 - lift)
      ..lineTo(cx + r * 2.25, cy - r * 1.74 - lift);
    canvas.drawPath(brow, line..color = colors.brow);

    // Bico em losango.
    final by = cy + r * 0.98;
    final beak = Path()
      ..moveTo(cx, by - r * 0.42)
      ..lineTo(cx + r * 0.27, by)
      ..lineTo(cx, by + r * 0.42)
      ..lineTo(cx - r * 0.27, by)
      ..close();
    canvas.drawPath(
      beak,
      Paint()
        ..color = colors.beak
        ..style = PaintingStyle.fill,
    );
  }

  void _paintEye(
    Canvas canvas,
    Offset center,
    double r,
    double stroke,
    Paint line,
  ) {
    final ringRadius = r - stroke / 2;

    switch (eyes) {
      case VigiEyes.closed:
        // Fechados, em arco para baixo.
        canvas.drawArc(
          Rect.fromCircle(
            center: center.translate(0, -r * 0.2),
            radius: r * 0.74,
          ),
          math.pi * 0.14,
          math.pi * 0.72,
          false,
          line..color = colors.ring,
        );
        return;
      case VigiEyes.happy:
        // Arcos para cima: o sorriso nos olhos.
        canvas.drawArc(
          Rect.fromCircle(
            center: center.translate(0, r * 0.3),
            radius: r * 0.74,
          ),
          math.pi * 1.12,
          math.pi * 0.76,
          false,
          line..color = colors.ring,
        );
        return;
      case VigiEyes.open:
      case VigiEyes.wide:
      case VigiEyes.alert:
      case VigiEyes.glow:
        break;
    }

    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(1, 1 - 0.92 * closed.clamp(0.0, 1.0));

    if (eyes == VigiEyes.glow && colors.glow.a > 0) {
      canvas.drawCircle(
        Offset.zero,
        ringRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 1.6
          ..color = colors.glow.withValues(alpha: 0.55 * glowStrength)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.3),
      );
    }

    canvas.drawCircle(Offset.zero, ringRadius, line..color = colors.ring);

    final pupilRadius = switch (eyes) {
      VigiEyes.wide => r * 0.5,
      VigiEyes.alert => r * 0.17,
      VigiEyes.glow => r * 0.32,
      _ => r * 0.4,
    };
    canvas.drawCircle(
      Offset.zero,
      pupilRadius,
      Paint()
        ..color = colors.pupil
        ..style = PaintingStyle.fill,
    );

    final hasHighlight = eyes == VigiEyes.open || eyes == VigiEyes.wide;
    if (hasHighlight && colors.highlight.a > 0) {
      canvas.drawCircle(
        Offset(pupilRadius * 0.4, -pupilRadius * 0.4),
        pupilRadius * 0.3,
        Paint()
          ..color = colors.highlight
          ..style = PaintingStyle.fill,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OwlPainter oldDelegate) =>
      eyes != oldDelegate.eyes ||
      colors != oldDelegate.colors ||
      closed != oldDelegate.closed ||
      raisedBrow != oldDelegate.raisedBrow ||
      glowStrength != oldDelegate.glowStrength;
}

/// O símbolo da marca: o rosto do Vigi, parado, nas cores do logotipo.
///
/// Sobre Linho, anéis e sobrolho são Petróleo e os olhos e o bico, Âmbar.
/// Sobre Petróleo, os anéis são Âmbar e o resto é Linho.
class VigiSymbol extends StatelessWidget {
  const VigiSymbol({super.key, this.size = 48, this.onPetroleo});

  final double size;

  /// `null` segue o tema: no noturno usa a versão sobre Petróleo.
  final bool? onPetroleo;

  @override
  Widget build(BuildContext context) {
    final dark = onPetroleo ?? context.isNight;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: OwlPainter(
          eyes: VigiEyes.open,
          colors: dark
              ? const OwlColors(
                  ring: VigiColors.ambar500,
                  pupil: VigiColors.linho100,
                  brow: VigiColors.linho100,
                  beak: VigiColors.linho100,
                  highlight: VigiColors.petroleo900,
                )
              : const OwlColors(
                  ring: VigiColors.petroleo800,
                  pupil: VigiColors.ambar500,
                  brow: VigiColors.petroleo800,
                  beak: VigiColors.ambar500,
                ),
        ),
      ),
    );
  }
}
