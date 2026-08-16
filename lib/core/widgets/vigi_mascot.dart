import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Estado visual do mascote Vigi — parametriza cor e ícone.
///
/// - [normal]  → petróleo (neutro, calmo)
/// - [atento]  → âmbar (prazo perto do fim)
/// - [alerta]  → pânico (único momento em que usa vermelho)
enum VigiState { normal, atento, alerta }

/// Mascote coruja "Vigi" — widget único parametrizado por [VigiState].
///
/// Usado em splash, home e tela de pânico. A animação de pulso
/// tem velocidade proporcional à urgência do estado.
class VigiMascot extends StatefulWidget {
  final VigiState state;
  final double size;
  final bool animate;

  const VigiMascot({
    super.key,
    this.state = VigiState.normal,
    this.size = 120,
    this.animate = true,
  });

  @override
  State<VigiMascot> createState() => _VigiMascotState();
}

class _VigiMascotState extends State<VigiMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: _pulseDuration,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.animate) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant VigiMascot oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Ajusta velocidade da animação quando o estado muda
    if (oldWidget.state != widget.state) {
      _pulseController.duration = _pulseDuration;
      if (widget.animate && !_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    }

    if (widget.animate && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.animate && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Duração do pulso — mais rápido = mais urgente.
  Duration get _pulseDuration {
    switch (widget.state) {
      case VigiState.normal:
        return const Duration(seconds: 2);
      case VigiState.atento:
        return const Duration(milliseconds: 1400);
      case VigiState.alerta:
        return const Duration(milliseconds: 800);
    }
  }

  Color get _stateColor {
    switch (widget.state) {
      case VigiState.normal:
        return AppColors.petroleo;
      case VigiState.atento:
        return AppColors.ambar;
      case VigiState.alerta:
        return AppColors.panico;
    }
  }

  IconData get _stateIcon {
    switch (widget.state) {
      case VigiState.normal:
        return Icons.shield_rounded;
      case VigiState.atento:
        return Icons.timer_rounded;
      case VigiState.alerta:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.animate ? _scaleAnimation.value : 1.0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.linho,
              border: Border.all(
                color: _stateColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: _stateColor.withValues(alpha: 0.30),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _stateIcon,
                size: widget.size * 0.5,
                color: _stateColor,
              ),
            ),
          ),
        );
      },
    );
  }
}
