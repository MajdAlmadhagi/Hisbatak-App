import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'neumorphic_surface.dart';
import 'onboarding_slide_data.dart';

/// Isometric 3D + Soft Tactile Neumorphism showcase stage.
///
/// Combines a gentle levitation micro-animation with 3D perspective tilt
/// driven by the horizontal [PageView] swipe offset, while respecting the
/// device's reduced-motion setting ([MediaQuery.disableAnimationsOf]).
class Onboarding3dStage extends StatefulWidget {
  final OnboardingSlideData slide;
  final double pageOffset;

  const Onboarding3dStage({
    super.key,
    required this.slide,
    required this.pageOffset,
  });

  @override
  State<Onboarding3dStage> createState() => _Onboarding3dStageState();
}

class _Onboarding3dStageState extends State<Onboarding3dStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _floatController.value = 0.5;
    } else if (!_floatController.isAnimating) {
      _floatController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final clamped = widget.pageOffset.clamp(-1.0, 1.0);
    final absDelta = clamped.abs();
    final scale = (1.0 - absDelta * 0.08).clamp(0.88, 1.0);
    final opacity = (1.0 - absDelta * 0.35).clamp(0.45, 1.0);

    final tiltMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..rotateY(clamped * 0.28)
      ..rotateX(-absDelta * 0.05);

    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final wave = math.sin(_floatController.value * math.pi);
        final floatY = (0.5 - wave) * 7.0;

        return Opacity(
          opacity: opacity,
          child: Transform(
            alignment: Alignment.center,
            transform: tiltMatrix,
            child: Transform.scale(
              scale: scale,
              child: Transform.translate(
                offset: Offset(clamped * -14.0, floatY),
                child: child,
              ),
            ),
          ),
        );
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 310, maxHeight: 310),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft ambient brand glow beneath the floating 3D pedestal
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.slide.accentColor.withValues(
                          alpha: isDark ? 0.22 : 0.16,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Tactile Neumorphic Studio Plinth
                NeumorphicSurface(
                  borderRadius: 36,
                  depth: 1.05,
                  accentTint: widget.slide.accentColor,
                  surfaceColor: isDark
                      ? const Color(0xFF132035)
                      : const Color(0xFFEFF3F8),
                  padding: EdgeInsets.all(isDark ? 10 : 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isDark ? 28 : 30),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          widget.slide.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, __) {
                            return Container(
                              color: isDark
                                  ? const Color(0xFF17263D)
                                  : const Color(0xFFEFF3F8),
                              alignment: Alignment.center,
                              child: Icon(
                                widget.slide.tagIcon,
                                size: 78,
                                color: widget.slide.accentColor,
                              ),
                            );
                          },
                        ),
                        // Subtle inner specular highlight for 3D clay depth
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(
                                    alpha: isDark ? 0.08 : 0.18,
                                  ),
                                  Colors.transparent,
                                  Colors.black.withValues(
                                    alpha: isDark ? 0.12 : 0.02,
                                  ),
                                ],
                              ),
                            ),
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
    );
  }
}
