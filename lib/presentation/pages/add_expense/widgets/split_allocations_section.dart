import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/expense_split_entity.dart';
import '../../../widgets/profile_currency_extension.dart';
import 'participants_selector.dart';

/// Renders the participant allocation UI for Equal, Percentage, and Custom
/// split modes cleanly without duplicate row templates.
class SplitAllocationsSection extends StatelessWidget {
  final SplitMethod splitMethod;
  final List<ParticipantUIItem> participants;
  final Set<String> selectedMemberIds;
  final String payerId;
  final double currentAmount;
  final double sharePerPerson;
  final Map<String, double> percentageSplits;
  final Map<String, double> customSplits;
  final ValueChanged<String> onToggleMember;
  final ValueChanged<String> onSelectPayer;
  final VoidCallback onDistributePercentages;
  final VoidCallback onDistributeCustomRemainder;
  final void Function(String memberId, double delta) onAdjustPercentage;
  final void Function(String memberId, double delta) onAdjustCustomAmount;

  const SplitAllocationsSection({
    super.key,
    required this.splitMethod,
    required this.participants,
    required this.selectedMemberIds,
    required this.payerId,
    required this.currentAmount,
    required this.sharePerPerson,
    required this.percentageSplits,
    required this.customSplits,
    required this.onToggleMember,
    required this.onSelectPayer,
    required this.onDistributePercentages,
    required this.onDistributeCustomRemainder,
    required this.onAdjustPercentage,
    required this.onAdjustCustomAmount,
  });

  @override
  Widget build(BuildContext context) {
    switch (splitMethod) {
      case SplitMethod.equal:
        return _buildEqualList(context);
      case SplitMethod.percentage:
        return _buildPercentageList(context);
      case SplitMethod.custom:
        return _buildCustomList(context);
    }
  }

