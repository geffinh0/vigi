import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/checkin_repository.dart';

/// Dados enviados junto com a confirmação.
class ConfirmCheckinParams extends Equatable {
  const ConfirmCheckinParams({
    this.latitude,
    this.longitude,
    this.intervalMinutes,
    this.modeId,
    this.resolvesAlert = false,
  });

  final double? latitude;
  final double? longitude;

  /// Intervalo do próximo ciclo. Ao sair de um modo temporário (Banho, Sono)
  /// o app volta para a Rotina, e o servidor precisa saber disso para não
  /// esperar o check-in no prazo errado.
  final int? intervalMinutes;

  /// Modo do próximo ciclo.
  final String? modeId;

  /// A confirmação encerra um alerta em que os contatos já foram avisados.
  final bool resolvesAlert;

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    intervalMinutes,
    modeId,
    resolvesAlert,
  ];
}

/// Confirma que a pessoa está bem e renova o prazo.
class ConfirmCheckinUseCase implements UseCase<void, ConfirmCheckinParams> {
  ConfirmCheckinUseCase(this.repository);

  final CheckinRepository repository;

  @override
  Future<Either<Failure, void>> call(ConfirmCheckinParams params) {
    return repository.confirmCheckin(
      latitude: params.latitude,
      longitude: params.longitude,
      intervalMinutes: params.intervalMinutes,
      modeId: params.modeId,
      resolvesAlert: params.resolvesAlert,
    );
  }
}
