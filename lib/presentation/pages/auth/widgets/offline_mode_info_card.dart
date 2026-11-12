import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// [OfflineModeInfoCard] showcases Hisbatak's signature Offline-First architecture,
/// presenting local encryption guarantees and 1-tap quick access.
class OfflineModeInfoCard extends StatelessWidget {
  final VoidCallback onQuickAccess;
  final bool isLoading;

  const OfflineModeInfoCard({
    super.key,
    required this.onQuickAccess,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDarkElevated.withValues(alpha: 0.85)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.brandGreen.withValues(alpha: 0.35)
              : AppColors.emerald.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppColors.emerald.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Security Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF006C49), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandGreen.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Iconsax.shield_security,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'خزينة محلية مشفرة 100%',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'أمان مالي كامل بدون إنترنت أو وسيط',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Features List
          _buildPillarRow(
            context,
            icon: Iconsax.lock,
            text: 'كافة سجلاتك وفواتيرك تُحفظ على ذاكرة هاتفك فقط',
          ),
          const SizedBox(height: 8),
          _buildPillarRow(
            context,
            icon: Iconsax.flash_1,
            text: 'سرعة فائقة واستجابة فورية دون انتظار اتصال شبكة',
          ),
          const SizedBox(height: 8),
          _buildPillarRow(
            context,
            icon: Iconsax.cloud_change,
            text: 'يمكنك ترقية حسابك والمزامنة السحابية في أي وقت لاحقاً',
          ),
          const SizedBox(height: 20),

          // 1-Tap Quick Offline Entry Button
          ElevatedButton(
            onPressed: isLoading ? null : onQuickAccess,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.brandGreen : AppColors.emerald,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.finger_scan, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'دخول فوري بحساب محلي',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

  Widget _buildPillarRow(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final isDark = context.isDarkMode;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? AppColors.brandGreen : AppColors.emerald,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }
}
