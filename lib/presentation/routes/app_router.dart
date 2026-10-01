import 'package:go_router/go_router.dart';
import '../pages/main_layout/main_navigation_screen.dart';
import '../pages/profile_setup/profile_setup_screen.dart';
import '../pages/splash/splash_screen.dart';
import '../pages/transactions/all_transactions_screen.dart';

/// [AppRouter] defines the declarative routing tree using GoRouter.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
/// Manages route declarations and screen transitions cleanly separated from UI logic.
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/setup-profile',
        name: 'setup_profile',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const MainNavigationScreen(initialIndex: 0),
      ),
      GoRoute(
        path: '/groups',
        name: 'groups',
        builder: (context, state) => const MainNavigationScreen(initialIndex: 1),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const MainNavigationScreen(initialIndex: 2),
      ),
      GoRoute(
        path: '/all-transactions',
        name: 'all_transactions',
        builder: (context, state) => const AllTransactionsScreen(),
      ),
    ],
  );
}
