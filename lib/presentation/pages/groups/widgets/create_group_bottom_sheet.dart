import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/group_entity.dart';
import '../../../bloc/groups/groups_bloc.dart';

/// [CreateGroupBottomSheet] allows users to create a new shared bill group
/// with name, category/icon, and dynamic initial members.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class CreateGroupBottomSheet extends StatefulWidget {
  const CreateGroupBottomSheet({super.key});

  @override
  State<CreateGroupBottomSheet> createState() => _CreateGroupBottomSheetState();
}

class _CreateGroupBottomSheetState extends State<CreateGroupBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _memberController = TextEditingController();
  final FocusNode _memberFocusNode = FocusNode();

  String _selectedType = 'trip';
  final List<String> _members = [];

  final List<_GroupTypeOption> _typeOptions = const [
    _GroupTypeOption(type: 'trip', label: AppStrings.groupTypeTrip, icon: Iconsax.routing),
    _GroupTypeOption(type: 'work', label: AppStrings.groupTypeWork, icon: Iconsax.buildings),
    _GroupTypeOption(type: 'home', label: AppStrings.groupTypeHome, icon: Iconsax.home),
    _GroupTypeOption(type: 'other', label: AppStrings.groupTypeOther, icon: Iconsax.profile_2user),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _memberController.dispose();
    _memberFocusNode.dispose();
    super.dispose();
  }

  void _addMember() {
    final name = _memberController.text.trim();
    if (name.isEmpty) return;
    if (_members.contains(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('هذا العضو موجود بالفعل في القائمة'),
          backgroundColor: AppColors.expense,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _members.add(name);
      _memberController.clear();
    });
    _memberFocusNode.requestFocus();
  }

  void _removeMember(int index) {
    setState(() {
      _members.removeAt(index);
    });
  }

  void _submitGroup() {
    if (!_formKey.currentState!.validate()) return;

    final groupName = _nameController.text.trim();
    final now = DateTime.now().toUtc();
    final groupId = 'grp_${DateTime.now().millisecondsSinceEpoch}';

    final group = GroupEntity(
      id: groupId,
      name: groupName,
      type: _selectedType,
      iconName: _selectedType,
      memberCount: _members.length,
      createdAt: now,
    );

    final memberEntities = _members.asMap().entries.map((entry) {
      final index = entry.key;
      final memberName = entry.value;
      return GroupMemberEntity(
        id: 'mem_${DateTime.now().millisecondsSinceEpoch}_$index',
        groupId: groupId,
        name: memberName,
        balance: 0.0,
        note: 'عضو جديد',
        lastActivity: 'الآن',
      );
    }).toList();

    context.read<GroupsBloc>().add(
          CreateGroupWithMembersEvent(
            group: group,
            members: memberEntities,
          ),
        );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إنشاء مجموعة "$groupName" بنجاح!'),
        backgroundColor: AppColors.emerald,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: bottomInset > 0 ? bottomInset + 16 : 24,
      ),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modal Grab Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.emerald.withValues(alpha: 0.2)
                              : AppColors.mintFixed,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Iconsax.profile_add,
                          color: isDark ? AppColors.mintContainer : AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppStrings.createNewGroup,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Iconsax.close_circle, color: context.appTextSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Group Name Field
              Text(
                AppStrings.groupName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: TextStyle(fontSize: 14, color: context.appTextPrimary),
                decoration: InputDecoration(
                  hintText: AppStrings.groupNameHint,
                  hintStyle: TextStyle(fontSize: 13, color: context.appTextMuted),
                  prefixIcon: Icon(Iconsax.edit_2,
                      color: context.appTextSecondary, size: 20),
                  filled: true,
                  fillColor: context.appCardBackground,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                        width: 1.5),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الرجاء إدخال اسم المجموعة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Group Type Selector
              Text(
                AppStrings.groupType,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: _typeOptions.map((opt) {
                  final isSelected = _selectedType == opt.type;
                  final activeBg = isDark ? AppColors.emerald : AppColors.primary;
                  final inactiveBg = context.appCardBackground;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = opt.type),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? activeBg : inactiveBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? activeBg : context.appBorder,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              opt.icon,
                              size: 20,
                              color: isSelected ? Colors.white : context.appTextSecondary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              opt.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : context.appTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Group Members Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.groupMembers,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.appTextPrimary,
                    ),
                  ),
                  Text(
                    '${_members.length} مضافين',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.mintContainer : AppColors.emerald,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Add Member Input Field
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _memberController,
                      focusNode: _memberFocusNode,
                      style: TextStyle(fontSize: 13, color: context.appTextPrimary),
                      onSubmitted: (_) => _addMember(),
                      decoration: InputDecoration(
                        hintText: AppStrings.addMemberHint,
                        hintStyle:
                            TextStyle(fontSize: 12, color: context.appTextMuted),
                        prefixIcon: Icon(Iconsax.user_add,
                            color: context.appTextSecondary, size: 18),
                        filled: true,
                        fillColor: context.appCardBackground,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.appBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.appBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: isDark ? AppColors.emerald : AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _addMember,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? AppColors.cardDarkElevated : context.appSurfaceVariant,
                        foregroundColor: context.appTextPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: context.appBorder),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: Row(
                        children: [
                          Icon(Iconsax.add, size: 18, color: context.appTextPrimary),
                          const SizedBox(width: 4),
                          Text(
                            AppStrings.addMember,
                            style: TextStyle(
                              fontSize: 12,
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
              const SizedBox(height: 10),

              // Added Members Chips
              if (_members.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _members.asMap().entries.map((entry) {
                    final index = entry.key;
                    final name = entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDarkElevated : AppColors.mintFixed,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.emerald.withValues(alpha: 0.3) : const Color(0xFF6CF8BB),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: isDark ? AppColors.emerald : AppColors.primary,
                            child: Text(
                              name.isNotEmpty ? name[0] : '?',
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: context.appTextPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _removeMember(index),
                            child: Icon(
                              Iconsax.close_circle,
                              size: 16,
                              color: context.appTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),

              // Submit Action Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.emerald : AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 1,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.tick_circle, size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.createGroupAction,
                        style: const TextStyle(
                          fontSize: 15,
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
}

class _GroupTypeOption {
  final String type;
  final String label;
  final IconData icon;

  const _GroupTypeOption({
    required this.type,
    required this.label,
    required this.icon,
  });
}
