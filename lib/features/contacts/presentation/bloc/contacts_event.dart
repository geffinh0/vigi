import 'package:equatable/equatable.dart';

abstract class ContactsEvent extends Equatable {
  const ContactsEvent();

  @override
  List<Object?> get props => [];
}

class LoadContactsRequested extends ContactsEvent {
  const LoadContactsRequested();
}

class AddContactRequested extends ContactsEvent {
  const AddContactRequested({
    required this.name,
    required this.phone,
    this.relationship,
  });

  final String name;
  final String phone;
  final String? relationship;

  @override
  List<Object?> get props => [name, phone, relationship];
}

class DeleteContactRequested extends ContactsEvent {
  const DeleteContactRequested(this.contactId);

  final String contactId;

  @override
  List<Object?> get props => [contactId];
}
