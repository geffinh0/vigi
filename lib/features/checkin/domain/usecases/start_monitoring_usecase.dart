import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../contacts/domain/repositories/contacts_repository.dart';
import '../repositories/checkin_repository.dart';

/// Modo e, opcionalmente, um intervalo diferente do padrão.
class StartMonitoringParams extends Equatable {
  const StartMonitoringParams({
    required this.modeId,
    this.intervalOverrideMinutes,
  });

  final String modeId;
  final int? intervalOverrideMinutes;

  @override
  List<Object?> get props => [modeId, intervalOverrideMinutes];
}

/// Inicia o monitoramento; exige ao menos um contato de emergência.
class StartMonitoringUseCase implements UseCase<void, StartMonitoringParams> {
  StartMonitoringUseCase(this.repository, this.contactsRepository);

  final CheckinRepository repository;
  final ContactsRepository contactsRepository;

  @override
  Future<Either<Failure, void>> call(StartMonitoringParams params) async {
    if (params.modeId.trim().isEmpty) {
      return const Left(
        ValidationFailure('Modo de monitoramento inválido'),
      );
    }
    if (params.intervalOverrideMinutes != null &&
        params.intervalOverrideMinutes! <= 0) {
      return const Left(
        ValidationFailure('Intervalo deve ser maior que 0 minutos'),
      );
    }

    final contactsResult = await contactsRepository.getContacts();
    return contactsResult.fold(
      Left.new,
      (contacts) {
        if (contacts.isEmpty) {
          return const Left(
            ValidationFailure(
              'Cadastre ao menos um contato de emergência antes de ativar o monitoramento',
            ),
          );
        }
        return repository.startMonitoring(
          modeId: params.modeId,
          intervalOverrideMinutes: params.intervalOverrideMinutes,
        );
      },
    );
  }
}
