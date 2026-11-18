import 'package:go_router/go_router.dart';
import '../pages/about/about_app_screen.dart';
import '../pages/auth/login_screen.dart';
import '../pages/lock/app_lock_screen.dart';
import '../pages/auth/signup_screen.dart';
import '../pages/main_layout/main_navigation_screen.dart';
import '../pages/onboarding/onboarding_screen.dart';
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
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/setup-profile',
        name: 'setup_profile',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/lock',
        name: 'lock',
        builder: (context, state) => const AppLockScreen(),
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
        path: '/members',
        name: 'members',
        builder: (context, state) => const MainNavigationScreen(initialIndex: 2),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const MainNavigationScreen(initialIndex: 3),
      ),
      GoRoute(
        path: '/all-transactions',
        name: 'all_transactions',
        builder: (context, state) => const AllTransactionsScreen(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutAppScreen(),
      ),
    ],
  );
}
