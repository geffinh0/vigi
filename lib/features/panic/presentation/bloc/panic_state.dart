import 'package:equatable/equatable.dart';
import '../../domain/entities/panic_alert_entity.dart';

abstract class PanicState extends Equatable {
  const PanicState();

  @override
  List<Object?> get props => [];
}

class PanicInitial extends PanicState {
  const PanicInitial();
}

class PanicLoading extends PanicState {
  const PanicLoading();
}

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

class PanicResolvedState extends PanicState {
  const PanicResolvedState();
}

class PanicFailure extends PanicState {
  const PanicFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
