import 'package:equatable/equatable.dart';

/// Eventos do `FamilyBloc`.
abstract class FamilyEvent extends Equatable {
  const FamilyEvent();

  @override
  List<Object?> get props => [];
}

/// Carrega o código e os vínculos.
class LoadFamilyLinksRequested extends FamilyEvent {
  const LoadFamilyLinksRequested({this.silent = false});

  /// Recarga disparada pelo Realtime: não mostra o indicador de carregamento.
  final bool silent;

  @override
  List<Object?> get props => [silent];
}

/// Pedido para acompanhar alguém pelo código.
class RequestFamilyLinkRequested extends FamilyEvent {
  const RequestFamilyLinkRequested(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

/// Autoriza ou recusa um pedido.
class RespondFamilyLinkRequested extends FamilyEvent {
  const RespondFamilyLinkRequested({
    required this.linkId,
    required this.accept,
  });

  final String linkId;
  final bool accept;

  @override
  List<Object?> get props => [linkId, accept];
}

/// Remove um vínculo.
class RemoveFamilyLinkRequested extends FamilyEvent {
  const RemoveFamilyLinkRequested(this.linkId);

  final String linkId;

  @override
  List<Object?> get props => [linkId];
}
