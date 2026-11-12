import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/core/errors/failures.dart';
import 'package:guardiao/features/family/data/datasources/family_remote_datasource.dart';
import 'package:guardiao/features/family/data/repositories/family_repository_impl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockFamilyRemoteDataSource extends Mock
    implements FamilyRemoteDataSource {}

void main() {
  late MockFamilyRemoteDataSource dataSource;
  late FamilyRepositoryImpl repository;

  setUp(() {
    dataSource = MockFamilyRemoteDataSource();
    repository = FamilyRepositoryImpl(dataSource);
  });

  Future<Failure> failureOf(Object error) async {
    when(() => dataSource.requestLinkByCode(any())).thenThrow(error);
    final result = await repository.requestLinkByCode('K7P2QX');
    return result.getLeft().toNullable()!;
  }

  group('mensagens de erro', () {
    test('mensagem amigável do banco chega como veio', () async {
      final failure = await failureOf(
        const PostgrestException(
          message: 'Este é o seu próprio código.',
          code: 'P0001',
        ),
      );
      expect(failure.message, 'Este é o seu próprio código.');
    });

    test(
      'a marca aparece como "Vigi", mesmo com o banco ainda antigo',
      () async {
        final failure = await failureOf(
          const PostgrestException(
            message: 'Código VIGI não encontrado. Confira as letras e números.',
            code: 'P0001',
          ),
        );
        expect(
          failure.message,
          'Código Vigi não encontrado. Confira as letras e números.',
        );
        expect(failure.message, isNot(contains('VIGI')));
      },
    );

    test('erro técnico ganha o contexto do que estava sendo feito', () async {
      final failure = await failureOf(
        const PostgrestException(message: 'timeout', code: '57014'),
      );
      expect(failure.message, 'Erro ao enviar pedido: timeout');
    });
  });
}
