import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';

/// [SocialAuthButtons] renders modern Google & Apple authentication buttons
/// for the online cloud mode.
class SocialAuthButtons extends StatelessWidget {
  final VoidCallback onGooglePressed;
  final VoidCallback onApplePressed;

  const SocialAuthButtons({
    super.key,
    required this.onGooglePressed,
    required this.onApplePressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Column(
      children: [
        // Divider with Text
        Row(
          children: [
            Expanded(
              child: Divider(
                color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                AppStrings.orContinueWith,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Social Buttons Row
        Row(
          children: [
            // Google Button
            Expanded(
              child: _SocialButton(
                  label: 'تسجيل الدخول بإستخدام Google',
                  onPressed: onGooglePressed,
                  iconWidget: Icon(Iconsax.google_1)
                  //const _GoogleIcon(),
                  ),
            ),
            // const SizedBox(width: 12),
            // // Apple Button
            // Expanded(
            //   child: _SocialButton(
            //     label: 'Apple',
            //     onPressed: onApplePressed,
            //       iconWidget: Icon(
            //       Icons.apple,
            //       size: 22,
            //       color: isDark ? Colors.white : Colors.black,
            //     ),
            //   ),
            // ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Widget iconWidget;

  const _SocialButton({
    required this.label,
    required this.onPressed,
    required this.iconWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.cardDarkElevated.withValues(alpha: 0.8)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconWidget,
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.appTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Styled Google 'G' using colored text glyph
          Text(
            'G',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: 'Roboto',
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [
                    Color(0xFF4285F4),
                    Color(0xFF34A853),
                    Color(0xFFFBBC05),
                    Color(0xFFEA4335),
                  ],
                ).createShader(const Rect.fromLTWH(0, 0, 20, 20)),
            ),
          ),
        ],
      ),
    );
  }
}
