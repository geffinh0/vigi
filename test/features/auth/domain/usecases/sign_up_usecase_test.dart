import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/errors/failures.dart';
import 'package:guardiao/features/auth/domain/entities/user_entity.dart';
import 'package:guardiao/features/auth/domain/repositories/auth_repository.dart';
import 'package:guardiao/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignUpUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignUpUseCase(mockRepository);
  });

  const tUser = UserEntity(
    id: 'user-123',
    email: 'ana@guardiao.com',
    fullName: 'Ana Silva',
  );

  const tParams = SignUpParams(
    email: 'ana@guardiao.com',
    password: 'password123',
    fullName: 'Ana Silva',
  );

  group('SignUpUseCase', () {
    test('retorna UserEntity quando o cadastro é bem-sucedido', () async {
      when(
        () => mockRepository.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          fullName: any(named: 'fullName'),
          phone: any(named: 'phone'),
        ),
      ).thenAnswer((_) async => const Right(tUser));

      final result = await useCase(tParams);

      expect(result, const Right(tUser));
      verify(
        () => mockRepository.signUp(
          email: tParams.email,
          password: tParams.password,
          fullName: tParams.fullName,
          phone: tParams.phone,
        ),
      ).called(1);
    });

    test('rejeita nome vazio com ValidationFailure', () async {
      final res = await useCase(
        const SignUpParams(
          email: 'a@a.com',
          password: '123456',
          fullName: '',
        ),
      );
      expect(res, isA<Left<Failure, UserEntity>>());
    });

    test('rejeita senha menor que 6 caracteres', () async {
      final res = await useCase(
        const SignUpParams(
          email: 'a@a.com',
          password: '123',
          fullName: 'Ana',
        ),
      );
      expect(res, isA<Left<Failure, UserEntity>>());
    });
  });
}
