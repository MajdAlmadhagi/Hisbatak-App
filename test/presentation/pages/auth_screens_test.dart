import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisbatak_app/core/constants/app_strings.dart';
import 'package:hisbatak_app/core/theme/app_theme.dart';
import 'package:hisbatak_app/domain/entities/auth_session.dart';
import 'package:hisbatak_app/domain/entities/user_profile.dart';
import 'package:hisbatak_app/domain/repositories/i_auth_repository.dart';
import 'package:hisbatak_app/domain/repositories/i_profile_repository.dart';
import 'package:hisbatak_app/domain/usecases/auth/auth_usecases.dart';
import 'package:hisbatak_app/domain/usecases/profile/profile_usecases.dart';
import 'package:hisbatak_app/presentation/bloc/auth/auth_bloc.dart';
import 'package:hisbatak_app/presentation/bloc/auth/auth_event.dart';
import 'package:hisbatak_app/presentation/bloc/auth/auth_state.dart';
import 'package:hisbatak_app/presentation/bloc/profile/profile_bloc.dart';
import 'package:hisbatak_app/presentation/bloc/theme/theme_cubit.dart';
import 'package:hisbatak_app/presentation/pages/auth/login_screen.dart';
import 'package:hisbatak_app/presentation/pages/auth/signup_screen.dart';

class _FakeAuthRepository implements IAuthRepository {
  AuthConnectionMode currentMode = AuthConnectionMode.offline;
  AuthSession? session;

  @override
  Future<AuthSession?> getCurrentSession() async => session;

  @override
  Future<AuthConnectionMode> getPreferredConnectionMode() async => currentMode;

  @override
  Future<AuthSession> login({
    required String identifier,
    required String password,
    required AuthConnectionMode mode,
    bool rememberMe = true,
  }) async {
    session = AuthSession(
      userId: 'test_user',
      name: identifier.isNotEmpty ? identifier : 'مستخدم تجريبي',
      email: identifier.contains('@') ? identifier : 'test@offline.local',
      connectionMode: mode,
      createdAt: DateTime.now(),
    );
    return session!;
  }

  @override
  Future<void> logout() async {
    session = null;
  }

  @override
  Future<void> setPreferredConnectionMode(AuthConnectionMode mode) async {
    currentMode = mode;
  }

  @override
  Future<AuthSession> signup({
    required String name,
    required String email,
    required String password,
    required AuthConnectionMode mode,
  }) async {
    session = AuthSession(
      userId: 'new_user',
      name: name,
      email: email,
      connectionMode: mode,
      createdAt: DateTime.now(),
    );
    return session!;
  }
}

class _FakeProfileRepository implements IProfileRepository {
  UserProfile profile = const UserProfile(
    id: 'user_test',
    fullName: 'مستخدم تجريبي',
    email: 'test@local.me',
    currencyCode: 'YER',
    currencySymbol: 'ر.ي',
    monthlyBudgetLimit: 10000,
    currentAvailable: 10000,
    biometricEnabled: false,
    isDarkMode: false,
    isConfigured: false,
  );

  @override
  Future<UserProfile> getUserProfile() async => profile;

  @override
  Future<bool> hasSeenOnboarding() async => true;

  @override
  Future<bool> isBiometricEnabled() async => false;

  @override
  Future<bool> isDarkMode() async => false;

  @override
  Future<void> resetAllData() async {}

  @override
  Future<void> saveUserProfile(UserProfile p) async {
    profile = p;
  }

  @override
  Future<void> setOnboardingCompleted() async {}

  @override
  Future<void> updateBiometricSetting(bool enabled) async {}

  @override
  Future<void> updateDarkModeSetting(bool isDark) async {}
}

Widget _wrapScreen(Widget child, AuthBloc authBloc, ProfileBloc profileBloc, ThemeCubit themeCubit) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>.value(value: authBloc),
      BlocProvider<ProfileBloc>.value(value: profileBloc),
      BlocProvider<ThemeCubit>.value(value: themeCubit),
    ],
    child: MaterialApp(
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: child,
      ),
    ),
  );
}

