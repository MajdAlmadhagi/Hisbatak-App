import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/transaction_item.dart';

/// [TransactionListTile] renders individual personal transactions matching Screen 2.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class TransactionListTile extends StatelessWidget {
  final TransactionItem item;
  final VoidCallback? onTap;

  const TransactionListTile({super.key, required this.item, this.onTap});

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart_outlined;
      case 'account_balance':
        return Icons.account_balance_outlined;
      case 'local_cafe':
        return Icons.local_cafe_outlined;
      case 'wifi':
        return Icons.wifi_rounded;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Color _getIconBgColor(bool isDark) {
    if (item.type == TransactionType.income) {
      return isDark ? AppColors.emerald.withValues(alpha: 0.25) : AppColors.mintFixed;
    }
    switch (item.category) {
      case 'بقالة وتموين':
      case 'مطاعم ومقاهي':
        return isDark ? const Color(0xFF3B1219) : const Color(0xFFFFE4E6);
      case 'فواتير ومسكن':
        return isDark ? const Color(0xFF3B1219) : const Color(0xFFFFEBEA);
      default:
        return isDark ? AppColors.cardDark : AppColors.surfaceVariant;
    }
  }

  Color _getIconColor(bool isDark) {
    if (item.type == TransactionType.income) {
      return isDark ? AppColors.mintContainer : AppColors.emerald;
    }
    return isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = item.type == TransactionType.income;
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.appBorder),
            ),
            child: Row(
          children: [
            // Icon Container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getIconBgColor(isDark),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(item.categoryIcon),
                color: _getIconColor(isDark),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
      
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: context.appTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${Formatters.formatArabicDate(item.dateTime)} • ${item.category}',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.appTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
      
            // Amount & Payment badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isIncome
                      ? '+${Formatters.formatCurrency(item.amount)}'
                      : '-${Formatters.formatCurrency(item.amount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isIncome
                        ? (isDark ? AppColors.mintContainer : AppColors.income)
                        : (isDark ? const Color(0xFFF87171) : AppColors.expense),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.paymentMethod,
                  style: TextStyle(
                    fontSize: 10,
                    color: context.appTextMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}
