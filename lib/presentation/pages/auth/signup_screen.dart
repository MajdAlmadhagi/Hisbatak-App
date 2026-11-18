import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/auth_session.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../widgets/hisbatak_mark.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/phone_otp_auth_section.dart';

/// [SignupScreen] streamlines workspace creation without dummy password clutter:
/// - Offline: Name only -> instant local wallet
/// - Online: Name + Phone OTP verification
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  AuthConnectionMode _signupMode = AuthConnectionMode.offline;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _onLocalCreate(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(
          QuickOfflineAccessEvent(localName: _nameController.text.trim()),
        );
  }

  void _onSendOtp(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(
          const SwitchConnectionModeEvent(AuthConnectionMode.online),
        );
    context.read<AuthBloc>().add(
          RequestPhoneOtpEvent(phoneNumber: _phoneController.text.trim()),
        );
  }

  void _onVerifyOtp(BuildContext context, AuthState state) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(
          VerifyPhoneOtpEvent(
            phoneNumber: _phoneController.text.trim(),
            code: _otpController.text.trim(),
            challengeId: state.otpChallengeId,
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
          context.read<ProfileBloc>().add(LoadProfileEvent());
          context.go('/setup-profile');
        }
      },
      builder: (context, state) {
        final isLoading = state.isLoading;
        final isOffline = _signupMode == AuthConnectionMode.offline;

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
                    const SizedBox(height: 20),
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    _buildModeSelector(context, isDark),
                    const SizedBox(height: 20),
                    AuthTextField(
                      label: AppStrings.fullNameLabel,
                      hintText: 'مثال: طارق منصور',
                      controller: _nameController,
                      prefixIcon: Iconsax.user,
                      textInputAction:
                          isOffline ? TextInputAction.done : TextInputAction.next,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'يرجى إدخال اسمك الكريم';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (isOffline)
                      ElevatedButton.icon(
                        onPressed: isLoading ? null : () => _onLocalCreate(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        icon: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Iconsax.shield_tick, size: 20),
                        label: const Text(
                          'إنشاء محفظة محلية فورية',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      PhoneOtpAuthSection(
                        phoneController: _phoneController,
                        otpController: _otpController,
                        authState: state,
                        onSendOtp: () => _onSendOtp(context),
                        onVerifyOtp: () => _onVerifyOtp(context, state),
                        verifyButtonLabel: 'تأكيد وإنشاء الحساب السحابي',
                      ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        AppStrings.termsAgreement,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: context.appTextMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
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
        const SizedBox(width: 38),
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
          'أنشئ مساحتك الشخصية فوراً على الجهاز أو فعّل المزامنة برقم الجوال',
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
                  subtitle: 'بدون كلمة مرور ⚡',
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
                  subtitle: 'تحقق برقم الهاتف ☁️',
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
