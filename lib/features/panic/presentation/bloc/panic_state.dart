import 'package:equatable/equatable.dart';
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

/// Pânico ativo, com o resultado do envio dos SMS.
class PanicActive extends PanicState {
  const PanicActive(this.alert, {this.contactsFound, this.smsSent});

  final PanicAlertEntity alert;

  /// Quantidade de contatos de emergência encontrados no momento do disparo.
  final int? contactsFound;

  /// Quantidade de SMS enviados automaticamente pelo aparelho.
  final int? smsSent;

  @override
  List<Object?> get props => [alert, contactsFound, smsSent];
}

/// Alerta encerrado.
class PanicResolvedState extends PanicState {
  const PanicResolvedState();
}

/// Erro exibido ao usuário.
class PanicFailure extends PanicState {
  const PanicFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
