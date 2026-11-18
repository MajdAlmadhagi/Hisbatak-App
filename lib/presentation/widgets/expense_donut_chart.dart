import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/budget_summary.dart';
import 'profile_currency_extension.dart';

/// [ExpenseDonutChart] renders the monthly expense breakdown chart.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class ExpenseDonutChart extends StatelessWidget {
  final List<CategoryExpense> categories;
  final String? currencySymbol;

  const ExpenseDonutChart({
    super.key,
    required this.categories,
    this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final activeCurrency = currencySymbol ?? context.watchCurrencySymbol();
    final activeCategories =
        categories.where((cat) => cat.amount > 0 || cat.percentage > 0).toList();
    final currentMonthLabel = Formatters.formatArabicMonthYear(DateTime.now());

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Iconsax.chart_2, size: 20, color: context.appTextPrimary),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.monthlyExpenseDistribution,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: context.appTextPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: context.appSurfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  currentMonthLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.appTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (activeCategories.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
              decoration: BoxDecoration(
                color: context.appSurfaceVariant.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Iconsax.chart_21,
                    size: 30,
                    color: context.appTextMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'لا توجد مصروفات مسجلة لهذا الشهر بعد',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.appTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'عند تسجيل مصروف جديد سيظهر التوزيع النسبي للفئات هنا.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.appTextSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            // Donut Chart & Legend Row
            Row(
              children: [
                // Legend
                Expanded(
                  child: Column(
                    children: activeCategories.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Color(cat.colorValue),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.categoryName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: context.appTextPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    Formatters.formatCurrency(
                                      cat.amount,
                                      currencySymbol: activeCurrency,
                                    ),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: context.appTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${cat.percentage.round()}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: context.appTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 16),

                // Donut Chart
                SizedBox(
                  width: 112,
                  height: 112,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 36,
                          startDegreeOffset: -90,
                          sections: activeCategories.map((cat) {
                            return PieChartSectionData(
                              value: cat.percentage > 0 ? cat.percentage : 1,
                              color: Color(cat.colorValue),
                              showTitle: false,
                              radius: 15,
                            );
                          }).toList(),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${activeCategories.length}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: context.appTextPrimary,
                            ),
                          ),
                          Text(
                            'فئات',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.emerald,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
