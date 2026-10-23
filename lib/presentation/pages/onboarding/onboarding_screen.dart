import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../core/theme/app_theme.dart';
import '../../../domain/repositories/i_profile_repository.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../widgets/hisbatak_mark.dart';

/// Data model representing a single slide in the onboarding flow.
class _OnboardingSlideData {
  final String tag;
  final IconData tagIcon;
  final String title;
  final String subtitle;
  final String imagePath;
  final String floatingBadge;
  final IconData floatingBadgeIcon;
  final List<String> features;
  final Color accentColor;

  const _OnboardingSlideData({
    required this.tag,
    required this.tagIcon,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.floatingBadge,
    required this.floatingBadgeIcon,
    required this.features,
    required this.accentColor,
  });
}

/// [OnboardingScreen] provides an interactive horizontal walkthrough for first-time users,
/// showcasing Hisbatak's core pillars: Personal Budgeting, Group Bill Splitting, and 100% Offline Privacy.
///
/// SOLID Principles:
/// - Single Responsibility Principle (SRP): Handles onboarding presentation and completion transition.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;

  final List<_OnboardingSlideData> _slides = const [
    _OnboardingSlideData(
      tag: AppStrings.onboardingSlide1Tag,
      tagIcon: Iconsax.wallet_3,
      title: AppStrings.onboardingSlide1Title,
      subtitle: AppStrings.onboardingSlide1Subtitle,
      imagePath: 'assets/images/onboarding/onboarding_budget.jpg',
      floatingBadge: 'ميزانية ذكية تفاعلية',
      floatingBadgeIcon: Iconsax.chart_2,
      features: [
        AppStrings.onboardingSlide1Feature1,
        AppStrings.onboardingSlide1Feature2,
        AppStrings.onboardingSlide1Feature3,
      ],
      accentColor: AppColors.brandGreen,
    ),
    _OnboardingSlideData(
      tag: AppStrings.onboardingSlide2Tag,
      tagIcon: Iconsax.people,
      title: AppStrings.onboardingSlide2Title,
      subtitle: AppStrings.onboardingSlide2Subtitle,
      imagePath: 'assets/images/onboarding/onboarding_split.jpg',
      floatingBadge: 'حساب الذمم والتقسيم العادل',
      floatingBadgeIcon: Iconsax.receipt_item,
      features: [
        AppStrings.onboardingSlide2Feature1,
        AppStrings.onboardingSlide2Feature2,
        AppStrings.onboardingSlide2Feature3,
      ],
      accentColor: Color(0xFF38BDF8),
    ),
    _OnboardingSlideData(
      tag: AppStrings.onboardingSlide3Tag,
      tagIcon: Iconsax.shield_tick,
      title: AppStrings.onboardingSlide3Title,
      subtitle: AppStrings.onboardingSlide3Subtitle,
      imagePath: 'assets/images/onboarding/onboarding_offline.jpg',
      floatingBadge: 'مشفر ومحفوظ محلياً 100%',
      floatingBadgeIcon: Iconsax.lock,
      features: [
        AppStrings.onboardingSlide3Feature1,
        AppStrings.onboardingSlide3Feature2,
        AppStrings.onboardingSlide3Feature3,
      ],
      accentColor: AppColors.mintContainer,
    ),
    _OnboardingSlideData(
      tag: AppStrings.onboardingSlide4Tag,
      tagIcon: Iconsax.cloud_connection,
      title: AppStrings.onboardingSlide4Title,
      subtitle: AppStrings.onboardingSlide4Subtitle,
      imagePath: 'assets/images/onboarding/onboarding_online_sync.jpg',
      floatingBadge: 'مزامنة سحابية فورية',
      floatingBadgeIcon: Iconsax.cloud_change,
      features: [
        AppStrings.onboardingSlide4Feature1,
        AppStrings.onboardingSlide4Feature2,
        AppStrings.onboardingSlide4Feature3,
      ],
      accentColor: Color(0xFF00E5A3),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);

    try {
      await di.sl<IProfileRepository>().setOnboardingCompleted();
    } catch (_) {}

    if (!mounted) return;

    final profileState = context.read<ProfileBloc>().state;
    try {
      if (profileState is ProfileLoaded && profileState.profile.isConfigured) {
        context.go('/home');
      } else {
        context.go('/setup-profile');
      }
    } catch (_) {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }
  }

  ///Function go to the next slide ,unless the last slide is reached ,then complete onboarding
  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding(); //if user reached the last slide ,complete the onboarding
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    //get the active slide data
    final activeSlide = _slides[_currentPage];

    return Scaffold(
      backgroundColor: context.appBackground,
      body: Stack(
        children: [
          // Ambient Glow Background matching the active slide color
          Positioned(
            top: -100,
            left: -80,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeSlide.accentColor.withValues(
                  alpha: isDark ? 0.14 : 0.12,
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: const SizedBox.shrink(),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top App Header & Skip Action
                _buildTopHeader(context, isDark),

                // Horizontal Page View Carousel
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _slides.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return _buildSlideItem(context, _slides[index], isDark);
                    },
                  ),
                ),

                // Bottom Indicator and Navigation Buttons
                _buildBottomControls(context, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Top bar containing the Hisbatak brand pill and Skip button
  Widget _buildTopHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Brand badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.appBorder.withValues(alpha: 0.8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HisbatakMark(size: 16),
                const SizedBox(width: 8),
                Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.brandGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  AppStrings.offlineReady,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandGreen,
                  ),
                ),
              ],
            ),
          ),

          // Skip button (fades out on the last slide)
          AnimatedOpacity(
            opacity: _currentPage == _slides.length - 1 ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 250),
            child: IgnorePointer(
              ignoring: _currentPage == _slides.length - 1,
              child: TextButton(
                onPressed: _completeOnboarding,
                style: TextButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.onboardingSkip,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: context.appTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Iconsax.arrow_left_1,
                      size: 14,
                      color: context.appTextSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the content of a single horizontal slide
  Widget _buildSlideItem(
    BuildContext context,
    _OnboardingSlideData slide,
    bool isDark,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3D Illustration Showcase Card
          Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 270),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.7),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: slide.accentColor.withValues(
                      alpha: isDark ? 0.22 : 0.14,
                    ),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.35 : 0.08,
                    ),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Main 3D Artwork
                    Image.asset(
                      slide.imagePath,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 250,
                          color: context.appSurfaceVariant,
                          alignment: Alignment.center,
                          child: Icon(
                            slide.tagIcon,
                            size: 80,
                            color: slide.accentColor,
                          ),
                        );
                      },
                    ),

                    // Subtle Bottom Gradient to anchor the floating badge
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.65),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Floating Glassmorphic Badge on the Artwork
                    Positioned(
                      bottom: 12,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: slide.accentColor.withValues(alpha: 0.5),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: slide.accentColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              slide.floatingBadgeIcon,
                              size: 14,
                              color: slide.accentColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              slide.floatingBadge,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Tag Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark
                  ? slide.accentColor.withValues(alpha: 0.16)
                  : AppColors.mintSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: slide.accentColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  slide.tagIcon,
                  size: 14,
                  color: isDark ? slide.accentColor : AppColors.emerald,
                ),
                const SizedBox(width: 6),
                Text(
                  slide.tag,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? slide.accentColor : AppColors.emerald,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            slide.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: context.appTextPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            slide.subtitle,
            style: TextStyle(
              fontSize: 13,
              color: context.appTextSecondary,
              height: 1.55,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),

          // Mini Feature Highlights List
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.appCardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.appBorder.withValues(alpha: 0.7),
              ),
            ),
            child: Column(
              children: slide.features.map((feature) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.brandGreen.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.tick_circle,
                          size: 14,
                          color: AppColors.brandGreen,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.appTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom controls bar containing page indicators and Next/Start button
  Widget _buildBottomControls(BuildContext context, bool isDark) {
    final isLastPage = _currentPage == _slides.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: context.appBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page Indicator Dots based on the number of slides
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (index) {
              final isSelected = index == _currentPage;
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.brandGreen
                        : (isDark ? Colors.white24 : Colors.black12),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color:
                                  AppColors.brandGreen.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Action Button
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: isLastPage
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.onboardingNext,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Iconsax.arrow_left_2, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.shield_tick,
                      size: 13,
                      color: AppColors.brandGreen,
                    ),
                    SizedBox(width: 6),
                    Text(
                      AppStrings.onboardingSafeOffline,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            secondChild: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isCompleting ? null : _completeOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: AppColors.emerald.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isCompleting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppStrings.onboardingStart,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Iconsax.arrow_left_2, size: 20),
                            ],
                          ),
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
