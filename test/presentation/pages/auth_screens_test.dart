import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisbatak_app/core/constants/app_strings.dart';
import 'package:hisbatak_app/core/theme/app_theme.dart';
import 'package:hisbatak_app/core/utils/validators.dart';
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

class _FakeAuthRepository implements IAuthRepository, ICloudAuthRepository {
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
      userId: '550e8400-e29b-41d4-a716-446655440001',
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
      userId: '550e8400-e29b-41d4-a716-446655440002',
      name: name,
      email: email,
      connectionMode: mode,
      createdAt: DateTime.now(),
    );
    return session!;
  }

  @override
  Future<OtpChallengeResult> requestPhoneOtp({
    required String phoneE164,
  }) async {
    final normalized = Validators.normalizePhoneE164(phoneE164);
    return OtpChallengeResult(
      phoneE164: normalized,
      challengeId: 'challenge_123',
      previewCode: '123456',
    );
  }

  @override
  Future<AuthSession> verifyPhoneOtp({
    required String phoneE164,
    required String code,
    String? challengeId,
    String? guestUserId,
  }) async {
    session = AuthSession(
      userId: guestUserId ?? '550e8400-e29b-41d4-a716-446655440003',
      name: 'مستخدم الهاتف',
      email: '${Validators.normalizePhoneE164(phoneE164)}@phone.hisbatak.app',
      connectionMode: AuthConnectionMode.online,
      token: 'token_otp',
      createdAt: DateTime.now(),
    );
    return session!;
  }

  @override
  Future<AuthSession> signInWithSocial({
    required SocialAuthProvider provider,
    required String idToken,
    String? email,
    String? displayName,
    String? guestUserId,
  }) async {
    session = AuthSession(
      userId: guestUserId ?? '550e8400-e29b-41d4-a716-446655440004',
      name: displayName ?? provider.name,
      email: email ?? '${provider.name}@social.hisbatak.app',
      connectionMode: AuthConnectionMode.online,
      token: 'token_social',
      createdAt: DateTime.now(),
    );
    return session!;
  }

  @override
  Future<AuthSession> claimGuestAccount({
    required String guestUserId,
    required String phoneE164,
    required String otpCode,
    String? challengeId,
  }) {
    return verifyPhoneOtp(
      phoneE164: phoneE164,
      code: otpCode,
      challengeId: challengeId,
      guestUserId: guestUserId,
    );
  }
}

