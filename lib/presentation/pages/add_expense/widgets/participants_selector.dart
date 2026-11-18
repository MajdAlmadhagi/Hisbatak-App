import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/utils/validators.dart';
import '../../../../domain/entities/expense_split_entity.dart';
import '../../../../domain/entities/group_entity.dart';
import '../../../bloc/groups/groups_bloc.dart';
import '../../../widgets/optional_phone_field.dart';
import '../../../widgets/profile_currency_extension.dart';
import 'expense_metadata_section.dart';

/// Represents a participant rendered inside the expense split sheet.
class ParticipantUIItem {
  final String id;
  final String name;
  final String avatarLetter;
  final Color avatarColor;
  final bool isUser;

  const ParticipantUIItem({
    required this.id,
    required this.name,
    required this.avatarLetter,
    required this.avatarColor,
    this.isUser = false,
  });
}

/// Header showing split method title and live split summary.
class SplitMethodHeader extends StatelessWidget {
  final SplitMethod splitMethod;
  final int selectedCount;
  final double sharePerPerson;
  final double totalAmount;
  final Set<String> selectedMemberIds;
  final Map<String, double> percentageSplits;
  final Map<String, double> customSplits;

  const SplitMethodHeader({
    super.key,
    required this.splitMethod,
    required this.selectedCount,
    required this.sharePerPerson,
    required this.totalAmount,
    required this.selectedMemberIds,
    required this.percentageSplits,
    required this.customSplits,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final symbol = context.watchCurrencySymbol();
    final String subtitle;

    switch (splitMethod) {
      case SplitMethod.equal:
        subtitle =
            '$selectedCount أفراد بالتساوي (${sharePerPerson.toStringAsFixed(2)} $symbol)';
        break;
      case SplitMethod.percentage:
        final sum = selectedMemberIds.fold(
          0.0,
          (prev, id) => prev + (percentageSplits[id] ?? 0.0),
        );
        subtitle = 'الإجمالي: ${sum.toStringAsFixed(1)}% / 100%';
        break;
      case SplitMethod.custom:
        final sum = selectedMemberIds.fold(
          0.0,
          (prev, id) => prev + (customSplits[id] ?? 0.0),
        );
        subtitle =
            '${sum.toStringAsFixed(2)} / ${totalAmount.toStringAsFixed(2)} $symbol';
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
            color: context.appTextSecondary,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.mintContainer : AppColors.emerald,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Segmented chips for selecting equal, percentage, or custom split mode.
class SplitMethodChips extends StatelessWidget {
  final SplitMethod selectedMethod;
  final ValueChanged<SplitMethod> onSelected;

  const SplitMethodChips({
    super.key,
    required this.selectedMethod,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SplitMethodChip(
          label: AppStrings.splitEqually,
          isSelected: selectedMethod == SplitMethod.equal,
          onTap: () => onSelected(SplitMethod.equal),
        ),
        const SizedBox(width: 8),
        _SplitMethodChip(
          label: AppStrings.splitByPercentage,
          isSelected: selectedMethod == SplitMethod.percentage,
          onTap: () => onSelected(SplitMethod.percentage),
        ),
        const SizedBox(width: 8),
        _SplitMethodChip(
          label: AppStrings.splitCustom,
          isSelected: selectedMethod == SplitMethod.custom,
          onTap: () => onSelected(SplitMethod.custom),
        ),
      ],
    );
  }
}

class _SplitMethodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SplitMethodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final activeBg = isDark ? AppColors.emerald : AppColors.primary;
    final inactiveBg = context.appSurfaceVariant;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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
}

/// Participants section header with selected counter and quick-add member action.
class ParticipantsHeader extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onAddMemberTap;

  const ParticipantsHeader({
    super.key,
    required this.selectedCount,
    required this.onAddMemberTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

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
                '$selectedCount محددين',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.mintContainer : AppColors.emerald,
                ),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: onAddMemberTap,
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
                  'إضافة عضو آخر',
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
}

/// Opens a quick modal sheet to add a new group member (with optional phone
/// for future sync identity linking) directly while adding a bill.
Future<void> showQuickAddMemberModal({
  required BuildContext context,
  required String groupId,
  required int initialColorSeed,
  required ValueChanged<ParticipantUIItem> onMemberAdded,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalCtx) => _QuickAddMemberSheet(
      groupId: groupId,
      initialColorSeed: initialColorSeed,
      onMemberAdded: (item) {
        onMemberAdded(item);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تمت إضافة "${item.name}" بنجاح للمجموعة والفاتورة!',
            ),
            backgroundColor: AppColors.emerald,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    ),
  );
}

class _QuickAddMemberSheet extends StatefulWidget {
  final String groupId;
  final int initialColorSeed;
  final ValueChanged<ParticipantUIItem> onMemberAdded;

  const _QuickAddMemberSheet({
    required this.groupId,
    required this.initialColorSeed,
    required this.onMemberAdded,
  });

  @override
  State<_QuickAddMemberSheet> createState() => _QuickAddMemberSheetState();
}

class _QuickAddMemberSheetState extends State<_QuickAddMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor =
        kParticipantPalette[widget.initialColorSeed % kParticipantPalette.length];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final trimmed = _nameCtrl.text.trim();
    final avatarChar = trimmed.isNotEmpty ? trimmed[0] : '؟';

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                        child: const Icon(
                          Iconsax.user_add,
                          color: AppColors.emerald,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'إضافة عضو جديد للمجموعة',
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
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _selectedColor,
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
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'اختر لون الرمز:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: kParticipantPalette.map((color) {
                    final isSelected = _selectedColor == color;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
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
                              ? const Icon(
                                  Iconsax.tick_circle,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                autofocus: true,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.appTextPrimary,
                ),
                onChanged: (_) => setState(() {}),
                validator: (val) => Validators.requiredField(val),
                decoration: InputDecoration(
                  labelText: 'اسم العضو *',
                  hintText: 'مثال: محمد السعيد',
                  prefixIcon: const Icon(Iconsax.personalcard, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              OptionalPhoneField(controller: _phoneCtrl),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
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
                      Icon(Iconsax.tick_circle, size: 18, color: Colors.white),
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
        ),
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final newMemberId = IdGenerator.prefixed('mem');
    final phoneE164 = Validators.tryNormalizePhoneE164(_phoneCtrl.text);

    if (widget.groupId.isNotEmpty) {
      final newMemberEntity = GroupMemberEntity(
        id: newMemberId,
        groupId: widget.groupId,
        name: name,
        phoneE164: phoneE164,
        balance: 0.0,
        note: 'انضم حديثاً',
        lastActivity: 'الآن',
      );
      context.read<GroupsBloc>().add(AddGroupMemberEvent(newMemberEntity));
    }

    final letter = name.isNotEmpty ? name[0] : 'ع';
    final item = ParticipantUIItem(
      id: newMemberId,
      name: name,
      avatarLetter: letter,
      avatarColor: _selectedColor,
    );

    Navigator.of(context).pop();
    widget.onMemberAdded(item);
  }
}
