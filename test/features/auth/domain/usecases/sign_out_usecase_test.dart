import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/errors/failures.dart';
import 'package:guardiao/core/usecases/usecase.dart';
import 'package:guardiao/features/auth/domain/repositories/auth_repository.dart';
import 'package:guardiao/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignOutUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignOutUseCase(mockRepository);
  });

  group('SignOutUseCase', () {
    test('chama repository.signOut e retorna Right(null)', () async {
      when(
        () => mockRepository.signOut(),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase(const NoParams());

      expect(result, const Right(null));
      verify(() => mockRepository.signOut()).called(1);
    });

    test('retorna Failure quando repository.signOut falha', () async {
      when(
        () => mockRepository.signOut(),
      ).thenAnswer((_) async => const Left(ServerFailure('Erro ao sair')));

      final result = await useCase(const NoParams());

      expect(result, const Left(ServerFailure('Erro ao sair')));
    });
  });
}
