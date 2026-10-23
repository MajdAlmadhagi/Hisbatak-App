import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/group_entity.dart';
import '../../../bloc/groups/groups_bloc.dart';

/// [CreateMemberModal] allows adding a brand new member from the all members hub.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class CreateMemberModal extends StatefulWidget {
  final List<GroupEntity> groups;

  const CreateMemberModal({
    super.key,
    required this.groups,
  });

  @override
  State<CreateMemberModal> createState() => _CreateMemberModalState();
}

class _CreateMemberModalState extends State<CreateMemberModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  String? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    if (widget.groups.isNotEmpty) {
      _selectedGroupId = widget.groups.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  IconData _getGroupIcon(String type) {
    switch (type) {
      case 'work':
        return Iconsax.buildings;
      case 'home':
        return Iconsax.home;
      case 'trip':
        return Icons.group;
      default:
        return Iconsax.profile_2user;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _selectedGroupId == null) return;

    final name = _nameController.text.trim();
    final newMember = GroupMemberEntity(
      id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
      groupId: _selectedGroupId!,
      name: name,
      balance: 0.0,
      note: 'عضو جديد',
      lastActivity: 'الآن',
    );

    context.read<GroupsBloc>().add(AddGroupMemberEvent(newMember));
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'تمت إضافة العضو "$name" بنجاح!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.emerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: bottomInset > 0 ? bottomInset + 16 : 28,
      ),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grab Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appBorder,
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.emerald.withValues(alpha: 0.2)
                            : AppColors.mintFixed,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.user_add,
                        color: isDark
                            ? AppColors.mintContainer
                            : AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.addNewMemberTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.appTextPrimary,
                          ),
                        ),
                        Text(
                          'أدخل بيانات العضو وحدد المجموعة',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.appTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Iconsax.close_circle, color: context.appTextMuted),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Member Name Input
            Text(
              AppStrings.memberNameLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              style: TextStyle(color: context.appTextPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: AppStrings.memberNameHint,
                hintStyle: TextStyle(color: context.appTextMuted, fontSize: 13),
                filled: true,
                fillColor: context.appSurfaceVariant,
                prefixIcon: Icon(Iconsax.user,
                    size: 20, color: context.appTextSecondary),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.appBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.appBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.emerald : AppColors.primary,
                    width: 1.8,
                  ),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'يرجى إدخال اسم العضو';
                }
                if (val.trim().length < 2) {
                  return 'الاسم قصير جداً';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Target Group Selection
            Text(
              AppStrings.selectGroupForNewMember,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 10),

            if (widget.groups.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.appSurfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'لا توجد مجموعات مسجلة بعد. أنشئ مجموعة أولاً.',
                    style: TextStyle(
                        fontSize: 12, color: context.appTextSecondary),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.groups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final group = widget.groups[index];
                    final isSelected = _selectedGroupId == group.id;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedGroupId = group.id;
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                  ? AppColors.emerald.withValues(alpha: 0.15)
                                  : AppColors.mintFixed)
                              : context.appSurfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? (isDark
                                    ? AppColors.emerald
                                    : AppColors.primary)
                                : context.appBorder,
                            width: isSelected ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark
                                        ? AppColors.emerald
                                        : AppColors.primary)
                                    : context.appCardBackground,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getGroupIcon(group.type),
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : context.appTextSecondary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                group.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: context.appTextPrimary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Iconsax.tick_circle,
                                size: 18,
                                color: isDark
                                    ? AppColors.emerald
                                    : AppColors.primary,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _selectedGroupId != null ? _submit : null,
                icon: const Icon(Iconsax.user_add, size: 20),
                label: const Text(
                  'حفظ وإضافة العضو',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? AppColors.emerald : AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
