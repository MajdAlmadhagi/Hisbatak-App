import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/repositories/i_auth_repository.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../widgets/hisbatak_mark.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/connection_mode_selector.dart';
import 'widgets/offline_mode_info_card.dart';
import 'widgets/phone_otp_auth_section.dart';
import 'widgets/social_auth_buttons.dart';

/// [LoginScreen] provides clutter-free progressive entry:
/// 1) Instant Local Workspace (no password wall), or
/// 2) Phone OTP / Google / Apple cloud sync.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _localNameController = TextEditingController();

  bool _showCustomLocalField = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _localNameController.dispose();
    super.dispose();
  }

  void _onQuickOfflineAccess(BuildContext context) {
    final customName = _localNameController.text.trim();
    context.read<AuthBloc>().add(
          QuickOfflineAccessEvent(
            localName: customName.isNotEmpty ? customName : 'مستخدم حسبتك',
          ),
        );
  }

  void _onSendOtp(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(
          RequestPhoneOtpEvent(phoneNumber: _phoneController.text.trim()),
        );
  }

  void _onVerifyOtp(BuildContext context, AuthState state) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final hasExistingGuest =
        state.session != null && state.session!.userId.isNotEmpty;
    if (hasExistingGuest) {
      context.read<AuthBloc>().add(
            LinkCloudAccountEvent(
              phoneNumber: _phoneController.text.trim(),
              code: _otpController.text.trim(),
              challengeId: state.otpChallengeId,
            ),
          );
    } else {
      context.read<AuthBloc>().add(
            VerifyPhoneOtpEvent(
              phoneNumber: _phoneController.text.trim(),
              code: _otpController.text.trim(),
              challengeId: state.otpChallengeId,
            ),
          );
    }
  }

  void _handleSuccessfulAuth(BuildContext context) {
    final profileBloc = context.read<ProfileBloc>();
    profileBloc.add(LoadProfileEvent());
    final profileState = profileBloc.state;
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }

        if (state.status == AuthStatus.otpSent && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.emerald,
              behavior: SnackBarBehavior.floating,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                    _buildTopBar(context, isDark),
                    const SizedBox(height: 24),
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    ConnectionModeSelector(
                      selectedMode: state.connectionMode,
                      onModeChanged: (mode) {
                        context.read<AuthBloc>().add(SwitchConnectionModeEvent(mode));
                      },
                    ),
                    const SizedBox(height: 22),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: KeyedSubtree(
                        key: ValueKey<bool>(isOffline),
                        child: isOffline
                            ? _buildOfflineContent(context, isLoading)
                            : _buildOnlineContent(context, state),
                      ),
                    ),
                    if (!isOffline) ...[
                      const SizedBox(height: 26),
                      _buildSignupPrompt(context),
                    ],
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        '🔒 بياناتك محفوظة محلياً ويمكنك ربطها سحابياً في أي وقت',
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
          'ابدأ مباشرةً على جهازك أو اربط رقم هاتفك للمزامنة السحابية',
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
        OfflineModeInfoCard(
          isLoading: isLoading,
          onQuickAccess: () => _onQuickOfflineAccess(context),
        ),
        const SizedBox(height: 14),
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
                'تخصيص اسم المحفظة المحلية',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.brandGreen : AppColors.emerald,
                ),
              ),
            ),
          )
        else
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
                ElevatedButton(
                  onPressed:
                      isLoading ? null : () => _onQuickOfflineAccess(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'ابدأ بالاسم المخصص',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOnlineContent(BuildContext context, AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PhoneOtpAuthSection(
          phoneController: _phoneController,
          otpController: _otpController,
          authState: state,
          onSendOtp: () => _onSendOtp(context),
          onVerifyOtp: () => _onVerifyOtp(context, state),
        ),
        const SizedBox(height: 20),
        SocialAuthButtons(
          onGooglePressed: () {
            context.read<AuthBloc>().add(
                  const SocialSignInEvent(
                    provider: SocialAuthProvider.google,
                    idToken: 'google_oauth_pending',
                    displayName: 'حساب Google',
                  ),
                );
          },
          onApplePressed: () {
            context.read<AuthBloc>().add(
                  const SocialSignInEvent(
                    provider: SocialAuthProvider.apple,
                    idToken: 'apple_oauth_pending',
                    displayName: 'حساب Apple',
                  ),
                );
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
