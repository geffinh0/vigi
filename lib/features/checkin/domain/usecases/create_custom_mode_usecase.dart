import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/monitoring_mode_entity.dart';
import '../repositories/checkin_repository.dart';

class CreateCustomModeParams extends Equatable {
  const CreateCustomModeParams({
    required this.name,
    required this.defaultIntervalMinutes,
    this.iconKey,
  });

  final String name;
  final int defaultIntervalMinutes;
  final String? iconKey;

  @override
  List<Object?> get props => [name, defaultIntervalMinutes, iconKey];
}

class CreateCustomModeUseCase
    implements UseCase<MonitoringModeEntity, CreateCustomModeParams> {
  CreateCustomModeUseCase(this.repository);

  final CheckinRepository repository;

  @override
  Future<Either<Failure, MonitoringModeEntity>> call(
    CreateCustomModeParams params,
  ) async {
    if (params.name.trim().isEmpty) {
      return const Left(
        ValidationFailure('Nome do modo não pode ser vazio'),
      );
    }
    if (params.defaultIntervalMinutes <= 0) {
      return const Left(
        ValidationFailure('Intervalo deve ser maior que 0 minutos'),
      );
    }

    return repository.createCustomMode(
      name: params.name.trim(),
      defaultIntervalMinutes: params.defaultIntervalMinutes,
      iconKey: params.iconKey,
    );
  }
}
