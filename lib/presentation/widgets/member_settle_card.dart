import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/group_entity.dart';

/// [MemberSettleCard] renders individual group member settlement cards matching Screen 3.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class MemberSettleCard extends StatelessWidget {
  final GroupMemberEntity member;
  final VoidCallback? onSettle;

  const MemberSettleCard({
    super.key,
    required this.member,
    this.onSettle,
  });

  @override
  Widget build(BuildContext context) {
    final owesUser = member.owesUser;
    final userOwes = member.userOwes;
    final isBalanced = member.isBalanced;
    final isDark = context.isDarkMode;

    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    if (owesUser) {
      badgeBg = isDark ? AppColors.emerald.withValues(alpha: 0.25) : AppColors.mintFixed;
      badgeText = isDark ? AppColors.mintContainer : const Color(0xFF005236);
      badgeLabel = 'لك';
    } else if (userOwes) {
      badgeBg = isDark ? const Color(0xFF3B1219) : const Color(0xFFFFE4E6);
      badgeText = isDark ? const Color(0xFFF87171) : AppColors.expense;
      badgeLabel = 'عليك';
    } else {
      badgeBg = context.appSurfaceVariant;
      badgeText = context.appTextSecondary;
      badgeLabel = 'متعادل';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: context.appSurfaceVariant,
                child: Text(
                  member.name.isNotEmpty ? member.name[0] : '?',
                  style: TextStyle(fontWeight: FontWeight.bold, color: context.appTextPrimary),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: owesUser ? AppColors.income : (userOwes ? AppColors.expense : AppColors.outline),
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? AppColors.cardDarkElevated : Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Member Info & Debt Amount
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: badgeText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (owesUser)
                  Text(
                    '${AppStrings.heOwesYou} ${Formatters.formatCurrency(member.balance)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.mintContainer : AppColors.income,
                    ),
                  )
                else if (userOwes)
                  Text(
                    '${AppStrings.youOweHer} ${Formatters.formatCurrency(member.balance.abs())}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFF87171) : AppColors.expense,
                    ),
                  )
                else
                  Text(
                    AppStrings.balancedAccount,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.appTextSecondary,
                    ),
                  ),
                const SizedBox(height: 2),
                if (member.note != null || member.lastActivity != null)
                  Text(
                    '${member.note ?? ''} • ${member.lastActivity ?? ''}',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.appTextMuted,
                    ),
                  ),
              ],
            ),
          ),

          // Settle Action Button
          if (!isBalanced)
            InkWell(
              onTap: onSettle,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.appSurfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.handshake_outlined, size: 14, color: context.appTextPrimary),
                    const SizedBox(width: 4),
                    Text(
                      AppStrings.settleAccount,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.appTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
