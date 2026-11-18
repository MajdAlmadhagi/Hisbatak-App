import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../widgets/app_logo_widget.dart';

/// Displays the top identity card and mission card on [AboutAppScreen].
class AboutHeroCard extends StatelessWidget {
  const AboutHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.cardDarkElevated,
                  const Color(0xFF0F2338),
                  AppColors.cardDark,
                ]
              : [
                  Colors.white,
                  AppColors.mintSoft.withValues(alpha: 0.6),
                  Colors.white,
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.emerald.withValues(alpha: 0.3)
              : AppColors.mintContainer.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppColors.emerald.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.emerald.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const AppLogoWidget(size: 84),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Hisbatak',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: context.appTextPrimary,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '|',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.emerald,
                  ),
                ),
              ),
              Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.mintContainer : AppColors.emerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.aboutAppSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: context.appTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primaryDark
                  : AppColors.surfaceVariant.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.appBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.emeraldLight,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${AppStrings.appFullVersion} • ${AppStrings.appReleaseDate}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: const [
              _HeroBadge(
                icon: Iconsax.security_safe,
                label: AppStrings.offlineFirstBadge,
              ),
              _HeroBadge(
                icon: Iconsax.cloud_cross,
                label: AppStrings.zeroCloudBadge,
              ),
              _HeroBadge(
                icon: Iconsax.lock,
                label: AppStrings.secureStorageBadge,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.emerald.withValues(alpha: 0.15)
            : AppColors.mintSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.emerald.withValues(alpha: 0.3)
              : AppColors.mintContainer.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.emerald),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.mintContainer : AppColors.emerald,
            ),
          ),
        ],
      ),
    );
  }
}

/// Presents the application's core mission statement.
class AboutMissionCard extends StatelessWidget {
  const AboutMissionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.emerald.withValues(alpha: 0.2)
                      : AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Iconsax.record_circle,
                  color: AppColors.emerald,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppStrings.ourMissionTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.appTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.ourMissionDescription,
            style: TextStyle(
              fontSize: 12.5,
              color: context.appTextSecondary,
              height: 1.65,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
