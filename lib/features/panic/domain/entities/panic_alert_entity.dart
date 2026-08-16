import 'package:equatable/equatable.dart';

/// Entidade de domínio representando um alerta de pânico ou emergência.
class PanicAlertEntity extends Equatable {
  const PanicAlertEntity({
    required this.id,
    required this.userId,
    required this.eventType,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String eventType;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
    id,
    userId,
    eventType,
    latitude,
    longitude,
    createdAt,
  ];
}
