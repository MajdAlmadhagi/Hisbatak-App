import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/budget_summary.dart';

/// [BudgetCard] displays the primary monthly budget overview matching Stitch Screen 2.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class BudgetCard extends StatelessWidget {
  final BudgetSummary summary;

  const BudgetCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final progress = summary.budgetLimit > 0
        ? (summary.totalSpent / summary.budgetLimit).clamp(0.0, 1.0)
        : 0.25;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Title and Trending pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.totalAvailableBudget,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.appTextSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.mintFixed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up_rounded, size: 14, color: Color(0xFF005236)),
                    SizedBox(width: 4),
                    Text(
                      AppStrings.thisMonthTrending,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF005236),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Large Amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                Formatters.formatCurrency(summary.totalAvailable, showDecimals: false)
                    .replaceAll(' ر.س', ''),
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: context.appTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ر.س',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.appTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 3: Spent & Max Limit Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppStrings.spentLabel} ${Formatters.formatCurrency(summary.totalSpent)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.appTextPrimary,
                ),
              ),
              Text(
                '${AppStrings.maxLimitLabel} ${Formatters.formatCurrency(summary.budgetLimit)}',
                style: TextStyle(
                  fontSize: 12,
                  color: context.appTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: context.appSurfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emerald),
            ),
          ),
          const SizedBox(height: 12),

          // Row 4: Remaining Percentage & Live Update
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'متبقي ${summary.remainingPercentage.toStringAsFixed(1)}% للشهر',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.emerald,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: context.appSurfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppStrings.liveUpdate,
                  style: TextStyle(fontSize: 10, color: context.appTextSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
