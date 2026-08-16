import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/resolve_panic_usecase.dart';
import '../../domain/usecases/trigger_panic_usecase.dart';
import 'panic_event.dart';
import 'panic_state.dart';

class PanicBloc extends Bloc<PanicEvent, PanicState> {
  PanicBloc({
    required this.triggerPanicUseCase,
    required this.resolvePanicUseCase,
  }) : super(const PanicInitial()) {
    on<PanicTriggered>(_onPanicTriggered);
    on<PanicResolved>(_onPanicResolved);
  }

  final TriggerPanicUseCase triggerPanicUseCase;
  final ResolvePanicUseCase resolvePanicUseCase;

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
    result.fold(
      (failure) => emit(PanicFailure(failure.message)),
      (alert) => emit(PanicActive(alert)),
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
