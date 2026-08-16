import 'package:equatable/equatable.dart';
import '../../domain/entities/emergency_contact_entity.dart';

abstract class ContactsState extends Equatable {
  const ContactsState();

  @override
  List<Object?> get props => [];
}

class ContactsInitial extends ContactsState {
  const ContactsInitial();
}

class ContactsLoading extends ContactsState {
  const ContactsLoading();
}

class ContactsLoaded extends ContactsState {
  const ContactsLoaded(this.contacts);

  final List<EmergencyContactEntity> contacts;

  @override
  List<Object?> get props => [contacts];
}

class ContactsFailure extends ContactsState {
  const ContactsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
