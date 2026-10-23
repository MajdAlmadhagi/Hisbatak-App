import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisbatak_app/core/utils/validators.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/expense_split_entity.dart';
import '../../../domain/entities/group_entity.dart';
import '../../../domain/entities/transaction_item.dart';
import '../../bloc/budget/budget_bloc.dart';
import '../../bloc/groups/groups_bloc.dart';
import '../../widgets/custom_numeric_keypad.dart';
import '../groups/widgets/create_group_bottom_sheet.dart';

/// Helper model for representing a participant in the expense split UI.
class _ParticipantUIItem {
  final String id;
  final String name;
  final String avatarLetter;
  final Color avatarColor;
  final bool isUser;

  const _ParticipantUIItem({
    required this.id,
    required this.name,
    required this.avatarLetter,
    required this.avatarColor,
    this.isUser = false,
  });
}

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
  final TextEditingController _titleController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  SplitMethod _selectedSplitMethod = SplitMethod.equal;
  String _selectedCategory = 'مطاعم وكافيهات';
  String? _selectedGroupId;
  String _payerId = 'user_me';

  // Dynamic participant selections & custom splits
  final Set<String> _selectedMemberIds = {'user_me'};
  final Map<String, double> _percentageSplits = {};
  final Map<String, double> _customSplits = {};
  final List<_ParticipantUIItem> _dynamicAddedMembers = [];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'مطاعم وكافيهات', 'icon': '🍔', 'dbIcon': 'local_cafe'},
    {'name': 'تموين ومقاضي', 'icon': '🛒', 'dbIcon': 'shopping_cart'},
    {'name': 'نقل ومواصلات', 'icon': '🚗', 'dbIcon': 'directions_car'},
    {'name': 'فواتير ومسكن', 'icon': '🏠', 'dbIcon': 'wifi'},
    {'name': 'بنزين وطاقة', 'icon': '⛽', 'dbIcon': 'fuel'},
    {'name': 'مياه وكهرباء', 'icon': '💦', 'dbIcon': 'water'},
    {'name': 'الأنترنت والهاتف', 'icon': '🌐', 'dbIcon': 'internet'},
    {'name': 'تعليم وجامعات', 'icon': '🎓', 'dbIcon': 'internet'},
    {'name': 'ترفية وتسوق', 'icon': '🛍️', 'dbIcon': 'shopping'},
    {'name': 'مصروفات أخرى', 'icon': '🛍️', 'dbIcon': 'other'},
  ];

  static const List<Color> _palette = [
    Color(0xFF10B981), // Emerald
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFF59E0B), // Amber
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Pink
    Color(0xFF6366F1), // Indigo
    Color(0xFF14B8A6), // Teal
  ];

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.initialGroupId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  double get _currentAmount => double.tryParse(_amountStr) ?? 0.0;

  void _onKeypadPress(String key) {
    setState(() {
      if (_amountStr == '0' || _amountStr == '0.00') {
        _amountStr = key == '.' ? '0.' : key;
      } else {
        if (key == '.' && _amountStr.contains('.')) return;
        _amountStr += key;
      }
      _syncSplitCalculations();
    });
  }

  void _onKeypadDelete() {
    setState(() {
      if (_amountStr.isNotEmpty) {
        _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        if (_amountStr.isEmpty) _amountStr = '0';
      }
      _syncSplitCalculations();
    });
  }

  /// Synchronize split allocations whenever the total amount or selected members change
  void _syncSplitCalculations() {
    final selectedCount = _selectedMemberIds.length;
    if (selectedCount == 0) return;

    final amount = _currentAmount;
    final equalShare = amount / selectedCount;
    final equalPct = 100.0 / selectedCount;

    for (final id in _selectedMemberIds) {
      if (!_percentageSplits.containsKey(id)) {
        _percentageSplits[id] = equalPct;
      }
      if (!_customSplits.containsKey(id)) {
        _customSplits[id] = equalShare;
      }
    }
  }

  /// Automatically distribute remaining percentage evenly across selected members
  void _distributePercentagesEqually() {
    if (_selectedMemberIds.isEmpty) return;
    final count = _selectedMemberIds.length;
    final share = 100.0 / count;
    setState(() {
      for (final id in _selectedMemberIds) {
        _percentageSplits[id] = double.parse(share.toStringAsFixed(1));
      }
    });
  }

  /// Automatically distribute remaining custom amount evenly across selected members
  void _distributeCustomRemainder() {
    if (_selectedMemberIds.isEmpty) return;
    final count = _selectedMemberIds.length;
    final currentSum = _selectedMemberIds.fold(
      0.0,
      (sum, id) => sum + (_customSplits[id] ?? 0.0),
    );
    final remainder = _currentAmount - currentSum;
    if (remainder.abs() < 0.01) return;

    final share = remainder / count;
    setState(() {
      for (final id in _selectedMemberIds) {
        final cur = _customSplits[id] ?? 0.0;
        _customSplits[id] = (cur + share).clamp(0.0, _currentAmount);
      }
    });
  }

  /// Get aggregated list of all participants for the active group
  List<_ParticipantUIItem> _getParticipants(GroupsState groupsState) {
    final List<_ParticipantUIItem> items = [];

    // Always add 'user_me' (أنت)
    items.add(const _ParticipantUIItem(
      id: 'user_me',
      name: 'أنت',
      avatarLetter: 'أ',
      avatarColor: AppColors.mintFixed,
      isUser: true,
    ));

    // Group members from Bloc
    if (groupsState is GroupsLoaded) {
      for (int i = 0; i < groupsState.activeMembers.length; i++) {
        final m = groupsState.activeMembers[i];
        if (m.id == 'user_me') continue;
        final color = _palette[(i + 1) % _palette.length];
        final letter = m.name.trim().isNotEmpty ? m.name.trim()[0] : 'ع';
        items.add(_ParticipantUIItem(
          id: m.id,
          name: m.name,
          avatarLetter: letter,
          avatarColor: color,
        ));
      }
    }

    // Add any dynamically created members
    for (final extra in _dynamicAddedMembers) {
      if (!items.any((el) => el.id == extra.id)) {
        items.add(extra);
      }
    }

    // Ensure all items are in selection by default if newly loaded
    for (final item in items) {
      if (!_selectedMemberIds.contains(item.id) &&
          _selectedMemberIds.length < 2) {
        _selectedMemberIds.add(item.id);
      }
    }

    return items;
  }

  /// Shows a modern modal dialog to quickly add a member to the group & split
  void _showAddMemberModal(BuildContext context, String groupId) {
    final nameCtrl = TextEditingController();
    Color selectedColor =
        _palette[(_dynamicAddedMembers.length + 2) % _palette.length];
    final isDark = context.isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final avatarChar =
                nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim()[0] : '؟';

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              decoration: BoxDecoration(
                color: modalCtx.appCardBackground,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Iconsax.user_add,
                                color: AppColors.emerald, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'إضافة عضو جديد للمجموعة',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: modalCtx.appTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Iconsax.close_circle,
                            color: modalCtx.appTextSecondary, size: 20),
                        onPressed: () => Navigator.of(modalCtx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Avatar Live Preview
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: selectedColor,
                          child: Text(
                            avatarChar,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'معاينة الرمز الرمزي',
                          style: TextStyle(
                            fontSize: 11,
                            color: modalCtx.appTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Color Picker Palette
                  Text(
                    'اختر لون الرمز:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: modalCtx.appTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _palette.map((color) {
                        final isSelected = selectedColor == color;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() => selectedColor = color);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? (isDark
                                        ? AppColors.mintContainer
                                        : AppColors.emerald)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: color,
                              child: isSelected
                                  ? const Icon(Iconsax.tick_circle,
                                      size: 14, color: Colors.white)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Member Name Input
                  TextFormField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: modalCtx.appTextPrimary,
                    ),
                    onChanged: (_) => setModalState(() {}),
                    decoration: InputDecoration(
                      labelText: 'اسم العضو *',
                      hintText: 'مثال: محمد السعيد',
                      prefixIcon: const Icon(Iconsax.personalcard, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;

                        final newMemberId =
                            'mem_${DateTime.now().millisecondsSinceEpoch}';
                        final newMemberEntity = GroupMemberEntity(
                          id: newMemberId,
                          groupId: groupId,
                          name: name,
                          balance: 0.0,
                          note: 'انضم حديثاً',
                          lastActivity: 'الآن',
                        );

                        // Save in Bloc and DB
                        modalCtx
                            .read<GroupsBloc>()
                            .add(AddGroupMemberEvent(newMemberEntity));

                        // Add to current bottom sheet participants list
                        final letter = name.isNotEmpty ? name[0] : 'ع';
                        final item = _ParticipantUIItem(
                          id: newMemberId,
                          name: name,
                          avatarLetter: letter,
                          avatarColor: selectedColor,
                        );

                        setState(() {
                          _dynamicAddedMembers.add(item);
                          _selectedMemberIds.add(newMemberId);
                          _syncSplitCalculations();
                        });

                        Navigator.of(modalCtx).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'تمت إضافة "$name" بنجاح للمجموعة والفاتورة!'),
                            backgroundColor: AppColors.emerald,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? AppColors.emerald : AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.tick_circle,
                              size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'إضافة العضو للفاتورة',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

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

    String? assignedGroupId;
    String? assignedExpenseId;

    if (_isSharedBill) {
      final selectedList = _selectedMemberIds.toList();
      if (selectedList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('الرجاء تحديد عضو واحد على الأقل للمشاركة بالفاتورة')),
        );
        return;
      }

      final groupsState = context.read<GroupsBloc>().state;
      String groupId = _selectedGroupId ?? 'grp_work';
      if (groupsState is GroupsLoaded &&
          groupsState.selectedGroupId.isNotEmpty &&
          _selectedGroupId == null) {
        groupId = groupsState.selectedGroupId;
      }

      assignedGroupId = groupId;
      assignedExpenseId = 'exp_${DateTime.now().millisecondsSinceEpoch}';

      final allParticipants = _getParticipants(groupsState);
      final memberNames = {
        for (final p in allParticipants) p.id: p.name,
      };

      // Select strategy and prepare custom values
      final ISplitCalculationStrategy strategy;
      Map<String, double>? customValues;

      switch (_selectedSplitMethod) {
        case SplitMethod.equal:
          strategy = EqualSplitStrategy();
          break;
        case SplitMethod.percentage:
          strategy = PercentageSplitStrategy();
          customValues = {
            for (final id in selectedList)
              id: _percentageSplits[id] ?? (100.0 / selectedList.length)
          };
          break;
        case SplitMethod.custom:
          strategy = CustomAmountSplitStrategy();
          customValues = {
            for (final id in selectedList)
              id: _customSplits[id] ?? (amount / selectedList.length)
          };
          break;
      }

      final splits = strategy.calculateSplits(
        totalAmount: amount,
        memberIds: selectedList,
        memberNames: memberNames,
        payerId: _payerId,
        customValues: customValues,
      );

      final payerName = memberNames[_payerId] ?? 'أنت';

      final groupExpense = GroupExpense(
        id: assignedExpenseId,
        groupId: groupId,
        title: title,
        totalAmount: amount,
        payerId: _payerId,
        payerName: payerName,
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
      groupId: assignedGroupId,
      expenseId: assignedExpenseId,
      isSynced: false,
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
    final isDark = context.isDarkMode;

    return BlocBuilder<GroupsBloc, GroupsState>(
      builder: (context, groupsState) {
        final groups =
            groupsState is GroupsLoaded ? groupsState.groups : <GroupEntity>[];
        final currentGroupId = _selectedGroupId ??
            (groupsState is GroupsLoaded &&
                    groupsState.selectedGroupId.isNotEmpty
                ? groupsState.selectedGroupId
                : (groups.isNotEmpty ? groups.first.id : 'grp_work'));

        final participants = _getParticipants(groupsState);
        final selectedCount = _selectedMemberIds.length;
        final sharePerPerson =
            selectedCount > 0 ? (amount / selectedCount) : 0.0;

        return Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: BoxDecoration(
            color: context.appCardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Drag Handle
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderVariant,
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
                          const Icon(Iconsax.cloud_cross,
                              size: 16, color: AppColors.emerald),
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
                        icon:
                            Icon(Iconsax.close_circle, color: context.appTextSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Divider(color: context.appBorder),

                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Toggle: Shared Bill vs Personal Expense
                        _buildTypeToggle(context, isDark),
                        const SizedBox(height: 16),

                        // Amount Display
                        _buildAmountDisplay(context),
                        const SizedBox(height: 14),

                        // Title Field
                        _buildTitleInput(context),
                        const SizedBox(height: 16),

                        if (_isSharedBill) ...[
                          // Group Picker Selector
                          _buildGroupSelector(
                              context, groups, currentGroupId, isDark),
                          const SizedBox(height: 14),

                          // Splitting Method Row Header
                          _buildSplitMethodHeader(
                              context, selectedCount, sharePerPerson, isDark),
                          const SizedBox(height: 8),

                          // Split Method Chips (Equal, Percentage, Custom)
                          _buildSplitMethodChips(context),
                          const SizedBox(height: 14),

                          // Dynamic Participants Section Header
                          _buildParticipantsHeader(
                              context, currentGroupId, isDark),
                          const SizedBox(height: 10),

                          // Dynamic Participants Body based on selected split method
                          _buildSplitMethodBody(
                            context: context,
                            participants: participants,
                            sharePerPerson: sharePerPerson,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Category Selector
                        _buildCategorySelector(context, isDark),
                        const SizedBox(height: 16),

                        // Numeric Keypad
                        CustomNumericKeypad(
                          onKeyPressed: _onKeypadPress,
                          onDelete: _onKeypadDelete,
                        ),
                        const SizedBox(height: 16),

                        // Save Button
                        _buildSaveButton(context, isDark),
                        const SizedBox(height: 8),

                        // Footer note
                        Center(
                          child: Text(
                            AppStrings.readyForSyncFooter,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.mintContainer
                                    : AppColors.emerald,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- UI Sub-Components ---

  Widget _buildTypeToggle(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.appSurfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Shared Bill Toggle
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isSharedBill = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isSharedBill
                      ? context.appCardBackground
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _isSharedBill
                      ? [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.2 : 0.06),
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
                      backgroundColor: _isSharedBill
                          ? AppColors.emerald
                          : Colors.transparent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppStrings.sharedBill,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isSharedBill
                            ? context.appTextPrimary
                            : context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Personal Expense Toggle
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isSharedBill = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isSharedBill
                      ? context.appCardBackground
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !_isSharedBill
                      ? [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.2 : 0.06),
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
                      color: !_isSharedBill
                          ? context.appTextPrimary
                          : context.appTextSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay(BuildContext context) {
    return Center(
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
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.appTextSecondary),
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
    );
  }

  Widget _buildTitleInput(BuildContext context) {
    return TextFormField(
      controller: _titleController,
      textAlign: TextAlign.center,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) => Validators.requiredField(value),
      style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: context.appTextPrimary),
      decoration: InputDecoration(
        hintText:
            _isSharedBill ? "مثال: غداء جماعي" : "مثال: مصاريف مواصلات,...",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.appTextSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.emerald, width: 2),
        ),
        labelText: "إسم الفاتورة",
        isDense: true,
        suffixIcon: Icon(Iconsax.edit_2,
            size: 16, color: context.appTextSecondary),
      ),
    );
  }

  Widget _buildGroupSelector(
    BuildContext context,
    List<GroupEntity> groups,
    String currentGroupId,
    bool isDark,
  ) {
    // if (groups.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              groups.isEmpty
                  ? ' إنشاء مجموعة مستهدفة'
                  : "حدد المجموعة المستهدفة",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: context.appTextSecondary,
              ),
            ),
            Text(
              '${groups.length} مجموعات متاحة',
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.mintContainer : AppColors.emerald,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...groups.map((grp) {
                final isSelected = grp.id == currentGroupId;
                final activeBg = isDark ? AppColors.emerald : AppColors.primary;
                final inactiveBg = context.appSurfaceVariant;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedGroupId = grp.id);
                    context.read<GroupsBloc>().add(SelectGroupEvent(grp.id));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? activeBg : inactiveBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? activeBg : context.appBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.profile_2user,
                          size: 14,
                          color: isSelected
                              ? Colors.white
                              : context.appTextSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          grp.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : context.appTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => const CreateGroupBottomSheet(),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.appSurfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.appBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.add,
                          size: 15, color: context.appTextPrimary),
                      const SizedBox(width: 4),
                      Text(
                        groups.isEmpty
                            ? "إضافة مجموعة جديدة"
                            : AppStrings.newGroup,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSplitMethodHeader(
    BuildContext context,
    int selectedCount,
    double sharePerPerson,
    bool isDark,
  ) {
    String subtitle = '';
    switch (_selectedSplitMethod) {
      case SplitMethod.equal:
        subtitle =
            '$selectedCount أفراد بالتساوي (${sharePerPerson.toStringAsFixed(2)} ر.س)';
        break;
      case SplitMethod.percentage:
        final sum = _selectedMemberIds.fold(
          0.0,
          (prev, id) => prev + (_percentageSplits[id] ?? 0.0),
        );
        subtitle = 'الإجمالي: ${sum.toStringAsFixed(1)}% / 100%';
        break;
      case SplitMethod.custom:
        final sum = _selectedMemberIds.fold(
          0.0,
          (prev, id) => prev + (_customSplits[id] ?? 0.0),
        );
        subtitle =
            '${sum.toStringAsFixed(2)} / ${_currentAmount.toStringAsFixed(2)} ر.س';
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppStrings.splitMethod,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: context.appTextSecondary),
        ),
        Text(
          subtitle,
          style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.mintContainer : AppColors.emerald,
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSplitMethodChips(BuildContext context) {
    return Row(
      children: [
        _buildSplitMethodChip(
            context, SplitMethod.equal, AppStrings.splitEqually),
        const SizedBox(width: 8),
        _buildSplitMethodChip(
            context, SplitMethod.percentage, AppStrings.splitByPercentage),
        const SizedBox(width: 8),
        _buildSplitMethodChip(
            context, SplitMethod.custom, AppStrings.splitCustom),
      ],
    );
  }

  Widget _buildSplitMethodChip(
      BuildContext context, SplitMethod method, String label) {
    final isSelected = _selectedSplitMethod == method;
    final isDark = context.isDarkMode;
    final activeBg = isDark ? AppColors.emerald : AppColors.primary;
    final inactiveBg = context.appSurfaceVariant;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSplitMethod = method;
            _syncSplitCalculations();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? activeBg : context.appBorder,
            ),
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

  Widget _buildParticipantsHeader(
    BuildContext context,
    String currentGroupId,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'المشاركون في الفاتورة',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.emerald.withValues(alpha: 0.2)
                    : AppColors.mintSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_selectedMemberIds.length} محددين',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.mintContainer : AppColors.emerald,
                ),
              ),
            ),
          ],
        ),
        // Modern Add Member Button
        GestureDetector(
          onTap: () => _showAddMemberModal(context, currentGroupId),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.emerald.withValues(alpha: 0.2)
                  : AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppColors.emerald.withValues(alpha: 0.4)
                    : AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.user_add,
                  size: 14,
                  color: isDark ? AppColors.mintContainer : AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'إضافة عضو اخر',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.mintContainer : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSplitMethodBody({
    required BuildContext context,
    required List<_ParticipantUIItem> participants,
    required double sharePerPerson,
    required bool isDark,
  }) {
    switch (_selectedSplitMethod) {
      case SplitMethod.equal:
        return _buildEqualParticipantsList(
          context: context,
          participants: participants,
          sharePerPerson: sharePerPerson,
          isDark: isDark,
        );
      case SplitMethod.percentage:
        return _buildPercentageParticipantsList(
          context: context,
          participants: participants,
          isDark: isDark,
        );
      case SplitMethod.custom:
        return _buildCustomParticipantsList(
          context: context,
          participants: participants,
          isDark: isDark,
        );
    }
  }

  // --- EQUAL SPLIT LIST ---
  Widget _buildEqualParticipantsList({
    required BuildContext context,
    required List<_ParticipantUIItem> participants,
    required double sharePerPerson,
    required bool isDark,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: participants.map((item) {
          final isSelected = _selectedMemberIds.contains(item.id);
          final isPayer = item.id == _payerId;

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  if (_selectedMemberIds.length > 1) {
                    _selectedMemberIds.remove(item.id);
                  }
                } else {
                  _selectedMemberIds.add(item.id);
                }
                _syncSplitCalculations();
              });
            },
            child: Container(
              width: 110,
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppColors.cardDark : const Color(0xFFF8FAFC))
                    : (isDark
                        ? AppColors.cardDark.withValues(alpha: 0.4)
                        : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? (isDark ? AppColors.emerald : AppColors.emeraldLight)
                      : context.appBorder.withValues(alpha: 0.5),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: item.avatarColor,
                        child: Text(
                          item.avatarLetter,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.emerald,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Iconsax.tick_circle,
                                size: 8, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.isUser ? 'أنت (الدافع)' : item.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? context.appTextPrimary
                          : context.appTextSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isSelected
                        ? '${sharePerPerson.toStringAsFixed(2)} ر.س'
                        : 'مستبعد',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? (isDark
                              ? AppColors.mintContainer
                              : AppColors.emerald)
                          : context.appTextMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Payer Switch Button / Indicator
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _payerId = item.id;
                        if (!_selectedMemberIds.contains(item.id)) {
                          _selectedMemberIds.add(item.id);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPayer
                            ? AppColors.emerald.withValues(alpha: 0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isPayer
                              ? AppColors.emerald
                              : context.appBorder.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        isPayer ? 'الدافع ✓' : 'تعيين كدافع',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight:
                              isPayer ? FontWeight.bold : FontWeight.normal,
                          color: isPayer
                              ? (isDark
                                  ? AppColors.mintContainer
                                  : AppColors.emerald)
                              : context.appTextMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- PERCENTAGE SPLIT LIST ---
  Widget _buildPercentageParticipantsList({
    required BuildContext context,
    required List<_ParticipantUIItem> participants,
    required bool isDark,
  }) {
    final totalPercent = _selectedMemberIds.fold(
      0.0,
      (prev, id) => prev + (_percentageSplits[id] ?? 0.0),
    );
    final is100Percent = (totalPercent - 100.0).abs() < 0.1;

    return Column(
      children: [
        // Balance Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: is100Percent
                ? (isDark
                    ? AppColors.emerald.withValues(alpha: 0.15)
                    : AppColors.mintSoft)
                : (isDark
                    ? AppColors.warning.withValues(alpha: 0.15)
                    : AppColors.warningSoft),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    is100Percent
                        ? Iconsax.tick_circle
                        : Iconsax.warning_2,
                    size: 16,
                    color: is100Percent ? AppColors.emerald : AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    is100Percent
                        ? 'النسبة مكتملة 100%'
                        : 'المجموع: ${totalPercent.toStringAsFixed(1)}% (متبقي ${(100 - totalPercent).toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: is100Percent
                          ? (isDark
                              ? AppColors.mintContainer
                              : AppColors.emerald)
                          : (isDark
                              ? AppColors.warning
                              : const Color(0xFFB45309)),
                    ),
                  ),
                ],
              ),
              if (!is100Percent)
                GestureDetector(
                  onTap: _distributePercentagesEqually,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.emerald,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'توزيع بالتساوي',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Member Percentage Controls
        ...participants.map((item) {
          final isSelected = _selectedMemberIds.contains(item.id);
          final currentPct = _percentageSplits[item.id] ?? 0.0;
          final memberAmount = (_currentAmount * currentPct / 100.0);

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? AppColors.cardDark : const Color(0xFFF8FAFC))
                  : (isDark
                      ? AppColors.cardDark.withValues(alpha: 0.3)
                      : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? (isDark ? AppColors.emerald : AppColors.emeraldLight)
                    : context.appBorder.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                // Selection Checkbox
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        if (_selectedMemberIds.length > 1) {
                          _selectedMemberIds.remove(item.id);
                          _percentageSplits.remove(item.id);
                        }
                      } else {
                        _selectedMemberIds.add(item.id);
                        _percentageSplits[item.id] =
                            100.0 / _selectedMemberIds.length;
                      }
                    });
                  },
                  child: Icon(
                    isSelected
                        ? Iconsax.tick_square
                        : Iconsax.close_square,
                    size: 18,
                    color:
                        isSelected ? AppColors.emerald : context.appTextMuted,
                  ),
                ),
                const SizedBox(width: 8),

                // Avatar
                CircleAvatar(
                  radius: 13,
                  backgroundColor: item.avatarColor,
                  child: Text(
                    item.avatarLetter,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),

                // Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.isUser ? 'أنت (الدافع)' : item.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? context.appTextPrimary
                              : context.appTextMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isSelected)
                        Text(
                          '${memberAmount.toStringAsFixed(2)} ر.س',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.mintContainer
                                : AppColors.emerald,
                          ),
                        ),
                    ],
                  ),
                ),

                // Percentage Stepper
                if (isSelected)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Iconsax.minus_cirlce, size: 18),
                        color: context.appTextSecondary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          if (currentPct > 5) {
                            setState(() {
                              _percentageSplits[item.id] = currentPct - 5;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.appSurfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${currentPct.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: context.appTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Iconsax.add_circle, size: 18),
                        color: context.appTextSecondary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          if (currentPct < 95) {
                            setState(() {
                              _percentageSplits[item.id] = currentPct + 5;
                            });
                          }
                        },
                      ),
                    ],
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- CUSTOM AMOUNT SPLIT LIST ---
  Widget _buildCustomParticipantsList({
    required BuildContext context,
    required List<_ParticipantUIItem> participants,
    required bool isDark,
  }) {
    final totalAssigned = _selectedMemberIds.fold(
      0.0,
      (prev, id) => prev + (_customSplits[id] ?? 0.0),
    );
    final remainder = _currentAmount - totalAssigned;
    final isMatching = remainder.abs() < 0.05;

    return Column(
      children: [
        // Balance Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isMatching
                ? (isDark
                    ? AppColors.emerald.withValues(alpha: 0.15)
                    : AppColors.mintSoft)
                : (remainder > 0
                    ? (isDark
                        ? AppColors.warning.withValues(alpha: 0.15)
                        : AppColors.warningSoft)
                    : (isDark
                        ? AppColors.expense.withValues(alpha: 0.15)
                        : AppColors.expenseSoft)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isMatching
                        ? Iconsax.tick_circle
                        : (remainder > 0
                            ? Iconsax.warning_2
                            : Iconsax.info_circle),
                    size: 16,
                    color: isMatching
                        ? AppColors.emerald
                        : (remainder > 0
                            ? AppColors.warning
                            : AppColors.expense),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isMatching
                        ? 'المبلغ موزع بالكامل (${_currentAmount.toStringAsFixed(2)} ر.س)'
                        : (remainder > 0
                            ? 'المتبقي: ${remainder.toStringAsFixed(2)} ر.س'
                            : 'فائض: ${(-remainder).toStringAsFixed(2)} ر.س'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isMatching
                          ? (isDark
                              ? AppColors.mintContainer
                              : AppColors.emerald)
                          : (remainder > 0
                              ? (isDark
                                  ? AppColors.warning
                                  : const Color(0xFFB45309))
                              : AppColors.expense),
                    ),
                  ),
                ],
              ),
              if (!isMatching && remainder > 0)
                GestureDetector(
                  onTap: _distributeCustomRemainder,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.emerald,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'توزيع المتبقي',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Custom Amount Stepper / Controls for each member
        ...participants.map((item) {
          final isSelected = _selectedMemberIds.contains(item.id);
          final currentVal = _customSplits[item.id] ?? 0.0;
          final pct =
              _currentAmount > 0 ? (currentVal / _currentAmount * 100.0) : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? AppColors.cardDark : const Color(0xFFF8FAFC))
                  : (isDark
                      ? AppColors.cardDark.withValues(alpha: 0.3)
                      : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? (isDark ? AppColors.emerald : AppColors.emeraldLight)
                    : context.appBorder.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        if (_selectedMemberIds.length > 1) {
                          _selectedMemberIds.remove(item.id);
                          _customSplits.remove(item.id);
                        }
                      } else {
                        _selectedMemberIds.add(item.id);
                        _customSplits[item.id] =
                            _currentAmount / _selectedMemberIds.length;
                      }
                    });
                  },
                  child: Icon(
                    isSelected
                        ? Iconsax.tick_square
                        : Iconsax.close_square,
                    size: 18,
                    color:
                        isSelected ? AppColors.emerald : context.appTextMuted,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 13,
                  backgroundColor: item.avatarColor,
                  child: Text(
                    item.avatarLetter,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.isUser ? 'أنت (الدافع)' : item.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? context.appTextPrimary
                              : context.appTextMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isSelected)
                        Text(
                          '${pct.toStringAsFixed(1)}% من الفاتورة',
                          style: TextStyle(
                            fontSize: 10,
                            color: context.appTextSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Iconsax.minus_cirlce, size: 18),
                        color: context.appTextSecondary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          if (currentVal >= 10) {
                            setState(() {
                              _customSplits[item.id] = currentVal - 10;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.appSurfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${currentVal.toStringAsFixed(0)} ر.س',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.mintContainer
                                : AppColors.emerald,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Iconsax.add_circle, size: 18),
                        color: context.appTextSecondary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _customSplits[item.id] = currentVal + 10;
                          });
                        },
                      ),
                    ],
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCategorySelector(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = cat['name'] == _selectedCategory;
          final activeBg = isDark ? AppColors.emerald : AppColors.primary;
          final inactiveBg = context.appSurfaceVariant;

          return GestureDetector(
            onTap: () =>
                setState(() => _selectedCategory = cat['name'] as String),
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? activeBg : inactiveBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(cat['icon'] as String,
                      style: const TextStyle(fontSize: 14)),
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
    );
  }

  Widget _buildSaveButton(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            _onSaveExpense();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.emerald : AppColors.primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.document_download, size: 20, color: Colors.white),
            SizedBox(width: 8),
            Text(
              AppStrings.saveOffline,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
