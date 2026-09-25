import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/clock.dart';
import '../../domain/entities/monitoring_mode_entity.dart';
import '../../domain/entities/monitoring_status_entity.dart';
import '../../domain/repositories/checkin_repository.dart';
import '../datasources/checkin_remote_datasource.dart';

/// Calcula os prazos (next_deadline) e converte exceções em [Failure].
class CheckinRepositoryImpl implements CheckinRepository {
  CheckinRepositoryImpl({
    required this.remoteDataSource,
    required this.clock,
  });

  final CheckinRemoteDataSource remoteDataSource;
  final Clock clock;

  @override
  Future<Either<Failure, void>> saveMonitoringSettings({
    required String modeId,
    required int intervalMinutes,
  }) async {
    try {
      await remoteDataSource.saveSettings(
        modeId: modeId,
        intervalMinutes: intervalMinutes,
      );
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Erro ao salvar configurações: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> startMonitoring({
    required String modeId,
    int? intervalOverrideMinutes,
  }) async {
    try {
      var interval = intervalOverrideMinutes ?? 60;
      if (intervalOverrideMinutes == null) {
        final modes = await remoteDataSource.getAvailableModes();
        final mode = modes.where((m) => m.id == modeId).firstOrNull;
        if (mode != null) {
          interval = mode.defaultIntervalMinutes;
        }
      }

      final nextDeadline = clock.now().add(Duration(minutes: interval));
      await remoteDataSource.startMonitoring(
        modeId: modeId,
        intervalMinutes: interval,
        nextDeadline: nextDeadline,
      );
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Erro ao iniciar monitoramento: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MonitoringModeEntity>>>
  getAvailableModes() async {
    try {
      final modes = await remoteDataSource.getAvailableModes();
      return Right(modes);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Erro ao carregar modos: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MonitoringModeEntity>> createCustomMode({
    required String name,
    required int defaultIntervalMinutes,
    String? iconKey,
  }) async {
    try {
      final mode = await remoteDataSource.createCustomMode(
        name: name,
        defaultIntervalMinutes: defaultIntervalMinutes,
        iconKey: iconKey,
      );
      return Right(mode);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Erro ao criar modo: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> confirmCheckin({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final currentStatus = await remoteDataSource.getStatus();
      final nextDeadline = clock.now().add(
        Duration(minutes: currentStatus.intervalMinutes),
      );

      await remoteDataSource.confirmCheckin(
        nextDeadline: nextDeadline,
        latitude: latitude,
        longitude: longitude,
      );
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Erro ao confirmar check-in: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> stopMonitoring() async {
    try {
      await remoteDataSource.stopMonitoring();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Erro ao pausar monitoramento: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MonitoringStatusEntity>> getStatus() async {
    try {
      final status = await remoteDataSource.getStatus();
      return Right(status);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Erro ao carregar status: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
