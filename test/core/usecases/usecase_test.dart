import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/errors/failures.dart';
import 'package:guardiao/core/usecases/usecase.dart';

class TestUseCase implements UseCase<String, NoParams> {
  @override
  Future<Either<Failure, String>> call(NoParams params) async {
    return const Right('sucesso');
  }
}

void main() {
  group('UseCase & NoParams', () {
    test('NoParams suporta igualdade estrutural', () {
      const p1 = NoParams();
      const p2 = NoParams();
      expect(p1, equals(p2));
    });

    test('TestUseCase executa retornando Right', () async {
      final useCase = TestUseCase();
      final result = await useCase(const NoParams());
      expect(result, const Right('sucesso'));
    });
  });
}
