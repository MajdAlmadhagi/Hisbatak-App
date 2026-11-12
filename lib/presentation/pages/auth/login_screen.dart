import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/theme/theme_cubit.dart';
import '../../widgets/hisbatak_mark.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/connection_mode_selector.dart';
import 'widgets/offline_mode_info_card.dart';
import 'widgets/social_auth_buttons.dart';

/// [LoginScreen] delivers a modern, high-aesthetic login experience matching Hisbatak's
/// Stitch Fintech design guidelines, supporting both Offline-First and Online Cloud modes.
///
/// SOLID Principles:
/// - Single Responsibility Principle (SRP): Coordinates login UI and user interactions.
/// - Dependency Inversion Principle (DIP): Relies on AuthBloc and ThemeCubit for state.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _localNameController = TextEditingController();

  bool _rememberMe = true;
  bool _showCustomLocalField = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _localNameController.dispose();
    super.dispose();
  }

  void _onLoginSubmitted(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState.isOnline) {
      if (!_formKey.currentState!.validate()) return;
      context.read<AuthBloc>().add(
            LoginSubmittedEvent(
              identifier: _identifierController.text.trim(),
              password: _passwordController.text.trim(),
              rememberMe: _rememberMe,
            ),
          );
    } else {
      context.read<AuthBloc>().add(
            LoginSubmittedEvent(
              identifier: _localNameController.text.trim().isNotEmpty
                  ? _localNameController.text.trim()
                  : 'مستخدم محلي',
              password: _passwordController.text.trim(),
              rememberMe: _rememberMe,
            ),
          );
    }
  }

  void _onQuickOfflineAccess(BuildContext context) {
    context.read<AuthBloc>().add(
          const QuickOfflineAccessEvent(localName: 'مستخدم حسبتك'),
        );
  }

  void _handleSuccessfulAuth(BuildContext context) {
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is ProfileLoaded && profileState.profile.isConfigured) {
      context.go('/home');
    } else {
      context.go('/setup-profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Iconsax.info_circle, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.expense,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }

        if (state.status == AuthStatus.authenticated) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Iconsax.tick_circle, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.successMessage!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.emerald,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(milliseconds: 1400),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
          _handleSuccessfulAuth(context);
        }
      },
      builder: (context, state) {
        final isOffline = state.isOffline;
        final isLoading = state.isLoading;

        return Scaffold(
          backgroundColor: context.appBackground,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Bar: Brand + Quick Theme Toggle
                    _buildTopBar(context, isDark),
                    const SizedBox(height: 24),

                    // Header Greetings
                    _buildHeader(context),
                    const SizedBox(height: 24),

                    // Connection Mode Selector (Offline vs Online)
                    ConnectionModeSelector(
                      selectedMode: state.connectionMode,
                      onModeChanged: (mode) {
                        context.read<AuthBloc>().add(SwitchConnectionModeEvent(mode));
                      },
                    ),
                    const SizedBox(height: 22),

                    // Body based on mode (Animated Switcher)
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 300),
                      crossFadeState: isOffline
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: _buildOfflineContent(context, isLoading),
                      secondChild: _buildOnlineContent(context, isLoading),
                    ),

                    const SizedBox(height: 28),

                    // Navigation to Signup
                    _buildSignupPrompt(context),
                    const SizedBox(height: 16),

                    // Bottom Security Tag
                    Center(
                      child: Text(
                        '🔒 حِسبَتك يحمي خصوصيتك المالية بأعلى معايير الأمان',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: context.appTextMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // App Mark Brand
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.brandNavy,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const HisbatakMark(size: 24, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              AppStrings.appName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: context.appTextPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),

        // Quick Dark / Light Mode Switcher
        BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            final isDarkModeActive = themeMode == ThemeMode.dark ||
                (themeMode == ThemeMode.system &&
                    MediaQuery.of(context).platformBrightness == Brightness.dark);

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.read<ThemeCubit>().toggleTheme(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDarkElevated : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDarkModeActive ? Iconsax.sun_1 : Iconsax.moon,
                        size: 16,
                        color: isDarkModeActive
                            ? const Color(0xFFFBBF24)
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isDarkModeActive ? 'نهاري' : 'ليلي',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.welcomeBack,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: context.appTextPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.loginSubtitle,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: context.appTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineContent(BuildContext context, bool isLoading) {
    final isDark = context.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Offline Security Info & Quick Access Card
        OfflineModeInfoCard(
          isLoading: isLoading,
          onQuickAccess: () => _onQuickOfflineAccess(context),
        ),
        const SizedBox(height: 16),

        // Optional custom local profile entry
        if (!_showCustomLocalField)
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _showCustomLocalField = true),
              icon: Icon(
                Iconsax.edit,
                size: 16,
                color: isDark ? AppColors.brandGreen : AppColors.emerald,
              ),
              label: Text(
                'تخصيص اسم الحساب المحلي أو كلمة مرور',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.brandGreen : AppColors.emerald,
                ),
              ),
            ),
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDarkElevated : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTextField(
                  label: AppStrings.localUsernameLabel,
                  hintText: AppStrings.localUsernameHint,
                  controller: _localNameController,
                  prefixIcon: Iconsax.user,
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  label: 'رمز مرور محلي (اختياري)',
                  hintText: 'قفل الحساب المحلي برمز سري',
                  controller: _passwordController,
                  prefixIcon: Iconsax.lock,
                  isPassword: true,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoading ? null : () => _onLoginSubmitted(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'دخول الحساب المحلي',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOnlineContent(BuildContext context, bool isLoading) {
    final isDark = context.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email / Phone Field
        AuthTextField(
          label: AppStrings.emailOrPhoneLabel,
          hintText: AppStrings.emailOrPhoneHint,
          controller: _identifierController,
          prefixIcon: Iconsax.sms,
          keyboardType: TextInputType.emailAddress,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'يرجى إدخال البريد الإلكتروني أو رقم الهاتف';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),

        // Password Field
        AuthTextField(
          label: AppStrings.passwordLabel,
          hintText: AppStrings.passwordHint,
          controller: _passwordController,
          prefixIcon: Iconsax.lock,
          isPassword: true,
          textInputAction: TextInputAction.done,
          validator: (val) {
            if (val == null || val.length < 4) {
              return 'كلمة المرور يجب أن لا تقل عن 4 خانات';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),

        // Remember Me & Forgot Password
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: AppColors.emerald,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    onChanged: (val) => setState(() => _rememberMe = val ?? true),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  AppStrings.rememberMe,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.appTextSecondary,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'سيتم إرسال رابط استعادة كلمة المرور لبريدك عند ربط خادم الـ API',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: AppColors.primaryLight,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              child: Text(
                AppStrings.forgotPassword,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Submit Button (Online Mode)
        ElevatedButton(
          onPressed: isLoading ? null : () => _onLoginSubmitted(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Iconsax.login_1, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.loginOnline,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 20),

        // Social Logins (Google / Apple)
        SocialAuthButtons(
          onGooglePressed: () {
            _identifierController.text = 'user.google@hisbatak.com';
            _passwordController.text = 'google_authenticated';
            _onLoginSubmitted(context);
          },
          onApplePressed: () {
            _identifierController.text = 'user.apple@icloud.com';
            _passwordController.text = 'apple_authenticated';
            _onLoginSubmitted(context);
          },
        ),
      ],
    );
  }

  Widget _buildSignupPrompt(BuildContext context) {
    final isDark = context.isDarkMode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppStrings.dontHaveAccount,
          style: TextStyle(
            fontSize: 13,
            color: context.appTextSecondary,
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () => context.go('/signup'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              AppStrings.createNewAccount,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.brandGreen : AppColors.emerald,
                decoration: TextDecoration.underline,
                decorationColor: isDark ? AppColors.brandGreen : AppColors.emerald,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
