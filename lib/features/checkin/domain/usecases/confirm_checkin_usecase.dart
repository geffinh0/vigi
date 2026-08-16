import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/checkin_repository.dart';

class ConfirmCheckinParams extends Equatable {
  const ConfirmCheckinParams({this.latitude, this.longitude});

  final double? latitude;
  final double? longitude;

  @override
  List<Object?> get props => [latitude, longitude];
}

class ConfirmCheckinUseCase implements UseCase<void, ConfirmCheckinParams> {
  ConfirmCheckinUseCase(this.repository);

  final CheckinRepository repository;

  @override
  Future<Either<Failure, void>> call(ConfirmCheckinParams params) {
    return repository.confirmCheckin(
      latitude: params.latitude,
      longitude: params.longitude,
    );
  }
}
