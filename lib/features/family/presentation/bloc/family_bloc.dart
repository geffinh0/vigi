import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/accept_family_invite_usecase.dart';
import '../../domain/usecases/get_family_links_usecase.dart';
import '../../domain/usecases/send_family_invite_usecase.dart';
import 'family_event.dart';
import 'family_state.dart';

class FamilyBloc extends Bloc<FamilyEvent, FamilyState> {
  FamilyBloc({
    required this.getFamilyLinksUseCase,
    required this.sendFamilyInviteUseCase,
    required this.acceptFamilyInviteUseCase,
  }) : super(const FamilyInitial()) {
    on<LoadFamilyLinksRequested>(_onLoadFamilyLinksRequested);
    on<SendFamilyInviteRequested>(_onSendFamilyInviteRequested);
    on<AcceptFamilyInviteRequested>(_onAcceptFamilyInviteRequested);
  }

  final GetFamilyLinksUseCase getFamilyLinksUseCase;
  final SendFamilyInviteUseCase sendFamilyInviteUseCase;
  final AcceptFamilyInviteUseCase acceptFamilyInviteUseCase;

  Future<void> _onLoadFamilyLinksRequested(
    LoadFamilyLinksRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(const FamilyLoading());
    final result = await getFamilyLinksUseCase(const NoParams());
    result.fold(
      (failure) => emit(FamilyFailure(failure.message)),
      (links) => emit(FamilyLoaded(links)),
    );
  }

  Future<void> _onSendFamilyInviteRequested(
    SendFamilyInviteRequested event,
    Emitter<FamilyState> emit,
  ) async {
    final result = await sendFamilyInviteUseCase(
      SendFamilyInviteParams(viewerUserId: event.viewerUserId),
    );
    result.fold(
      (failure) => emit(FamilyFailure(failure.message)),
      (_) => add(const LoadFamilyLinksRequested()),
    );
  }

  Future<void> _onAcceptFamilyInviteRequested(
    AcceptFamilyInviteRequested event,
    Emitter<FamilyState> emit,
  ) async {
    final result = await acceptFamilyInviteUseCase(
      AcceptFamilyInviteParams(linkId: event.linkId),
    );
    result.fold(
      (failure) => emit(FamilyFailure(failure.message)),
      (_) => add(const LoadFamilyLinksRequested()),
    );
  }
}
