import 'package:equatable/equatable.dart';
import '../../../panic/domain/entities/panic_alert_entity.dart';
import 'monitoring_snapshot_entity.dart';

/// Situação exibida à família.
enum WellbeingLevel {
  /// Monitoramento ativo e dentro do prazo.
  ok,

  /// Prazo vencido: o celular da pessoa está tocando o alarme.
  late,

  /// Pânico ou check-in não respondido: os contatos foram acionados.
  emergency,

  /// Monitoramento desligado pela própria pessoa.
  paused,
}

/// Resumo do bem-estar exibido à família. Deliberadamente mínimo (não
/// invasivo): situação atual, último sinal de vida e, somente em emergência,
/// a localização enviada pelo alerta.
class WellbeingStatus extends Equatable {
  const WellbeingStatus({
    required this.level,
    this.lastSignal,
    this.nextDeadline,
    this.alertEvent,
  });

  /// Deriva a situação a partir do estado do monitoramento e dos eventos
  /// recentes (em qualquer ordem). Função pura: testável sem backend.
  factory WellbeingStatus.evaluate({
    required MonitoringSnapshotEntity? snapshot,
    required List<PanicAlertEntity> events,
    required DateTime now,
  }) {
    final sorted = [...events]
      ..sort(
        (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
          a.createdAt ?? DateTime(0),
        ),
      );

    const alertTypes = {'panic', 'alert_triggered'};
    const okTypes = {'checkin', 'alert_resolved', 'routine_start'};

    final lastAlert = sorted
        .where((e) => alertTypes.contains(e.eventType))
        .firstOrNull;
    final lastOk = sorted
        .where((e) => okTypes.contains(e.eventType))
        .firstOrNull;

    DateTime? lastSignal = snapshot?.lastPing;
    final lastOkAt = lastOk?.createdAt;
    if (lastOkAt != null &&
        (lastSignal == null || lastOkAt.isAfter(lastSignal))) {
      lastSignal = lastOkAt;
    }

    final alertAt = lastAlert?.createdAt;
    final alertIsOpen =
        alertAt != null &&
        now.difference(alertAt) < const Duration(hours: 24) &&
        (lastOkAt == null || lastOkAt.isBefore(alertAt));

    if (alertIsOpen) {
      return WellbeingStatus(
        level: WellbeingLevel.emergency,
        lastSignal: lastSignal,
        nextDeadline: snapshot?.nextDeadline,
        alertEvent: lastAlert,
      );
    }

    if (snapshot == null || !snapshot.active) {
      return WellbeingStatus(
        level: WellbeingLevel.paused,
        lastSignal: lastSignal,
      );
    }

    final deadline = snapshot.nextDeadline;
    return WellbeingStatus(
      level: deadline != null && now.isAfter(deadline)
          ? WellbeingLevel.late
          : WellbeingLevel.ok,
      lastSignal: lastSignal,
      nextDeadline: deadline,
    );
  }

  final WellbeingLevel level;
  final DateTime? lastSignal;
  final DateTime? nextDeadline;

  /// Evento que originou a emergência (pânico ou check-in não respondido).
  final PanicAlertEntity? alertEvent;

  bool get isPanic => alertEvent?.eventType == 'panic';

  @override
  List<Object?> get props => [level, lastSignal, nextDeadline, alertEvent];
}
