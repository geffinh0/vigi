import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/checkin_messages.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vigi_palette.dart';
import '../../../../core/theme/vigi_tokens.dart';
import '../../../../core/utils/vigi_text.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/vigi_text_field.dart';
import '../../domain/entities/monitoring_mode_entity.dart';
import '../bloc/checkin_bloc.dart';
import '../bloc/checkin_event.dart';
import 'mode_icons.dart';

/// Limites do intervalo entre check-ins.
const int kMinIntervalMinutes = 1;
const int kMaxIntervalMinutes = 720;

/// Próximo valor do intervalo ao tocar em "mais" ou "menos". O passo cresce
/// com o valor, para ir de 1 minuto a 12 horas em poucos toques.
int stepInterval(int minutes, {required bool up}) {
  int stepFor(int m) {
    if (m < 10) return 1;
    if (m < 60) return 5;
    if (m < 180) return 15;
    return 30;
  }

  final step = up ? stepFor(minutes) : stepFor(minutes - 1);
  final next = up ? minutes + step : minutes - step;
  return next.clamp(kMinIntervalMinutes, kMaxIntervalMinutes);
}

/// Escolha do intervalo com dois botões grandes. Sem controle deslizante:
/// nenhuma ação do Vigi depende de arrastar o dedo.
class IntervalStepper extends StatelessWidget {
  const IntervalStepper({
    super.key,
    required this.minutes,
    required this.onChanged,
  });

  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;

    Widget button({
      required IconData icon,
      required String label,
      required bool up,
    }) {
      final next = stepInterval(minutes, up: up);
      final enabled = next != minutes;
      return Semantics(
        button: true,
        enabled: enabled,
        label: label,
        onTap: enabled ? () => onChanged(next) : null,
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: VigiSizes.button,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size.square(VigiSizes.button),
            ),
            onPressed: enabled ? () => onChanged(next) : null,
            child: Icon(icon, size: VigiSizes.icon),
          ),
        ),
      );
    }

    return Row(
      children: [
        button(
          icon: Icons.remove_rounded,
          label: 'Diminuir o intervalo',
          up: false,
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            label: 'Intervalo: ${VigiText.remainingSpoken(minutes * 60)}',
            excludeSemantics: true,
            child: Text(
              VigiText.interval(minutes),
              textAlign: TextAlign.center,
              style: AppTypography.h1.copyWith(
                color: palette.text,
                fontFeatures: AppTypography.tabular,
              ),
            ),
          ),
        ),
        button(
          icon: Icons.add_rounded,
          label: 'Aumentar o intervalo',
          up: true,
        ),
      ],
    );
  }
}

/// Folha de um modo: ajusta o intervalo e mostra, antes de confirmar, o que
/// muda ("O próximo check-in passa a ser às 14:40.").
Future<void> showModeSheet(
  BuildContext context, {
  required MonitoringModeEntity mode,
  required bool monitoring,
  required bool isActive,
}) {
  final bloc = context.read<CheckinBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _ModeSheet(
      mode: mode,
      monitoring: monitoring,
      isActive: isActive,
      onConfirm: (minutes) {
        bloc.add(
          StartMonitoringRequested(
            modeId: mode.id,
            intervalOverrideMinutes: minutes,
          ),
        );
        Navigator.of(sheetContext).pop();
      },
    ),
  );
}

class _ModeSheet extends StatefulWidget {
  const _ModeSheet({
    required this.mode,
    required this.monitoring,
    required this.isActive,
    required this.onConfirm,
  });

  final MonitoringModeEntity mode;
  final bool monitoring;
  final bool isActive;
  final ValueChanged<int> onConfirm;

  @override
  State<_ModeSheet> createState() => _ModeSheetState();
}

class _ModeSheetState extends State<_ModeSheet> {
  late int _minutes = widget.mode.defaultIntervalMinutes.clamp(
    kMinIntervalMinutes,
    kMaxIntervalMinutes,
  );

