import 'package:equatable/equatable.dart';
import '../../domain/entities/family_link_entity.dart';

abstract class FamilyState extends Equatable {
  const FamilyState();

  @override
  List<Object?> get props => [];
}

class FamilyInitial extends FamilyState {
  const FamilyInitial();
}

class FamilyLoading extends FamilyState {
  const FamilyLoading();
}

class FamilyLoaded extends FamilyState {
  const FamilyLoaded(this.links);

  final List<FamilyLinkEntity> links;

  @override
  List<Object?> get props => [links];
}

class FamilyFailure extends FamilyState {
  const FamilyFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
