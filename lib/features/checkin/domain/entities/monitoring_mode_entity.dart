import 'package:equatable/equatable.dart';

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

  @override
  List<Object?> get props => [
    id,
    name,
    iconKey,
    defaultIntervalMinutes,
    isSystemDefault,
  ];
}
