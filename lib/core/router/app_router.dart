import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../app/app.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/checkin/presentation/pages/checkin_alert_page.dart';
import '../../features/checkin/presentation/pages/monitoring_settings_page.dart';
import '../../features/contacts/presentation/pages/contacts_page.dart';
import '../../features/family/presentation/cubit/family_dashboard_cubit.dart';
import '../../features/family/presentation/pages/family_dashboard_page.dart';
import '../../features/family/presentation/pages/family_panel_page.dart';
import '../../injection/injection_container.dart';
import 'go_router_refresh_stream.dart';

export 'go_router_refresh_stream.dart';
import '../../features/panic/presentation/pages/panic_page.dart';

GoRouter buildRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (authState is AuthUnauthenticated && !isAuthRoute) {
        return '/login';
      }
      if (authState is AuthAuthenticated && isAuthRoute) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const GuardiaoHomePage(),
      ),
      GoRoute(
        path: '/monitoring-settings',
        builder: (context, state) => const MonitoringSettingsPage(),
      ),
      GoRoute(
        path: '/checkin-alert',
        builder: (context, state) => const CheckinAlertPage(),
      ),
      GoRoute(
        path: '/contacts',
        builder: (context, state) => const ContactsPage(),
      ),
      GoRoute(
        path: '/panic',
        builder: (context, state) => const PanicPage(),
      ),
      GoRoute(
        path: '/family',
        builder: (context, state) => const FamilyPanelPage(),
      ),
      GoRoute(
        path: '/family-dashboard',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<FamilyDashboardCubit>()..start(),
          child: const FamilyDashboardPage(),
        ),
      ),
    ],
  );
}
