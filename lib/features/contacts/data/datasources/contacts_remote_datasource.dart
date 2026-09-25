import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/emergency_contact_model.dart';

/// Acesso à tabela `emergency_contacts`.
abstract class ContactsRemoteDataSource {
  Future<List<EmergencyContactModel>> getContacts();

  Future<EmergencyContactModel> addContact({
    required String name,
    required String phone,
    String? relationship,
  });

  Future<void> deleteContact(String contactId);
}

/// Implementação de [ContactsRemoteDataSource] com Supabase.
class ContactsRemoteDataSourceImpl implements ContactsRemoteDataSource {
  ContactsRemoteDataSourceImpl(this.client);

  final SupabaseClient client;

  @override
  Future<List<EmergencyContactModel>> getContacts() async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    final response = await client
        .from('emergency_contacts')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: true);

    return (response as List<dynamic>)
        .map(
          (json) => EmergencyContactModel.fromMap(json as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<EmergencyContactModel> addContact({
    required String name,
    required String phone,
    String? relationship,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    final response = await client
        .from('emergency_contacts')
        .insert({
          'user_id': user.id,
          'name': name,
          'phone': phone,
          'relationship': relationship,
        })
        .select()
        .single();

    return EmergencyContactModel.fromMap(response);
  }

  @override
  Future<void> deleteContact(String contactId) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    await client
        .from('emergency_contacts')
        .delete()
        .eq('id', contactId)
        .eq('user_id', user.id);
  }
}
