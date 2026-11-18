import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';

/// Section heading used across [AboutAppScreen].
class AboutSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const AboutSectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.emerald,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: AppColors.emerald, size: 18),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: context.appTextPrimary,
          ),
        ),
      ],
    );
  }
}

/// Showcases the key capabilities of Hisbatak.
class AboutFeaturesSection extends StatelessWidget {
  const AboutFeaturesSection({super.key});

  static const List<AboutFeatureItem> _features = [
    AboutFeatureItem(
      icon: Iconsax.wallet_3,
      color: Color(0xFF10B981),
      title: AppStrings.feature1Title,
      desc: AppStrings.feature1Desc,
    ),
    AboutFeatureItem(
      icon: Iconsax.profile_2user,
      color: Color(0xFF6366F1),
      title: AppStrings.feature2Title,
      desc: AppStrings.feature2Desc,
    ),
    AboutFeatureItem(
      icon: Iconsax.security_safe,
      color: Color(0xFF00A86B),
      title: AppStrings.feature3Title,
      desc: AppStrings.feature3Desc,
    ),
    AboutFeatureItem(
      icon: Iconsax.chart_2,
      color: Color(0xFFF59E0B),
      title: AppStrings.feature4Title,
      desc: AppStrings.feature4Desc,
    ),
    AboutFeatureItem(
      icon: Iconsax.refresh_2,
      color: Color(0xFF0EA5E9),
      title: AppStrings.feature5Title,
      desc: AppStrings.feature5Desc,
    ),
    AboutFeatureItem(
      icon: Iconsax.colorfilter,
      color: Color(0xFFEC4899),
      title: AppStrings.feature6Title,
      desc: AppStrings.feature6Desc,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _features
          .map((feature) => _FeatureTile(feature: feature))
          .toList(),
    );
  }
}

class AboutFeatureItem {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  const AboutFeatureItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });
}

class _FeatureTile extends StatelessWidget {
  final AboutFeatureItem feature;

  const _FeatureTile({required this.feature});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature.icon, color: feature.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  feature.desc,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: context.appTextSecondary,
                    height: 1.45,
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

/// Interactive actions list for privacy pledge, rating, sharing, updates,
/// licenses, and support.
class AboutActionsSection extends StatelessWidget {
  final bool isCheckingUpdates;
  final VoidCallback onPrivacyPledge;
  final VoidCallback onRateApp;
  final VoidCallback onShareApp;
  final VoidCallback onCheckUpdates;
  final VoidCallback onShowLicenses;
  final VoidCallback onShowSupport;

  const AboutActionsSection({
    super.key,
    required this.isCheckingUpdates,
    required this.onPrivacyPledge,
    required this.onRateApp,
    required this.onShareApp,
    required this.onCheckUpdates,
    required this.onShowLicenses,
    required this.onShowSupport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AboutActionTile(
          icon: Iconsax.shield_tick,
          iconColor: AppColors.emerald,
          title: AppStrings.privacyPledgeTitle,
          subtitle: AppStrings.privacyPledgeSub,
          onTap: onPrivacyPledge,
        ),
        _AboutActionTile(
          icon: Iconsax.star_1,
          iconColor: AppColors.warning,
          title: AppStrings.rateAppTitle,
          subtitle: AppStrings.rateAppSub,
          onTap: onRateApp,
        ),
        _AboutActionTile(
          icon: Iconsax.share,
          iconColor: const Color(0xFF6366F1),
          title: AppStrings.shareAppTitle,
          subtitle: AppStrings.shareAppSub,
          onTap: onShareApp,
        ),
        _AboutActionTile(
          icon: Iconsax.refresh_circle,
          iconColor: const Color(0xFF0EA5E9),
          title: AppStrings.checkUpdatesTitle,
          subtitle: isCheckingUpdates
              ? 'جارِ التحقق من حالة التحديث...'
              : AppStrings.checkUpdatesSub,
          trailing: isCheckingUpdates
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.emerald),
                  ),
                )
              : null,
          onTap: onCheckUpdates,
        ),
        _AboutActionTile(
          icon: Iconsax.document_text,
          iconColor: const Color(0xFF8B5CF6),
          title: AppStrings.termsAndLicensesTitle,
          subtitle: AppStrings.termsAndLicensesSub,
          onTap: onShowLicenses,
        ),
        _AboutActionTile(
          icon: Iconsax.headphone,
          iconColor: const Color(0xFFEC4899),
          title: AppStrings.supportAndFeedbackTitle,
          subtitle: AppStrings.supportAndFeedbackSub,
          onTap: onShowSupport,
        ),
      ],
    );
  }
}

class _AboutActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _AboutActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.appCardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.appTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.appTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Iconsax.arrow_left_2,
                  color: context.appTextMuted,
                  size: 14,
                ),
          ],
        ),
      ),
    );
  }
}
