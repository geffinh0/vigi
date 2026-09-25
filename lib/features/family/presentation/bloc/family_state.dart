import 'package:equatable/equatable.dart';
import '../../domain/entities/family_link_entity.dart';

/// Estados do `FamilyBloc`.
abstract class FamilyState extends Equatable {
  const FamilyState();

  @override
  List<Object?> get props => [];
}

/// Estado antes do carregamento.
class FamilyInitial extends FamilyState {
  const FamilyInitial();
}

/// Carregando.
class FamilyLoading extends FamilyState {
  const FamilyLoading();
}

/// Vínculos e código carregados.
class FamilyLoaded extends FamilyState {
  const FamilyLoaded(this.links, {this.myCode, this.myUserId});

  final List<FamilyLinkEntity> links;

  /// Código VIGI que a pessoa compartilha com quem vai acompanhá-la.
  final String? myCode;
  final String? myUserId;

  /// Pedidos de familiares aguardando a autorização desta pessoa.
  List<FamilyLinkEntity> get pendingRequests =>
      links.where((l) => l.isPending && l.monitoredUserId == myUserId).toList();

  /// Quem já acompanha esta pessoa.
  List<FamilyLinkEntity> get followers => links
      .where((l) => l.isAccepted && l.monitoredUserId == myUserId)
      .toList();

  /// Pessoas que esta conta acompanha (ou pediu para acompanhar).
  List<FamilyLinkEntity> get following =>
      links.where((l) => l.viewerUserId == myUserId).toList();

  @override
  List<Object?> get props => [links, myCode, myUserId];
}

/// Erro exibido ao usuário.
class FamilyFailure extends FamilyState {
  const FamilyFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Mensagem de sucesso pontual (ex.: "Pedido enviado para Maria").
class FamilyActionSuccess extends FamilyState {
  const FamilyActionSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
