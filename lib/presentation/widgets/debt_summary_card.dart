import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/group_entity.dart';
import 'profile_currency_extension.dart';

/// [DebtSummaryCard] displays aggregated group balances across all groups.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class DebtSummaryCard extends StatelessWidget {
  final DebtSummary summary;
  final String? currencySymbol;

  const DebtSummaryCard({
    super.key,
    required this.summary,
    this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final activeCurrency = currencySymbol ?? context.watchCurrencySymbol();

    final net = summary.netPosition;
    final Color netBgColor;
    final Color netTextColor;
    final String netText;

    if (net > 0) {
      netBgColor = isDark
          ? AppColors.emerald.withValues(alpha: 0.2)
          : AppColors.mintSoft;
      netTextColor = isDark ? AppColors.mintContainer : AppColors.emerald;
      netText =
          '+${Formatters.formatCurrency(net, currencySymbol: activeCurrency)} (لك)';
    } else if (net < 0) {
      netBgColor = isDark
          ? const Color(0xFF3B1219)
          : const Color(0xFFFFF1F2);
      netTextColor = isDark ? const Color(0xFFF87171) : AppColors.expense;
      netText =
          '${Formatters.formatSignedCurrency(net, currencySymbol: activeCurrency)} (عليك)';
    } else {
      netBgColor = context.appSurfaceVariant;
      netTextColor = context.appTextSecondary;
      netText = '0 $activeCurrency (متزن)';
    }

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
                  Icon(Iconsax.bank, size: 20, color: context.appTextPrimary),
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
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF005236),
                  ),
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
                          Icon(Iconsax.arrow_up_3,
                              size: 14, color: AppColors.expense),
                          SizedBox(width: 4),
                          Text(
                            AppStrings.youOwe,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.expense,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        summary.totalUserOwes > 0
                            ? '-${Formatters.formatCurrency(summary.totalUserOwes, currencySymbol: activeCurrency)}'
                            : '0 $activeCurrency',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? const Color(0xFFF87171)
                              : AppColors.expense,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ل${summary.personsUserOwes} أشخاص',
                        style: TextStyle(
                          fontSize: 10,
                          color: context.appTextMuted,
                        ),
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
                          Icon(Iconsax.arrow_down_2,
                              size: 14, color: AppColors.income),
                          SizedBox(width: 4),
                          Text(
                            AppStrings.owesYou,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.income,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        summary.totalOwedToUser > 0
                            ? '+${Formatters.formatCurrency(summary.totalOwedToUser, currencySymbol: activeCurrency)}'
                            : '0 $activeCurrency',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? AppColors.mintContainer
                              : AppColors.income,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'من ${summary.personsOwingUser} أشخاص',
                        style: TextStyle(
                          fontSize: 10,
                          color: context.appTextMuted,
                        ),
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
              color: netBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.netPosition,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                ),
                Text(
                  netText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: netTextColor,
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
