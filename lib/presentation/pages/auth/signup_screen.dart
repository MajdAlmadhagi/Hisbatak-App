import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hisbatak_app/core/utils/validators.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/auth_session.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/theme/theme_cubit.dart';
import '../../widgets/hisbatak_mark.dart';
import 'widgets/auth_text_field.dart';

/// [SignupScreen] provides an elegant, modern registration flow supporting
/// both local-first offline accounts and cloud-synced accounts.
///
/// SOLID Principles:
/// - Single Responsibility Principle (SRP): Handles user registration inputs and validation.
/// - Dependency Inversion Principle (DIP): Dispatches events to AuthBloc.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _agreedToTerms = true;
  AuthConnectionMode _signupMode = AuthConnectionMode.offline;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSignupSubmitted(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('يرجى الموافقة على شروط الاستخدام وسياسة الخصوصية'),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Update bloc connection mode to match chosen signup mode
    context.read<AuthBloc>().add(SwitchConnectionModeEvent(_signupMode));

    context.read<AuthBloc>().add(
          SignupSubmittedEvent(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          ),
        );
  }

  void _onQuickLocalSignup(BuildContext context) {
    context.read<AuthBloc>().add(
          const SwitchConnectionModeEvent(AuthConnectionMode.offline),
        );
    context.read<AuthBloc>().add(
          SignupSubmittedEvent(
            name: _nameController.text.trim().isNotEmpty
                ? _nameController.text.trim()
                : 'مستخدم محلي',
            email: _emailController.text.trim(),
            password: '',
          ),
        );
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
                  const Icon(Iconsax.info_circle,
                      color: Colors.white, size: 18),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }

        if (state.status == AuthStatus.authenticated) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Iconsax.tick_circle,
                        color: Colors.white, size: 18),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
          // After successful signup, proceed to profile setup!
          context.go('/setup-profile');
        }
      },
      builder: (context, state) {
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
                    // Top Navigation Bar
                    _buildTopBar(context, isDark),
                    const SizedBox(height: 20),

                    // Header
                    _buildHeader(context),
                    const SizedBox(height: 20),

                    // Mode Selection Banner
                    _buildModeSelector(context, isDark),
                    const SizedBox(height: 20),

                    // Input Fields
                    AuthTextField(
                      label: AppStrings.fullNameLabel,
                      hintText: 'مثال: طارق منصور',
                      controller: _nameController,
                      prefixIcon: Iconsax.user,
                      textInputAction: TextInputAction.next,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'يرجى إدخال اسمك الكريم';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    AuthTextField(
                      label: AppStrings.emailOrPhoneLabel,
                      hintText: AppStrings.emailOrPhoneHint,
                      controller: _emailController,
                      prefixIcon: Iconsax.sms,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'يرجى إدخال البريد الإلكتروني أو رقم الهاتف';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    AuthTextField(
                      label: AppStrings.passwordLabel,
                      hintText: AppStrings.passwordHint,
                      controller: _passwordController,
                      prefixIcon: Iconsax.lock,
                      isPassword: true,
                      textInputAction: TextInputAction.next,
                      validator: (val) => Validators.validatePassword(val),
                    ),
                    const SizedBox(height: 14),

                    AuthTextField(
                      label: AppStrings.confirmPasswordLabel,
                      hintText: AppStrings.confirmPasswordHint,
                      controller: _confirmPasswordController,
                      prefixIcon: Iconsax.lock_1,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      validator: (val) => Validators.validatMatching(
                          val, _passwordController.text),
                    ),
                    const SizedBox(height: 16),

                    // Terms and Conditions Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreedToTerms,
                            activeColor: AppColors.emerald,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            onChanged: (val) {
                              setState(() => _agreedToTerms = val ?? false);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppStrings.termsAgreement,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: context.appTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    ElevatedButton(
                      onPressed:
                          isLoading ? null : () => _onSignupSubmitted(context),
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
                                const Icon(Iconsax.user_add,
                                    size: 20, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  AppStrings.signupOnline,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 14),

                    // Quick Local Vault Setup Alternative Button
                    OutlinedButton(
                      onPressed:
                          isLoading ? null : () => _onQuickLocalSignup(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDark ? AppColors.brandGreen : AppColors.emerald,
                        side: BorderSide(
                          color:
                              isDark ? AppColors.brandGreen : AppColors.emerald,
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.shield_tick, size: 18),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              AppStrings.continueOfflineAlternative,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Navigation to Login
                    _buildLoginPrompt(context),
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
        // Back Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go('/login'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDarkElevated : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
              ),
              child: Icon(
                Icons.arrow_back,
                size: 20,
                color: context.appTextPrimary,
              ),
            ),
          ),
        ),

        // Brand Logo
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.brandNavy,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const HisbatakMark(size: 20, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.appName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.appTextPrimary,
              ),
            ),
          ],
        ),

        // Theme Switcher
        BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            final isDarkModeActive = themeMode == ThemeMode.dark ||
                (themeMode == ThemeMode.system &&
                    MediaQuery.of(context).platformBrightness ==
                        Brightness.dark);

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.read<ThemeCubit>().toggleTheme(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDarkElevated : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                    ),
                  ),
                  child: Icon(
                    isDarkModeActive ? Iconsax.sun_1 : Iconsax.moon,
                    size: 18,
                    color: isDarkModeActive
                        ? const Color(0xFFFBBF24)
                        : AppColors.primary,
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
          AppStrings.createAccountTitle,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: context.appTextPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.createAccountSubtitle,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: context.appTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector(BuildContext context, bool isDark) {
    final isOffline = _signupMode == AuthConnectionMode.offline;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDarkElevated : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نوع الحساب المفضل للبدء:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.appTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SignupModeChip(
                  isSelected: isOffline,
                  title: 'محلي (أوفلاين)',
                  subtitle: 'تشفير على الهاتف 🔒',
                  activeColor: AppColors.emerald,
                  onTap: () =>
                      setState(() => _signupMode = AuthConnectionMode.offline),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SignupModeChip(
                  isSelected: !isOffline,
                  title: 'سحابي (أونلاين)',
                  subtitle: 'مزامنة ومجموعات ☁️',
                  activeColor: const Color(0xFF0284C7),
                  onTap: () =>
                      setState(() => _signupMode = AuthConnectionMode.online),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    final isDark = context.isDarkMode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppStrings.alreadyHaveAccount,
          style: TextStyle(
            fontSize: 13,
            color: context.appTextSecondary,
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () => context.go('/login'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              AppStrings.loginNow,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.brandGreen : AppColors.emerald,
                decoration: TextDecoration.underline,
                decorationColor:
                    isDark ? AppColors.brandGreen : AppColors.emerald,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignupModeChip extends StatelessWidget {
  final bool isSelected;
  final String title;
  final String subtitle;
  final Color activeColor;
  final VoidCallback onTap;

  const _SignupModeChip({
    required this.isSelected,
    required this.title,
    required this.subtitle,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: isDark ? 0.25 : 0.12)
              : (isDark ? AppColors.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? activeColor : context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? activeColor
                    : (isDark
                        ? AppColors.textSecondary
                        : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
