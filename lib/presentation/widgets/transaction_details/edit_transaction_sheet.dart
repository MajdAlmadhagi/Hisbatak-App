import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/transaction_item.dart';
import '../../bloc/budget/budget_bloc.dart';

/// Bottom sheet form for editing a [TransactionItem] locally with reactive BLoC update.
class EditTransactionSheet extends StatefulWidget {
  final TransactionItem item;

  const EditTransactionSheet({super.key, required this.item});

  @override
  State<EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<EditTransactionSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _groupNameController;
  late final TextEditingController _newMemberController;
  late TransactionType _selectedType;
  late String _selectedCategory;
  late String _selectedPaymentMethod;
  late List<String> _memberNames;

  static const List<Map<String, String>> _categories = [
    {'name': 'بقالة وتموين', 'icon': 'shopping_cart'},
    {'name': 'مطاعم ومقاهي', 'icon': 'local_cafe'},
    {'name': 'فواتير ومسكن', 'icon': 'wifi'},
    {'name': 'ترفيه وتسوق', 'icon': 'shopping_cart'},
    {'name': 'نقل ومواصلات', 'icon': 'directions_car'},
    {'name': 'راتب ودخل', 'icon': 'account_balance'},
    {'name': 'أخرى', 'icon': 'receipt_long'},
  ];

  static const List<String> _paymentMethods = [
    'مدى • من البطاقة',
    'فاتورة مشتركة',
    'نقداً (كاش)',
    'تحويل بنكي',
    'Apple Pay',
    'بطاقة ائتمانية',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _amountController = TextEditingController(
      text: widget.item.amount.toStringAsFixed(
        widget.item.amount.truncateToDouble() == widget.item.amount ? 0 : 2,
      ),
    );
    _groupNameController =
        TextEditingController(text: widget.item.groupName ?? '');
    _newMemberController = TextEditingController();
    _selectedType = widget.item.type;
    _selectedCategory = _categories.any((c) => c['name'] == widget.item.category)
        ? widget.item.category
        : _categories.first['name']!;
    _selectedPaymentMethod =
        _paymentMethods.contains(widget.item.paymentMethod)
            ? widget.item.paymentMethod
            : _paymentMethods.first;
    _memberNames = List.from(widget.item.memberNames);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _groupNameController.dispose();
    _newMemberController.dispose();
    super.dispose();
  }

  void _addMember() {
    final name = _newMemberController.text.trim();
    if (name.isEmpty || _memberNames.contains(name)) return;
    setState(() {
      _memberNames.add(name);
      _newMemberController.clear();
    });
  }

  void _removeMember(int index) {
    setState(() => _memberNames.removeAt(index));
  }

  void _saveChanges() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    final groupName = _groupNameController.text.trim();

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
      orElse: () => {
        'name': _selectedCategory,
        'icon': widget.item.categoryIcon,
      },
    );

    final updatedTx = widget.item.copyWith(
      title: title,
      amount: amount,
      category: _selectedCategory,
      categoryIcon: catObj['icon'] ?? widget.item.categoryIcon,
      paymentMethod: _selectedPaymentMethod,
      type: _selectedType,
      groupName: groupName.isNotEmpty ? groupName : null,
      memberNames: _memberNames,
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

  InputDecoration _fieldDecoration(
    BuildContext context, {
    String? hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.appTextMuted, fontSize: 13),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: context.appTextSecondary, size: 20)
          : null,
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
    );
  }

  Widget _fieldLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: context.appTextSecondary,
        ),
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
                  AppStrings.editTransaction,
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
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    context,
                    title: 'مصروف (-)',
                    isSelected: _selectedType == TransactionType.expense,
                    selectedColor:
                        isDark ? const Color(0xFFF87171) : AppColors.expense,
                    onTap: () =>
                        setState(() => _selectedType = TransactionType.expense),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeButton(
                    context,
                    title: 'دخل (+)',
                    isSelected: _selectedType == TransactionType.income,
                    selectedColor:
                        isDark ? AppColors.mintContainer : AppColors.emerald,
                    onTap: () =>
                        setState(() => _selectedType = TransactionType.income),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _fieldLabel(context, AppStrings.transactionTitleLabel),
            TextField(
              controller: _titleController,
              style: TextStyle(color: context.appTextPrimary, fontSize: 14),
              decoration: _fieldDecoration(context),
            ),
            const SizedBox(height: 14),
            _fieldLabel(context, AppStrings.transactionAmountLabel),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                color: context.appTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              decoration: _fieldDecoration(
                context,
                prefixIcon: Iconsax.money_3,
              ),
            ),
            const SizedBox(height: 14),
            _fieldLabel(context, AppStrings.transactionCategory),
            _DropdownCard(
              value: _selectedCategory,
              items: _categories.map((c) => c['name']!).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),
            const SizedBox(height: 14),
            _fieldLabel(context, AppStrings.paymentMethodLabel),
            _DropdownCard(
              value: _selectedPaymentMethod,
              items: _paymentMethods,
              onChanged: (val) => setState(() => _selectedPaymentMethod = val),
            ),
            const SizedBox(height: 14),
            _fieldLabel(context, AppStrings.transactionGroup),
            TextField(
              controller: _groupNameController,
              style: TextStyle(color: context.appTextPrimary, fontSize: 14),
              decoration: _fieldDecoration(
                context,
                hint: 'اسم المجموعة (اختياري)',
                prefixIcon: Iconsax.profile_2user,
              ),
            ),
            const SizedBox(height: 14),
            _fieldLabel(context, 'المشاركون بالعملية'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newMemberController,
                    style:
                        TextStyle(color: context.appTextPrimary, fontSize: 13),
                    onSubmitted: (_) => _addMember(),
                    decoration: _fieldDecoration(
                      context,
                      hint: 'أدخل اسم عضو ثم اضغط إضافة...',
                      prefixIcon: Iconsax.user_add,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addMember,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.cardDarkElevated
                        : context.appSurfaceVariant,
                    foregroundColor: context.appTextPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: context.appBorder),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'إضافة',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (_memberNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _memberNames.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final name = entry.value;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.cardDarkElevated
                          : AppColors.mintSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.emerald.withValues(alpha: 0.3)
                            : const Color(0xFF6CF8BB),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 9,
                          backgroundColor:
                              isDark ? AppColors.emerald : AppColors.primary,
                          child: Text(
                            name.isNotEmpty ? name[0] : '?',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: context.appTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeMember(idx),
                          child: Icon(
                            Iconsax.close_circle,
                            size: 14,
                            color: context.appTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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

  Widget _buildTypeButton(
    BuildContext context, {
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

class _DropdownCard extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _DropdownCard({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: context.appCardBackground,
          icon: Icon(Iconsax.arrow_down_1, color: context.appTextPrimary),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 13,
                  color: context.appTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}
