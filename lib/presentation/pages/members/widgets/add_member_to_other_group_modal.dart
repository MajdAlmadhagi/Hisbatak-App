import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/group_entity.dart';
import '../../../bloc/groups/groups_bloc.dart';

/// [AddMemberToOtherGroupModal] allows adding an existing member to another group.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class AddMemberToOtherGroupModal extends StatefulWidget {
  final ConsolidatedMemberEntity member;
  final List<GroupEntity> allGroups;

  const AddMemberToOtherGroupModal({
    super.key,
    required this.member,
    required this.allGroups,
  });

  @override
  State<AddMemberToOtherGroupModal> createState() =>
      _AddMemberToOtherGroupModalState();
}

class _AddMemberToOtherGroupModalState
    extends State<AddMemberToOtherGroupModal> {
  String? _selectedGroupId;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final available = widget.member.availableGroups(widget.allGroups);
    if (available.isNotEmpty) {
      _selectedGroupId = available.first.id;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  IconData _getGroupIcon(String type) {
    switch (type) {
      case 'work':
        return Iconsax.buildings;
      case 'home':
        return Iconsax.home;
      case 'trip':
        return Iconsax.routing;
      default:
        return Iconsax.profile_2user;
    }
  }

  void _submit() {
    if (_selectedGroupId == null) return;

    final targetGroup = widget.allGroups.firstWhere(
      (g) => g.id == _selectedGroupId,
    );

    context.read<GroupsBloc>().add(
          AddExistingMemberToGroupEvent(
            memberName: widget.member.name,
            avatarUrl: widget.member.avatarUrl,
            targetGroupId: _selectedGroupId!,
            note: _noteController.text.trim().isNotEmpty
                ? _noteController.text.trim()
                : 'تمت الإضافة من قائمة الأعضاء',
          ),
        );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'تمت إضافة "${widget.member.name}" إلى ${targetGroup.name} بنجاح!',
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
    final availableGroups = widget.member.availableGroups(widget.allGroups);
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
                      color:
                          isDark ? AppColors.mintContainer : AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.addToAnotherGroupTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.appTextPrimary,
                        ),
                      ),
                      Text(
                        widget.member.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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
          const SizedBox(height: 16),

          // Current Groups Tags
          Text(
            AppStrings.currentJoinedGroups,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: context.appTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: widget.member.memberships.map((m) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: context.appSurfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.appBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getGroupIcon(m.groupType),
                        size: 13, color: context.appTextSecondary),
                    const SizedBox(width: 6),
                    Text(
                      m.groupName,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.appTextPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),
          Divider(color: context.appBorder, height: 1),
          const SizedBox(height: 16),

          if (availableGroups.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.appSurfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Iconsax.tick_circle, size: 36, color: AppColors.income),
                  const SizedBox(height: 10),
                  Text(
                    AppStrings.memberAlreadyInAll,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: context.appTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.noGroupsAvailableForMember,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ] else ...[
            Text(
              AppStrings.selectGroupToJoin,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 10),

            // Available Groups List
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: availableGroups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final group = availableGroups[index];
                  final isSelected = _selectedGroupId == group.id;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedGroupId = group.id;
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? AppColors.emerald.withValues(alpha: 0.15)
                                : AppColors.mintFixed)
                            : context.appSurfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? AppColors.emerald : AppColors.primary)
                              : context.appBorder,
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
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
                              size: 18,
                              color: isSelected
                                  ? Colors.white
                                  : context.appTextSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: context.appTextPrimary,
                                  ),
                                ),
                                Text(
                                  '${group.memberCount} أعضاء',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: context.appTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? (isDark
                                      ? AppColors.emerald
                                      : AppColors.primary)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? (isDark
                                        ? AppColors.emerald
                                        : AppColors.primary)
                                    : context.appBorder,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    size: 14, color: Colors.white)
                                : null,
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
                label: Text(
                  AppStrings.confirmAddToGroup,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
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
        ],
      ),
    );
  }
}
