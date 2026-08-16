import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../panic/domain/entities/panic_alert_entity.dart';
import '../entities/family_link_entity.dart';

abstract class FamilyRepository {
  Future<Either<Failure, List<FamilyLinkEntity>>> getFamilyLinks();

  Future<Either<Failure, FamilyLinkEntity>> createInvite({
    required String viewerUserId,
  });

  Future<Either<Failure, void>> acceptInvite({
    required String linkId,
  });

  Stream<List<PanicAlertEntity>> watchMonitoredEvents(String monitoredUserId);
}
