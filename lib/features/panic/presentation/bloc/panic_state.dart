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
  const PanicActive(this.alert);

  final PanicAlertEntity alert;

  @override
  List<Object?> get props => [alert];
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
