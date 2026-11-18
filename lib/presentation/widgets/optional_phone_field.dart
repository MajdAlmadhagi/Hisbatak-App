import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';

/// Shared optional phone input field that validates and normalizes E.164 phone numbers.
class OptionalPhoneField extends StatelessWidget {
  final TextEditingController controller;
  final Color? fillColor;
  final String label;
  final String hint;
  final ValueChanged<String>? onSubmitted;

  const OptionalPhoneField({
    super.key,
    required this.controller,
    this.fillColor,
    this.label = 'رقم الجوال (اختياري للمزامنة)',
    this.hint = 'مثال: 770000000 أو +967770000000',
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final focusColor = isDark ? AppColors.emerald : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: context.appTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          style: TextStyle(fontSize: 14, color: context.appTextPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 12, color: context.appTextMuted),
            prefixIcon:
                Icon(Iconsax.call, color: context.appTextSecondary, size: 20),
            filled: true,
            fillColor: fillColor ?? context.appSurfaceVariant,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.appBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.appBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: focusColor, width: 1.6),
            ),
          ),
          validator: (val) => Validators.validatePhone(val),
          onFieldSubmitted: onSubmitted,
        ),
      ],
    );
  }
}
