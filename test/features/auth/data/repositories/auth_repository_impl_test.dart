import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/errors/failures.dart';
import 'package:guardiao/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:guardiao/features/auth/data/models/user_model.dart';
import 'package:guardiao/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:guardiao/features/auth/domain/entities/user_entity.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(mockDataSource);
  });

  const tUserModel = UserModel(
    id: '1',
    email: 'ana@guardiao.com',
    fullName: 'Ana Silva',
  );

  group('AuthRepositoryImpl', () {
    test(
      'retorna Right(UserModel) quando o datasource tem sucesso no login',
      () async {
        when(
          () => mockDataSource.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => tUserModel);

        final result = await repository.signIn(
          email: 'ana@guardiao.com',
          password: 'password123',
        );

        expect(result, const Right(tUserModel));
        verify(
          () => mockDataSource.signIn(
            email: 'ana@guardiao.com',
            password: 'password123',
          ),
        ).called(1);
      },
    );

    test(
      'retorna Left(AuthFailure) quando o datasource lança AuthException',
      () async {
        when(
          () => mockDataSource.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const AuthException('Credenciais incorretas'));

        final result = await repository.signIn(
          email: 'ana@guardiao.com',
          password: 'errada',
        );

        expect(result, isA<Left<Failure, UserEntity>>());
        result.fold(
          (failure) => expect(failure.message, 'Credenciais incorretas'),
          (_) => fail('Deveria retornar Left'),
        );
      },
    );

    test('retorna Right(UserModel) no cadastro com sucesso', () async {
      when(
        () => mockDataSource.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          fullName: any(named: 'fullName'),
          phone: any(named: 'phone'),
        ),
      ).thenAnswer((_) async => tUserModel);

      final result = await repository.signUp(
        email: 'ana@guardiao.com',
        password: 'password123',
        fullName: 'Ana Silva',
      );

      expect(result, const Right(tUserModel));
    });

    test('retorna Right(null) no signOut com sucesso', () async {
      when(() => mockDataSource.signOut()).thenAnswer((_) async {});

      final result = await repository.signOut();

      expect(result, const Right(null));
    });
  });
}
