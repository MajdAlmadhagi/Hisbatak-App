import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../bloc/auth/auth_state.dart';
import 'auth_text_field.dart';

/// Shared Phone OTP input & verification section for passwordless cloud login/claim.
class PhoneOtpAuthSection extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController otpController;
  final AuthState authState;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;
  final String sendButtonLabel;
  final String verifyButtonLabel;

  const PhoneOtpAuthSection({
    super.key,
    required this.phoneController,
    required this.otpController,
    required this.authState,
    required this.onSendOtp,
    required this.onVerifyOtp,
    this.sendButtonLabel = 'إرسال رمز التحقق (OTP)',
    this.verifyButtonLabel = 'تأكيد الرمز والمتابعة',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isLoading = authState.isLoading;
    final otpSent = authState.isOtpSent || authState.otpChallengeId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          label: 'رقم الهاتف السحابي',
          hintText: '770000000 أو 0500000000',
          controller: phoneController,
          prefixIcon: Iconsax.call,
          keyboardType: TextInputType.phone,
          textInputAction: otpSent ? TextInputAction.next : TextInputAction.done,
          validator: (val) => Validators.validatePhone(val, isRequired: true),
        ),
        if (otpSent) ...[
          const SizedBox(height: 14),
          if (authState.devOtpPreviewCode != null)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.emerald.withValues(alpha: 0.16)
                    : AppColors.mintSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.emerald.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.sms_notification,
                    size: 16,
                    color: AppColors.emerald,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'وضع المعاينة المحلية: استخدم الرمز ${authState.devOtpPreviewCode}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.mintContainer
                            : AppColors.emerald,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          AuthTextField(
            label: 'رمز التحقق (OTP)',
            hintText: 'أدخل الرمز المكون من 6 أرقام',
            controller: otpController,
            prefixIcon: Iconsax.shield_tick,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            validator: (val) {
              if (!otpSent) return null;
              final digits = Validators.normalizeDigits((val ?? '').trim());
              if (digits.length < 4) {
                return 'يرجى إدخال رمز التحقق المرسل إليك';
              }
              return null;
            },
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: isLoading ? null : (otpSent ? onVerifyOtp : onSendOtp),
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
                    Icon(
                      otpSent ? Iconsax.tick_circle : Iconsax.sms_tracking,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      otpSent ? verifyButtonLabel : sendButtonLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
        if (otpSent) ...[
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: isLoading ? null : onSendOtp,
              child: const Text(
                'إعادة إرسال الرمز',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
