import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/errors/failures.dart' as f;
import 'package:guardiao/core/usecases/usecase.dart';
import 'package:guardiao/features/auth/domain/entities/user_entity.dart';
import 'package:guardiao/features/auth/domain/repositories/auth_repository.dart';
import 'package:guardiao/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:guardiao/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:guardiao/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:guardiao/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:guardiao/features/auth/presentation/bloc/auth_event.dart';
import 'package:guardiao/features/auth/presentation/bloc/auth_state.dart';
import 'package:mocktail/mocktail.dart';

class MockSignInUseCase extends Mock implements SignInUseCase {}

class MockSignUpUseCase extends Mock implements SignUpUseCase {}

class MockSignOutUseCase extends Mock implements SignOutUseCase {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockSignInUseCase mockSignInUseCase;
  late MockSignUpUseCase mockSignUpUseCase;
  late MockSignOutUseCase mockSignOutUseCase;
  late MockAuthRepository mockAuthRepository;

  setUpAll(() {
    registerFallbackValue(const SignInParams(email: '', password: ''));
    registerFallbackValue(
      const SignUpParams(email: '', password: '', fullName: ''),
    );
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    mockSignInUseCase = MockSignInUseCase();
    mockSignUpUseCase = MockSignUpUseCase();
    mockSignOutUseCase = MockSignOutUseCase();
    mockAuthRepository = MockAuthRepository();

    when(
      () => mockAuthRepository.authStateChanges,
    ).thenAnswer((_) => const Stream.empty());
  });

  const tUser = UserEntity(
    id: 'user-1',
    email: 'ana@guardiao.com',
    fullName: 'Ana Silva',
  );

  AuthBloc buildBloc() => AuthBloc(
    signInUseCase: mockSignInUseCase,
    signUpUseCase: mockSignUpUseCase,
    signOutUseCase: mockSignOutUseCase,
    authRepository: mockAuthRepository,
  );

  group('AuthBloc', () {
    test('estado inicial é AuthInitial', () {
      expect(buildBloc().state, equals(const AuthInitial()));
    });

    blocTest<AuthBloc, AuthState>(
      'emite [AuthLoading, AuthAuthenticated] quando o login tem sucesso',
      build: () {
        when(
          () => mockSignInUseCase(any()),
        ).thenAnswer((_) async => const Right(tUser));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const AuthSignInRequested(email: 'ana@guardiao.com', password: '123'),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthAuthenticated(tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emite [AuthLoading, AuthFailure] quando o login falha',
      build: () {
        when(() => mockSignInUseCase(any())).thenAnswer(
          (_) async => const Left(f.ServerFailure('Credenciais inválidas')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const AuthSignInRequested(email: 'ana@guardiao.com', password: 'wrong'),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthFailure('Credenciais inválidas'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emite [AuthLoading, AuthAuthenticated] no cadastro com sucesso',
      build: () {
        when(
          () => mockSignUpUseCase(any()),
        ).thenAnswer((_) async => const Right(tUser));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const AuthSignUpRequested(
          email: 'ana@guardiao.com',
          password: 'password123',
          fullName: 'Ana Silva',
        ),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthAuthenticated(tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emite [AuthLoading, AuthUnauthenticated] no logout com sucesso',
      build: () {
        when(
          () => mockSignOutUseCase(any()),
        ).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      expect: () => [
        const AuthLoading(),
        const AuthUnauthenticated(),
      ],
    );
  });
}
