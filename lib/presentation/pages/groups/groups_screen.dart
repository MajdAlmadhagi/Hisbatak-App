import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../bloc/groups/groups_bloc.dart';
import '../add_expense/add_expense_bottom_sheet.dart';
import '../../widgets/debt_summary_card.dart';
import '../../widgets/hisbatak_loader.dart';
import '../../widgets/member_settle_card.dart';
import '../../widgets/offline_status_pill.dart';

/// [GroupsScreen] renders collaborative bill splitting, group members, and debts matching Screen 3.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  IconData _getGroupIcon(String type) {
    switch (type) {
      case 'work':
        return Icons.apartment_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'trip':
        return Icons.hiking_rounded;
      default:
        return Icons.group_rounded;
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
                    child: Icon(Icons.person,
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
                            fontSize: 11, color: context.appTextSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  const OfflineStatusPill(isCompact: true),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.appCardBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.appBorder),
                    ),
                    child: Icon(Icons.picture_as_pdf_outlined,
                        size: 18, color: context.appTextPrimary),
                  ),
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
                style: TextStyle(fontSize: 11, color: context.appTextSecondary),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.appSurfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppStrings.newGroup,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: context.appTextSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Members and Settlements Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.groupMembersAndSettlements,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary),
              ),
              Text(
                '${state.activeMembers.length} أعضاء في ${state.selectedGroup?.name ?? ''}',
                style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.mintContainer : AppColors.emerald,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Members List
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
                  Icon(Icons.receipt_long_rounded,
                      size: 20, color: Colors.white),
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
          Center(
            child: Text(
              AppStrings.automaticSyncNote,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: context.appTextMuted),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
