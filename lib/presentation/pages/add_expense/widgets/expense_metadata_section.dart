import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../domain/entities/group_entity.dart';
import '../../../widgets/profile_currency_extension.dart';

/// Category option metadata for personal and shared expenses.
class ExpenseCategoryOption {
  final String name;
  final String icon;
  final String dbIcon;

  const ExpenseCategoryOption({
    required this.name,
    required this.icon,
    required this.dbIcon,
  });
}

const List<ExpenseCategoryOption> kExpenseCategories = [
  ExpenseCategoryOption(
    name: 'مطاعم وكافيهات',
    icon: '🍔',
    dbIcon: 'local_cafe',
  ),
  ExpenseCategoryOption(
    name: 'تموين ومقاضي',
    icon: '🛒',
    dbIcon: 'shopping_cart',
  ),
  ExpenseCategoryOption(
    name: 'نقل ومواصلات',
    icon: '🚗',
    dbIcon: 'directions_car',
  ),
  ExpenseCategoryOption(
    name: 'فواتير ومسكن',
    icon: '🏠',
    dbIcon: 'wifi',
  ),
  ExpenseCategoryOption(
    name: 'بنزين وطاقة',
    icon: '⛽',
    dbIcon: 'fuel',
  ),
  ExpenseCategoryOption(
    name: 'مياه وكهرباء',
    icon: '💦',
    dbIcon: 'water',
  ),
  ExpenseCategoryOption(
    name: 'الأنترنت والهاتف',
    icon: '🌐',
    dbIcon: 'internet',
  ),
  ExpenseCategoryOption(
    name: 'تعليم وجامعات',
    icon: '🎓',
    dbIcon: 'internet',
  ),
  ExpenseCategoryOption(
    name: 'ترفية وتسوق',
    icon: '🛍️',
    dbIcon: 'shopping',
  ),
  ExpenseCategoryOption(
    name: 'مصروفات أخرى',
    icon: '🛍️',
    dbIcon: 'other',
  ),
];

const List<Color> kParticipantPalette = [
  Color(0xFF10B981),
  Color(0xFF3B82F6),
  Color(0xFF8B5CF6),
  Color(0xFFF59E0B),
  Color(0xFF06B6D4),
  Color(0xFFEC4899),
  Color(0xFF6366F1),
  Color(0xFF14B8A6),
];

/// Segmented switch between shared bill and personal expense.
class ExpenseTypeToggle extends StatelessWidget {
  final bool isSharedBill;
  final ValueChanged<bool> onChanged;

  const ExpenseTypeToggle({
    super.key,
    required this.isSharedBill,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.appSurfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildSegment(
            context: context,
            label: AppStrings.sharedBill,
            selected: isSharedBill,
            isDark: isDark,
            showDot: true,
            onTap: () => onChanged(true),
          ),
          _buildSegment(
            context: context,
            label: AppStrings.personalExpense,
            selected: !isSharedBill,
            isDark: isDark,
            showDot: false,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required BuildContext context,
    required String label,
    required bool selected,
    required bool isDark,
    required bool showDot,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? context.appCardBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showDot) ...[
                CircleAvatar(
                  radius: 3,
                  backgroundColor:
                      selected ? AppColors.emerald : Colors.transparent,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? context.appTextPrimary
                      : context.appTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Large currency + keypad amount display.
class ExpenseAmountDisplay extends StatelessWidget {
  final String amountStr;

  const ExpenseAmountDisplay({
    super.key,
    required this.amountStr,
  });

  @override
  Widget build(BuildContext context) {
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
                '${context.watchCurrencySymbol()} ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.appTextSecondary,
                ),
              ),
              Text(
                amountStr,
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
}

/// Title text field for the expense.
class ExpenseTitleInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isSharedBill;

  const ExpenseTitleInput({
    super.key,
    required this.controller,
    required this.isSharedBill,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.center,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) => Validators.requiredField(value),
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: context.appTextPrimary,
      ),
      decoration: InputDecoration(
        hintText:
            isSharedBill ? 'مثال: غداء جماعي' : 'مثال: مصاريف مواصلات...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.appTextSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.emerald, width: 2),
        ),
        labelText: 'اسم الفاتورة',
        isDense: true,
        suffixIcon: Icon(
          Iconsax.edit_2,
          size: 16,
          color: context.appTextSecondary,
        ),
      ),
    );
  }
}

/// Horizontal target group picker with inline "New group" shortcut.
class ExpenseGroupSelector extends StatelessWidget {
  final List<GroupEntity> groups;
  final String currentGroupId;
  final ValueChanged<String> onSelectGroup;
  final VoidCallback onCreateGroup;

  const ExpenseGroupSelector({
    super.key,
    required this.groups,
    required this.currentGroupId,
    required this.onSelectGroup,
    required this.onCreateGroup,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final activeBg = isDark ? AppColors.emerald : AppColors.primary;
    final inactiveBg = context.appSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              groups.isEmpty
                  ? 'إنشاء مجموعة مستهدفة'
                  : 'حدد المجموعة المستهدفة',
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
                return GestureDetector(
                  onTap: () => onSelectGroup(grp.id),
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
                onTap: onCreateGroup,
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
                            ? 'إضافة مجموعة جديدة'
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
}

/// Horizontal category selector strip.
class ExpenseCategorySelector extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const ExpenseCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final activeBg = isDark ? AppColors.emerald : AppColors.primary;
    final inactiveBg = context.appSurfaceVariant;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: kExpenseCategories.map((cat) {
          final isSelected = cat.name == selectedCategory;
          return GestureDetector(
            onTap: () => onSelected(cat.name),
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? activeBg : inactiveBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(cat.icon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    cat.name,
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
}

/// Primary save CTA at the bottom of the add-expense sheet.
class ExpenseSaveButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ExpenseSaveButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.emerald : AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
