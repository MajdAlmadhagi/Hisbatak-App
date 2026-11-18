import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/budget_summary.dart';
import 'expense_donut_chart.dart';
import 'profile_currency_extension.dart';

/// [BudgetCard] displays the primary monthly budget overview.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class BudgetCard extends StatelessWidget {
  final BudgetSummary summary;
  final String? currencySymbol;

  const BudgetCard({
    super.key,
    required this.summary,
    this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final activeCurrency = currencySymbol ?? context.watchCurrencySymbol();
    final progress = summary.budgetLimit > 0
        ? (summary.totalSpent / summary.budgetLimit).clamp(0.0, 1.0)
        : 0.0;

    final trending = summary.monthTrending;
    final Color trendingBg;
    final Color trendingFg;
    final IconData trendingIcon;
    final String trendingText;

    if (trending > 0) {
      trendingBg = AppColors.mintFixed;
      trendingFg = const Color(0xFF005236);
      trendingIcon = Iconsax.trend_up;
      trendingText =
          '${Formatters.formatSignedCurrency(trending, currencySymbol: activeCurrency)} هذا الشهر';
    } else if (trending < 0) {
      trendingBg = isDark ? const Color(0xFF3B1219) : const Color(0xFFFFF1F2);
      trendingFg = isDark ? const Color(0xFFF87171) : AppColors.expense;
      trendingIcon = Iconsax.trend_down;
      trendingText =
          '${Formatters.formatSignedCurrency(trending, currencySymbol: activeCurrency)} هذا الشهر';
    } else {
      trendingBg = context.appSurfaceVariant;
      trendingFg = context.appTextSecondary;
      trendingIcon = Iconsax.minus;
      trendingText = '0 $activeCurrency هذا الشهر';
    }

    final remainingColor = summary.remainingPercentage <= 15
        ? AppColors.expense
        : (summary.remainingPercentage <= 30
            ? AppColors.warning
            : AppColors.emerald);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: const Border(
          top: BorderSide(color: AppColors.emerald, width: 2.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Title and monthly net trend pill
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: trendingBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trendingIcon, size: 14, color: trendingFg),
                    const SizedBox(width: 4),
                    Text(
                      trendingText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: trendingFg,
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
                Formatters.formatAmount(summary.totalAvailable),
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: summary.totalAvailable < 0
                      ? AppColors.expense
                      : context.appTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                activeCurrency,
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
                '${AppStrings.spentLabel} ${Formatters.formatCurrency(summary.totalSpent, currencySymbol: activeCurrency)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.appTextPrimary,
                ),
              ),
              Text(
                '${AppStrings.maxLimitLabel} ${Formatters.formatCurrency(summary.budgetLimit, currencySymbol: activeCurrency)}',
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
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 0.9 ? AppColors.expense : AppColors.emerald,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Row 4: Remaining Percentage & Live Update
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'متبقي ${summary.remainingPercentage.toStringAsFixed(1)}% للشهر',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: remainingColor,
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
                  style:
                      TextStyle(fontSize: 10, color: context.appTextSecondary),
                ),
              ),
            ],
          ),
          const Divider(thickness: 1, height: 20),

          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (ctx) {
                    return AlertDialog(
                      backgroundColor: context.appCardBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: context.appBorder),
                      ),
                      title: Text(
                        'تفاصيل النفقات الشهرية',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.appTextPrimary,
                        ),
                      ),
                      content: SizedBox(
                        width: 340,
                        child: ExpenseDonutChart(
                          categories: summary.categories,
                          currencySymbol: activeCurrency,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                              side: const BorderSide(
                                color: AppColors.emerald,
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: const Text(
                            'إخفاء',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Iconsax.graph),
              label: const Text(
                'عرض تفاصيل النفقات الشهرية',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
