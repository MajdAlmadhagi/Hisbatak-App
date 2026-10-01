import 'package:equatable/equatable.dart';

/// [CategoryExpense] captures the aggregated expense amount and percentage per category.
class CategoryExpense extends Equatable {
  final String categoryName;
  final double amount;
  final double percentage;
  final int colorValue;

  const CategoryExpense({
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.colorValue,
  });

  @override
  List<Object?> get props => [categoryName, amount, percentage, colorValue];
}

/// [BudgetSummary] encapsulates monthly budget numbers, expense totals, and category breakdown.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
/// Represents financial analytics and budget status for the presentation layer.
class BudgetSummary extends Equatable {
  final double totalAvailable;
  final double totalSpent;
  final double budgetLimit;
  final double monthTrending;
  final double remainingPercentage;
  final List<CategoryExpense> categories;

  const BudgetSummary({
    required this.totalAvailable,
    required this.totalSpent,
    required this.budgetLimit,
    required this.monthTrending,
    required this.remainingPercentage,
    required this.categories,
  });

  @override
  List<Object?> get props => [
        totalAvailable,
        totalSpent,
        budgetLimit,
        monthTrending,
        remainingPercentage,
        categories,
      ];
}
