import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/core/services/secure_local_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

/// Armazenamento antigo, em texto simples.
class FakeLegacyStorage extends LocalStorage {
  FakeLegacyStorage([this.session]);

  String? session;

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() async => session;

  @override
  Future<bool> hasAccessToken() async => session != null;

  @override
  Future<void> persistSession(String persistSessionString) async {
    session = persistSessionString;
  }

  @override
  Future<void> removePersistedSession() async {
    session = null;
  }
}

void main() {
  const key = 'sb-projeto-auth-token';
  late MockSecureStorage secure;
  late Map<String, String> vault;

  setUp(() {
    secure = MockSecureStorage();
    vault = {};
    when(
      () => secure.read(key: any(named: 'key')),
    ).thenAnswer((i) async => vault[i.namedArguments[#key]]);
    when(
      () => secure.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((i) async {
      vault[i.namedArguments[#key] as String] =
          i.namedArguments[#value] as String;
    });
    when(
      () => secure.delete(key: any(named: 'key')),
    ).thenAnswer((i) async => vault.remove(i.namedArguments[#key]));
  });

  group('SecureLocalStorage', () {
    test('guarda e lê a sessão no armazenamento seguro', () async {
      final storage = SecureLocalStorage(
        persistSessionKey: key,
        storage: secure,
      );
      expect(await storage.hasAccessToken(), isFalse);

      await storage.persistSession('{"access_token":"abc"}');
      expect(vault[key], '{"access_token":"abc"}');
      expect(await storage.hasAccessToken(), isTrue);
      expect(await storage.accessToken(), '{"access_token":"abc"}');
    });

    test(
      'quem já estava logado continua logado: migra a sessão antiga',
      () async {
        final legacy = FakeLegacyStorage('{"access_token":"antiga"}');
        final storage = SecureLocalStorage(
          persistSessionKey: key,
          storage: secure,
          legacy: legacy,
        );

        expect(await storage.accessToken(), '{"access_token":"antiga"}');
        // Passou para o cofre e saiu do texto simples.
        expect(vault[key], '{"access_token":"antiga"}');
        expect(legacy.session, isNull);
      },
    );

    test('sair remove a sessão dos dois lugares', () async {
      final legacy = FakeLegacyStorage('{"access_token":"antiga"}');
      final storage = SecureLocalStorage(
        persistSessionKey: key,
        storage: secure,
        legacy: legacy,
      );
      await storage.persistSession('{"access_token":"nova"}');

      await storage.removePersistedSession();
      expect(vault, isEmpty);
      expect(legacy.session, isNull);
      expect(await storage.hasAccessToken(), isFalse);
    });

    test('falha no cofre não trava o app: a pessoa só entra de novo', () async {
      when(
        () => secure.read(key: any(named: 'key')),
      ).thenThrow(Exception('chave do Keystore perdida'));
      final storage = SecureLocalStorage(
        persistSessionKey: key,
        storage: secure,
      );
      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.accessToken(), isNull);
    });
  });
}
