import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/app.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/checkin/presentation/pages/checkin_alert_page.dart';
import '../../features/checkin/presentation/pages/monitoring_settings_page.dart';
import '../../features/contacts/presentation/pages/contacts_page.dart';
import '../../features/family/presentation/pages/family_panel_page.dart';
import '../../features/panic/presentation/pages/panic_page.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

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
    ],
  );
}
