import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/errors/failures.dart';
import 'package:guardiao/features/auth/domain/entities/user_entity.dart';
import 'package:guardiao/features/auth/domain/repositories/auth_repository.dart';
import 'package:guardiao/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignInUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignInUseCase(mockRepository);
  });

  const tUser = UserEntity(
    id: 'user-123',
    email: 'teste@guardiao.com',
    fullName: 'Ana Silva',
  );

  const tParams = SignInParams(
    email: 'teste@guardiao.com',
    password: 'password123',
  );

  group('SignInUseCase', () {
    test('retorna UserEntity quando o repository tem sucesso', () async {
      when(
        () => mockRepository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(tUser));

      final result = await useCase(tParams);

      expect(result, const Right(tUser));
      verify(
        () => mockRepository.signIn(
          email: tParams.email,
          password: tParams.password,
        ),
      ).called(1);
    });

    test(
      'retorna ValidationFailure quando email ou senha estão vazios',
      () async {
        final resEmptyEmail = await useCase(
          const SignInParams(email: '', password: '123'),
        );
        expect(resEmptyEmail, isA<Left<Failure, UserEntity>>());

        final resEmptyPass = await useCase(
          const SignInParams(email: 'a@a.com', password: ''),
        );
        expect(resEmptyPass, isA<Left<Failure, UserEntity>>());
      },
    );

    test(
      'retorna AuthFailure quando o repository falha com credenciais inválidas',
      () async {
        when(
          () => mockRepository.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async => const Left(AuthFailure('Credenciais inválidas')),
        );

        final result = await useCase(tParams);

        expect(result, const Left(AuthFailure('Credenciais inválidas')));
      },
    );
  });
}
