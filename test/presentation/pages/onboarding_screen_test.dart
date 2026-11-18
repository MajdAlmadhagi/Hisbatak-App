import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hisbatak_app/core/constants/app_strings.dart';
import 'package:hisbatak_app/core/di/injection_container.dart' as di;
import 'package:hisbatak_app/domain/entities/user_profile.dart';
import 'package:hisbatak_app/domain/repositories/i_profile_repository.dart';
import 'package:hisbatak_app/domain/usecases/profile/profile_usecases.dart';
import 'package:hisbatak_app/presentation/bloc/profile/profile_bloc.dart';
import 'package:hisbatak_app/presentation/pages/onboarding/onboarding_screen.dart';

class FakeProfileRepository implements IProfileRepository {
  bool onboardingCompleted = false;

  @override
  Future<UserProfile> getUserProfile() async {
    return const UserProfile(
      id: '550e8400-e29b-41d4-a716-446655440000',
      fullName: 'مستخدم تجريبي',
      email: 'test@local.offline',
      currencyCode: 'YER',
      currencySymbol: 'ر.ي',
      monthlyBudgetLimit: 10000,
      currentAvailable: 10000,
      biometricEnabled: false,
      isDarkMode: false,
      isConfigured: false,
    );
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {}

  @override
  Future<void> updateBiometricSetting(bool enabled) async {}

  @override
  Future<void> updateDarkModeSetting(bool isDark) async {}

  @override
  Future<void> resetAllData() async {
    onboardingCompleted = false;
  }

  @override
  Future<bool> isDarkMode() async => false;

  @override
  Future<bool> isBiometricEnabled() async => false;

  @override
  Future<bool> hasSeenOnboarding() async => onboardingCompleted;

  @override
  Future<void> setOnboardingCompleted() async {
    onboardingCompleted = true;
  }
}

void main() {
  late FakeProfileRepository fakeRepo;
  late ProfileBloc profileBloc;

  setUp(() {
    fakeRepo = FakeProfileRepository();
    if (di.sl.isRegistered<IProfileRepository>()) {
      di.sl.unregister<IProfileRepository>();
    }
    di.sl.registerSingleton<IProfileRepository>(fakeRepo);

    profileBloc = ProfileBloc(
      getProfileUseCase: GetProfileUseCase(fakeRepo),
      saveProfileUseCase: SaveProfileUseCase(fakeRepo),
      profileRepository: fakeRepo,
    );
  });

  tearDown(() {
    profileBloc.close();
  });

  Widget buildTestableWidget({bool disableAnimations = false}) {
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(body: Text('Login Page')),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home Page')),
        ),
      ],
    );

    return BlocProvider<ProfileBloc>.value(
      value: profileBloc,
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        ),
      ),
    );
  }

  Future<void> pumpTransition(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('OnboardingScreen 3D & Neumorphism tests', () {
    testWidgets(
        'Renders streamlined first slide with 3D stage, light copy, and gentle animation',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text(AppStrings.appName), findsOneWidget);
      expect(find.text(AppStrings.offlineReady), findsOneWidget);
      expect(find.text('مصاريفك بوضوح تام'), findsOneWidget);
      expect(find.text('الميزانية الشخصية'), findsOneWidget);
      expect(find.text(AppStrings.onboardingNext), findsOneWidget);
      expect(find.text(AppStrings.onboardingSkip), findsOneWidget);
      // Verify old heavy bullet clutter was removed
      expect(find.text(AppStrings.onboardingSlide1Feature1), findsNothing);
      expect(find.text(AppStrings.onboardingSafeOffline), findsNothing);
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('Navigates cleanly through all 3 Isometric 3D slides',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump(const Duration(milliseconds: 250));

      // Slide 2
      await tester.tap(find.text(AppStrings.onboardingNext));
      await pumpTransition(tester);

      expect(find.text('قسّم الفواتير بلا إحراج'), findsOneWidget);
      expect(find.text('المجموعات والذمم'), findsOneWidget);

      // Slide 3
      await tester.tap(find.text(AppStrings.onboardingNext));
      await pumpTransition(tester);

      expect(find.text('أوفلاين دائماً.. سحابي متى شئت'), findsOneWidget);
      expect(find.text('خصوصية ومزامنة مرنة'), findsOneWidget);
      expect(find.text(AppStrings.onboardingStart), findsOneWidget);
    });

    testWidgets(
        'Tapping Start on last slide completes onboarding and opens Login',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text(AppStrings.onboardingNext));
      await pumpTransition(tester);
      await tester.tap(find.text(AppStrings.onboardingNext));
      await pumpTransition(tester);

      expect(fakeRepo.onboardingCompleted, isFalse);

      await tester.tap(find.text(AppStrings.onboardingStart));
      await pumpTransition(tester);

      expect(fakeRepo.onboardingCompleted, isTrue);
      expect(find.text('Login Page'), findsOneWidget);
    });

    testWidgets('Tapping Skip immediately completes onboarding',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump(const Duration(milliseconds: 200));

      expect(fakeRepo.onboardingCompleted, isFalse);

      await tester.tap(find.text(AppStrings.onboardingSkip));
      await pumpTransition(tester);

      expect(fakeRepo.onboardingCompleted, isTrue);
      expect(find.text('Login Page'), findsOneWidget);
    });

    testWidgets('Respects device reduced motion setting',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(disableAnimations: true));
      await tester.pumpAndSettle();

      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('مصاريفك بوضوح تام'), findsOneWidget);
    });
  });
}
