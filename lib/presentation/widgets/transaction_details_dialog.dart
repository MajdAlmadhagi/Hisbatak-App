import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/transaction_item.dart';
import '../bloc/budget/budget_bloc.dart';

/// [TransactionDetailsDialog] provides an interactive dialog to view, edit, or delete
/// any transaction in Hisbatak.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
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
        return Icons.shopping_cart_outlined;
      case 'account_balance':
        return Icons.account_balance_outlined;
      case 'local_cafe':
        return Icons.local_cafe_outlined;
      case 'wifi':
        return Icons.wifi_rounded;
      case 'directions_car':
        return Icons.directions_car_outlined;
      default:
        return Icons.receipt_long_outlined;
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
                color: isDark ? const Color(0xFF3B1219) : const Color(0xFFFFE4E6),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_forever_rounded, color: isDark ? const Color(0xFFF87171) : AppColors.expense, size: 24),
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
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              context.read<BudgetBloc>().add(DeletePersonalTransactionEvent(item.id));
              Navigator.pop(dialogCtx); // close dialog
              Navigator.pop(context); // close bottom sheet
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text(AppStrings.delete, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openEditModal(BuildContext context) {
    Navigator.pop(context); // close previous view sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditTransactionSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isIncome = item.type == TransactionType.income;

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
          // Drag handle
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

          // Header with Title & Close button
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
                icon: Icon(Icons.close_rounded, color: context.appTextMuted, size: 22),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Header Card (Icon + Title + Big Amount)
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
                        ? (isDark ? AppColors.emerald.withValues(alpha: 0.25) : AppColors.mintFixed)
                        : (isDark ? const Color(0xFF3B1219) : const Color(0xFFFFE4E6)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCategoryIcon(item.categoryIcon),
                    color: isIncome
                        ? (isDark ? AppColors.mintContainer : AppColors.emerald)
                        : (isDark ? const Color(0xFFF87171) : AppColors.expense),
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
                      ? '+${Formatters.formatCurrency(item.amount)}'
                      : '-${Formatters.formatCurrency(item.amount)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isIncome
                        ? (isDark ? AppColors.mintContainer : AppColors.income)
                        : (isDark ? const Color(0xFFF87171) : AppColors.expense),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isIncome
                        ? (isDark ? AppColors.emerald.withValues(alpha: 0.2) : AppColors.mintSoft)
                        : (isDark ? const Color(0xFF3B1219) : const Color(0xFFFFEBEA)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isIncome ? 'حركة دخل / إيداع' : 'حركة مصروف شخصي',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isIncome
                          ? (isDark ? AppColors.mintContainer : AppColors.emerald)
                          : (isDark ? const Color(0xFFF87171) : AppColors.expense),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Details List
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.appCardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.appBorder),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  context,
                  icon: Icons.calendar_today_outlined,
                  label: AppStrings.transactionDate,
                  value: Formatters.formatArabicDate(item.dateTime),
                ),
                Divider(color: context.appBorder, height: 16),
                _buildDetailRow(
                  context,
                  icon: Icons.category_outlined,
                  label: AppStrings.transactionCategory,
                  value: item.category,
                ),
                Divider(color: context.appBorder, height: 16),
                _buildDetailRow(
                  context,
                  icon: Icons.payment_outlined,
                  label: AppStrings.paymentMethodLabel,
                  value: item.paymentMethod,
                ),
                Divider(color: context.appBorder, height: 16),
                _buildDetailRow(
                  context,
                  icon: Icons.verified_user_outlined,
                  label: 'حالة الحفظ',
                  value: AppStrings.safeRecord,
                  valueColor: isDark ? AppColors.mintContainer : AppColors.emerald,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons: Edit & Delete
          Row(
            children: [
              // Edit Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openEditModal(context),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text(AppStrings.editTransaction, style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    foregroundColor: isDark ? AppColors.mintContainer : AppColors.emerald,
                    side: BorderSide(
                      color: isDark ? AppColors.emerald : AppColors.emerald,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Delete Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showDeleteConfirmation(context),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text(AppStrings.deleteTransaction, style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    backgroundColor: isDark ? const Color(0xFF3B1219) : const Color(0xFFFFE4E6),
                    foregroundColor: isDark ? const Color(0xFFF87171) : AppColors.expense,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF5B1B26) : const Color(0xFFFECDD3),
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

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.appTextSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: context.appTextSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? context.appTextPrimary,
          ),
        ),
      ],
    );
  }
}

/// [_EditTransactionSheet] provides a comprehensive form to modify a transaction.
class _EditTransactionSheet extends StatefulWidget {
  final TransactionItem item;

