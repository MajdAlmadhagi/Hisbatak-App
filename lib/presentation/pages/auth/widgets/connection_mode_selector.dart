import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/auth_session.dart';

/// [ConnectionModeSelector] provides an interactive, modern segmented selector
/// allowing the user to switch seamlessly between Offline Mode and Online Mode.

class ConnectionModeSelector extends StatelessWidget {
  final AuthConnectionMode selectedMode;
  final ValueChanged<AuthConnectionMode> onModeChanged;

  const ConnectionModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isOffline = selectedMode == AuthConnectionMode.offline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode Header Label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Iconsax.routing,
                  size: 16,
                  color: isDark ? AppColors.brandGreen : AppColors.emerald,
                ),
                const SizedBox(width: 6),
                Text(
                  AppStrings.connectionMode,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.appTextPrimary,
                  ),
                ),
              ],
            ),
            // Status Tag
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isOffline
                    ? (isDark ? AppColors.cardDarkElevated : AppColors.mintSoft)
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isOffline
                      ? AppColors.emerald.withValues(alpha: 0.4)
                      : const Color(0xFF38BDF8).withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isOffline ? AppColors.brandGreen : const Color(0xFF0284C7),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOffline ? 'بدون اتصال' : 'سحابي متزامن',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isOffline
                          ? (isDark ? AppColors.brandGreen : AppColors.emerald)
                          : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Modern Segmented Toggle Bar
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDarkElevated : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Offline Option
              Expanded(
                child: _ModeTab(
                  isSelected: isOffline,
                  title: AppStrings.offlineModeShort,
                  icon: Iconsax.shield_tick,
                  activeColor: AppColors.emerald,
                  activeGradient: const LinearGradient(
                    colors: [Color(0xFF0B1F3A), Color(0xFF006C49)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  onTap: () => onModeChanged(AuthConnectionMode.offline),
                ),
              ),
              const SizedBox(width: 6),
              // Online Option
              Expanded(
                child: _ModeTab(
                  isSelected: !isOffline,
                  title: AppStrings.onlineModeShort,
                  icon: Iconsax.cloud_connection,
                  activeColor: const Color(0xFF0284C7),
                  activeGradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF0284C7)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  onTap: () => onModeChanged(AuthConnectionMode.online),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Contextual Explanation Card
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(sizeFactor: animation, child: child),
            );
          },
          child: isOffline
              ? _FeatureHintCard(
                  key: const ValueKey('offline_hint'),
                  icon: Iconsax.security_user,
                  iconColor: AppColors.brandGreen,
                  title: 'بيئة محلية آمنة 100%',
                  subtitle:
                      'تعمل بالكامل على جهازك دون إرسال أي بيانات أو فواتير لأي خادم خارجي.',
                  borderColor: AppColors.emerald.withValues(alpha: 0.25),
                  bgColor: isDark
                      ? AppColors.cardDark.withValues(alpha: 0.6)
                      : AppColors.mintSoft.withValues(alpha: 0.5),
                )
              : _FeatureHintCard(
                  key: const ValueKey('online_hint'),
                  icon: Iconsax.cloud_change,
                  iconColor: const Color(0xFF38BDF8),
                  title: 'مزامنة ومشاركة فورية',
                  subtitle:
                      'تتيح لك حفظ نسخة احتياطية سحابية ومشاركة مصاريف المجموعات عبر أجهزة متعددة.',
                  borderColor: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                  bgColor: isDark
                      ? AppColors.cardDark.withValues(alpha: 0.6)
                      : const Color(0xFFF0F9FF),
                ),
        ),
      ],
    );
  }
}

class _ModeTab extends StatelessWidget {
  final bool isSelected;
  final String title;
  final IconData icon;
  final Color activeColor;
  final Gradient activeGradient;
  final VoidCallback onTap;

  const _ModeTab({
    required this.isSelected,
    required this.title,
    required this.icon,
    required this.activeColor,
    required this.activeGradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? activeGradient : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.textSecondary : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.textSecondary : const Color(0xFF475569)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureHintCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color borderColor;
  final Color bgColor;

  const _FeatureHintCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.borderColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: isDark ? AppColors.textSecondary : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
