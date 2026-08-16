import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../errors/failures.dart';

/// Contrato padrao para casos de uso assincronos com Either.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Parametro vazio para casos de uso que nao exigem argumentos.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
