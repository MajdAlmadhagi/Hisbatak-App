import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Provides Soft Tactile Neumorphism surfaces and extruded controls
/// calibrated for both light alabaster (`#EEF3F8`) and deep fintech dark mode.
class NeumorphicSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? surfaceColor;
  final Color? accentTint;
  final double depth;

  const NeumorphicSurface({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 28,
    this.surfaceColor,
    this.accentTint,
    this.depth = 1.0,
  });

  static List<BoxShadow> convexShadows({
    required bool isDark,
    Color? accentTint,
    double depth = 1.0,
  }) {
    if (isDark) {
      return [
        BoxShadow(
          color: const Color(0xFF24344D).withValues(alpha: 0.55),
          offset: Offset(-5 * depth, -5 * depth),
          blurRadius: 14 * depth,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.62),
          offset: Offset(8 * depth, 10 * depth),
          blurRadius: 22 * depth,
        ),
        if (accentTint != null)
          BoxShadow(
            color: accentTint.withValues(alpha: 0.14),
            offset: Offset(0, 10 * depth),
            blurRadius: 26 * depth,
          ),
      ];
    }

    return [
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.94),
        offset: Offset(-7 * depth, -7 * depth),
        blurRadius: 16 * depth,
      ),
      BoxShadow(
        color: const Color(0xFFCBD8E6).withValues(alpha: 0.72),
        offset: Offset(8 * depth, 11 * depth),
        blurRadius: 22 * depth,
      ),
      if (accentTint != null)
        BoxShadow(
          color: accentTint.withValues(alpha: 0.12),
          offset: Offset(0, 12 * depth),
          blurRadius: 26 * depth,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bg = surfaceColor ??
        (isDark ? const Color(0xFF131F33) : const Color(0xFFEEF3F8));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark
              ? (accentTint ?? Colors.white).withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.85),
          width: 1.4,
        ),
        boxShadow: convexShadows(
          isDark: isDark,
          accentTint: accentTint,
          depth: depth,
        ),
      ),
      child: child,
    );
  }
}

/// Tactile pill button with soft 3D bevel depth.
class NeumorphicPillButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? glowColor;
  final double height;
  final double borderRadius;

  const NeumorphicPillButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.glowColor,
    this.height = 54,
    this.borderRadius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bg = backgroundColor ?? AppColors.brandNavy;
    final fg = foregroundColor ?? Colors.white;
    final glow = glowColor ?? bg;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.8),
              offset: const Offset(-3, -3),
              blurRadius: 8,
            ),
          BoxShadow(
            color: glow.withValues(alpha: isDark ? 0.42 : 0.28),
            offset: const Offset(0, 10),
            blurRadius: 20,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(
              color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.22),
              width: 1,
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}