  Widget _buildEqualList(BuildContext context) {
    final isDark = context.isDarkMode;
    final symbol = context.watchCurrencySymbol();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: participants.map((item) {
          final isSelected = selectedMemberIds.contains(item.id);
          final isPayer = item.id == payerId;

          return GestureDetector(
            onTap: () => onToggleMember(item.id),
            child: Container(
              width: 112,
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppColors.cardDark : const Color(0xFFF8FAFC))
                    : (isDark
                        ? AppColors.cardDark.withValues(alpha: 0.4)
                        : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? (isDark ? AppColors.emerald : AppColors.emeraldLight)
                      : context.appBorder.withValues(alpha: 0.5),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: item.avatarColor,
                        child: Text(
                          item.avatarLetter,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.emerald,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Iconsax.tick_circle,
                              size: 8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.isUser
                        ? (isPayer ? 'أنت (الدافع)' : 'أنت')
                        : item.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? context.appTextPrimary
                          : context.appTextSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isSelected
                        ? '${sharePerPerson.toStringAsFixed(2)} $symbol'
                        : 'مستبعد',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? (isDark
                              ? AppColors.mintContainer
                              : AppColors.emerald)
                          : context.appTextMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => onSelectPayer(item.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isPayer
                            ? AppColors.emerald.withValues(alpha: 0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isPayer
                              ? AppColors.emerald
                              : context.appBorder.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        isPayer ? 'الدافع ✓' : 'تعيين كدافع',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight:
                              isPayer ? FontWeight.bold : FontWeight.normal,
                          color: isPayer
                              ? (isDark
                                  ? AppColors.mintContainer
                                  : AppColors.emerald)
                              : context.appTextMuted,
                        ),
                      ),
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

  Widget _buildPercentageList(BuildContext context) {
    final isDark = context.isDarkMode;
    final symbol = context.watchCurrencySymbol();
    final totalPercent = selectedMemberIds.fold(
      0.0,
      (prev, id) => prev + (percentageSplits[id] ?? 0.0),
    );
    final is100Percent = (totalPercent - 100.0).abs() < 0.1;

    return Column(
      children: [
        _AllocationStatusBanner(
          isComplete: is100Percent,
          isError: false,
          message: is100Percent
              ? 'النسبة مكتملة 100%'
              : 'المجموع: ${totalPercent.toStringAsFixed(1)}% (متبقي ${(100 - totalPercent).toStringAsFixed(1)}%)',
          actionLabel: is100Percent ? null : 'توزيع بالتساوي',
          onAction: is100Percent ? null : onDistributePercentages,
        ),
        const SizedBox(height: 8),
        ...participants.map((item) {
          final isSelected = selectedMemberIds.contains(item.id);
          final isPayer = item.id == payerId;
          final currentPct = percentageSplits[item.id] ?? 0.0;
          final memberAmount = currentAmount * currentPct / 100.0;

          return _AllocationMemberRow(
            item: item,
            isSelected: isSelected,
            isPayer: isPayer,
            subtitle: '${memberAmount.toStringAsFixed(2)} $symbol',
            valueLabel: '${currentPct.toStringAsFixed(0)}%',
            valueColor: context.appTextPrimary,
            canDecrement: currentPct > 5,
            canIncrement: currentPct < 95,
            onToggle: () => onToggleMember(item.id),
            onDecrement: () => onAdjustPercentage(item.id, -5),
            onIncrement: () => onAdjustPercentage(item.id, 5),
            isDark: isDark,
          );
        }),
      ],
    );
  }

  Widget _buildCustomList(BuildContext context) {
    final isDark = context.isDarkMode;
    final symbol = context.watchCurrencySymbol();
    final totalAssigned = selectedMemberIds.fold(
      0.0,
      (prev, id) => prev + (customSplits[id] ?? 0.0),
    );
    final remainder = currentAmount - totalAssigned;
    final isMatching = remainder.abs() < 0.05;

    return Column(
      children: [
        _AllocationStatusBanner(
          isComplete: isMatching,
          isError: !isMatching && remainder < 0,
          message: isMatching
              ? 'المبلغ موزع بالكامل (${currentAmount.toStringAsFixed(2)} $symbol)'
              : (remainder > 0
                  ? 'المتبقي: ${remainder.toStringAsFixed(2)} $symbol'
                  : 'فائض: ${(-remainder).toStringAsFixed(2)} $symbol'),
          actionLabel: (!isMatching && remainder > 0) ? 'توزيع المتبقي' : null,
          onAction: (!isMatching && remainder > 0)
              ? onDistributeCustomRemainder
              : null,
        ),
        const SizedBox(height: 8),
        ...participants.map((item) {
          final isSelected = selectedMemberIds.contains(item.id);
          final isPayer = item.id == payerId;
          final currentVal = customSplits[item.id] ?? 0.0;
          final pct =
              currentAmount > 0 ? (currentVal / currentAmount * 100.0) : 0.0;

          return _AllocationMemberRow(
            item: item,
            isSelected: isSelected,
            isPayer: isPayer,
            subtitle: '${pct.toStringAsFixed(1)}% من الفاتورة',
            valueLabel: '${currentVal.toStringAsFixed(0)} $symbol',
            valueColor: isDark ? AppColors.mintContainer : AppColors.emerald,
            canDecrement: currentVal >= 10,
            canIncrement: true,
            onToggle: () => onToggleMember(item.id),
            onDecrement: () => onAdjustCustomAmount(item.id, -10),
            onIncrement: () => onAdjustCustomAmount(item.id, 10),
            isDark: isDark,
          );
        }),
      ],
    );
  }
}

class _AllocationStatusBanner extends StatelessWidget {
  final bool isComplete;
  final bool isError;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _AllocationStatusBanner({
    required this.isComplete,
    required this.isError,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final Color bgColor;
    final Color accentColor;
    final Color textColor;
    final IconData icon;

    if (isComplete) {
      bgColor =
          isDark ? AppColors.emerald.withValues(alpha: 0.15) : AppColors.mintSoft;
      accentColor = AppColors.emerald;
      textColor = isDark ? AppColors.mintContainer : AppColors.emerald;
      icon = Iconsax.tick_circle;
    } else if (isError) {
      bgColor = isDark
          ? AppColors.expense.withValues(alpha: 0.15)
          : AppColors.expenseSoft;
      accentColor = AppColors.expense;
      textColor = AppColors.expense;
      icon = Iconsax.info_circle;
    } else {
      bgColor = isDark
          ? AppColors.warning.withValues(alpha: 0.15)
          : AppColors.warningSoft;
      accentColor = AppColors.warning;
      textColor = isDark ? AppColors.warning : const Color(0xFFB45309);
      icon = Iconsax.warning_2;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, size: 16, color: accentColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emerald,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AllocationMemberRow extends StatelessWidget {
  final ParticipantUIItem item;
  final bool isSelected;
  final bool isPayer;
  final String subtitle;
  final String valueLabel;
  final Color valueColor;
  final bool canDecrement;
  final bool canIncrement;
  final VoidCallback onToggle;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool isDark;

  const _AllocationMemberRow({
    required this.item,
    required this.isSelected,
    required this.isPayer,
    required this.subtitle,
    required this.valueLabel,
    required this.valueColor,
    required this.canDecrement,
    required this.canIncrement,
    required this.onToggle,
    required this.onDecrement,
    required this.onIncrement,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? AppColors.cardDark : const Color(0xFFF8FAFC))
            : (isDark
                ? AppColors.cardDark.withValues(alpha: 0.3)
                : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? (isDark ? AppColors.emerald : AppColors.emeraldLight)
              : context.appBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              isSelected ? Iconsax.tick_square : Iconsax.close_square,
              size: 18,
              color: isSelected ? AppColors.emerald : context.appTextMuted,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 13,
            backgroundColor: item.avatarColor,
            child: Text(
              item.avatarLetter,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.isUser
                      ? (isPayer ? 'أنت (الدافع)' : 'أنت')
                      : item.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? context.appTextPrimary
                        : context.appTextMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isSelected)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.mintContainer
                          : AppColors.emerald,
                    ),
                  ),
              ],
            ),
          ),
          if (isSelected)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Iconsax.minus_cirlce, size: 18),
                  color: context.appTextSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: canDecrement ? onDecrement : null,
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.appSurfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    valueLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Iconsax.add_circle, size: 18),
                  color: context.appTextSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: canIncrement ? onIncrement : null,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
