import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/id_generator.dart';
import '../../../domain/entities/expense_split_entity.dart';
import '../../../domain/entities/group_entity.dart';
import '../../../domain/entities/transaction_item.dart';
import '../../bloc/budget/budget_bloc.dart';
import '../../bloc/groups/groups_bloc.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../widgets/custom_numeric_keypad.dart';
import '../groups/widgets/create_group_bottom_sheet.dart';
import 'widgets/expense_metadata_section.dart';
import 'widgets/participants_selector.dart';
import 'widgets/split_allocations_section.dart';

/// Interactive modal sheet for logging personal expenses or splitting shared bills
/// with Equal, Percentage, or Custom member allocations.
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
  late final String _fallbackGuestId = IdGenerator.uuidV4();
  String _payerId = '';

  final Set<String> _selectedMemberIds = {};
  final Map<String, double> _percentageSplits = {};
  final Map<String, double> _customSplits = {};
  final List<ParticipantUIItem> _dynamicAddedMembers = [];

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.initialGroupId;
    final uid = _resolveUserId();
    _payerId = uid;
    _selectedMemberIds
      ..clear()
      ..add(uid);
  }

  String _resolveUserId() {
    try {
      final profileState = context.read<ProfileBloc>().state;
      if (profileState is ProfileLoaded &&
          profileState.profile.id.isNotEmpty) {
        return profileState.profile.id;
      }
    } catch (_) {}
    return _fallbackGuestId;
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

  void _syncSplitCalculations() {
    final selectedCount = _selectedMemberIds.length;
    if (selectedCount == 0) return;

    final amount = _currentAmount;
    final equalShare = amount / selectedCount;
    final equalPct = 100.0 / selectedCount;

    for (final id in _selectedMemberIds) {
      _percentageSplits.putIfAbsent(id, () => equalPct);
      _customSplits.putIfAbsent(id, () => equalShare);
    }
  }

  void _distributePercentagesEqually() {
    if (_selectedMemberIds.isEmpty) return;
    final share = 100.0 / _selectedMemberIds.length;
    setState(() {
      for (final id in _selectedMemberIds) {
        _percentageSplits[id] = double.parse(share.toStringAsFixed(1));
      }
    });
  }

  void _distributeCustomRemainder() {
    if (_selectedMemberIds.isEmpty) return;
    final currentSum = _selectedMemberIds.fold(
      0.0,
      (sum, id) => sum + (_customSplits[id] ?? 0.0),
    );
    final remainder = _currentAmount - currentSum;
    if (remainder.abs() < 0.01) return;

    final share = remainder / _selectedMemberIds.length;
    setState(() {
      for (final id in _selectedMemberIds) {
        final cur = _customSplits[id] ?? 0.0;
        _customSplits[id] = (cur + share).clamp(0.0, _currentAmount);
      }
    });
  }

  List<ParticipantUIItem> _getParticipants(GroupsState groupsState) {
    final items = <ParticipantUIItem>[];
    final currentUserId = _resolveUserId();

    items.add(ParticipantUIItem(
      id: currentUserId,
      name: 'أنت',
      avatarLetter: 'أ',
      avatarColor: AppColors.mintFixed,
      isUser: true,
    ));

    if (groupsState is GroupsLoaded) {
      for (int i = 0; i < groupsState.activeMembers.length; i++) {
        final member = groupsState.activeMembers[i];
        if (member.id == currentUserId ||
            member.id == 'user_me' ||
            member.linkedUserId == currentUserId) {
          continue;
        }
        final color = kParticipantPalette[(i + 1) % kParticipantPalette.length];
        final letter =
            member.name.trim().isNotEmpty ? member.name.trim()[0] : 'ع';
        items.add(ParticipantUIItem(
          id: member.id,
          name: member.name,
          avatarLetter: letter,
          avatarColor: color,
        ));
      }
    }

    for (final extra in _dynamicAddedMembers) {
      if (!items.any((el) => el.id == extra.id)) {
        items.add(extra);
      }
    }

    for (final item in items) {
      if (!_selectedMemberIds.contains(item.id) &&
          _selectedMemberIds.length < 2) {
        _selectedMemberIds.add(item.id);
      }
    }

    return items;
  }

  void _toggleMemberSelection(String memberId) {
    setState(() {
      if (_selectedMemberIds.contains(memberId)) {
        if (_selectedMemberIds.length > 1) {
          _selectedMemberIds.remove(memberId);
          _percentageSplits.remove(memberId);
          _customSplits.remove(memberId);
        }
      } else {
        _selectedMemberIds.add(memberId);
        if (_selectedSplitMethod == SplitMethod.percentage) {
          _percentageSplits[memberId] = 100.0 / _selectedMemberIds.length;
        } else if (_selectedSplitMethod == SplitMethod.custom) {
          _customSplits[memberId] = _currentAmount / _selectedMemberIds.length;
        }
        _syncSplitCalculations();
      }
    });
  }

  void _selectPayer(String memberId) {
    setState(() {
      _payerId = memberId;
      _selectedMemberIds.add(memberId);
      _syncSplitCalculations();
    });
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

    final currentUserId = _resolveUserId();
    String? assignedGroupId;
    String? assignedExpenseId;

    if (_isSharedBill) {
      final selectedList = _selectedMemberIds.toList();
      if (selectedList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء تحديد عضو واحد على الأقل للمشاركة بالفاتورة'),
          ),
        );
        return;
      }

      final groupsState = context.read<GroupsBloc>().state;
      final groups =
          groupsState is GroupsLoaded ? groupsState.groups : <GroupEntity>[];
      String? groupId = _selectedGroupId;
      if (groupId == null && groupsState is GroupsLoaded) {
        if (groupsState.selectedGroupId.isNotEmpty) {
          groupId = groupsState.selectedGroupId;
        } else if (groups.isNotEmpty) {
          groupId = groups.first.id;
        }
      }

      if (groupId == null ||
          groupId.isEmpty ||
          !groups.any((g) => g.id == groupId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء إنشاء أو اختيار مجموعة أولاً لمشاركة الفاتورة'),
          ),
        );
        return;
      }

      final ISplitCalculationStrategy strategy;
      Map<String, double>? customValues;

      switch (_selectedSplitMethod) {
        case SplitMethod.equal:
          strategy = EqualSplitStrategy();
          break;
        case SplitMethod.percentage:
          final totalPct = selectedList.fold<double>(
            0.0,
            (sum, id) =>
                sum + (_percentageSplits[id] ?? (100.0 / selectedList.length)),
          );
          if ((totalPct - 100.0).abs() > 0.5) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'يجب أن يكون مجموع النسب 100% (الحالي ${totalPct.toStringAsFixed(1)}%)',
                ),
                backgroundColor: AppColors.expense,
              ),
            );
            return;
          }
          strategy = PercentageSplitStrategy();
          customValues = {
            for (final id in selectedList)
              id: _percentageSplits[id] ?? (100.0 / selectedList.length),
          };
          break;
        case SplitMethod.custom:
          final totalCustom = selectedList.fold<double>(
            0.0,
            (sum, id) =>
                sum + (_customSplits[id] ?? (amount / selectedList.length)),
          );
          if ((totalCustom - amount).abs() > 0.5) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'مجموع الحصص (${totalCustom.toStringAsFixed(2)}) لا يساوي إجمالي الفاتورة (${amount.toStringAsFixed(2)})',
                ),
                backgroundColor: AppColors.expense,
              ),
            );
            return;
          }
          strategy = CustomAmountSplitStrategy();
          customValues = {
            for (final id in selectedList)
              id: _customSplits[id] ?? (amount / selectedList.length),
          };
          break;
      }

      assignedGroupId = groupId;
      assignedExpenseId = IdGenerator.prefixed('exp');

      final allParticipants = _getParticipants(groupsState);
      final memberNames = {
        for (final p in allParticipants) p.id: p.name,
      };

      final splits = strategy.calculateSplits(
        totalAmount: amount,
        memberIds: selectedList,
        memberNames: memberNames,
        payerId: _payerId,
        customValues: customValues,
      );

      final groupExpense = GroupExpense(
        id: assignedExpenseId,
        groupId: groupId,
        title: title,
        totalAmount: amount,
        payerId: _payerId,
        payerName: memberNames[_payerId] ?? 'أنت',
        category: _selectedCategory,
        splitMethod: _selectedSplitMethod,
        splits: splits,
        dateTime: DateTime.now(),
      );

      context.read<GroupsBloc>().add(AddSharedExpenseEvent(groupExpense));
    }

    final paidByCurrentUser = !_isSharedBill || _payerId == currentUserId;
    if (paidByCurrentUser) {
      final catInfo = kExpenseCategories.firstWhere(
        (c) => c.name == _selectedCategory,
        orElse: () => kExpenseCategories.first,
      );

      final transaction = TransactionItem(
        id: IdGenerator.prefixed('tx'),
        title: title,
        amount: amount,
        category: _selectedCategory,
        categoryIcon: catInfo.dbIcon,
        paymentMethod: _isSharedBill ? 'فاتورة مشتركة' : 'مدى • بطاقة',
        dateTime: DateTime.now(),
        type: TransactionType.expense,
        groupId: assignedGroupId,
        expenseId: assignedExpenseId,
        isSynced: false,
      );

      context.read<BudgetBloc>().add(AddPersonalTransactionEvent(transaction));
    }

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          paidByCurrentUser
              ? 'تم حفظ "$title" محلياً بنجاح!'
              : 'تم قيد "$title" على حساب المجموعة بنجاح!',
        ),
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
                : (groups.isNotEmpty ? groups.first.id : ''));

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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Iconsax.cloud_cross,
                            size: 16,
                            color: AppColors.emerald,
                          ),
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
                        icon: Icon(
                          Iconsax.close_circle,
                          color: context.appTextSecondary,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Divider(color: context.appBorder),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExpenseTypeToggle(
                          isSharedBill: _isSharedBill,
                          onChanged: (val) =>
                              setState(() => _isSharedBill = val),
                        ),
                        const SizedBox(height: 16),
                        ExpenseAmountDisplay(amountStr: _amountStr),
                        const SizedBox(height: 14),
                        ExpenseTitleInput(
                          controller: _titleController,
                          isSharedBill: _isSharedBill,
                        ),
                        const SizedBox(height: 16),
                        if (_isSharedBill) ...[
                          ExpenseGroupSelector(
                            groups: groups,
                            currentGroupId: currentGroupId,
                            onSelectGroup: (groupId) {
                              setState(() => _selectedGroupId = groupId);
                              context
                                  .read<GroupsBloc>()
                                  .add(SelectGroupEvent(groupId));
                            },
                            onCreateGroup: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const CreateGroupBottomSheet(),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          SplitMethodHeader(
                            splitMethod: _selectedSplitMethod,
                            selectedCount: selectedCount,
                            sharePerPerson: sharePerPerson,
                            totalAmount: amount,
                            selectedMemberIds: _selectedMemberIds,
                            percentageSplits: _percentageSplits,
                            customSplits: _customSplits,
                          ),
                          const SizedBox(height: 8),
                          SplitMethodChips(
                            selectedMethod: _selectedSplitMethod,
                            onSelected: (method) {
                              setState(() {
                                _selectedSplitMethod = method;
                                _syncSplitCalculations();
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          ParticipantsHeader(
                            selectedCount: _selectedMemberIds.length,
                            onAddMemberTap: () {
                              showQuickAddMemberModal(
                                context: context,
                                groupId: currentGroupId,
                                initialColorSeed:
                                    _dynamicAddedMembers.length + 2,
                                onMemberAdded: (item) {
                                  setState(() {
                                    _dynamicAddedMembers.add(item);
                                    _selectedMemberIds.add(item.id);
                                    _syncSplitCalculations();
                                  });
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          SplitAllocationsSection(
                            splitMethod: _selectedSplitMethod,
                            participants: participants,
                            selectedMemberIds: _selectedMemberIds,
                            payerId: _payerId,
                            currentAmount: amount,
                            sharePerPerson: sharePerPerson,
                            percentageSplits: _percentageSplits,
                            customSplits: _customSplits,
                            onToggleMember: _toggleMemberSelection,
                            onSelectPayer: _selectPayer,
                            onDistributePercentages:
                                _distributePercentagesEqually,
                            onDistributeCustomRemainder:
                                _distributeCustomRemainder,
                            onAdjustPercentage: (id, delta) {
                              setState(() {
                                final current = _percentageSplits[id] ?? 0.0;
                                _percentageSplits[id] =
                                    (current + delta).clamp(0.0, 100.0);
                              });
                            },
                            onAdjustCustomAmount: (id, delta) {
                              setState(() {
                                final current = _customSplits[id] ?? 0.0;
                                _customSplits[id] = (current + delta)
                                    .clamp(0.0, double.infinity);
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        ExpenseCategorySelector(
                          selectedCategory: _selectedCategory,
                          onSelected: (name) =>
                              setState(() => _selectedCategory = name),
                        ),
                        const SizedBox(height: 16),
                        CustomNumericKeypad(
                          onKeyPressed: _onKeypadPress,
                          onDelete: _onKeypadDelete,
                        ),
                        const SizedBox(height: 16),
                        ExpenseSaveButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _onSaveExpense();
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            AppStrings.readyForSyncFooter,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.mintContainer
                                  : AppColors.emerald,
                              fontWeight: FontWeight.bold,
                            ),
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
}
