import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/panic_alert_entity.dart';
import '../../domain/repositories/panic_repository.dart';
import '../datasources/panic_remote_datasource.dart';

class PanicRepositoryImpl implements PanicRepository {
  PanicRepositoryImpl(this.remoteDataSource);

  final PanicRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, PanicAlertEntity>> triggerPanic({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final alert = await remoteDataSource.triggerPanic(
        latitude: latitude,
        longitude: longitude,
      );
      return Right(alert);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Erro ao disparar pânico: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resolvePanic() async {
    try {
      await remoteDataSource.resolvePanic();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Erro ao resolver pânico: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
