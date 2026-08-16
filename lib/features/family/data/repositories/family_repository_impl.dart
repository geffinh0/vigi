import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../../../panic/domain/entities/panic_alert_entity.dart';
import '../../domain/entities/family_link_entity.dart';
import '../../domain/repositories/family_repository.dart';
import '../datasources/family_remote_datasource.dart';

class FamilyRepositoryImpl implements FamilyRepository {
  FamilyRepositoryImpl(this.remoteDataSource);

  final FamilyRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, List<FamilyLinkEntity>>> getFamilyLinks() async {
    try {
      final links = await remoteDataSource.getFamilyLinks();
      return Right(links);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Erro ao buscar vínculos: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FamilyLinkEntity>> createInvite({
    required String viewerUserId,
  }) async {
    try {
      final link = await remoteDataSource.createInvite(
        viewerUserId: viewerUserId,
      );
      return Right(link);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return const Left(
          ValidationFailure('Já existe um convite entre estes usuários.'),
        );
      }
      return Left(ServerFailure('Erro ao enviar convite: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> acceptInvite({required String linkId}) async {
    try {
      await remoteDataSource.acceptInvite(linkId: linkId);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Erro ao aceitar convite: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<PanicAlertEntity>> watchMonitoredEvents(String monitoredUserId) {
    return remoteDataSource.watchMonitoredEvents(monitoredUserId);
  }
}
