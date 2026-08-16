import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/status_ring.dart';
import '../bloc/panic_bloc.dart';
import '../bloc/panic_event.dart';

/// Botão de Pânico com proteção contra toques acidentais.
///
/// Exige pressionar e segurar por 3 segundos para acionar o alerta.
class PanicButton extends StatefulWidget {
  const PanicButton({
    super.key,
    this.size = 200,
    this.onPanicTriggered,
  });

  final double size;
  final VoidCallback? onPanicTriggered;

  @override
  State<PanicButton> createState() => _PanicButtonState();
}

class _PanicButtonState extends State<PanicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _holdController;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerPanic();
      }
    });
  }

  void _triggerPanic() {
    context.read<PanicBloc>().add(const PanicTriggered());
    widget.onPanicTriggered?.call();
    _holdController.reset();
  }

  void _onTapDown(TapDownDetails details) {
    _holdController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (_holdController.isAnimating) {
      _holdController.reverse();
    }
  }

  void _onTapCancel() {
    if (_holdController.isAnimating) {
      _holdController.reverse();
    }
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _holdController,
      builder: (context, child) {
        final progress = _holdController.value;
        final isHolding = progress > 0;

        return GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: Stack(
            alignment: Alignment.center,
            children: [
              StatusRing(
                progress: progress,
                size: widget.size,
                strokeWidth: 10,
                color: AppColors.panico,
                child: Container(
                  width: widget.size - 24,
                  height: widget.size - 24,
                  decoration: BoxDecoration(
                    color: isHolding
                        ? AppColors.panico.withValues(alpha: 0.9)
                        : AppColors.panico,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.panico.withValues(
                          alpha: isHolding ? 0.6 : 0.3,
                        ),
                        blurRadius: isHolding ? 24 : 12,
                        spreadRadius: isHolding ? 4 : 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.emergency,
                        color: AppColors.linho,
                        size: 48,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isHolding ? 'SEGURE...' : 'PÂNICO',
                        style: AppTypography.h3.copyWith(
                          color: AppColors.linho,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Segure 3s',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.linho.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
