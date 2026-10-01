import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/budget_summary.dart';

/// [ExpenseDonutChart] renders the monthly expense breakdown chart matching Stitch Screen 2.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class ExpenseDonutChart extends StatelessWidget {
  final List<CategoryExpense> categories;

  const ExpenseDonutChart({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 20, color: context.appTextPrimary),
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
                  AppStrings.june2024,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.appTextSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Donut Chart & Legend Row
          Row(
            children: [
              // Legend
              Expanded(
                child: Column(
                  children: categories.map((cat) {
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
                            child: Text(
                              cat.categoryName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.appTextPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${cat.percentage.toInt()}%',
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
              const SizedBox(width: 20),

              // Donut Chart
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        startDegreeOffset: -90,
                        sections: categories.map((cat) {
                          return PieChartSectionData(
                            value: cat.percentage,
                            color: Color(cat.colorValue),
                            showTitle: false,
                            radius: 16,
                          );
                        }).toList(),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${categories.length}',
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
                            color: context.appTextSecondary,
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
