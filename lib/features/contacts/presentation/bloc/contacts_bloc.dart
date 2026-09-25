import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/add_contact_usecase.dart';
import '../../domain/usecases/delete_contact_usecase.dart';
import '../../domain/usecases/get_contacts_usecase.dart';
import 'contacts_event.dart';
import 'contacts_state.dart';

/// Estado da tela de contatos de emergência.
class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  ContactsBloc({
    required this.getContactsUseCase,
    required this.addContactUseCase,
    required this.deleteContactUseCase,
  }) : super(const ContactsInitial()) {
    on<LoadContactsRequested>(_onLoadContactsRequested);
    on<AddContactRequested>(_onAddContactRequested);
    on<DeleteContactRequested>(_onDeleteContactRequested);
  }

  final GetContactsUseCase getContactsUseCase;
  final AddContactUseCase addContactUseCase;
  final DeleteContactUseCase deleteContactUseCase;

  Future<void> _onLoadContactsRequested(
    LoadContactsRequested event,
    Emitter<ContactsState> emit,
  ) async {
    emit(const ContactsLoading());
    final result = await getContactsUseCase(const NoParams());
    result.fold(
      (failure) => emit(ContactsFailure(failure.message)),
      (contacts) => emit(ContactsLoaded(contacts)),
    );
  }

  Future<void> _onAddContactRequested(
    AddContactRequested event,
    Emitter<ContactsState> emit,
  ) async {
    final result = await addContactUseCase(
      AddContactParams(
        name: event.name,
        phone: event.phone,
        relationship: event.relationship,
      ),
    );
    result.fold(
      (failure) => emit(ContactsFailure(failure.message)),
      (_) => add(const LoadContactsRequested()),
    );
  }

  Future<void> _onDeleteContactRequested(
    DeleteContactRequested event,
    Emitter<ContactsState> emit,
  ) async {
    final result = await deleteContactUseCase(
      DeleteContactParams(event.contactId),
    );
    result.fold(
      (failure) => emit(ContactsFailure(failure.message)),
      (_) => add(const LoadContactsRequested()),
    );
  }
}
