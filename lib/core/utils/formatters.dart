import 'package:intl/intl.dart';

/// [Formatters] provides utility methods for formatting Arabic currency, dates, and percentages.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
/// Handles solely data formatting logic cleanly separated from widgets.
class Formatters {
  static final NumberFormat _currencyFormatter = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _decimalFormatter = NumberFormat('#,##0.00', 'en_US');

  /// Formats an amount to integer or decimal with Arabic currency symbol.
  /// Example: 14850.0 -> "14,850 ر.س"
  static String formatCurrency(double amount, {String currencySymbol = 'ر.س', bool showDecimals = false}) {
    final formatted = showDecimals
        ? _decimalFormatter.format(amount)
        : _currencyFormatter.format(amount.round());
    return '$formatted $currencySymbol';
  }

  /// Formats positive and negative signed amounts.
  /// Example: 2400 -> "+2,400 ر.س", -340 -> "-340 ر.س"
  static String formatSignedCurrency(double amount, {String currencySymbol = 'ر.س'}) {
    final absAmount = amount.abs();
    final formatted = _currencyFormatter.format(absAmount.round());
    if (amount > 0) {
      return '+$formatted $currencySymbol';
    } else if (amount < 0) {
      return '-$formatted $currencySymbol';
    } else {
      return '0 $currencySymbol';
    }
  }

  /// Formats a percentage value.
  /// Example: 74.2 -> "74.2%"
  static String formatPercentage(double percent) {
    return '${percent.toStringAsFixed(1)}%';
  }

  /// Converts standard DateTime into user-friendly Arabic timestamp string.
  static String formatArabicDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final timeStr = DateFormat('hh:mm a', 'en_US')
        .format(dateTime)
        .replaceAll('AM', 'ص')
        .replaceAll('PM', 'م');

    if (itemDate == today) {
      return 'اليوم، $timeStr';
    } else if (itemDate == today.subtract(const Duration(days: 1))) {
      return 'أمس، $timeStr';
    } else {
      final months = [
        'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
      ];
      return '${dateTime.day} ${months[dateTime.month - 1]}، $timeStr';
    }
  }
}
