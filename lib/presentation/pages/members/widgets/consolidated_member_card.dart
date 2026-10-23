import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/group_entity.dart';

/// [ConsolidatedMemberCard] displays an individual member with their cross-group memberships,
/// overall net balance, and an action button to add them to other groups.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class ConsolidatedMemberCard extends StatelessWidget {
  final ConsolidatedMemberEntity member;
  final List<GroupEntity> allGroups;
  final VoidCallback onAddToGroup;

  const ConsolidatedMemberCard({
    super.key,
    required this.member,
    required this.allGroups,
    required this.onAddToGroup,
  });

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

  Color _getAvatarGradientColor(String name) {
    final colors = [
      const Color(0xFF10B981), // Emerald
      const Color(0xFF0D9488), // Teal
      const Color(0xFF0284C7), // Sky Blue
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFFF59E0B), // Amber
    ];
    final hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final owesUser = member.owesUser;
    final userOwes = member.userOwes;
    final isBalanced = member.isBalanced;
    final availableGroups = member.availableGroups(allGroups);
    final canAddToMoreGroups = availableGroups.isNotEmpty;
    final primaryAvatarColor = _getAvatarGradientColor(member.name);

    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    if (owesUser) {
      badgeBg = isDark
          ? AppColors.emerald.withValues(alpha: 0.22)
          : AppColors.mintFixed;
      badgeText = isDark ? AppColors.mintContainer : const Color(0xFF005236);
      badgeLabel = 'يَدين لك';
    } else if (userOwes) {
      badgeBg = isDark ? const Color(0xFF3B1219) : const Color(0xFFFFE4E6);
      badgeText = isDark ? const Color(0xFFF87171) : AppColors.expense;
      badgeLabel = 'عليك له';
    } else {
      badgeBg = context.appSurfaceVariant;
      badgeText = context.appTextSecondary;
      badgeLabel = 'متوازن';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Member Profile & Net Balance Row
          Row(
            children: [
              // Avatar with gradient accent
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryAvatarColor,
                      primaryAvatarColor.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryAvatarColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    member.name.trim().isNotEmpty ? member.name.trim()[0] : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name & Groups Count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: context.appTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.groupsCount == 1
                          ? 'مساهم في مجموعة واحدة'
                          : 'مساهم في ${member.groupsCount} مجموعات',
                      style: TextStyle(
                        fontSize: 11.8,
                        color: context.appTextMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Balance Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: owesUser
                        ? (isDark
                            ? AppColors.emerald.withValues(alpha: 0.4)
                            : AppColors.income.withValues(alpha: 0.2))
                        : (userOwes
                            ? (isDark
                                ? AppColors.expense.withValues(alpha: 0.4)
                                : AppColors.expense.withValues(alpha: 0.2))
                            : context.appBorder),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      isBalanced
                          ? '0 ر.س'
                          : Formatters.formatSignedCurrency(
                              member.totalBalance),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: badgeText,
                      ),
                    ),
                    Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: badgeText.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. Groups Chips Row
          Text(
            'المجموعات المسجل بها :',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: context.appTextPrimary,
            ),
          ),
          const SizedBox(height: 6),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: member.memberships.map((m) {
              final owesInGroup = m.owesUser;
              final userOwesInGroup = m.userOwes;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: context.appSurfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.appBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getGroupIcon(m.groupType),
                      size: 13,
                      color: context.appTextSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      m.groupName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.appTextPrimary,
                      ),
                    ),
                    if (!m.isBalanced) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(${Formatters.formatSignedCurrency(m.balance)})',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: owesInGroup
                              ? AppColors.income
                              : (userOwesInGroup
                                  ? AppColors.expense
                                  : context.appTextMuted),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),
          Divider(color: context.appBorder.withValues(alpha: 0.7), height: 1),
          const SizedBox(height: 10),

          // 3. Quick Action: Add To Another Group Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (member.memberships
                  .any((m) => m.note != null && m.note!.isNotEmpty)) ...[
                Text(
                  ' الفاتورة : ',
                  style: TextStyle(
                    fontSize: 10.6,
                    fontWeight: FontWeight.w700,
                    color: context.appTextPrimary,
                  ),
                ),
                Expanded(
                  child: Text(
                    member.memberships.firstWhere((m) => m.note != null).note ??
                        '',
                    style: TextStyle(
                      fontSize: 10.6,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              ] else
                const Spacer(),
              if (canAddToMoreGroups)
                InkWell(
                  onTap: onAddToGroup,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.emerald.withValues(alpha: 0.16)
                          : AppColors.mintFixed,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? AppColors.emerald.withValues(alpha: 0.4)
                            : AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.user_add,
                          size: 15,
                          color: isDark
                              ? AppColors.mintContainer
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppStrings.addToAnotherGroup,
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
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: context.appSurfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.tick_circle,
                          size: 13, color: AppColors.income),
                      const SizedBox(width: 5),
                      Text(
                        AppStrings.memberAlreadyInAll,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
