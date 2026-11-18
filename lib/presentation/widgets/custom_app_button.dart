import 'package:flutter/material.dart';
import 'package:hisbatak_app/core/constants/app_colors.dart';
import 'package:hisbatak_app/core/theme/app_theme.dart';

class CustomAppButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? text;
  final bool isLoading;

  const CustomAppButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.text,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.appCardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.emerald),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 20, color: context.appTextPrimary),
                    if (text != null && text!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        text!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
