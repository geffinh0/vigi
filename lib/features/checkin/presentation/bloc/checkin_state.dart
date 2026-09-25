import 'package:equatable/equatable.dart';
import '../../../../core/widgets/vigi_mascot.dart';
import '../../domain/entities/monitoring_mode_entity.dart';

/// Estados do `CheckinBloc`.
abstract class CheckinState extends Equatable {
  const CheckinState();

  @override
  List<Object?> get props => [];
}

/// Estado antes do carregamento.
class CheckinInitial extends CheckinState {
  const CheckinInitial();
}

/// Operação em andamento.
class CheckinLoading extends CheckinState {
  const CheckinLoading();
}

/// Monitoramento parado, com os modos disponíveis.
class CheckinIdle extends CheckinState {
  const CheckinIdle({
    this.intervalMinutes = 60,
    this.availableModes = const [],
    this.selectedMode,
  });

  final int intervalMinutes;
  final List<MonitoringModeEntity> availableModes;
  final MonitoringModeEntity? selectedMode;

  CheckinIdle copyWith({
    int? intervalMinutes,
    List<MonitoringModeEntity>? availableModes,
    MonitoringModeEntity? selectedMode,
  }) {
    return CheckinIdle(
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      availableModes: availableModes ?? this.availableModes,
      selectedMode: selectedMode ?? this.selectedMode,
    );
  }

  @override
  List<Object?> get props => [intervalMinutes, availableModes, selectedMode];
}

/// Monitoramento ativo com o tempo restante.
class CheckinMonitoring extends CheckinState {
  const CheckinMonitoring({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.nextDeadline,
    required this.vigiState,
    this.activeMode,
  });

  final int remainingSeconds;
  final int totalSeconds;
  final DateTime nextDeadline;
  final VigiState vigiState;
  final MonitoringModeEntity? activeMode;

  double get progress =>
      totalSeconds > 0 ? (totalSeconds - remainingSeconds) / totalSeconds : 0.0;

  @override
  List<Object?> get props => [
    remainingSeconds,
    totalSeconds,
    nextDeadline,
    vigiState,
    activeMode,
  ];
}

/// Prazo vencido: alarme tocando; após a tolerância, contatos avisados.
class CheckinAlertActive extends CheckinState {
  const CheckinAlertActive({
    required this.expiredAt,
    this.activeMode,
    this.escalatesAt,
    this.contactsFound,
    this.smsSent,
  });

  final DateTime expiredAt;
  final MonitoringModeEntity? activeMode;

  /// Momento em que os contatos de emergência serão acionados se não houver resposta.
  final DateTime? escalatesAt;

  /// Preenchidos após o acionamento automático dos contatos (dead man's switch).
  final int? contactsFound;
  final int? smsSent;

  bool get contactsAlerted => contactsFound != null;

  @override
  List<Object?> get props => [
    expiredAt,
    activeMode,
    escalatesAt,
    contactsFound,
    smsSent,
  ];
}

/// Erro exibido ao usuário.
class CheckinFailure extends CheckinState {
  const CheckinFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
