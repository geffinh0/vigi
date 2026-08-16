import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/core/errors/failures.dart';

void main() {
  group('Failures', () {
    test('ServerFailure armazena mensagem e suporta igualdade por valor', () {
      const f1 = ServerFailure('Erro no servidor');
      const f2 = ServerFailure('Erro no servidor');
      const f3 = ServerFailure('Outro erro');

      expect(f1.message, 'Erro no servidor');
      expect(f1, equals(f2));
      expect(f1, isNot(equals(f3)));
    });

    test('CacheFailure armazena mensagem e suporta igualdade', () {
      const f1 = CacheFailure('Erro no cache');
      const f2 = CacheFailure('Erro no cache');

      expect(f1.message, 'Erro no cache');
      expect(f1, equals(f2));
    });

    test(
      'NetworkFailure tem mensagem padrão e suporta mensagem customizada',
      () {
        const f1 = NetworkFailure();
        const f2 = NetworkFailure('Sem internet');

        expect(f1.message, 'Sem conexão com a internet.');
        expect(f2.message, 'Sem internet');
      },
    );

    test('ValidationFailure armazena mensagem de validação', () {
      const f = ValidationFailure('Telefone inválido');
      expect(f.message, 'Telefone inválido');
    });

    test('AuthFailure armazena mensagem de autenticação', () {
      const f = AuthFailure('Credenciais inválidas');
      expect(f.message, 'Credenciais inválidas');
    });
  });
}
