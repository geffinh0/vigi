import 'package:equatable/equatable.dart';
import '../../../../core/services/emergency_dispatcher.dart';
import '../../domain/entities/panic_alert_entity.dart';

/// Estados do `PanicBloc`.
abstract class PanicState extends Equatable {
  const PanicState();

  @override
  List<Object?> get props => [];
}

/// Nenhum pânico ativo.
class PanicInitial extends PanicState {
  const PanicInitial();
}

/// Enviando o alerta.
class PanicLoading extends PanicState {
  const PanicLoading();
}

/// Pedido de ajuda ativo, com o resultado do envio dos SMS.
class PanicActive extends PanicState {
  const PanicActive(
    this.alert, {
    this.contactsFound,
    this.smsSent,
    this.deliveries = const [],
    this.sentAt,
    this.address,
  });

  final PanicAlertEntity alert;

  /// Quantidade de contatos de emergência encontrados no momento do disparo.
  final int? contactsFound;

  /// Quantidade de SMS enviados automaticamente pelo aparelho.
  final int? smsSent;

  /// Quem foi avisado e se a mensagem saiu.
  final List<ContactDelivery> deliveries;

  /// Quando os contatos foram avisados.
  final DateTime? sentAt;

  /// Endereço aproximado enviado aos contatos.
  final String? address;

  @override
  List<Object?> get props => [
    alert,
    contactsFound,
    smsSent,
    deliveries,
    sentAt,
    address,
  ];
}

/// Pedido cancelado pela pessoa. [contactsNotified] diz se os contatos já
/// tinham sido avisados (e, portanto, receberam também o cancelamento).
class PanicResolvedState extends PanicState {
  const PanicResolvedState({this.contactsNotified = false});

  final bool contactsNotified;

  @override
  List<Object?> get props => [contactsNotified];
}

/// Erro exibido ao usuário.
class PanicFailure extends PanicState {
  const PanicFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
