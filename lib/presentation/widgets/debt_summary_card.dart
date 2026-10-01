import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/group_entity.dart';

/// [DebtSummaryCard] displays aggregated group balances matching Screen 3.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class DebtSummaryCard extends StatelessWidget {
  final DebtSummary summary;

  const DebtSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_outlined, size: 20, color: context.appTextPrimary),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.totalBalanceSummary,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: context.appTextPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.mintFixed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  AppStrings.updatedLive,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF005236)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Two Balance Cards
          Row(
            children: [
              // You Owe (عليك للآخرين)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.appBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.arrow_upward_rounded, size: 14, color: AppColors.expense),
                          SizedBox(width: 4),
                          Text(
                            AppStrings.youOwe,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.expense),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '-${Formatters.formatCurrency(summary.totalUserOwes)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? const Color(0xFFF87171) : AppColors.expense,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ل${summary.personsUserOwes} أشخاص',
                        style: TextStyle(fontSize: 10, color: context.appTextMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Owes You (لك في ذمة الآخرين)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.appBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.income),
                          SizedBox(width: 4),
                          Text(
                            AppStrings.owesYou,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.income),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '+${Formatters.formatCurrency(summary.totalOwedToUser)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.mintContainer : AppColors.income,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'من ${summary.personsOwingUser} أشخاص',
                        style: TextStyle(fontSize: 10, color: context.appTextMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Footer: Net Position
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.emerald.withValues(alpha: 0.2) : AppColors.mintSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.netPosition,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.appTextPrimary),
                ),
                Text(
                  '+${Formatters.formatCurrency(summary.netPosition)} (موجب)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.mintContainer : AppColors.emerald,
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
