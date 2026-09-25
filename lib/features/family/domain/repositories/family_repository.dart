import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../panic/domain/entities/panic_alert_entity.dart';
import '../entities/family_link_entity.dart';
import '../entities/monitoring_snapshot_entity.dart';

abstract class FamilyRepository {
  Future<Either<Failure, List<FamilyLinkEntity>>> getFamilyLinks();

  Future<Either<Failure, String>> getMyLinkCode();

  /// Retorna o nome da pessoa que precisa autorizar o pedido.
  Future<Either<Failure, String>> requestLinkByCode(String code);

  Future<Either<Failure, void>> respondToLink({
    required String linkId,
    required bool accept,
  });

  Future<Either<Failure, void>> removeLink(String linkId);

  Stream<void> watchLinksChanges();

  Stream<MonitoringSnapshotEntity?> watchMonitoringSnapshot(String userId);

  Stream<List<PanicAlertEntity>> watchMonitoredEvents(String monitoredUserId);

  Future<Map<String, String>> getModeNames();
}
