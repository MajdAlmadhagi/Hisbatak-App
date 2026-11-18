import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/transaction_item.dart';

/// Displays structured metadata rows (date, category, payment method, group,
/// participants, and local persistence status) for a [TransactionItem].
class TransactionInfoCard extends StatelessWidget {
  final TransactionItem item;

  const TransactionInfoCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        children: [
          _TransactionDetailRow(
            icon: Iconsax.calendar_1,
            label: AppStrings.transactionDate,
            value: Formatters.formatArabicDate(item.dateTime),
          ),
          Divider(color: context.appBorder, height: 16),
          _TransactionDetailRow(
            icon: Iconsax.category,
            label: AppStrings.transactionCategory,
            value: item.category,
          ),
          Divider(color: context.appBorder, height: 16),
          _TransactionDetailRow(
            icon: Iconsax.card,
            label: AppStrings.paymentMethodLabel,
            value: item.paymentMethod,
          ),
          if (item.hasGroup) ...[
            Divider(color: context.appBorder, height: 16),
            _TransactionDetailRow(
              icon: Iconsax.profile_2user,
              label: AppStrings.transactionGroup,
              value: item.groupName!,
            ),
          ],
          if (item.memberNames.isNotEmpty) ...[
            Divider(color: context.appBorder, height: 16),
            _ParticipantsSection(memberNames: item.memberNames),
          ],
          Divider(color: context.appBorder, height: 16),
          _TransactionDetailRow(
            icon: Iconsax.shield_tick,
            label: 'حالة الحفظ',
            value: AppStrings.safeRecord,
            valueColor: isDark ? AppColors.mintContainer : AppColors.emerald,
          ),
        ],
      ),
    );
  }
}

class _TransactionDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _TransactionDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.appTextSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: context.appTextSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? context.appTextPrimary,
          ),
        ),
      ],
    );
  }
}

class _ParticipantsSection extends StatelessWidget {
  final List<String> memberNames;

  const _ParticipantsSection({required this.memberNames});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Iconsax.people, size: 18, color: context.appTextSecondary),
            const SizedBox(width: 10),
            Text(
              'المشاركون بالعملية',
              style: TextStyle(fontSize: 13, color: context.appTextSecondary),
            ),
            const Spacer(),
            Text(
              '${memberNames.length} أعضاء',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.mintContainer : AppColors.emerald,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: memberNames.map((name) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.cardDarkElevated : AppColors.mintSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppColors.emerald.withValues(alpha: 0.3)
                      : const Color(0xFF6CF8BB),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 9,
                    backgroundColor:
                        isDark ? AppColors.emerald : AppColors.primary,
                    child: Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: context.appTextPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
