import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;
import '../core/router/go_router_refresh_stream.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/usecases/sign_in_usecase.dart';
import '../features/auth/domain/usecases/sign_out_usecase.dart';
import '../features/auth/domain/usecases/sign_up_usecase.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/family/data/datasources/family_remote_datasource.dart';
import '../features/family/data/repositories/family_repository_impl.dart';
import '../features/family/domain/usecases/get_family_links_usecase.dart';
import '../features/family/domain/usecases/request_family_link_usecase.dart';
import '../features/family/presentation/cubit/family_dashboard_cubit.dart';
import '../features/family/presentation/pages/family_dashboard_page.dart';

/// App web do familiar. Reaproveita a autenticação e o domínio do app
/// principal, mas sem nenhum plugin de hardware (SMS, alarmes, widget):
/// o familiar só observa, quem é monitorado é o celular do idoso.
class FamilyWebApp extends StatefulWidget {
  const FamilyWebApp({super.key, required this.client});

  final SupabaseClient client;

  @override
  State<FamilyWebApp> createState() => _FamilyWebAppState();
}

class _FamilyWebAppState extends State<FamilyWebApp> {
  late final AuthBloc _authBloc;
  late final FamilyRepositoryImpl _familyRepository;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authRepository = AuthRepositoryImpl(
      AuthRemoteDataSourceImpl(widget.client),
    );
    _authBloc = AuthBloc(
      signInUseCase: SignInUseCase(authRepository),
      signUpUseCase: SignUpUseCase(authRepository),
      signOutUseCase: SignOutUseCase(authRepository),
      authRepository: authRepository,
    )..add(const AuthCheckRequested());
    _familyRepository = FamilyRepositoryImpl(
      FamilyRemoteDataSourceImpl(widget.client),
    );

    _router = GoRouter(
      initialLocation: '/',
      refreshListenable: GoRouterRefreshStream(_authBloc.stream),
      redirect: (context, state) {
        final auth = _authBloc.state;
        final isAuthRoute =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';
        if (auth is AuthUnauthenticated && !isAuthRoute) return '/login';
        if (auth is AuthAuthenticated && isAuthRoute) return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(
            title: 'VIGI Família',
            subtitle: 'Acompanhe quem você ama, sem invadir a privacidade',
          ),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/',
          // O painel só é montado com a sessão confirmada: ao reabrir o PWA com
          // o token expirado, o Supabase ainda está renovando a sessão e as
          // consultas falhariam com "Usuário não autenticado".
          builder: (context, state) => BlocBuilder<AuthBloc, AuthState>(
            buildWhen: (previous, current) =>
                (previous is AuthAuthenticated) !=
                (current is AuthAuthenticated),
            builder: (context, auth) {
              if (auth is! AuthAuthenticated) {
                return const Scaffold(
                  backgroundColor: AppColors.linho,
                  body: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.petroleo,
                    ),
                  ),
                );
              }
              return BlocProvider(
                create: (_) => FamilyDashboardCubit(
                  repository: _familyRepository,
                  getFamilyLinksUseCase: GetFamilyLinksUseCase(
                    _familyRepository,
                  ),
                  requestFamilyLinkUseCase: RequestFamilyLinkUseCase(
                    _familyRepository,
                  ),
                  currentUserId: () => widget.client.auth.currentUser?.id,
                )..start(),
                child: FamilyDashboardPage(
                  onSignOut: () => _authBloc.add(const AuthSignOutRequested()),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: 'VIGI Família',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        routerConfig: _router,
        // No computador, o conteúdo fica centralizado com largura de celular
        // (as telas foram desenhadas para leitura fácil em coluna única).
        builder: (context, child) => ColoredBox(
          color: AppColors.linhoEscuro,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
