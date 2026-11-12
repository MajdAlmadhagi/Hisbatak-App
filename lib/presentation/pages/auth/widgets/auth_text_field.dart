import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// [AuthTextField] provides a sleek, modern text input field tailored for
/// Hisbatak's Fintech aesthetic.
class AuthTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final bool enabled;
  final Widget? suffix;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.enabled = true,
    this.suffix,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscureText;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 6),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : AppColors.textPrimary,
            ),
          ),
        ),

        // Text Field Container
        Focus(
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.cardDarkElevated.withValues(alpha: 0.8)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isFocused
                    ? AppColors.emerald
                    : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                width: _isFocused ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isFocused
                      ? AppColors.emerald.withValues(alpha: 0.12)
                      : (isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : const Color(0xFF0F172A).withValues(alpha: 0.04)),
                  blurRadius: _isFocused ? 10 : 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.isPassword && _obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              enabled: widget.enabled,
              validator: widget.validator,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.appTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                prefixIcon: Icon(
                  widget.prefixIcon,
                  size: 20,
                  color: _isFocused
                      ? (isDark ? AppColors.brandGreen : AppColors.emerald)
                      : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                ),
                suffixIcon: widget.isPassword
                    ? IconButton(
                        icon: Icon(
                          _obscureText ? Iconsax.eye_slash : Iconsax.eye,
                          size: 20,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        onPressed: () {
                          setState(() => _obscureText = !_obscureText);
                        },
                      )
                    : widget.suffix,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
