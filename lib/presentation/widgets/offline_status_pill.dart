import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// [OfflineStatusPill] displays the offline active banner and security badge.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class OfflineStatusPill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final bool isCompact;

  const OfflineStatusPill({
    super.key,
    this.text = 'يعمل دون اتصال ☁️✓',
    this.icon,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final accent = isDark ? AppColors.mintContainer : AppColors.emerald;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 14,
        vertical: isCompact ? 5 : 8,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.emerald.withValues(alpha: 0.16)
            : AppColors.mintSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (isDark ? AppColors.emerald : AppColors.mintContainer)
              .withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 4),
            Icon(icon, size: 14, color: accent),
          ],
        ],
      ),
    );
  }
}

/// [OfflineTopBanner] displays the connection & sync status banner for Home screen.
class OfflineTopBanner extends StatelessWidget {
  final bool isOnlineMode;
  final int pendingSyncCount;
  final VoidCallback? onSyncTap;

  const OfflineTopBanner({
    super.key,
    this.isOnlineMode = false,
    this.pendingSyncCount = 0,
    this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bgColor = isDark
        ? AppColors.cardDarkElevated
        : const Color(0xFFE8FDF3);
    final borderColor = isDark
        ? AppColors.emerald.withValues(alpha: 0.35)
        : const Color(0xFF6CF8BB).withValues(alpha: 0.5);
    final titleColor = isDark ? AppColors.mintContainer : AppColors.emerald;
    final subtitleColor =
        isDark ? context.appTextSecondary : const Color(0xFF005236);
    final badgeBg = isDark ? AppColors.cardDark : Colors.white;

    final String titleText;
    final String subtitleText;
    final String badgeText;

    if (isOnlineMode && pendingSyncCount > 0) {
      titleText = 'مزامنة قيد الانتظار ($pendingSyncCount)';
      subtitleText = 'سيتم رفع التعديلات المحلية تلقائياً عند الاتصال';
      badgeText = 'بانتظار الرفع';
    } else if (isOnlineMode) {
      titleText = 'المزامنة السحابية مفعلة';
      subtitleText = 'كافة السجلات محفوظة محلياً ومربوطة بحسابك';
      badgeText = 'مربوط سحابياً';
    } else {
      titleText = 'الوضع المحلي النشط';
      subtitleText = 'محفوظ على جهازك بالكامل بدون إنترنت';
      badgeText = 'سجل محلي آمن';
    }

    return InkWell(
      onTap: onSyncTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.emerald.withValues(alpha: 0.25)
                    : const Color(0xFF6CF8BB),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOnlineMode ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                color: titleColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitleText,
                    style: TextStyle(
                      fontSize: 11,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(12),
                border: isDark ? Border.all(color: context.appBorder) : null,
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
