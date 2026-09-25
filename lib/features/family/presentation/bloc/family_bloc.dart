import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/repositories/family_repository.dart';
import '../../domain/usecases/get_family_links_usecase.dart';
import '../../domain/usecases/get_my_link_code_usecase.dart';
import '../../domain/usecases/remove_family_link_usecase.dart';
import '../../domain/usecases/request_family_link_usecase.dart';
import '../../domain/usecases/respond_family_link_usecase.dart';
import 'family_event.dart';
import 'family_state.dart';

class FamilyBloc extends Bloc<FamilyEvent, FamilyState> {
  FamilyBloc({
    required this.getFamilyLinksUseCase,
    required this.getMyLinkCodeUseCase,
    required this.requestFamilyLinkUseCase,
    required this.respondFamilyLinkUseCase,
    required this.removeFamilyLinkUseCase,
    required this.currentUserId,
    this.repository,
  }) : super(const FamilyInitial()) {
    on<LoadFamilyLinksRequested>(_onLoad);
    on<RequestFamilyLinkRequested>(_onRequest);
    on<RespondFamilyLinkRequested>(_onRespond);
    on<RemoveFamilyLinkRequested>(_onRemove);
  }

  final GetFamilyLinksUseCase getFamilyLinksUseCase;
  final GetMyLinkCodeUseCase getMyLinkCodeUseCase;
  final RequestFamilyLinkUseCase requestFamilyLinkUseCase;
  final RespondFamilyLinkUseCase respondFamilyLinkUseCase;
  final RemoveFamilyLinkUseCase removeFamilyLinkUseCase;
  final String? Function() currentUserId;

  /// Opcional: quando presente, pedidos novos aparecem em tempo real.
  final FamilyRepository? repository;

  StreamSubscription<void>? _linksSubscription;
  String? _myCode;

  Future<void> _onLoad(
    LoadFamilyLinksRequested event,
    Emitter<FamilyState> emit,
  ) async {
    if (!event.silent) emit(const FamilyLoading());

    if (_myCode == null) {
      final codeResult = await getMyLinkCodeUseCase(const NoParams());
      _myCode = codeResult.toNullable();
    }

    final result = await getFamilyLinksUseCase(const NoParams());
    result.fold(
      (failure) => emit(FamilyFailure(failure.message)),
      (links) => emit(
        FamilyLoaded(links, myCode: _myCode, myUserId: currentUserId()),
      ),
    );

    _linksSubscription ??= repository?.watchLinksChanges().skip(1).listen((_) {
      if (!isClosed) add(const LoadFamilyLinksRequested(silent: true));
    }, onError: (_) {});
  }

  Future<void> _onRequest(
    RequestFamilyLinkRequested event,
    Emitter<FamilyState> emit,
  ) async {
    final result = await requestFamilyLinkUseCase(event.code);
    result.fold(
      (failure) => emit(FamilyFailure(failure.message)),
      (name) => emit(
        FamilyActionSuccess(
          'Pedido enviado! Agora ${name.isEmpty ? 'a pessoa' : name} '
          'precisa tocar em "Permitir" no celular dela.',
        ),
      ),
    );
    add(const LoadFamilyLinksRequested(silent: true));
  }

  Future<void> _onRespond(
    RespondFamilyLinkRequested event,
    Emitter<FamilyState> emit,
  ) async {
    final result = await respondFamilyLinkUseCase(
      RespondFamilyLinkParams(linkId: event.linkId, accept: event.accept),
    );
    result.fold((failure) => emit(FamilyFailure(failure.message)), (_) {});
    add(const LoadFamilyLinksRequested(silent: true));
  }

  Future<void> _onRemove(
    RemoveFamilyLinkRequested event,
    Emitter<FamilyState> emit,
  ) async {
    final result = await removeFamilyLinkUseCase(event.linkId);
    result.fold((failure) => emit(FamilyFailure(failure.message)), (_) {});
    add(const LoadFamilyLinksRequested(silent: true));
  }

  @override
  Future<void> close() async {
    await _linksSubscription?.cancel();
    return super.close();
  }
}
