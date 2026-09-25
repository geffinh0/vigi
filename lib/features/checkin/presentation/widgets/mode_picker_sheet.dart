import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../domain/entities/monitoring_mode_entity.dart';
import '../bloc/checkin_bloc.dart';
import '../bloc/checkin_event.dart';
import '../bloc/checkin_state.dart';

/// Folha inferior para escolher ou criar um modo.
class ModePickerSheet extends StatefulWidget {
  const ModePickerSheet({
    super.key,
    required this.modes,
    this.initialMode,
    this.initialIntervalMinutes,
    required this.onStartMonitoring,
  });

  final List<MonitoringModeEntity> modes;
  final MonitoringModeEntity? initialMode;
  final int? initialIntervalMinutes;
  final void Function(MonitoringModeEntity mode, int intervalMinutes)
  onStartMonitoring;

  @override
  State<ModePickerSheet> createState() => _ModePickerSheetState();
}

class _ModePickerSheetState extends State<ModePickerSheet> {
  late MonitoringModeEntity? _selectedMode;
  late int _currentInterval;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode ?? widget.modes.firstOrNull;
    _currentInterval =
        widget.initialIntervalMinutes ??
        _selectedMode?.defaultIntervalMinutes ??
        60;
  }

  IconData _getModeIcon(String? iconKey) {
    switch (iconKey) {
      case 'routine':
        return Icons.schedule_outlined;
      case 'shower':
        return Icons.shower_outlined;
      case 'sleep':
        return Icons.bedtime_outlined;
      case 'walk':
        return Icons.directions_walk_outlined;
      default:
        return Icons.shield_outlined;
    }
  }

  String _formatInterval(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final remainingMin = minutes % 60;
    if (remainingMin == 0) {
      return '$hours h ($minutes min)';
    }
    return '${hours}h ${remainingMin}m ($minutes min)';
  }

  void _showCreateModeDialog(BuildContext context) {
    final nameController = TextEditingController();
    var interval = 30;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.linho,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Novo Modo Customizado',
                style: AppTypography.h3,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Modo',
                      hintText: 'Ex: Caminhada, Leitura...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Intervalo: ${_formatInterval(interval)}',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.petroleo,
                    ),
                  ),
                  Slider(
                    value: interval.toDouble().clamp(1.0, 720.0),
                    min: 1,
                    max: 720,
                    divisions: 719,
                    activeColor: AppColors.petroleo,
                    inactiveColor: AppColors.linhoEscuro,
                    onChanged: (val) {
                      setDialogState(() {
                        interval = val.round();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancelar',
                    style: AppTypography.button.copyWith(
                      color: AppColors.cinzaTexto,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.petroleo,
                    foregroundColor: AppColors.linho,
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty && interval > 0) {
                      context.read<CheckinBloc>().add(
                        CreateCustomModeRequested(
                          name: name,
                          defaultIntervalMinutes: interval,
                        ),
                      );
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CheckinBloc, CheckinState>(
      listener: (context, state) {
        if (state is CheckinIdle && state.selectedMode != null) {
          setState(() {
            _selectedMode = state.selectedMode;
            _currentInterval = state.selectedMode!.defaultIntervalMinutes;
          });
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Modos de Monitoramento',
                  style: AppTypography.h3.copyWith(color: AppColors.petroleo),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _showCreateModeDialog(context),
                icon: const Icon(
                  Icons.add,
                  size: 18,
                  color: AppColors.petroleo,
                ),
                label: Text(
                  'Criar modo',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.petroleo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Lista de cards dos modos
          ...widget.modes.map((mode) {
            final isSelected = _selectedMode?.id == mode.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                backgroundColor: isSelected ? Colors.white : AppColors.linho,
                borderColor: isSelected
                    ? AppColors.petroleo
                    : AppColors.linhoEscuro,
                onTap: () {
                  setState(() {
                    _selectedMode = mode;
                    _currentInterval = mode.defaultIntervalMinutes;
                  });
                  context.read<CheckinBloc>().add(SelectModeRequested(mode));
                },
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.petroleo
                            : AppColors.linhoEscuro,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getModeIcon(mode.iconKey),
                        color: isSelected ? Colors.white : AppColors.petroleo,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  mode.name,
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.petroleo,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (mode.isSystemDefault) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.linhoEscuro,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Padrão',
                                    style: AppTypography.caption.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.petroleo,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Padrão: ${_formatInterval(mode.defaultIntervalMinutes)}',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? AppColors.petroleo
                          : AppColors.cinzaTexto,
                    ),
                  ],
                ),
              ),
            );
          }),
          if (_selectedMode != null) ...[
            const SizedBox(height: 12),
            AppCard(
              backgroundColor: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Ajustar Intervalo',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.petroleo,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatInterval(_currentInterval),
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.petroleo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _currentInterval.toDouble().clamp(1.0, 720.0),
                    min: 1,
                    max: 720,
                    divisions: 719,
                    activeColor: AppColors.petroleo,
                    inactiveColor: AppColors.linhoEscuro,
                    onChanged: (val) {
                      setState(() {
                        _currentInterval = val.round();
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1 min', style: AppTypography.caption),
                      Text('12 horas', style: AppTypography.caption),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppPrimaryButton(
              text:
                  'Iniciar ${_selectedMode!.name} (${_formatInterval(_currentInterval)})',
              icon: Icons.play_arrow,
              onPressed: () {
                widget.onStartMonitoring(_selectedMode!, _currentInterval);
              },
            ),
          ],
        ],
      ),
    );
  }
}
