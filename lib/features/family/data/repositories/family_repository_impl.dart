import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../../../panic/domain/entities/panic_alert_entity.dart';
import '../../domain/entities/family_link_entity.dart';
import '../../domain/entities/monitoring_snapshot_entity.dart';
import '../../domain/repositories/family_repository.dart';
import '../datasources/family_remote_datasource.dart';

class FamilyRepositoryImpl implements FamilyRepository {
  FamilyRepositoryImpl(this.remoteDataSource);

  final FamilyRemoteDataSource remoteDataSource;

  /// As funções do banco lançam mensagens já amigáveis (ex.: código inválido).
  Future<Either<Failure, T>> _guard<T>(
    Future<T> Function() action,
    String context,
  ) async {
    try {
      return Right(await action());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      final isFriendly = e.code == 'P0001';
      return Left(
        ServerFailure(isFriendly ? e.message : '$context: ${e.message}'),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FamilyLinkEntity>>> getFamilyLinks() =>
      _guard(remoteDataSource.getFamilyLinks, 'Erro ao buscar vínculos');

  @override
  Future<Either<Failure, String>> getMyLinkCode() =>
      _guard(remoteDataSource.getMyLinkCode, 'Erro ao gerar código');

  @override
  Future<Either<Failure, String>> requestLinkByCode(String code) => _guard(
    () => remoteDataSource.requestLinkByCode(code),
    'Erro ao enviar pedido',
  );

  @override
  Future<Either<Failure, void>> respondToLink({
    required String linkId,
    required bool accept,
  }) => _guard(
    () => remoteDataSource.respondToLink(linkId: linkId, accept: accept),
    'Erro ao responder pedido',
  );

  @override
  Future<Either<Failure, void>> removeLink(String linkId) => _guard(
    () => remoteDataSource.removeLink(linkId),
    'Erro ao remover vínculo',
  );

  @override
  Stream<void> watchLinksChanges() => remoteDataSource.watchLinksChanges();

  @override
  Stream<MonitoringSnapshotEntity?> watchMonitoringSnapshot(String userId) =>
      remoteDataSource.watchMonitoringSnapshot(userId);

  @override
  Stream<List<PanicAlertEntity>> watchMonitoredEvents(String monitoredUserId) =>
      remoteDataSource.watchMonitoredEvents(monitoredUserId);

  @override
  Future<Map<String, String>> getModeNames() async {
    try {
      return await remoteDataSource.getModeNames();
    } catch (_) {
      return const {};
    }
  }
}
