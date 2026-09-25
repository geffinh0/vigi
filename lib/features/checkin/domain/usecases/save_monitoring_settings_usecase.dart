import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/checkin_repository.dart';

/// Modo e intervalo escolhidos nas configurações.
class SaveMonitoringSettingsParams extends Equatable {
  const SaveMonitoringSettingsParams({
    required this.modeId,
    required this.intervalMinutes,
  });

  final String modeId;
  final int intervalMinutes;

  @override
  List<Object?> get props => [modeId, intervalMinutes];
}

/// Salva o intervalo preferido de um modo.
class SaveMonitoringSettingsUseCase
    implements UseCase<void, SaveMonitoringSettingsParams> {
  const SaveMonitoringSettingsUseCase(this.repository);

  final CheckinRepository repository;

  @override
  Future<Either<Failure, void>> call(
    SaveMonitoringSettingsParams params,
  ) async {
    if (params.intervalMinutes <= 0) {
      return const Left(
        ValidationFailure(
          'O intervalo de monitoramento deve ser maior que 0 minutos.',
        ),
      );
    }
    if (params.modeId.trim().isEmpty) {
      return const Left(
        ValidationFailure('O modo de monitoramento não pode ser vazio.'),
      );
    }

    return repository.saveMonitoringSettings(
      modeId: params.modeId,
      intervalMinutes: params.intervalMinutes,
    );
  }
}
