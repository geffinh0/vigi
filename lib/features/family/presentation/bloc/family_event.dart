import 'package:equatable/equatable.dart';

abstract class FamilyEvent extends Equatable {
  const FamilyEvent();

  @override
  List<Object?> get props => [];
}

class LoadFamilyLinksRequested extends FamilyEvent {
  const LoadFamilyLinksRequested({this.silent = false});

  /// Recarga disparada pelo Realtime: não mostra o indicador de carregamento.
  final bool silent;

  @override
  List<Object?> get props => [silent];
}

class RequestFamilyLinkRequested extends FamilyEvent {
  const RequestFamilyLinkRequested(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

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

class RemoveFamilyLinkRequested extends FamilyEvent {
  const RemoveFamilyLinkRequested(this.linkId);

  final String linkId;

  @override
  List<Object?> get props => [linkId];
}
