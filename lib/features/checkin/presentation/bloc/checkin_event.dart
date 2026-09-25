import 'package:equatable/equatable.dart';
import '../../domain/entities/monitoring_mode_entity.dart';

/// Eventos do `CheckinBloc`.
abstract class CheckinEvent extends Equatable {
  const CheckinEvent();

  @override
  List<Object?> get props => [];
}

/// Carrega modos e estado do monitoramento (após o login).
class LoadCheckinStatusRequested extends CheckinEvent {
  const LoadCheckinStatusRequested();
}

/// Recarrega a lista de modos.
class LoadAvailableModesRequested extends CheckinEvent {
  const LoadAvailableModesRequested();
}

/// Seleciona um modo na tela inicial.
class SelectModeRequested extends CheckinEvent {
  const SelectModeRequested(this.mode);

  final MonitoringModeEntity mode;

  @override
  List<Object?> get props => [mode];
}

/// Salva o intervalo de um modo.
class SaveMonitoringSettingsRequested extends CheckinEvent {
  const SaveMonitoringSettingsRequested({
    required this.modeId,
    required this.intervalMinutes,
  });

  final String modeId;
  final int intervalMinutes;

  @override
  List<Object?> get props => [modeId, intervalMinutes];
}

/// Inicia o monitoramento em um modo.
class StartMonitoringRequested extends CheckinEvent {
  const StartMonitoringRequested({
    required this.modeId,
    this.intervalOverrideMinutes,
  });

  final String modeId;
  final int? intervalOverrideMinutes;

  @override
  List<Object?> get props => [modeId, intervalOverrideMinutes];
}

/// Cria um modo personalizado.
class CreateCustomModeRequested extends CheckinEvent {
  const CreateCustomModeRequested({
    required this.name,
    required this.defaultIntervalMinutes,
    this.iconKey,
  });

  final String name;
  final int defaultIntervalMinutes;
  final String? iconKey;

  @override
  List<Object?> get props => [name, defaultIntervalMinutes, iconKey];
}

/// "Estou bem": renova o prazo e silencia o alarme.
class ConfirmCheckinRequested extends CheckinEvent {
  const ConfirmCheckinRequested({this.latitude, this.longitude});

  final double? latitude;
  final double? longitude;

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Pausa o monitoramento.
class StopMonitoringRequested extends CheckinEvent {
  const StopMonitoringRequested();
}

/// Pulso de 1 s da contagem regressiva (interno).
class CheckinTickReceived extends CheckinEvent {
  const CheckinTickReceived({
    required this.remainingSeconds,
    required this.nextDeadline,
    this.activeMode,
  });

  final int remainingSeconds;
  final DateTime nextDeadline;
  final MonitoringModeEntity? activeMode;

  @override
  List<Object?> get props => [remainingSeconds, nextDeadline, activeMode];
}

/// Disparado internamente quando o alarme de check-in expirado não é
/// respondido dentro do período de tolerância: aciona os contatos de emergência.
class CheckinEscalationRequested extends CheckinEvent {
  const CheckinEscalationRequested();
}
