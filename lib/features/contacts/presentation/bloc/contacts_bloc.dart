import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/emergency_contact_entity.dart';
import '../../domain/usecases/add_contact_usecase.dart';
import '../../domain/usecases/delete_contact_usecase.dart';
import '../../domain/usecases/get_contacts_usecase.dart';
import 'contacts_event.dart';
import 'contacts_state.dart';

/// Pessoas de vigília: quem é avisado em um pedido de ajuda.
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

  /// Última lista carregada. Uma falha ao salvar ou remover não pode fazer
  /// as pessoas sumirem da tela (nem da frase "vamos avisar Maria e João").
  List<EmergencyContactEntity>? _contacts;

  Future<void> _onLoadContactsRequested(
    LoadContactsRequested event,
    Emitter<ContactsState> emit,
  ) async {
    // Recarregar com a lista já na tela não mostra o indicador de espera.
    if (_contacts == null) emit(const ContactsLoading());
    final result = await getContactsUseCase(const NoParams());
    result.fold(
      (failure) => _fail(failure.message, emit),
      (contacts) {
        _contacts = contacts;
        emit(ContactsLoaded(contacts));
      },
    );
  }

  void _fail(String message, Emitter<ContactsState> emit) {
    emit(ContactsFailure(message));
    final contacts = _contacts;
    if (contacts != null) emit(ContactsLoaded(contacts));
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
      (failure) => _fail(failure.message, emit),
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
      (failure) => _fail(failure.message, emit),
      (_) => add(const LoadContactsRequested()),
    );
  }
}
