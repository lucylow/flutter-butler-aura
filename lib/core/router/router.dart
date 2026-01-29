import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/devices/devices_list_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/landing/landing_screen.dart';
import '../../features/settings/settings_screen.dart';

/// Notifier used by GoRouter to refresh redirect when auth state changes.
class AuthRedirectNotifier extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;
  void update(bool isAuthenticated) {
    if (_isAuthenticated != isAuthenticated) {
      _isAuthenticated = isAuthenticated;
      notifyListeners();
    }
  }
}

final authRedirectNotifierProvider =
    ChangeNotifierProvider<AuthRedirectNotifier>((ref) {
  final notifier = AuthRedirectNotifier();
  final authState = ref.watch(authStateProvider);
  notifier.update(authState.value != null);
  ref.listen(authStateProvider, (prev, next) {
    notifier.update(next.value != null);
  });
  return notifier;
});

bool _isProtectedRoute(String location) {
  return location == '/' ||
      location.startsWith('/devices') ||
      location.startsWith('/chat') ||
      location.startsWith('/settings');
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authRedirectNotifierProvider);
  return GoRouter(
    refreshListenable: authNotifier,
    initialLocation: '/landing',
    redirect: (context, state) {
      final isAuth = authNotifier.isAuthenticated;
      final location = state.matchedLocation;
      // Handle empty path (e.g. web first load with no hash) so we don't hit errorBuilder
      if (location.isEmpty) {
        return isAuth ? '/' : '/landing';
      }
      if (!isAuth && _isProtectedRoute(location)) return '/login';
      if (isAuth && (location == '/login' || location.startsWith('/login'))) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/landing',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
        routes: [
           GoRoute(
            path: 'devices',
            builder: (context, state) => const DevicesListScreen(),
          ),
           GoRoute(
            path: 'chat',
            builder: (context, state) => const ChatScreen(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ]
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.toString() ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});