  String get _confirmLabel {
    if (!widget.monitoring) return 'Começar a vigiar';
    if (widget.isActive) return 'Salvar';
    return 'Trocar para ${widget.mode.shortName}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;
    final next = DateTime.now().add(Duration(minutes: _minutes));

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          VigiSpace.screen,
          0,
          VigiSpace.screen,
          VigiSpace.x6 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(ModeIcons.of(widget.mode), color: palette.text),
                ),
                const SizedBox(width: VigiSpace.x3),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      widget.mode.shortName,
                      style: AppTypography.h2.copyWith(color: palette.text),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: VigiSpace.x2),
            Text(
              'De quanto em quanto tempo o Vigi pergunta se está tudo bem.',
              style: AppTypography.bodyMedium.copyWith(
                color: palette.textMuted,
              ),
            ),
            const SizedBox(height: VigiSpace.x6),
            IntervalStepper(
              minutes: _minutes,
              onChanged: (value) => setState(() => _minutes = value),
            ),
            const SizedBox(height: VigiSpace.x6),
            // Sempre dizer o que vem a seguir, antes de confirmar.
            Semantics(
              liveRegion: true,
              child: Text(
                'O próximo check-in passa a ser às ${VigiText.clock(next)}.',
                style: AppTypography.bodyLarge.copyWith(color: palette.text),
              ),
            ),
            const SizedBox(height: VigiSpace.x6),
            AppPrimaryButton(
              text: _confirmLabel,
              onPressed: () => widget.onConfirm(_minutes),
            ),
            const SizedBox(height: VigiSizes.touchGap),
            AppPrimaryButton(
              text: 'Cancelar',
              variant: AppButtonVariant.outline,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Folha "Criar modo": nome, ícone (entre 12 opções) e intervalo.
Future<void> showCreateModeSheet(BuildContext context) {
  final bloc = context.read<CheckinBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _CreateModeSheet(
      onCreate: (name, iconKey, minutes) {
        bloc.add(
          CreateCustomModeRequested(
            name: name,
            defaultIntervalMinutes: minutes,
            iconKey: iconKey,
          ),
        );
        Navigator.of(sheetContext).pop();
      },
    ),
  );
}

class _CreateModeSheet extends StatefulWidget {
  const _CreateModeSheet({required this.onCreate});

  final void Function(String name, String iconKey, int minutes) onCreate;

  @override
  State<_CreateModeSheet> createState() => _CreateModeSheetState();
}

class _CreateModeSheetState extends State<_CreateModeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _iconKey = 'walk';
  int _minutes = 45;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onCreate(_name.text.trim(), _iconKey, _minutes);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          VigiSpace.screen,
          0,
          VigiSpace.screen,
          VigiSpace.x6 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Criar modo',
                  style: AppTypography.h2.copyWith(color: palette.text),
                ),
              ),
              const SizedBox(height: VigiSpace.x4),
              VigiTextField(
                label: 'Nome do modo',
                hint: 'Exemplo: Caminhada',
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                maxLength: 24,
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Dê um nome ao modo. Exemplo: Caminhada.'
                    : null,
              ),
              const SizedBox(height: VigiSpace.x6),
              Text(
                'Ícone',
                style: AppTypography.label.copyWith(color: palette.text),
              ),
              const SizedBox(height: VigiSpace.x2),
              Wrap(
                spacing: VigiSizes.touchGap,
                runSpacing: VigiSizes.touchGap,
                children: [
                  for (final entry in ModeIcons.options.entries)
                    _IconOption(
                      icon: entry.value.icon,
                      label: entry.value.label,
                      selected: entry.key == _iconKey,
                      onTap: () => setState(() => _iconKey = entry.key),
                    ),
                ],
              ),
              const SizedBox(height: VigiSpace.x6),
              Text(
                'Intervalo',
                style: AppTypography.label.copyWith(color: palette.text),
              ),
              const SizedBox(height: VigiSpace.x2),
              IntervalStepper(
                minutes: _minutes,
                onChanged: (value) => setState(() => _minutes = value),
              ),
              const SizedBox(height: VigiSpace.x6),
              AppPrimaryButton(text: 'Criar modo', onPressed: _submit),
              const SizedBox(height: VigiSizes.touchGap),
              AppPrimaryButton(
                text: 'Cancelar',
                variant: AppButtonVariant.outline,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: selected ? palette.fill : palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VigiRadius.sm),
          side: BorderSide(color: selected ? palette.fill : palette.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VigiRadius.sm),
          child: SizedBox.square(
            dimension: VigiSizes.touch,
            child: Icon(
              icon,
              size: VigiSizes.icon,
              color: selected ? palette.onFill : palette.text,
            ),
          ),
        ),
      ),
    );
  }
}

/// Texto do chip de modo ativo na tela inicial.
String activeModeLabel(
  MonitoringModeEntity? mode, {
  required int intervalMinutes,
  DateTime? deadline,
}) {
  return CheckinMessages.modeChip(
    modeName: mode?.shortName ?? 'Rotina',
    intervalMinutes: intervalMinutes,
    isSleep: mode?.isSleep ?? false,
    deadline: deadline,
  );
}
