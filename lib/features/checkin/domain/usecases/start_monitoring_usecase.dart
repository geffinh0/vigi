import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../contacts/domain/repositories/contacts_repository.dart';
import '../repositories/checkin_repository.dart';

class StartMonitoringParams extends Equatable {
  const StartMonitoringParams({required this.intervalMinutes});

  final int intervalMinutes;

  @override
  List<Object?> get props => [intervalMinutes];
}

class StartMonitoringUseCase implements UseCase<void, StartMonitoringParams> {
  StartMonitoringUseCase(this.repository, this.contactsRepository);

  final CheckinRepository repository;
  final ContactsRepository contactsRepository;

  @override
  Future<Either<Failure, void>> call(StartMonitoringParams params) async {
    if (params.intervalMinutes <= 0) {
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
          intervalMinutes: params.intervalMinutes,
        );
      },
    );
  }
}
