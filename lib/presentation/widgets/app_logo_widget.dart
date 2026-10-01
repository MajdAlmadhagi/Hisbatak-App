import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

/// [AppLogoWidget] renders the Hisbatak wallet logo (matching Stitch Screen 7 & Splash branding).
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class AppLogoWidget extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isDark;

  const AppLogoWidget({
    super.key,
    this.size = 80,
    this.showText = false,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF131B2E),
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: EdgeInsets.all(size * 0.18),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Wallet Outline
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size * 0.16),
                  border: Border.all(color: Colors.white, width: size * 0.04),
                ),
              ),
              // Top Dots (Green & Red)
              Positioned(
                top: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: size * 0.12,
                      height: size * 0.12,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: size * 0.2),
                    Container(
                      width: size * 0.12,
                      height: size * 0.12,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              // Center Emerald Stripe
              Positioned(
                top: size * 0.22,
                left: 0,
                right: 0,
                child: Container(
                  height: size * 0.04,
                  color: AppColors.emeraldLight,
                ),
              ),
              // Wallet Button/Latch
              Positioned(
                right: size * 0.04,
                top: size * 0.18,
                child: Container(
                  width: size * 0.14,
                  height: size * 0.14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(size * 0.04),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: size * 0.05,
                    height: size * 0.05,
                    decoration: const BoxDecoration(
                      color: Color(0xFF131B2E),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 12),
          Text(
            AppStrings.appName,
            style: TextStyle(
              fontSize: size * 0.35,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}
