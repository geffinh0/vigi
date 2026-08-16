import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn({
    required String email,
    required String password,
  });

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  });

  Future<void> signOut();

  Future<UserModel?> getCurrentUser();

  Stream<UserEntity?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this.client);

  final SupabaseClient client;

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Falha ao autenticar: usuário não retornado.');
    }

    final profile = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return UserModel.fromMap(
      profile ?? {'id': user.id, 'full_name': ''},
      email: user.email ?? email,
    );
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final metadata = <String, dynamic>{
      'full_name': fullName,
    };
    if (phone != null) {
      metadata['phone'] = phone;
    }

    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Falha ao registrar usuário.');
    }

    return UserModel(
      id: user.id,
      email: user.email ?? email,
      fullName: fullName,
      phone: phone,
    );
  }

  @override
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final profile = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return UserModel.fromMap(
      profile ?? {'id': user.id, 'full_name': ''},
      email: user.email ?? '',
    );
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return client.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      if (user == null) return null;
      return UserEntity(
        id: user.id,
        email: user.email ?? '',
        fullName: (user.userMetadata?['full_name'] as String?) ?? '',
        phone: user.userMetadata?['phone'] as String?,
      );
    });
  }
}
