import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/constants/app_colors.dart';

/// Lightweight slide model for the streamlined 3D Onboarding experience.
class OnboardingSlideData {
  final String tag;
  final IconData tagIcon;
  final String title;
  final String subtitle;
  final String imagePath;
  final Color accentColor;

  const OnboardingSlideData({
    required this.tag,
    required this.tagIcon,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.accentColor,
  });

  static const List<OnboardingSlideData> slides = [
    OnboardingSlideData(
      tag: 'الميزانية الشخصية',
      tagIcon: Iconsax.wallet_3,
      title: 'مصاريفك بوضوح تام',
      subtitle: 'سجّل نفقاتك اليومية وتابع المتبقي من ميزانيتك بنظرة واحدة.',
      imagePath: 'assets/images/onboarding/onboarding_budget_3d.jpg',
      accentColor: AppColors.brandGreen,
    ),
    OnboardingSlideData(
      tag: 'المجموعات والذمم',
      tagIcon: Iconsax.people,
      title: 'قسّم الفواتير بلا إحراج',
      subtitle: 'احسب نصيب كل شخص في الرحلات والسكن وسوِّ الذمم بضغطة.',
      imagePath: 'assets/images/onboarding/onboarding_split_3d.jpg',
      accentColor: Color(0xFF0EA5E9),
    ),
    OnboardingSlideData(
      tag: 'خصوصية ومزامنة مرنة',
      tagIcon: Iconsax.shield_tick,
      title: 'أوفلاين دائماً.. سحابي متى شئت',
      subtitle: 'بياناتك آمنة على جهازك مع قفل PIN، وخيار ربط هاتفك للمزامنة.',
      imagePath: 'assets/images/onboarding/onboarding_sync_3d.jpg',
      accentColor: Color(0xFF00C896),
    ),
  ];
}
