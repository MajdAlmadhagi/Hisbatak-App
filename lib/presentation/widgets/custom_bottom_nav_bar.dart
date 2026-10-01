import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// [CustomBottomNavBar] renders the modern navigation bar with center floating action button.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAddExpenseTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddExpenseTap,
  });

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isDark = context.isDarkMode;
    final isSelected = currentIndex == index;
    final activeColor = isDark ? AppColors.mintContainer : AppColors.primary;
    final inactiveColor = context.appTextMuted;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: context.appNavBarBg,
        border: Border(top: BorderSide(color: context.appNavBarBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 6, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Settings (Right in RTL / Left in LTR)
          _buildNavItem(
            context: context,
            icon: Icons.settings_outlined,
            label: 'الإعدادات',
            index: 2,
          ),

          // 2. Groups
          _buildNavItem(
            context: context,
            icon: Icons.groups_2_outlined,
            label: 'المجموعات والتقسيم',
            index: 1,
          ),

          // 3. Center Add Button
          GestureDetector(
            onTap: onAddExpenseTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.emerald : AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 26),
                ),
                const SizedBox(height: 4),
                Text(
                  'مصروف جديد',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.mintContainer : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // 4. Home
          _buildNavItem(
            context: context,
            icon: Icons.account_balance_wallet_outlined,
            label: 'الرئيسية',
            index: 0,
          ),
        ],
      ),
    );
  }
}
