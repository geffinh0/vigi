import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/emergency_dispatcher.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/panic_alert_entity.dart';
import '../../domain/usecases/resolve_panic_usecase.dart';
import '../../domain/usecases/trigger_panic_usecase.dart';
import 'panic_event.dart';
import 'panic_state.dart';

class PanicBloc extends Bloc<PanicEvent, PanicState> {
  PanicBloc({
    required this.triggerPanicUseCase,
    required this.resolvePanicUseCase,
    this.emergencyDispatcher,
  }) : super(const PanicInitial()) {
    on<PanicTriggered>(_onPanicTriggered);
    on<PanicResolved>(_onPanicResolved);
  }

  final TriggerPanicUseCase triggerPanicUseCase;
  final ResolvePanicUseCase resolvePanicUseCase;
  final EmergencyDispatcher? emergencyDispatcher;

  Future<void> _onPanicTriggered(
    PanicTriggered event,
    Emitter<PanicState> emit,
  ) async {
    emit(const PanicLoading());
    final result = await triggerPanicUseCase(
      TriggerPanicParams(
        latitude: event.latitude,
        longitude: event.longitude,
      ),
    );

    // Mesmo que o registro no Supabase falhe (ex.: sem internet), os contatos
    // precisam ser avisados: o SMS segue pela operadora.
    final alert = result.getOrElse(
      (_) => PanicAlertEntity(
        id: 'local',
        userId: '',
        eventType: 'panic',
        latitude: event.latitude,
        longitude: event.longitude,
        createdAt: DateTime.now(),
      ),
    );

    final dispatch = await emergencyDispatcher?.dispatch(
      reason: EmergencyReason.panic,
      latitude: alert.latitude,
      longitude: alert.longitude,
      eventId: result.isRight() ? alert.id : null,
    );

    if (result.isLeft() && (dispatch == null || dispatch.smsSent == 0)) {
      result.mapLeft((failure) => emit(PanicFailure(failure.message)));
      return;
    }

    emit(
      PanicActive(
        alert,
        contactsFound: dispatch?.contactsFound,
        smsSent: dispatch?.smsSent,
      ),
    );
  }

  Future<void> _onPanicResolved(
    PanicResolved event,
    Emitter<PanicState> emit,
  ) async {
    emit(const PanicLoading());
    final result = await resolvePanicUseCase(const NoParams());
    result.fold(
      (failure) => emit(PanicFailure(failure.message)),
      (_) => emit(const PanicResolvedState()),
    );
  }
}