  const _EditTransactionSheet({required this.item});

  @override
  State<_EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<_EditTransactionSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late TransactionType _selectedType;
  late String _selectedCategory;
  late String _selectedPaymentMethod;

  final List<Map<String, String>> _categories = const [
    {'name': 'بقالة وتموين', 'icon': 'shopping_cart'},
    {'name': 'مطاعم ومقاهي', 'icon': 'local_cafe'},
    {'name': 'فواتير ومسكن', 'icon': 'wifi'},
    {'name': 'ترفيه وتسوق', 'icon': 'shopping_cart'},
    {'name': 'نقل ومواصلات', 'icon': 'directions_car'},
    {'name': 'راتب ودخل', 'icon': 'account_balance'},
    {'name': 'أخرى', 'icon': 'receipt_long'},
  ];

  final List<String> _paymentMethods = const [
    'مدى • من البطاقة',
    'نقداً (كاش)',
    'تحويل بنكي',
    'Apple Pay',
    'بطاقة ائتمانية',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _amountController = TextEditingController(text: widget.item.amount.toStringAsFixed(widget.item.amount.truncateToDouble() == widget.item.amount ? 0 : 2));
    _selectedType = widget.item.type;
    _selectedCategory = widget.item.category;
    _selectedPaymentMethod = widget.item.paymentMethod;

    // Check if category exists in list, else default
    if (!_categories.any((c) => c['name'] == _selectedCategory)) {
      _selectedCategory = _categories.first['name']!;
    }
    if (!_paymentMethods.contains(_selectedPaymentMethod)) {
      _selectedPaymentMethod = _paymentMethods.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (title.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال عنوان صحيح ومبلغ صالح'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final catObj = _categories.firstWhere(
      (c) => c['name'] == _selectedCategory,
      orElse: () => {'name': _selectedCategory, 'icon': widget.item.categoryIcon},
    );

    final updatedTx = widget.item.copyWith(
      title: title,
      amount: amount,
      category: _selectedCategory,
      categoryIcon: catObj['icon'] ?? widget.item.categoryIcon,
      paymentMethod: _selectedPaymentMethod,
      type: _selectedType,
    );

    context.read<BudgetBloc>().add(UpdatePersonalTransactionEvent(updatedTx));
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.transactionUpdated),
        backgroundColor: AppColors.emerald,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.editTransaction,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: context.appTextMuted, size: 22),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Type Toggle (Expense vs Income)
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    title: 'مصروف (-)',
                    isSelected: _selectedType == TransactionType.expense,
                    selectedColor: isDark ? const Color(0xFFF87171) : AppColors.expense,
                    onTap: () => setState(() => _selectedType = TransactionType.expense),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeButton(
                    title: 'دخل (+)',
                    isSelected: _selectedType == TransactionType.income,
                    selectedColor: isDark ? AppColors.mintContainer : AppColors.emerald,
                    onTap: () => setState(() => _selectedType = TransactionType.income),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title Field
            Text(
              AppStrings.transactionTitleLabel,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.appTextSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              style: TextStyle(color: context.appTextPrimary, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: context.appCardBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.appBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.emerald, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Amount Field
            Text(
              AppStrings.transactionAmountLabel,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.appTextSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: context.appTextPrimary, fontSize: 14, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: context.appCardBackground,
                prefixIcon: Icon(Icons.payments_outlined, color: context.appTextSecondary, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.appBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.emerald, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Category Selector
            Text(
              AppStrings.transactionCategory,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.appTextSecondary),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: context.appCardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.appBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: context.appCardBackground,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.appTextPrimary),
                  items: _categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat['name'],
                      child: Text(
                        cat['name']!,
                        style: TextStyle(fontSize: 13, color: context.appTextPrimary, fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCategory = val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Payment Method Selector
            Text(
              AppStrings.paymentMethodLabel,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.appTextSecondary),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: context.appCardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.appBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPaymentMethod,
                  isExpanded: true,
                  dropdownColor: context.appCardBackground,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.appTextPrimary),
                  items: _paymentMethods.map((method) {
                    return DropdownMenuItem<String>(
                      value: method,
                      child: Text(
                        method,
                        style: TextStyle(fontSize: 13, color: context.appTextPrimary, fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedPaymentMethod = val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text(
                  AppStrings.saveChanges,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required String title,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDarkMode;
    return Material(
      color: isSelected
          ? selectedColor.withValues(alpha: isDark ? 0.25 : 0.12)
          : context.appCardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? selectedColor : context.appBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? selectedColor : context.appTextSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
