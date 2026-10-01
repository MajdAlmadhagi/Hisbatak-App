import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/expense_split_entity.dart';
import '../../../domain/entities/transaction_item.dart';
import '../../bloc/budget/budget_bloc.dart';
import '../../bloc/groups/groups_bloc.dart';
import '../../widgets/custom_numeric_keypad.dart';

/// [AddExpenseBottomSheet] renders the interactive expense splitting modal matching Stitch Screen 4.
///
/// SOLID Principles:
/// - Single Responsibility Principle (SRP): UI interaction for entering and splitting expenses.
/// - Open/Closed Principle (OCP): Uses ISplitCalculationStrategy for calculation modes.
class AddExpenseBottomSheet extends StatefulWidget {
  final String? initialGroupId;

  const AddExpenseBottomSheet({super.key, this.initialGroupId});

  @override
  State<AddExpenseBottomSheet> createState() => _AddExpenseBottomSheetState();
}

class _AddExpenseBottomSheetState extends State<AddExpenseBottomSheet> {
  bool _isSharedBill = true;
  String _amountStr = '240.00';
  final TextEditingController _titleController = TextEditingController(text: 'عشاء جماعي - مطعم الرومانسية');
  SplitMethod _selectedSplitMethod = SplitMethod.equal;
  String _selectedCategory = 'مطاعم وكافيهات';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'مطاعم وكافيهات', 'icon': '🍔', 'dbIcon': 'local_cafe'},
    {'name': 'تموين ومقاضي', 'icon': '🛒', 'dbIcon': 'shopping_cart'},
    {'name': 'نقل ومواصلات', 'icon': '🚗', 'dbIcon': 'directions_car'},
    {'name': 'فواتير ومسكن', 'icon': '⚡', 'dbIcon': 'wifi'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _onKeypadPress(String key) {
    setState(() {
      if (_amountStr == '0' || _amountStr == '0.00') {
        _amountStr = key == '.' ? '0.' : key;
      } else {
        if (key == '.' && _amountStr.contains('.')) return;
        _amountStr += key;
      }
    });
  }

  void _onKeypadDelete() {
    setState(() {
      if (_amountStr.isNotEmpty) {
        _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        if (_amountStr.isEmpty) _amountStr = '0';
      }
    });
  }

  double get _currentAmount => double.tryParse(_amountStr) ?? 0.0;

  void _onSaveExpense() {
    final amount = _currentAmount;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال مبلغ صحيح')),
      );
      return;
    }

    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'مصروف جديد';

    if (_isSharedBill) {
      // Save to group expenses
      final groupsState = context.read<GroupsBloc>().state;
      String groupId = widget.initialGroupId ?? 'grp_work';
      if (groupsState is GroupsLoaded && groupsState.selectedGroupId.isNotEmpty) {
        groupId = groupsState.selectedGroupId;
      }

      final strategy = _selectedSplitMethod == SplitMethod.percentage
          ? PercentageSplitStrategy()
          : EqualSplitStrategy();

      final splits = strategy.calculateSplits(
        totalAmount: amount,
        memberIds: ['user_me', 'mem_1', 'mem_2'],
        memberNames: {
          'user_me': 'أنت (الدافع)',
          'mem_1': 'خالد العتيبي',
          'mem_2': 'سارة المقرن',
        },
        payerId: 'user_me',
      );

      final groupExpense = GroupExpense(
        id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
        groupId: groupId,
        title: title,
        totalAmount: amount,
        payerId: 'user_me',
        payerName: 'أنت',
        category: _selectedCategory,
        splitMethod: _selectedSplitMethod,
        splits: splits,
        dateTime: DateTime.now(),
      );

      context.read<GroupsBloc>().add(AddSharedExpenseEvent(groupExpense));
    }

    // Also add to personal transactions feed
    final catInfo = _categories.firstWhere(
      (c) => c['name'] == _selectedCategory,
      orElse: () => _categories.first,
    );

    final transaction = TransactionItem(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      amount: amount,
      category: _selectedCategory,
      categoryIcon: catInfo['dbIcon'] as String,
      paymentMethod: _isSharedBill ? 'فاتورة مشتركة' : 'مدى • بطاقة',
      dateTime: DateTime.now(),
      type: TransactionType.expense,
      isSynced: false, // New on this device; the next sync uploads it.
    );

    context.read<BudgetBloc>().add(AddPersonalTransactionEvent(transaction));

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حفظ "$title" محلياً بنجاح!'),
        backgroundColor: AppColors.emerald,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = _currentAmount;
    final sharePerPerson = (amount / 3);
    final isDark = context.isDarkMode;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : AppColors.borderVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),

          // Header: Title & Close
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.emerald),
                    const SizedBox(width: 6),
                    Text(
                      AppStrings.addNewTransaction,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.appTextPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close, color: context.appTextSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Divider(color: context.appBorder),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Toggle: Shared Bill vs Personal Expense
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.appSurfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        // Shared Bill
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isSharedBill = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isSharedBill ? context.appCardBackground : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _isSharedBill
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 3,
                                    backgroundColor: _isSharedBill ? AppColors.emerald : Colors.transparent,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppStrings.sharedBill,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _isSharedBill ? context.appTextPrimary : context.appTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Personal Expense
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isSharedBill = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isSharedBill ? context.appCardBackground : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !_isSharedBill
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  AppStrings.personalExpense,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: !_isSharedBill ? context.appTextPrimary : context.appTextSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount Display
                  Center(
                    child: Column(
                      children: [
                        Text(
                          AppStrings.requiredSplitAmount,
                          style: TextStyle(fontSize: 12, color: context.appTextSecondary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'SAR ',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appTextSecondary),
                            ),
                            Text(
                              _amountStr,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: context.appTextPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Title Pill with edit icon
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.appSurfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _titleController,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.appTextPrimary),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        suffixIcon: Icon(Icons.edit_outlined, size: 16, color: context.appTextSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_isSharedBill) ...[
                    // Splitting Method Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.splitMethod,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.appTextSecondary),
                        ),
                        Text(
                          '3 أفراد بالتساوي',
                          style: TextStyle(fontSize: 11, color: isDark ? AppColors.mintContainer : AppColors.emerald, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Split Method Chips
                    Row(
                      children: [
                        _buildSplitMethodChip(context, SplitMethod.equal, AppStrings.splitEqually),
                        const SizedBox(width: 8),
                        _buildSplitMethodChip(context, SplitMethod.percentage, AppStrings.splitByPercentage),
                        const SizedBox(width: 8),
                        _buildSplitMethodChip(context, SplitMethod.custom, AppStrings.splitCustom),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Participants Cards
                    Row(
                      children: [
                        _buildParticipantCard(
                          context: context,
                          name: 'أنت (الدافع)',
                          amount: sharePerPerson,
                          avatarLetter: 'أ',
                          avatarColor: AppColors.mintFixed,
                        ),
                        const SizedBox(width: 8),
                        _buildParticipantCard(
                          context: context,
                          name: 'خالد العتيبي',
                          amount: sharePerPerson,
                          avatarLetter: 'خ',
                          avatarColor: const Color(0xFFDBEAFE),
                        ),
                        const SizedBox(width: 8),
                        _buildParticipantCard(
                          context: context,
                          name: 'سارة المقرن',
                          amount: sharePerPerson,
                          avatarLetter: 'س',
                          avatarColor: const Color(0xFFA7F3D0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Category Selector
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = cat['name'] == _selectedCategory;
                        final activeBg = isDark ? AppColors.emerald : AppColors.primary;
                        final inactiveBg = context.appSurfaceVariant;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat['name'] as String),
                          child: Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? activeBg : inactiveBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Text(cat['icon'] as String, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  cat['name'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : context.appTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Numeric Keypad
                  CustomNumericKeypad(
                    onKeyPressed: _onKeypadPress,
                    onDelete: _onKeypadDelete,
                  ),
                  const SizedBox(height: 16),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _onSaveExpense,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.emerald : AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_outlined, size: 20, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            AppStrings.saveOffline,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Footer
                  Center(
                    child: Text(
                      AppStrings.readyForSyncFooter,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: isDark ? AppColors.mintContainer : AppColors.emerald, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitMethodChip(BuildContext context, SplitMethod method, String label) {
    final isSelected = _selectedSplitMethod == method;
    final isDark = context.isDarkMode;
    final activeBg = isDark ? AppColors.emerald : AppColors.primary;
    final inactiveBg = context.appSurfaceVariant;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSplitMethod = method),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : context.appTextPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantCard({
    required BuildContext context,
    required String name,
    required double amount,
    required String avatarLetter,
    required Color avatarColor,
  }) {
    final isDark = context.isDarkMode;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.appBorder),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: avatarColor,
              child: Text(
                avatarLetter,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.appTextPrimary),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${amount.toStringAsFixed(2)} ر.س',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? AppColors.mintContainer : AppColors.emerald),
            ),
          ],
        ),
      ),
    );
  }
}
