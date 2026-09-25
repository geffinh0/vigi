import 'package:equatable/equatable.dart';

/// Modo de monitoramento com seu intervalo padrão de check-in.
class MonitoringModeEntity extends Equatable {
  const MonitoringModeEntity({
    required this.id,
    required this.name,
    this.iconKey,
    required this.defaultIntervalMinutes,
    required this.isSystemDefault,
  });

  final String id;
  final String name;
  final String? iconKey;
  final int defaultIntervalMinutes;
  final bool isSystemDefault;

  MonitoringModeEntity copyWith({
    String? id,
    String? name,
    String? iconKey,
    int? defaultIntervalMinutes,
    bool? isSystemDefault,
  }) {
    return MonitoringModeEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      defaultIntervalMinutes:
          defaultIntervalMinutes ?? this.defaultIntervalMinutes,
      isSystemDefault: isSystemDefault ?? this.isSystemDefault,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    iconKey,
    defaultIntervalMinutes,
    isSystemDefault,
  ];
}
