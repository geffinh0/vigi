import 'package:equatable/equatable.dart';

/// Eventos do `PanicBloc`.
abstract class PanicEvent extends Equatable {
  const PanicEvent();

  @override
  List<Object?> get props => [];
}

/// Botão de pânico acionado.
class PanicTriggered extends PanicEvent {
  const PanicTriggered({this.latitude, this.longitude});

  final double? latitude;
  final double? longitude;

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Usuário informou que está seguro.
class PanicResolved extends PanicEvent {
  const PanicResolved();
}
