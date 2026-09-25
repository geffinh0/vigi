import 'package:equatable/equatable.dart';
import '../../domain/entities/emergency_contact_entity.dart';

/// Estados do `ContactsBloc`.
abstract class ContactsState extends Equatable {
  const ContactsState();

  @override
  List<Object?> get props => [];
}

/// Estado antes do carregamento.
class ContactsInitial extends ContactsState {
  const ContactsInitial();
}

/// Carregando.
class ContactsLoading extends ContactsState {
  const ContactsLoading();
}

/// Contatos carregados.
class ContactsLoaded extends ContactsState {
  const ContactsLoaded(this.contacts);

  final List<EmergencyContactEntity> contacts;

  @override
  List<Object?> get props => [contacts];
}

/// Erro exibido ao usuário.
class ContactsFailure extends ContactsState {
  const ContactsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