class _FakeProfileRepository implements IProfileRepository {
  UserProfile profile = const UserProfile(
    id: '550e8400-e29b-41d4-a716-446655440001',
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

Widget _wrapScreen(
  Widget child,
  AuthBloc authBloc,
  ProfileBloc profileBloc,
  ThemeCubit themeCubit,
) {
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

  AuthBloc createAuthBloc() => AuthBloc(
        loginUseCase: LoginUseCase(fakeAuthRepo),
        signupUseCase: SignupUseCase(fakeAuthRepo),
        getAuthSessionUseCase: GetAuthSessionUseCase(fakeAuthRepo),
        getPreferredModeUseCase: GetPreferredModeUseCase(fakeAuthRepo),
        setPreferredModeUseCase: SetPreferredModeUseCase(fakeAuthRepo),
        logoutUseCase: LogoutUseCase(fakeAuthRepo),
        cloudAuthRepository: fakeAuthRepo,
      );

  setUp(() {
    fakeAuthRepo = _FakeAuthRepository();
    fakeProfileRepo = _FakeProfileRepository();

    authBloc = createAuthBloc();

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
          predicate<AuthState>(
              (state) => state.isAuthenticated && state.isOffline),
        ]),
      );
    });

    test('Phone OTP request and verification authenticates cloud session',
        () async {
      authBloc.add(const RequestPhoneOtpEvent(phoneNumber: '770000000'));
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          predicate<AuthState>((state) => state.isLoading),
          predicate<AuthState>(
            (state) =>
                state.isOtpSent &&
                state.pendingPhoneE164 == '+967770000000' &&
                state.devOtpPreviewCode == '123456',
          ),
        ]),
      );

      authBloc.add(const VerifyPhoneOtpEvent(
        phoneNumber: '770000000',
        code: '123456',
        challengeId: 'challenge_123',
      ));
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          predicate<AuthState>((state) => state.isLoading),
          predicate<AuthState>(
              (state) => state.isAuthenticated && state.isOnline),
        ]),
      );
    });
  });

  group('LoginScreen Widget Tests', () {
    testWidgets('Renders LoginScreen in offline mode with quick entry card',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _wrapScreen(const LoginScreen(), authBloc, profileBloc, themeCubit),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.welcomeBack), findsOneWidget);
      expect(find.text(AppStrings.offlineModeShort), findsOneWidget);
      expect(find.text(AppStrings.onlineModeShort), findsOneWidget);

      expect(find.text('خزينة محلية مشفرة 100%'), findsOneWidget);
      expect(find.text('دخول فوري بحساب محلي'), findsOneWidget);
      expect(find.text('نهاري'), findsNothing);
      expect(find.text('ليلي'), findsNothing);
      expect(themeCubit.state, ThemeMode.system);
    });

    testWidgets(
        'Tapping online tab shows Phone OTP and Social logins without dummy password clutter',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final widgetAuthBloc = createAuthBloc();
      addTearDown(widgetAuthBloc.close);

      await tester.pumpWidget(
        _wrapScreen(const LoginScreen(), widgetAuthBloc, profileBloc, themeCubit),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(AppStrings.onlineModeShort));
      await tester.tap(find.text(AppStrings.onlineModeShort));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(widgetAuthBloc.state.isOnline, isTrue);
      expect(find.text('رقم الهاتف السحابي'), findsOneWidget);
      expect(find.text('إرسال رمز التحقق (OTP)'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text(AppStrings.passwordLabel), findsNothing);
    });

    testWidgets('Entering valid phone and requesting OTP reveals OTP input',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final widgetAuthBloc = createAuthBloc();
      addTearDown(widgetAuthBloc.close);

      await tester.pumpWidget(
        _wrapScreen(const LoginScreen(), widgetAuthBloc, profileBloc, themeCubit),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(AppStrings.onlineModeShort));
      await tester.tap(find.text(AppStrings.onlineModeShort));
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '770000000');
      await tester.ensureVisible(find.text('إرسال رمز التحقق (OTP)'));
      await tester.tap(find.text('إرسال رمز التحقق (OTP)'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('وضع المعاينة المحلية: استخدم الرمز 123456'),
          findsOneWidget);
      expect(find.text('رمز التحقق (OTP)'), findsOneWidget);
      expect(find.text('تأكيد الرمز والمتابعة'), findsOneWidget);
    });
  });

  group('SignupScreen Widget Tests', () {
    testWidgets(
        'Renders streamlined SignupScreen for instant local wallet and phone sync toggle',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _wrapScreen(const SignupScreen(), authBloc, profileBloc, themeCubit),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.createAccountTitle), findsOneWidget);
      expect(find.text(AppStrings.fullNameLabel), findsOneWidget);
      expect(find.text('محلي (أوفلاين)'), findsOneWidget);
      expect(find.text('سحابي (أونلاين)'), findsOneWidget);
      expect(find.text('إنشاء محفظة محلية فورية'), findsOneWidget);
      expect(find.text(AppStrings.confirmPasswordLabel), findsNothing);

      await tester.ensureVisible(find.text('سحابي (أونلاين)'));
      await tester.tap(find.text('سحابي (أونلاين)'));
      await tester.pumpAndSettle();

      expect(find.text('رقم الهاتف السحابي'), findsOneWidget);
      expect(find.text('إرسال رمز التحقق (OTP)'), findsOneWidget);
    });
  });
}