void main() {
  late _FakeAuthRepository fakeAuthRepo;
  late _FakeProfileRepository fakeProfileRepo;
  late AuthBloc authBloc;
  late ProfileBloc profileBloc;
  late ThemeCubit themeCubit;

  setUp(() {
    fakeAuthRepo = _FakeAuthRepository();
    fakeProfileRepo = _FakeProfileRepository();

    authBloc = AuthBloc(
      loginUseCase: LoginUseCase(fakeAuthRepo),
      signupUseCase: SignupUseCase(fakeAuthRepo),
      getAuthSessionUseCase: GetAuthSessionUseCase(fakeAuthRepo),
      getPreferredModeUseCase: GetPreferredModeUseCase(fakeAuthRepo),
      setPreferredModeUseCase: SetPreferredModeUseCase(fakeAuthRepo),
      logoutUseCase: LogoutUseCase(fakeAuthRepo),
    );

    profileBloc = ProfileBloc(
      getProfileUseCase: GetProfileUseCase(fakeProfileRepo),
      saveProfileUseCase: SaveProfileUseCase(fakeProfileRepo),
      profileRepository: fakeProfileRepo,
    );

    themeCubit = ThemeCubit(profileRepository: fakeProfileRepo);
  });

  tearDown(() {
    authBloc.close();
    profileBloc.close();
    themeCubit.close();
  });

  group('Auth BLoC Tests', () {
    test('Default mode is offline', () {
      expect(authBloc.state.isOffline, isTrue);
    });

    test('Switch connection mode event updates mode to online', () async {
      authBloc.add(const SwitchConnectionModeEvent(AuthConnectionMode.online));
      await expectLater(
        authBloc.stream,
        emits(predicate<AuthState>((state) => state.isOnline)),
      );
    });

    test('Quick offline access authenticates immediately', () async {
      authBloc.add(const QuickOfflineAccessEvent(localName: 'محفظة طارق'));
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          predicate<AuthState>((state) => state.isLoading),
          predicate<AuthState>((state) => state.isAuthenticated && state.isOffline),
        ]),
      );
    });
  });

  group('LoginScreen Widget Tests', () {
    testWidgets('Renders LoginScreen in offline mode with quick entry card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _wrapScreen(const LoginScreen(), authBloc, profileBloc, themeCubit),
      );
      await tester.pumpAndSettle();

      // Checks title and subtitle
      expect(find.text(AppStrings.welcomeBack), findsOneWidget);
      expect(find.text(AppStrings.offlineModeShort), findsOneWidget);
      expect(find.text(AppStrings.onlineModeShort), findsOneWidget);

      // Offline info card is visible
      expect(find.text('خزينة محلية مشفرة 100%'), findsOneWidget);
      expect(find.text('دخول فوري بحساب محلي'), findsOneWidget);
    });

    testWidgets('Tapping online tab switches to online fields and social logins', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _wrapScreen(const LoginScreen(), authBloc, profileBloc, themeCubit),
      );
      await tester.pumpAndSettle();

      // Tap on online tab
      final onlineTab = find.text(AppStrings.onlineModeShort);
      await tester.tap(onlineTab);
      await tester.pumpAndSettle();

      // Now online mode form should be visible
      expect(find.text(AppStrings.emailOrPhoneLabel), findsOneWidget);
      expect(find.text(AppStrings.passwordLabel), findsOneWidget);
      expect(find.text(AppStrings.loginOnline), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
    });
  });

  group('SignupScreen Widget Tests', () {
    testWidgets('Renders SignupScreen with inputs and connection mode selector', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _wrapScreen(const SignupScreen(), authBloc, profileBloc, themeCubit),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.createAccountTitle), findsOneWidget);
      expect(find.text(AppStrings.fullNameLabel), findsOneWidget);
      expect(find.text(AppStrings.emailOrPhoneLabel), findsOneWidget);
      expect(find.text(AppStrings.passwordLabel), findsOneWidget);
      expect(find.text(AppStrings.confirmPasswordLabel), findsOneWidget);
      expect(find.text(AppStrings.signupOnline), findsOneWidget);
      expect(find.text(AppStrings.continueOfflineAlternative), findsOneWidget);
    });
  });
}
