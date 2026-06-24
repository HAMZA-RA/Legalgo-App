import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:legalgo_mobile/features/admin/dashboard/presentation/screens/admin_dashboard_screen.dart';
import 'package:legalgo_mobile/features/admin/packs/presentation/screens/admin_packs_screen.dart';
import 'package:legalgo_mobile/features/admin/payments/presentation/screens/admin_payments_screen.dart';
import 'package:legalgo_mobile/features/admin/requests/presentation/screens/admin_requests_screen.dart';
import 'package:legalgo_mobile/features/admin/shell/presentation/screens/admin_shell_screen.dart';
import 'package:legalgo_mobile/features/admin/subscriptions/presentation/screens/admin_subscriptions_screen.dart';
import 'package:legalgo_mobile/features/admin/users/presentation/screens/admin_users_screen.dart';
import 'package:legalgo_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:legalgo_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:legalgo_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:legalgo_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:legalgo_mobile/features/auth/presentation/screens/splash_screen.dart';
import 'package:legalgo_mobile/features/client/dashboard/presentation/screens/client_dashboard_screen.dart';
import 'package:legalgo_mobile/features/client/shell/presentation/screens/client_shell_screen.dart';
import 'package:legalgo_mobile/features/documents/presentation/screens/client_documents_screen.dart';
import 'package:legalgo_mobile/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:legalgo_mobile/features/payments/presentation/screens/client_payments_screen.dart';
import 'package:legalgo_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:legalgo_mobile/features/requests/presentation/screens/client_requests_screen.dart';
import 'package:legalgo_mobile/features/requests/presentation/screens/request_details_screen.dart';
import 'package:legalgo_mobile/features/settings/presentation/screens/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final path = state.uri.path;
      final publicRoutes = {'/login', '/register'};

      if (auth.status == AuthStatus.unknown) {
        return path == '/splash' ? null : '/splash';
      }

      if (!auth.isAuthenticated) {
        return publicRoutes.contains(path) ? null : '/login';
      }

      final role = auth.user?.role;
      if (path == '/splash' || publicRoutes.contains(path)) {
        return role == UserRole.admin
            ? '/admin/dashboard'
            : '/client/dashboard';
      }

      if (path == '/client/home') {
        return '/client/dashboard';
      }

      if (path.startsWith('/admin') && role != UserRole.admin) {
        return '/client/dashboard';
      }

      if (path.startsWith('/client') && role == UserRole.admin) {
        return '/admin/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            ClientShellScreen(currentPath: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/client/home',
            name: 'client-home-legacy',
            redirect: (context, state) => '/client/dashboard',
          ),
          GoRoute(
            path: '/client/dashboard',
            name: 'client-dashboard',
            builder: (context, state) => const ClientDashboardScreen(),
          ),
          GoRoute(
            path: '/client/requests',
            name: 'client-requests',
            builder: (context, state) => const ClientRequestsScreen(),
          ),
          GoRoute(
            path: '/client/requests/:requestId',
            name: 'client-request-details',
            builder: (context, state) => RequestDetailsScreen(
              requestId: state.pathParameters['requestId'] ?? '',
              admin: false,
            ),
          ),
          GoRoute(
            path: '/client/documents',
            name: 'client-documents',
            builder: (context, state) => const ClientDocumentsScreen(),
          ),
          GoRoute(
            path: '/client/payments',
            name: 'client-payments',
            builder: (context, state) => const ClientPaymentsScreen(),
          ),
          GoRoute(
            path: '/client/notifications',
            name: 'client-notifications',
            builder: (context, state) =>
                const NotificationsScreen(admin: false),
          ),
          GoRoute(
            path: '/client/profile',
            name: 'client-profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/client/settings',
            name: 'client-settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AdminShellScreen(currentPath: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            name: 'admin-dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            name: 'admin-users',
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: '/admin/requests',
            name: 'admin-requests',
            builder: (context, state) => const AdminRequestsScreen(),
          ),
          GoRoute(
            path: '/admin/requests/:requestId',
            name: 'admin-request-details',
            builder: (context, state) => RequestDetailsScreen(
              requestId: state.pathParameters['requestId'] ?? '',
              admin: true,
            ),
          ),
          GoRoute(
            path: '/admin/payments',
            name: 'admin-payments',
            builder: (context, state) => const AdminPaymentsScreen(),
          ),
          GoRoute(
            path: '/admin/notifications',
            name: 'admin-notifications',
            builder: (context, state) => const NotificationsScreen(admin: true),
          ),
          GoRoute(
            path: '/admin/subscriptions',
            name: 'admin-subscriptions',
            builder: (context, state) => const AdminSubscriptionsScreen(),
          ),
          GoRoute(
            path: '/admin/packs',
            name: 'admin-packs',
            builder: (context, state) => const AdminPacksScreen(),
          ),
          GoRoute(
            path: '/admin/settings',
            name: 'admin-settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('LegalGo')),
      body: Center(child: Text(state.error?.message ?? 'Page introuvable')),
    ),
  );
});
