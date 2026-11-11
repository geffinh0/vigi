import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/alarm_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vigi_palette.dart';
import '../../../../core/theme/vigi_state.dart';
import '../../../../core/theme/vigi_tokens.dart';
import '../../../../core/widgets/status_ring.dart';
import '../bloc/panic_bloc.dart';
import '../bloc/panic_event.dart';

/// Onde o botão de pânico aparece.
enum PanicButtonStyle {
  /// O botão grande da tela "Pedir ajuda": 200 dp de diâmetro.
  large,

  /// O rodapé fixo da tela inicial: "Pedir ajuda, segure 3 s".
  footer,
}

/// Botão de pânico.
///
/// Segurar por 3 segundos pede ajuda; toques rápidos não disparam nada. Para
/// a pessoa entender que está funcionando, o gesto dá retorno o tempo todo:
/// o anel em volta do botão se preenche; a cada segundo, uma vibração curta
/// e o número muda ("3", "2", "1"); no terceiro segundo, uma vibração longa
/// e o pedido sai. Se soltar antes, o anel volta e uma frase explica o que
/// aconteceu.
class PanicButton extends StatefulWidget {
  const PanicButton({
    super.key,
    this.size = VigiSizes.panic,
    this.style = PanicButtonStyle.large,
    this.onPanicTriggered,
    this.onReleasedEarly,
    this.onTap,
  });

  /// Diâmetro do botão no estilo [PanicButtonStyle.large].
  final double size;
  final PanicButtonStyle style;

  /// Chamado depois que o pedido de ajuda foi enviado ao bloc.
  final VoidCallback? onPanicTriggered;

  /// A pessoa soltou antes dos 3 segundos.
  final VoidCallback? onReleasedEarly;

  /// Toque rápido (sem segurar). No rodapé, abre a tela "Pedir ajuda".
  final VoidCallback? onTap;

  /// Tempo que a pessoa precisa segurar.
  static const holdDuration = Duration(seconds: 3);

  /// Frase mostrada quando a pessoa solta antes.
  static const releasedEarlyMessage =
      'Você soltou antes. Segure por 3 segundos para pedir ajuda.';

  @override
  State<PanicButton> createState() => _PanicButtonState();
}

class _PanicButtonState extends State<PanicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hold;
  int _lastSecond = 3;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _hold = AnimationController(vsync: this, duration: PanicButton.holdDuration)
      ..addListener(_onProgress)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _trigger();
      });
  }

  int get _secondsLeft => (3 - (_hold.value * 3).floor()).clamp(1, 3);

  void _onProgress() {
    if (!_hold.isAnimating || _hold.status != AnimationStatus.forward) return;
    final seconds = _secondsLeft;
    if (seconds != _lastSecond) {
      _lastSecond = seconds;
      // Uma vibração curta por segundo.
      VigiHaptics.holdTick();
    }
  }

  void _trigger() {
    if (_triggered) return;
    _triggered = true;
    // Pânico acionado: um pulso longo de 800 ms. Sem som próprio: em uma
    // situação de risco, fazer barulho pode não ser desejado.
    VigiHaptics.panicTriggered();
    context.read<PanicBloc>().add(const PanicTriggered());
    widget.onPanicTriggered?.call();
    _hold.reset();
    _lastSecond = 3;
    _triggered = false;
  }

  void _onDown(TapDownDetails details) {
    _lastSecond = 3;
    VigiHaptics.holdTick();
    _hold.forward(from: 0);
  }

  void _onRelease() {
    if (_hold.status != AnimationStatus.forward) return;
    final progress = _hold.value;
    _hold.reverse();
    // Um toque rápido não é uma tentativa de pedir ajuda.
    if (progress < 0.12) {
      widget.onTap?.call();
    } else {
      widget.onReleasedEarly?.call();
    }
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Pedir ajuda',
      hint: 'Segure por 3 segundos para avisar seus contatos',
      // Com leitor de tela, tocar duas vezes e segurar pede ajuda.
      onLongPress: _trigger,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onDown,
        onTapUp: (_) => _onRelease(),
        onTapCancel: _onRelease,
        child: AnimatedBuilder(
          animation: _hold,
          builder: (context, _) {
            final holding = _hold.value > 0;
            return widget.style == PanicButtonStyle.large
                ? _Large(
                    size: widget.size,
                    progress: _hold.value,
                    holding: holding,
                    secondsLeft: _secondsLeft,
                  )
                : _Footer(
                    progress: _hold.value,
                    holding: holding,
                    secondsLeft: _secondsLeft,
                  );
          },
        ),
      ),
    );
  }
}

class _Large extends StatelessWidget {
  const _Large({
    required this.size,
    required this.progress,
    required this.holding,
    required this.secondsLeft,
  });

  final double size;
  final double progress;
  final bool holding;
  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    const stroke = 12.0;
    const gap = 10.0;
    return StatusRing(
      progress: progress,
      state: VigiState.alerta,
      size: size + 2 * (stroke + gap),
      strokeWidth: stroke,
      trackColor: VigiColors.sinal100,
      fillColor: Colors.transparent,
      showDot: false,
      showHalo: holding,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: VigiColors.sinal500,
          shape: BoxShape.circle,
        ),
        // Branco sobre Sinal 500 só vale para texto grande (24 sp ou mais,
        // negrito); por isso o tamanho aqui não acompanha a fonte do sistema.
        child: MediaQuery.withNoTextScaling(
          child: holding
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$secondsLeft',
                      style: AppTypography.display.copyWith(
                        color: VigiColors.branco,
                        fontSize: 72,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: VigiSpace.x1),
                    Text(
                      'Segure…',
                      style: AppTypography.h2.copyWith(
                        color: VigiColors.branco,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Segure para\npedir ajuda',
                  textAlign: TextAlign.center,
                  style: AppTypography.h2.copyWith(
                    color: VigiColors.branco,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.progress,
    required this.holding,
    required this.secondsLeft,
  });

  final double progress;
  final bool holding;
  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;
    return Container(
      constraints: const BoxConstraints(minHeight: VigiSizes.button + 8),
      padding: const EdgeInsets.symmetric(
        horizontal: VigiSpace.x4,
        vertical: VigiSpace.x3,
      ),
      decoration: BoxDecoration(
        color: holding ? VigiColors.sinal100 : palette.surface,
        borderRadius: BorderRadius.circular(VigiRadius.md),
        border: Border.all(
          color: holding ? VigiColors.sinal500 : palette.border,
          width: holding ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          StatusRing(
            progress: progress,
            state: VigiState.alerta,
            size: 48,
            strokeWidth: 4,
            trackColor: Colors.transparent,
            fillColor: Colors.transparent,
            showDot: false,
            showHalo: false,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: VigiColors.sinal500,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: VigiSpace.x3),
          Expanded(
            child: Text(
              holding ? 'Segure… $secondsLeft' : 'Pedir ajuda',
              style: AppTypography.label.copyWith(
                color: holding ? VigiColors.sinal700 : palette.text,
              ),
            ),
          ),
          if (!holding)
            Text(
              'segure 3 s',
              style: AppTypography.caption.copyWith(color: palette.textMuted),
            ),
        ],
      ),
    );
  }
}
