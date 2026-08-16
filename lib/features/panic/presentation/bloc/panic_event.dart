import 'package:equatable/equatable.dart';

abstract class PanicEvent extends Equatable {
  const PanicEvent();

  @override
  List<Object?> get props => [];
}

class PanicTriggered extends PanicEvent {
  const PanicTriggered({this.latitude, this.longitude});

  final double? latitude;
  final double? longitude;

  @override
  List<Object?> get props => [latitude, longitude];
}

class PanicResolved extends PanicEvent {
  const PanicResolved();
}
