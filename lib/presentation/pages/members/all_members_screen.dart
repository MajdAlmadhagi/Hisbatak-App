import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/group_entity.dart';
import '../../bloc/groups/groups_bloc.dart';
import '../../widgets/hisbatak_loader.dart';
import 'widgets/add_member_to_other_group_modal.dart';
import 'widgets/consolidated_member_card.dart';
import 'widgets/create_member_modal.dart';

enum MemberFilterType { all, owesYou, youOwe, balanced }

/// [AllMembersScreen] displays the unified directory of all group members across separated groups.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class AllMembersScreen extends StatefulWidget {
  const AllMembersScreen({super.key});

  @override
  State<AllMembersScreen> createState() => _AllMembersScreenState();
}

class _AllMembersScreenState extends State<AllMembersScreen> {
  final TextEditingController _searchController = TextEditingController();
  MemberFilterType _activeFilter = MemberFilterType.all;
  String? _selectedGroupFilter; // null = all groups

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddMemberModal(BuildContext context, List<GroupEntity> groups) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateMemberModal(groups: groups),
    );
  }

  void _showAddToOtherGroupModal(
    BuildContext context,
    ConsolidatedMemberEntity member,
    List<GroupEntity> allGroups,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddMemberToOtherGroupModal(
        member: member,
        allGroups: allGroups,
      ),
    );
  }

  List<ConsolidatedMemberEntity> _filterMembers(
    List<ConsolidatedMemberEntity> members,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    return members.where((m) {
      // 1. Text Search query
      if (query.isNotEmpty && !m.name.toLowerCase().contains(query)) {
        return false;
      }

      // 2. Group Filter
      if (_selectedGroupFilter != null && !m.isInGroup(_selectedGroupFilter!)) {
        return false;
      }

      // 3. Status Filter
      switch (_activeFilter) {
        case MemberFilterType.owesYou:
          return m.owesUser;
        case MemberFilterType.youOwe:
          return m.userOwes;
        case MemberFilterType.balanced:
          return m.isBalanced;
        case MemberFilterType.all:
          return true;
      }
    }).toList();
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
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.danger, size: 48, color: AppColors.expense),
                      const SizedBox(height: 12),
                      Text(
                        state.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.appTextPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<GroupsBloc>().add(LoadGroupsEvent());
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, GroupsLoaded state) {
    final isDark = context.isDarkMode;
    final allMembers = state.allMembers;
    final allGroups = state.groups;
    final filteredMembers = _filterMembers(allMembers);

    // Compute overview stats
    double totalOwedToUser = 0.0;
    double totalUserOwes = 0.0;
    for (final m in allMembers) {
      if (m.totalBalance > 0) {
        totalOwedToUser += m.totalBalance;
      } else if (m.totalBalance < 0) {
        totalUserOwes += m.totalBalance.abs();
      }
    }
    final netReceivables = totalOwedToUser - totalUserOwes;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<GroupsBloc>().add(LoadGroupsEvent());
      },
      color: isDark ? AppColors.emerald : AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Bar / Screen Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.emerald.withValues(alpha: 0.18)
                            : AppColors.mintFixed,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.emerald.withValues(alpha: 0.3)
                              : AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Icon(
                        Iconsax.people,
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
                          AppStrings.membersScreenTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.appTextPrimary,
                          ),
                        ),
                        Text(
                          '${allMembers.length} ${AppStrings.uniqueMembersStat} عبر ${allGroups.length} مجموعات',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.appTextSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Quick Add Member Button
                InkWell(
                  onTap: () => _showAddMemberModal(context, allGroups),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.emerald.withValues(alpha: 0.2)
                          : AppColors.mintFixed,
                      borderRadius: BorderRadius.circular(9),
                      // border: Border.all(
                      //   color: isDark
                      //       ? AppColors.emerald.withValues(alpha: 0.4)
                      //       : AppColors.primary.withValues(alpha: 0.25),
                      // ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          size: 16,
                          color: isDark
                              ? AppColors.mintContainer
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppStrings.addNewMemberQuick,
                          style: TextStyle(
                            fontSize: 12,
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

            const SizedBox(height: 16),

            // 2. Summary KPI Cards
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.cardDark,
                          AppColors.cardDarkElevated,
                        ]
                      : [
                          const Color(0xFFF0FDF4),
                          Colors.white,
                        ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? AppColors.emerald.withValues(alpha: 0.25)
                      : AppColors.emerald.withValues(alpha: 0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Stat 1: Total Members
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.totalMembersStat,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.appTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${allMembers.length}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: context.appTextPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'أعضاء',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: context.appTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 1,
                    height: 36,
                    color: context.appBorder.withValues(alpha: 0.8),
                  ),

                  // Stat 2: Active Groups
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.groupsCoveredStat,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.appTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${allGroups.length}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: context.appTextPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'مجموعات',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: context.appTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    width: 1,
                    height: 36,
                    color: context.appBorder.withValues(alpha: 0.8),
                  ),

                  // Stat 3: Net Outstanding
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.netReceivablesStat,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.appTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.formatSignedCurrency(netReceivables),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: netReceivables > 0
                                  ? AppColors.income
                                  : (netReceivables < 0
                                      ? AppColors.expense
                                      : context.appTextPrimary),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Search Bar
            Container(
              decoration: BoxDecoration(
                color: context.appCardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.appBorder),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: 13, color: context.appTextPrimary),
                decoration: InputDecoration(
                  hintText: AppStrings.searchMembersHint,
                  hintStyle:
                      TextStyle(fontSize: 12, color: context.appTextMuted),
                  prefixIcon: Icon(
                    Iconsax.search_normal,
                    size: 18,
                    color: context.appTextSecondary,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Iconsax.close_circle,
                              size: 18, color: context.appTextMuted),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 4. Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: AppStrings.filterAllMembers,
                    count: allMembers.length,
                    isSelected: _activeFilter == MemberFilterType.all,
                    onTap: () =>
                        setState(() => _activeFilter = MemberFilterType.all),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: AppStrings.filterOwesYou,
                    count: allMembers.where((m) => m.owesUser).length,
                    isSelected: _activeFilter == MemberFilterType.owesYou,
                    selectedColor: AppColors.income,
                    onTap: () => setState(
                        () => _activeFilter = MemberFilterType.owesYou),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: AppStrings.filterYouOwe,
                    count: allMembers.where((m) => m.userOwes).length,
                    isSelected: _activeFilter == MemberFilterType.youOwe,
                    selectedColor: AppColors.expense,
                    onTap: () =>
                        setState(() => _activeFilter = MemberFilterType.youOwe),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: AppStrings.filterBalanced,
                    count: allMembers.where((m) => m.isBalanced).length,
                    isSelected: _activeFilter == MemberFilterType.balanced,
                    onTap: () => setState(
                        () => _activeFilter = MemberFilterType.balanced),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Group Filter selector (if there are groups)
            if (allGroups.length > 1) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildGroupFilterChip(
                      label: 'جميع المجموعات',
                      icon: Iconsax.category,
                      isSelected: _selectedGroupFilter == null,
                      onTap: () => setState(() => _selectedGroupFilter = null),
                    ),
                    const SizedBox(width: 6),
                    ...allGroups.map((g) {
                      final isSelected = _selectedGroupFilter == g.id;
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _buildGroupFilterChip(
                          label: g.name,
                          icon: _getGroupIcon(g.type),
                          isSelected: isSelected,
                          onTap: () => setState(
                            () =>
                                _selectedGroupFilter = isSelected ? null : g.id,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ] else ...[
              const SizedBox(height: 6),
            ],

            // 5. Members List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'قائمة الأعضاء (${filteredMembers.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                ),
                if (_searchController.text.isNotEmpty ||
                    _selectedGroupFilter != null ||
                    _activeFilter != MemberFilterType.all)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _searchController.clear();
                        _selectedGroupFilter = null;
                        _activeFilter = MemberFilterType.all;
                      });
                    },
                    child: Row(
                      spacing: 1,
                      children: [
                        Icon(Icons.close, size: 16, color: Colors.red),
                        Text(
                          'مسح الفلترة',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.red
                              // isDark
                              //     ? AppColors.mintContainer
                              //     : AppColors.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // 6. Member Cards or Empty State
            if (filteredMembers.isEmpty)
              _buildEmptyState(context, isDark, allGroups)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredMembers.length,
                itemBuilder: (context, index) {
                  final member = filteredMembers[index];
                  return ConsolidatedMemberCard(
                    key: ValueKey(member.name),
                    member: member,
                    allGroups: allGroups,
                    onAddToGroup: () => _showAddToOtherGroupModal(
                      context,
                      member,
                      allGroups,
                    ),
                  );
                },
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    Color? selectedColor,
  }) {
    final isDark = context.isDarkMode;
    final primaryColor =
        selectedColor ?? (isDark ? AppColors.mintContainer : AppColors.primary);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? primaryColor.withValues(alpha: 0.22)
                  : primaryColor.withValues(alpha: 0.12))
              : context.appCardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : context.appBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w700,
                color: isSelected ? primaryColor : context.appTextSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.2)
                    : context.appSurfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? primaryColor : context.appTextMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDarkMode;
    final activeColor = isDark ? AppColors.mintContainer : AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.emerald.withValues(alpha: 0.2)
                  : AppColors.mintFixed)
              : context.appSurfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : context.appBorder,
            width: isSelected ? 1.3 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? activeColor : context.appTextSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : context.appTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    List<GroupEntity> allGroups,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: context.appSurfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.user_search,
              size: 28,
              color: context.appTextMuted,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.noMembersFoundTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: context.appTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.noMembersFoundDesc,
            style: TextStyle(
              fontSize: 12,
              color: context.appTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => _showAddMemberModal(context, allGroups),
            icon: const Icon(Iconsax.user_add, size: 18),
            label: Text(
              AppStrings.addNewMemberQuick,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.emerald : AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
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
}
