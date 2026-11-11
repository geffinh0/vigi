import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vigi_palette.dart';
import '../../../../core/theme/vigi_tokens.dart';
import '../../../../core/utils/vigi_text.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/vigi_dialogs.dart';
import '../../domain/entities/monitoring_mode_entity.dart';
import '../bloc/checkin_bloc.dart';
import '../bloc/checkin_event.dart';
import '../bloc/checkin_state.dart';
import '../widgets/mode_icons.dart';
import '../widgets/mode_sheets.dart';

/// Aba "Modos": seletor com chips grandes (ícone, nome e intervalo). O modo
/// ativo tem fundo Petróleo e texto Linho; "Criar modo" é o último chip, com
/// borda tracejada.
class ModesTab extends StatelessWidget {
  const ModesTab({super.key});

  static const _fallbackModes = [
    MonitoringModeEntity(
      id: 'system-default-routine',
      name: 'Rotina padrão',
      iconKey: 'routine',
      defaultIntervalMinutes: 60,
      isSystemDefault: true,
    ),
    MonitoringModeEntity(
      id: 'system-default-shower',
      name: 'Banho',
      iconKey: 'shower',
      defaultIntervalMinutes: 20,
      isSystemDefault: true,
    ),
    MonitoringModeEntity(
      id: 'system-default-sleep',
      name: 'Sono',
      iconKey: 'sleep',
      defaultIntervalMinutes: 480,
      isSystemDefault: true,
    ),
  ];

  Future<void> _pause(BuildContext context) async {
    final bloc = context.read<CheckinBloc>();
    final ok = await showVigiConfirm(
      context,
      title: 'Pausar a vigília?',
      message:
          'O Vigi deixa de perguntar se está tudo bem e ninguém será '
          'avisado até você começar de novo.',
      confirmLabel: 'Pausar a vigília',
      cancelLabel: 'Continuar vigiando',
    );
    if (ok) bloc.add(const StopMonitoringRequested());
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;

    return BlocBuilder<CheckinBloc, CheckinState>(
      buildWhen: (previous, current) =>
          current is CheckinIdle ||
          current is CheckinLoading ||
          (current is CheckinMonitoring &&
              (previous is! CheckinMonitoring ||
                  previous.activeMode != current.activeMode ||
                  previous.availableModes != current.availableModes ||
                  previous.totalSeconds != current.totalSeconds)),
      builder: (context, state) {
        final monitoring = state is CheckinMonitoring;
        final loaded = switch (state) {
          CheckinIdle(:final availableModes) => availableModes,
          CheckinMonitoring(:final availableModes) => availableModes,
          _ => const <MonitoringModeEntity>[],
        };
        final modes = loaded.isEmpty ? _fallbackModes : loaded;
        final activeId = switch (state) {
          CheckinMonitoring(:final activeMode) => activeMode?.id,
          CheckinIdle(:final selectedMode) => selectedMode?.id,
          _ => null,
        };

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            VigiSpace.screen,
            VigiSpace.x4,
            VigiSpace.screen,
            VigiSpace.x6,
          ),
          children: [
            Semantics(
              header: true,
              child: Text(
                'Modos',
                style: AppTypography.h2.copyWith(color: palette.text),
              ),
            ),
            const SizedBox(height: VigiSpace.x2),
            Text(
              monitoring
                  ? 'Toque em um modo para trocar. Você vê o novo horário '
                        'antes de confirmar.'
                  : 'Toque em um modo para começar a vigiar.',
              style: AppTypography.bodyLarge.copyWith(color: palette.text),
            ),
            const SizedBox(height: VigiSpace.x6),
            if (state is CheckinLoading)
              const Padding(
                padding: EdgeInsets.all(VigiSpace.x8),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              for (final mode in modes) ...[
                ModeChip(
                  mode: mode,
                  active: monitoring && mode.id == activeId,
                  onTap: () => showModeSheet(
                    context,
                    mode: mode,
                    monitoring: monitoring,
                    isActive: monitoring && mode.id == activeId,
                  ),
                ),
                const SizedBox(height: VigiSizes.touchGap),
              ],
              _CreateModeChip(onTap: () => showCreateModeSheet(context)),
              if (monitoring) ...[
                const SizedBox(height: VigiSpace.block),
                AppPrimaryButton(
                  text: 'Pausar a vigília',
                  variant: AppButtonVariant.outline,
                  onPressed: () => _pause(context),
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}

/// Chip grande de um modo: ícone, nome e intervalo ("Banho, 20 min").
class ModeChip extends StatelessWidget {
  const ModeChip({
    super.key,
    required this.mode,
    required this.active,
    required this.onTap,
  });

  final MonitoringModeEntity mode;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;
    final foreground = active ? palette.onFill : palette.text;
    final interval = VigiText.interval(mode.defaultIntervalMinutes);

    return Semantics(
      button: true,
      selected: active,
      label:
          '${mode.shortName}, ${VigiText.remainingSpoken(mode.defaultIntervalMinutes * 60)}'
          '${active ? ', modo ativo' : ''}',
      excludeSemantics: true,
      child: Material(
        color: active ? palette.fill : palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VigiRadius.sm),
          side: BorderSide(
            color: active ? palette.fill : palette.border,
            width: active ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VigiRadius.sm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: VigiSizes.button),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VigiSpace.x4,
                vertical: VigiSpace.x3,
              ),
              child: Row(
                children: [
                  Icon(
                    ModeIcons.of(mode),
                    color: foreground,
                    size: VigiSizes.icon,
                  ),
                  const SizedBox(width: VigiSpace.x3),
                  Expanded(
                    child: Text(
                      mode.shortName,
                      style: AppTypography.label.copyWith(color: foreground),
                    ),
                  ),
                  const SizedBox(width: VigiSpace.x2),
                  Text(
                    active ? '$interval · ativo' : interval,
                    style: AppTypography.bodyMedium.copyWith(
                      color: active ? foreground : palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateModeChip extends StatelessWidget {
  const _CreateModeChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;
    return Semantics(
      button: true,
      label: 'Criar modo',
      excludeSemantics: true,
      child: CustomPaint(
        foregroundPainter: _DashedBorderPainter(color: palette.fieldBorder),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(VigiRadius.sm),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(VigiRadius.sm),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: VigiSizes.button),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VigiSpace.x4,
                  vertical: VigiSpace.x3,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: palette.text),
                    const SizedBox(width: VigiSpace.x2),
                    Flexible(
                      child: Text(
                        'Criar modo',
                        style: AppTypography.label.copyWith(
                          color: palette.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(1),
          const Radius.circular(VigiRadius.sm),
        ),
      );
    const dash = 8.0;
    const gap = 6.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dash),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color;
}
