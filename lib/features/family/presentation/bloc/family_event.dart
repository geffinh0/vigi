import 'package:equatable/equatable.dart';

abstract class FamilyEvent extends Equatable {
  const FamilyEvent();

  @override
  List<Object?> get props => [];
}

class LoadFamilyLinksRequested extends FamilyEvent {
  const LoadFamilyLinksRequested();
}

class SendFamilyInviteRequested extends FamilyEvent {
  const SendFamilyInviteRequested(this.viewerUserId);

  final String viewerUserId;

  @override
  List<Object?> get props => [viewerUserId];
}

class AcceptFamilyInviteRequested extends FamilyEvent {
  const AcceptFamilyInviteRequested(this.linkId);

  final String linkId;

  @override
  List<Object?> get props => [linkId];
}
