import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import 'hisbatak_mark.dart';

/// [AppLogoWidget] renders the Hisbatak app logo: the "ح" mark on the navy
/// rounded tile, exactly as it appears on the launcher icon.
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
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.brandNavy,
            // Same corner radius as the launcher icon (230 / 1024).
            borderRadius: BorderRadius.circular(size * 0.225),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          // The mark takes the same share of the tile as on the launcher icon (660 / 1024).
          child: HisbatakMark(size: size * 0.645, color: Colors.white),
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
