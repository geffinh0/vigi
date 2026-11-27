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

  bool get _isShower =>
      iconKey == 'shower' || name.toLowerCase().contains('banho');

  /// Modo Sono: ativa o tema noturno e a coruja noturna.
  bool get isSleep => iconKey == 'sleep' || name.toLowerCase().contains('sono');

  bool get isShower => _isShower;

  /// Modo Rotina: o padrão, para onde o app volta depois de um modo
  /// temporário.
  bool get isRoutine =>
      iconKey == 'routine' || name.toLowerCase().contains('rotina');

  /// Modos temporários (Banho, Sono): ao confirmar, o app volta à Rotina.
  bool get isTemporary => _isShower || isSleep;

  /// Nome curto para a interface: "Rotina padrão" vira "Rotina".
  String get shortName => isRoutine && isSystemDefault ? 'Rotina' : name;

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
