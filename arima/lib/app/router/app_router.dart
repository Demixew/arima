import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/domain/auth_session.dart';
import '../../features/auth/presentation/auth_bootstrap_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/parent/presentation/parent_home_page.dart';
import '../../features/teacher/presentation/teacher_home_page.dart';
import 'router_refresh_notifier.dart';

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  final AsyncValue<AuthSession?> authState = ref.watch(authControllerProvider);
  final RouterRefreshNotifier refreshNotifier = ref.watch(routerRefreshNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'bootstrap',
        builder: (BuildContext context, GoRouterState state) => const AuthBootstrapPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (BuildContext context, GoRouterState state) => const LoginPage(),
      ),
      GoRoute(
        path: '/student',
        name: 'studentHome',
        builder: (BuildContext context, GoRouterState state) => HomePage(
          title: AppLocalizations.of(context)?.studentWorkspace,
        ),
      ),
      GoRoute(
        path: '/teacher',
        name: 'teacherHome',
        builder: (BuildContext context, GoRouterState state) =>
            const TeacherHomePage(),
      ),
      GoRoute(
        path: '/parent',
        name: 'parentHome',
        builder: (BuildContext context, GoRouterState state) =>
            const ParentHomePage(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final bool loading = authState.isLoading;
      final bool onBootstrap = state.matchedLocation == '/';
      final bool onLogin = state.matchedLocation == '/login';
      if (loading) {
        return onBootstrap || onLogin ? null : '/';
      }

      final AuthSession? session = authState.valueOrNull;
      final bool isAuthenticated = session != null;

      if (!isAuthenticated) {
        return onLogin ? null : '/login';
      }

      if (onLogin || onBootstrap) {
        return '/${session.user.role.name}';
      }

      final String expectedPath = '/${session.user.role.name}';
      if (state.matchedLocation != expectedPath) {
        return expectedPath;
      }

      return null;
    },
  );
});
