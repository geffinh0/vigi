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

class MonitoringSettingsPage extends StatefulWidget {
  const MonitoringSettingsPage({super.key});

  @override
  State<MonitoringSettingsPage> createState() => _MonitoringSettingsPageState();
}

class _MonitoringSettingsPageState extends State<MonitoringSettingsPage> {
  MonitoringModeEntity? _selectedMode;
  int _intervalMinutes = 60;
  List<MonitoringModeEntity> _modes = [];
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final state = context.read<CheckinBloc>().state;
      if (state is CheckinIdle) {
        _modes = state.availableModes;
        _selectedMode = state.selectedMode ?? _modes.firstOrNull;
        _intervalMinutes = state.intervalMinutes;
      }
      _initialized = true;
    }
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
    return Scaffold(
      backgroundColor: AppColors.linho,
      appBar: AppBar(
        title: const Text('Configurações de Rotina'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.petroleo),
            tooltip: 'Criar Modo Customizado',
            onPressed: () => _showCreateModeDialog(context),
          ),
        ],
      ),
      body: BlocListener<CheckinBloc, CheckinState>(
        listener: (context, state) {
          if (state is CheckinIdle) {
            setState(() {
              _modes = state.availableModes;
              if (_selectedMode == null ||
                  !_modes.any((m) => m.id == _selectedMode?.id)) {
                _selectedMode = state.selectedMode ?? _modes.firstOrNull;
              }
            });
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Modo Padrão de Monitoramento',
                  style: AppTypography.h3.copyWith(color: AppColors.petroleo),
                ),
                const SizedBox(height: 6),
                Text(
                  'Escolha o modo e o intervalo que serão ativados ao iniciar o monitoramento na tela inicial.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 16),
                ..._modes.map((mode) {
                  final isSelected = _selectedMode?.id == mode.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      backgroundColor: isSelected
                          ? Colors.white
                          : AppColors.linho,
                      borderColor: isSelected
                          ? AppColors.petroleo
                          : AppColors.linhoEscuro,
                      onTap: () {
                        setState(() {
                          _selectedMode = mode;
                          _intervalMinutes = mode.defaultIntervalMinutes;
                        });
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
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.petroleo,
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
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
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
                const SizedBox(height: 16),
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
                              'Intervalo Personalizado',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.petroleo,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatInterval(_intervalMinutes),
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.petroleo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _intervalMinutes.toDouble().clamp(1.0, 720.0),
                        min: 1,
                        max: 720,
                        divisions: 719,
                        activeColor: AppColors.petroleo,
                        inactiveColor: AppColors.linhoEscuro,
                        onChanged: (val) {
                          setState(() {
                            _intervalMinutes = val.round();
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
                const SizedBox(height: 24),
                AppPrimaryButton(
                  text: 'Salvar Configuração',
                  icon: Icons.check,
                  onPressed: () {
                    if (_selectedMode != null) {
                      context.read<CheckinBloc>().add(
                        SaveMonitoringSettingsRequested(
                          modeId: _selectedMode!.id,
                          intervalMinutes: _intervalMinutes,
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Configuração salva com sucesso!'),
                          backgroundColor: AppColors.petroleo,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
