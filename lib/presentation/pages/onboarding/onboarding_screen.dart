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
import 'widgets/neumorphic_surface.dart';
import 'widgets/onboarding_3d_stage.dart';
import 'widgets/onboarding_slide_data.dart';

/// Streamlined Isometric 3D + Soft Neumorphism onboarding walkthrough.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;

  static const _slides = OnboardingSlideData.slides;

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
        context.go('/login');
      }
    } catch (_) {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  double _currentScrollPage() {
    if (_pageController.hasClients && _pageController.position.haveDimensions) {
      return _pageController.page ?? _currentPage.toDouble();
    }
    return _currentPage.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final activeSlide = _slides[_currentPage];
    final canvasBg = isDark ? const Color(0xFF0C1424) : const Color(0xFFEEF3F8);

    return Scaffold(
      backgroundColor: canvasBg,
      body: Stack(
        children: [
          // Soft ambient corner tint following current slide identity
          Positioned(
            top: -120,
            right: -90,
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOut,
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      activeSlide.accentColor.withValues(
                        alpha: isDark ? 0.16 : 0.14,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context, isDark),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, _) {
                      final pagePos = _currentScrollPage();
                      return PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _slides.length,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                        },
                        itemBuilder: (context, index) {
                          return _buildSlideContent(
                            context,
                            _slides[index],
                            pagePos - index,
                            isDark,
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildBottomControls(context, isDark, activeSlide),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDark) {
    final isLast = _currentPage == _slides.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
          AnimatedOpacity(
            opacity: isLast ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 220),
            child: IgnorePointer(
              ignoring: isLast,
              child: GestureDetector(
                onTap: _completeOnboarding,
                child: NeumorphicSurface(
                  borderRadius: 20,
                  depth: 0.4,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.onboardingSkip,
                        style: TextStyle(
                          fontSize: 12.5,
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
          ),
        ],
      ),
    );
  }

  Widget _buildSlideContent(
    BuildContext context,
    OnboardingSlideData slide,
    double pageOffset,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            flex: 6,
            child: Onboarding3dStage(
              slide: slide,
              pageOffset: pageOffset,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: slide.accentColor.withValues(alpha: isDark ? 0.16 : 0.11),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: slide.accentColor.withValues(alpha: 0.25),
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
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? slide.accentColor : AppColors.emerald,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: context.appTextPrimary,
              height: 1.25,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 310),
            child: Text(
              slide.subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: context.appTextSecondary,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(
    BuildContext context,
    bool isDark,
    OnboardingSlideData activeSlide,
  ) {
    final isLastPage = _currentPage == _slides.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (index) {
              final isSelected = index == _currentPage;
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: isSelected ? 28 : 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeSlide.accentColor
                        : (isDark
                            ? const Color(0xFF22304A)
                            : const Color(0xFFD0DBE8)),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color:
                                  activeSlide.accentColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : NeumorphicSurface.convexShadows(
                            isDark: isDark,
                            depth: 0.2,
                          ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: isLastPage
                  ? NeumorphicPillButton(
                      key: const ValueKey('onboarding_start_btn'),
                      onPressed: _isCompleting ? null : _completeOnboarding,
                      backgroundColor: AppColors.emerald,
                      glowColor: AppColors.emerald,
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
                    )
                  : NeumorphicPillButton(
                      key: const ValueKey('onboarding_next_btn'),
                      onPressed: _nextPage,
                      backgroundColor: AppColors.brandNavy,
                      glowColor: activeSlide.accentColor,
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
          ),
        ],
      ),
    );
  }
}
