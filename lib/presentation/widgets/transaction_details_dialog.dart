import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/transaction_item.dart';
import '../bloc/budget/budget_bloc.dart';
import 'profile_currency_extension.dart';
import 'transaction_details/edit_transaction_sheet.dart';
import 'transaction_details/transaction_info_card.dart';

/// [TransactionDetailsDialog] provides an interactive sheet to view, edit, or delete
/// any transaction in Hisbatak.
class TransactionDetailsDialog extends StatelessWidget {
  final TransactionItem item;

  const TransactionDetailsDialog({super.key, required this.item});

  static Future<void> show(BuildContext context, TransactionItem item) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionDetailsDialog(item: item),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Iconsax.shopping_cart;
      case 'account_balance':
        return Iconsax.bank;
      case 'local_cafe':
        return Iconsax.coffee;
      case 'wifi':
        return Iconsax.wifi;
      case 'directions_car':
        return Iconsax.car;
      default:
        return Iconsax.receipt_item;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    final isDark = context.isDarkMode;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.appCardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF3B1219) : const Color(0xFFFFE4E6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.trash,
                color: isDark ? const Color(0xFFF87171) : AppColors.expense,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppStrings.confirmDelete,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.appTextPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          AppStrings.confirmDeleteMsg,
          style: TextStyle(
            fontSize: 13,
            color: context.appTextSecondary,
            height: 1.5,
          ),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              AppStrings.cancel,
              style: TextStyle(
                color: context.appTextMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context
                  .read<BudgetBloc>()
                  .add(DeletePersonalTransactionEvent(item.id));
              Navigator.pop(dialogCtx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(AppStrings.transactionDeleted),
                  backgroundColor: AppColors.expense,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              AppStrings.delete,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _openEditModal(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditTransactionSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isIncome = item.type == TransactionType.income;
    final activeCurrency = context.watchCurrencySymbol();

    return Container(
      decoration: BoxDecoration(
        color: context.appBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: context.appBorder, width: 1.5),
        ),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: context.appTextMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.transactionDetails,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.appTextPrimary,
                ),
              ),
              IconButton(
                icon: Icon(
                  Iconsax.close_circle,
                  color: context.appTextMuted,
                  size: 22,
                ),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.appCardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.appBorder),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isIncome
                        ? (isDark
                            ? AppColors.emerald.withValues(alpha: 0.25)
                            : AppColors.mintFixed)
                        : (isDark
                            ? const Color(0xFF3B1219)
                            : const Color(0xFFFFE4E6)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCategoryIcon(item.categoryIcon),
                    color: isIncome
                        ? (isDark ? AppColors.mintContainer : AppColors.emerald)
                        : (isDark
                            ? const Color(0xFFF87171)
                            : AppColors.expense),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  isIncome
                      ? '+${Formatters.formatCurrency(item.amount, currencySymbol: activeCurrency)}'
                      : '-${Formatters.formatCurrency(item.amount, currencySymbol: activeCurrency)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isIncome
                        ? (isDark ? AppColors.mintContainer : AppColors.income)
                        : (isDark
                            ? const Color(0xFFF87171)
                            : AppColors.expense),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isIncome
                        ? (isDark
                            ? AppColors.emerald.withValues(alpha: 0.2)
                            : AppColors.mintSoft)
                        : (isDark
                            ? const Color(0xFF3B1219)
                            : const Color(0xFFFFEBEA)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isIncome ? 'حركة دخل / إيداع' : 'حركة مصروف شخصي',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isIncome
                          ? (isDark
                              ? AppColors.mintContainer
                              : AppColors.emerald)
                          : (isDark
                              ? const Color(0xFFF87171)
                              : AppColors.expense),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TransactionInfoCard(item: item),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openEditModal(context),
                  icon: const Icon(Iconsax.edit_2, size: 18),
                  label: const Text(
                    AppStrings.editTransaction,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    foregroundColor:
                        isDark ? AppColors.mintContainer : AppColors.emerald,
                    side: const BorderSide(color: AppColors.emerald, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showDeleteConfirmation(context),
                  icon: const Icon(Iconsax.trash, size: 18),
                  label: const Text(
                    AppStrings.deleteTransaction,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    backgroundColor: isDark
                        ? const Color(0xFF3B1219)
                        : const Color(0xFFFFE4E6),
                    foregroundColor:
                        isDark ? const Color(0xFFF87171) : AppColors.expense,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF5B1B26)
                            : const Color(0xFFFECDD3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
