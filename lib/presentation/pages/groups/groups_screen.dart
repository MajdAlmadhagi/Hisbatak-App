import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisbatak_app/presentation/widgets/custom_app_button.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../bloc/groups/groups_bloc.dart';
import '../add_expense/add_expense_bottom_sheet.dart';
import '../../widgets/debt_summary_card.dart';
import '../../widgets/hisbatak_loader.dart';
import '../../widgets/member_settle_card.dart';
import 'widgets/add_member_bottom_sheet.dart';
import 'widgets/create_group_bottom_sheet.dart';

/// [GroupsScreen] renders collaborative bill splitting, group members, and debts matching Screen 3.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

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

  void _showAddExpenseModal(BuildContext context, String groupId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddExpenseBottomSheet(initialGroupId: groupId),
    );
  }

  void _showCreateGroupModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CreateGroupBottomSheet(),
    );
  }

  void _showAddMemberModal(
      BuildContext context, String groupId, String groupName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddMemberBottomSheet(
        groupId: groupId,
        groupName: groupName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appBackground,
      child: SafeArea(
        child: BlocBuilder<GroupsBloc, GroupsState>(
          builder: (context, state) {
            if (state is GroupsLoading) {
              return const Center(child: HisbatakLoader());
            } else if (state is GroupsLoaded) {
              return _buildContent(context, state);
            } else if (state is GroupsError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, GroupsLoaded state) {
    final selectedGroupId = state.selectedGroupId;
    final isDark = context.isDarkMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        isDark ? AppColors.cardDark : const Color(0xFFE2E8F0),
                    child: Icon(Iconsax.user,
                        color: context.appTextSecondary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.groupsAndSplits,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.appTextPrimary,
                        ),
                      ),
                      Text(
                        state.selectedGroup?.name ?? AppStrings.groupWork,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: context.appTextSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  CustomAppButton(
                    icon: Iconsax.document_download,
                    onPressed: () {},
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Subheader
          Text(
            AppStrings.groupsSharedExpenses,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.appTextPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Total Balance Debt Summary Card
          DebtSummaryCard(summary: state.debtSummary),
          const SizedBox(height: 20),

          // Active Groups Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.activeGroups,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary),
              ),
              Text(
                '${state.groups.length} مجموعات نشطة',
                style: TextStyle(
                    fontSize: 11,
                    color: context.appTextSecondary,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Group Selection Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...state.groups.map((grp) {
                  final isSelected = grp.id == selectedGroupId;
                  final activeBg =
                      isDark ? AppColors.emerald : AppColors.primary;
                  final inactiveBg = context.appCardBackground;
                  final activeText = Colors.white;
                  final inactiveText = context.appTextPrimary;

                  return GestureDetector(
                    onTap: () {
                      context.read<GroupsBloc>().add(SelectGroupEvent(grp.id));
                    },
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? activeBg : inactiveBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? activeBg : context.appBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getGroupIcon(grp.type),
                            size: 16,
                            color: isSelected ? activeText : inactiveText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            grp.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? activeText : inactiveText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                // New Group Button
                GestureDetector(
                  onTap: () => _showCreateGroupModal(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.appSurfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.appBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.add,
                          size: 16,
                          color: context.appTextPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppStrings.newGroup,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: context.appTextPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Members and Settlements Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.groupMembersAndSettlements,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.appTextPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${state.activeMembers.length} أعضاء في ${state.selectedGroup?.name ?? ''}',
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.mintContainer
                            : AppColors.emerald,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (state.selectedGroup != null)
                GestureDetector(
                  onTap: () => _showAddMemberModal(
                    context,
                    state.selectedGroupId,
                    state.selectedGroup?.name ?? '',
                  ),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.cardDarkElevated
                          : AppColors.mintFixed,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? AppColors.emerald.withValues(alpha: 0.3)
                            : const Color(0xFF6CF8BB),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.user_add,
                          size: 14,
                          color: isDark
                              ? AppColors.mintContainer
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppStrings.addMember,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.mintContainer
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Members List or Empty State
          if (state.activeMembers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: context.appCardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.appBorder),
              ),
              child: Column(
                children: [
                  Icon(
                    Iconsax.profile_2user,
                    size: 38,
                    color: context.appTextSecondary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppStrings.noMembersInGroup,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.appTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.noMembersInGroupDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.appTextSecondary,
                    ),
                  ),
                  if (state.selectedGroup != null) ...[
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () => _showAddMemberModal(
                        context,
                        state.selectedGroupId,
                        state.selectedGroup?.name ?? '',
                      ),
                      icon: const Icon(Iconsax.user_add, size: 16),
                      label: const Text(AppStrings.addFirstMember),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? AppColors.emerald : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            ...state.activeMembers.map((member) {
              return MemberSettleCard(
                member: member,
                onSettle: () {
                  context.read<GroupsBloc>().add(
                        SettleMemberEvent(
                            memberId: member.id, groupId: member.groupId),
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تمت تسوية حساب ${member.name} بنجاح!'),
                      backgroundColor: AppColors.emerald,
                    ),
                  );
                },
              );
            }),
          const SizedBox(height: 20),

          // Add Shared Bill Big Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () =>
                  _showAddExpenseModal(context, state.selectedGroupId),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.emerald : AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.receipt_item, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    AppStrings.addSharedBill,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Bottom automatic sync note
          // Center(
          //   child: Text(
          //     AppStrings.automaticSyncNote,
          //     textAlign: TextAlign.center,
          //     style: TextStyle(fontSize: 11, color: context.appTextMuted),
          //   ),
          // ),
          // const SizedBox(height: 24),
        ],
      ),
    );
  }
}
