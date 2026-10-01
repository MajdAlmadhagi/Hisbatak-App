import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// [OfflineStatusPill] displays the offline active banner and security badge (matching Screen 1, 2, 3, 5).
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class OfflineStatusPill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final bool isCompact;

  const OfflineStatusPill({
    super.key,
    this.text = 'يعمل دون اتصال ☁️✓',
    this.icon,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 14,
        vertical: isCompact ? 5 : 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.mintSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.mintContainer.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.emerald,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.emerald,
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 4),
            Icon(icon, size: 14, color: AppColors.emerald),
          ],
        ],
      ),
    );
  }
}

/// [OfflineTopBanner] displays the top card for Home screen: "وضع عدم الاتصال نشط - تمت المزامنة محلياً بنجاح (☁️✓)".
class OfflineTopBanner extends StatelessWidget {
  const OfflineTopBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FDF3),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF6CF8BB).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF6CF8BB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_done_rounded,
                color: AppColors.emerald, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'وضع عدم الاتصال نشط',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.emerald,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'تمت المزامنة محلياً بنجاح (☁️✓)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF005236),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'سجل آمن 100%',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.emerald),
            ),
          ),
        ],
      ),
    );
  }
}
