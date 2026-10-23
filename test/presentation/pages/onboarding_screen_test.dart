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
      id: 'user_me',
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

  Widget buildTestableWidget() {
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/setup-profile',
          builder: (context, state) =>
              const Scaffold(body: Text('Setup Profile Page')),
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
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
      ),
    );
  }

  group('OnboardingScreen tests', () {
    testWidgets('Renders first slide correctly with branding and next button',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Brand badge and app title
      expect(find.text(AppStrings.appName), findsOneWidget);
      expect(find.text(AppStrings.offlineReady), findsOneWidget);

      // Slide 1 title and tag
      expect(find.text(AppStrings.onboardingSlide1Title), findsOneWidget);
      expect(find.text(AppStrings.onboardingSlide1Tag), findsOneWidget);
      expect(find.text(AppStrings.onboardingSlide1Feature1), findsOneWidget);

      // Next and Skip buttons
      expect(find.text(AppStrings.onboardingNext), findsOneWidget);
      expect(find.text(AppStrings.onboardingSkip), findsOneWidget);
    });

    testWidgets(
        'Swipes horizontally through all 4 slides including online sync',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Tap Next to advance to slide 2
      await tester.tap(find.text(AppStrings.onboardingNext));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.onboardingSlide2Title), findsOneWidget);
      expect(find.text(AppStrings.onboardingSlide2Tag), findsOneWidget);
      expect(find.text(AppStrings.onboardingSlide2Feature1), findsOneWidget);

      // Tap Next to advance to slide 3
      await tester.tap(find.text(AppStrings.onboardingNext));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.onboardingSlide3Title), findsOneWidget);
      expect(find.text(AppStrings.onboardingSlide3Tag), findsOneWidget);
      expect(find.text(AppStrings.onboardingSlide3Feature1), findsOneWidget);

      // Tap Next to advance to slide 4 (Online features)
      await tester.tap(find.text(AppStrings.onboardingNext));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.onboardingSlide4Title), findsOneWidget);
      expect(find.text(AppStrings.onboardingSlide4Tag), findsOneWidget);
      expect(find.text(AppStrings.onboardingSlide4Feature1), findsOneWidget);

      // On final slide, "ابدأ الآن" is shown
      expect(find.text(AppStrings.onboardingStart), findsOneWidget);
    });

    testWidgets('Tapping Start on last slide sets onboarding completed',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Navigate to last slide (4th slide)
      await tester.tap(find.text(AppStrings.onboardingNext));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.onboardingNext));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.onboardingNext));
      await tester.pumpAndSettle();

      expect(fakeRepo.onboardingCompleted, isFalse);

      await tester.tap(find.text(AppStrings.onboardingStart));
      await tester.pump();

      expect(fakeRepo.onboardingCompleted, isTrue);
    });

    testWidgets('Tapping Skip immediately sets onboarding completed',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(fakeRepo.onboardingCompleted, isFalse);

      await tester.tap(find.text(AppStrings.onboardingSkip));
      await tester.pump();

      expect(fakeRepo.onboardingCompleted, isTrue);
    });
  });
}
