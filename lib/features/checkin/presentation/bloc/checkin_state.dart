import 'package:equatable/equatable.dart';
import '../../../../core/services/emergency_dispatcher.dart';
import '../../../../core/theme/vigi_state.dart';
import '../../domain/entities/monitoring_mode_entity.dart';

/// Estados do `CheckinBloc`. Cada um corresponde a um degrau da escada de
/// estados do Vigi ([vigiState]).
abstract class CheckinState extends Equatable {
  const CheckinState();

  /// Degrau da escada em que o app está.
  VigiState get vigiState => VigiState.descansando;

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

/// **Descansando**: monitoramento pausado, com os modos disponíveis.
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

/// **Vigiando** (ou **Noturno**, no modo Sono): monitoramento ativo, prazo
/// distante. Logo após uma confirmação fica **Aliviado** por 3 segundos.
class CheckinMonitoring extends CheckinState {
  const CheckinMonitoring({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.nextDeadline,
    this.activeMode,
    this.availableModes = const [],
    this.relieved = false,
    this.reliefAfterAlert = false,
  });

  final int remainingSeconds;
  final int totalSeconds;
  final DateTime nextDeadline;
  final MonitoringModeEntity? activeMode;
  final List<MonitoringModeEntity> availableModes;

  /// A pessoa acabou de confirmar: a coruja pisca e agradece.
  final bool relieved;

  /// A confirmação encerrou um alerta: o texto diz também que os contatos
  /// foram avisados de que está tudo bem.
  final bool reliefAfterAlert;

  /// Fração do prazo que ainda resta (1.0 = prazo inteiro). É o que o anel
  /// de vigília mostra.
  double get remainingFraction => totalSeconds > 0
      ? (remainingSeconds / totalSeconds).clamp(0.0, 1.0)
      : 0.0;

  bool get isSleep => activeMode?.isSleep ?? false;

  @override
  VigiState get vigiState {
    if (relieved) return VigiState.aliviado;
    return isSleep ? VigiState.noturno : VigiState.vigiando;
  }

  @override
  List<Object?> get props => [
    remainingSeconds,
    totalSeconds,
    nextDeadline,
    activeMode,
    availableModes,
    relieved,
    reliefAfterAlert,
  ];
}

/// **Sua vez** e, nos minutos finais da tolerância, **Última chamada**: o
/// prazo chegou e o Vigi pergunta se está tudo bem.
class CheckinCalling extends CheckinState {
  const CheckinCalling({
    required this.deadline,
    required this.lastCallAt,
    required this.escalatesAt,
    this.lastCall = false,
    this.canSnooze = true,
    this.activeMode,
  });

  /// Quando o check-in venceu.
  final DateTime deadline;

  /// Quando começa a última chamada.
  final DateTime lastCallAt;

  /// Quando os contatos serão avisados se não houver resposta.
  final DateTime escalatesAt;

  final bool lastCall;

  /// "Preciso de mais 10 minutos" ainda não foi usado neste ciclo.
  final bool canSnooze;
  final MonitoringModeEntity? activeMode;

  @override
  VigiState get vigiState =>
      lastCall ? VigiState.ultimaChamada : VigiState.suaVez;

  @override
  List<Object?> get props => [
    deadline,
    lastCallAt,
    escalatesAt,
    lastCall,
    canSnooze,
    activeMode,
  ];
}

/// **Alerta**: a pessoa não respondeu e os contatos foram avisados.
class CheckinAlertActive extends CheckinState {
  const CheckinAlertActive({
    required this.expiredAt,
    required this.alertedAt,
    this.activeMode,
    this.contactsFound = 0,
    this.smsSent = 0,
    this.deliveries = const [],
    this.latitude,
    this.longitude,
    this.address,
  });

  /// Quando o check-in venceu.
  final DateTime expiredAt;

  /// Quando os contatos foram avisados.
  final DateTime alertedAt;
  final MonitoringModeEntity? activeMode;

  final int contactsFound;
  final int smsSent;

  /// Quem foi avisado e se a mensagem saiu.
  final List<ContactDelivery> deliveries;
  final double? latitude;
  final double? longitude;

  /// Endereço aproximado enviado aos contatos.
  final String? address;

  bool get hasLocation => latitude != null && longitude != null;

  @override
  VigiState get vigiState => VigiState.alerta;

  @override
  List<Object?> get props => [
    expiredAt,
    alertedAt,
    activeMode,
    contactsFound,
    smsSent,
    deliveries,
    latitude,
    longitude,
    address,
  ];
}

/// Erro exibido ao usuário.
class CheckinFailure extends CheckinState {
  const CheckinFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
