import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// [SettingsItemTile] renders setting rows matching Stitch Screen 5.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class SettingsItemTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;
  final Color? iconBgColor;
  final Color? iconColor;

  const SettingsItemTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
    this.iconBgColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final defaultBg = isDestructive
        ? (isDark ? const Color(0xFF3B1219) : const Color(0xFFFFF1F2))
        : context.appCardBackground;
    final defaultBorder = isDestructive
        ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECDD3))
        : context.appBorder;
    final defaultIconBg = iconBgColor ??
        (isDestructive
            ? (isDark ? const Color(0xFF4C0519) : const Color(0xFFFFE4E6))
            : context.appSurfaceVariant);
    final defaultIconColor = iconColor ??
        (isDestructive
            ? (isDark ? const Color(0xFFF87171) : AppColors.expense)
            : context.appTextPrimary);
    final defaultTitleColor = isDestructive
        ? (isDark ? const Color(0xFFF87171) : AppColors.expense)
        : context.appTextPrimary;
    final defaultSubtitleColor = isDestructive
        ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFBE123C))
        : context.appTextSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: defaultBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: defaultBorder),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: defaultIconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: defaultIconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: defaultTitleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: defaultSubtitleColor,
                    ),
                  ),
                ],
              ),
            ),

            // Trailing
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
