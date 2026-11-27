import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/logger.dart';

/// Guarda a sessão do Supabase no armazenamento seguro do sistema (Keystore
/// no Android, Keychain no iOS), em vez de texto simples.
///
/// Quem já estava logado antes desta versão não precisa entrar de novo: a
/// sessão antiga é lida uma vez de [legacy] e migrada.
class SecureLocalStorage extends LocalStorage {
  SecureLocalStorage({
    required this.persistSessionKey,
    FlutterSecureStorage? storage,
    this.legacy,
  }) : _storage = storage ?? const FlutterSecureStorage();

  /// Chave sob a qual a sessão é guardada.
  final String persistSessionKey;

  /// Armazenamento usado pelas versões anteriores (SharedPreferences).
  final LocalStorage? legacy;

  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {
    try {
      await legacy?.initialize();
    } catch (_) {}
  }

  Future<String?> _read() async {
    try {
      final value = await _storage.read(key: persistSessionKey);
      if (value != null) return value;
    } catch (e) {
      // Chave do Keystore perdida (ex.: restauração de backup): a pessoa
      // entra de novo, sem travar o app.
      AppLogger.warning('Falha ao ler a sessão segura', e);
    }

    // Migração única da sessão em texto simples.
    try {
      final old = await legacy?.accessToken();
      if (old == null) return null;
      await persistSession(old);
      await legacy?.removePersistedSession();
      return old;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> hasAccessToken() async => await _read() != null;

  @override
  Future<String?> accessToken() => _read();

  @override
  Future<void> persistSession(String persistSessionString) async {
    try {
      await _storage.write(key: persistSessionKey, value: persistSessionString);
    } catch (e) {
      AppLogger.warning('Falha ao guardar a sessão segura', e);
    }
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await _storage.delete(key: persistSessionKey);
    } catch (e) {
      AppLogger.warning('Falha ao remover a sessão segura', e);
    }
    try {
      await legacy?.removePersistedSession();
    } catch (_) {}
  }
}
