import 'dart:convert';
import '../../domain/entities/budget_summary.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/transaction_item.dart';
import '../../domain/entities/user_profile.dart';
import 'formatters.dart';

/// [ReportExporter] builds portable RFC-4180 CSV (with UTF-8 BOM for Arabic Excel)
/// and structured JSON backups from live app state.
class ReportExporter {
  static const String _utf8Bom = '\uFEFF';

  static String _csvCell(Object? value) {
    final raw = value?.toString() ?? '';
    final escaped = raw.replaceAll('"', '""');
    final needsQuotes = escaped.contains(',') ||
        escaped.contains('"') ||
        escaped.contains('\n') ||
        escaped.contains('\r');
    return needsQuotes ? '"$escaped"' : escaped;
  }

  /// Generates a CSV ledger of personal transactions.
  static String buildTransactionsCsv(
    List<TransactionItem> transactions, {
    String currencySymbol = 'ر.س',
  }) {
    final buffer = StringBuffer()..write(_utf8Bom);
    buffer.writeln(
      ['التاريخ', 'العنوان', 'التصنيف', 'النوع', 'المبلغ', 'العملة', 'طريقة الدفع', 'المجموعة']
          .map(_csvCell)
          .join(','),
    );

    for (final tx in transactions) {
      buffer.writeln([
        tx.dateTime.toIso8601String(),
        tx.title,
        tx.category,
        tx.type == TransactionType.income ? 'دخل' : 'مصروف',
        tx.amount.toStringAsFixed(2),
        currencySymbol,
        tx.paymentMethod,
        tx.groupName ?? '-',
      ].map(_csvCell).join(','));
    }

    return buffer.toString();
  }

  /// Generates a CSV report of debt balances across all groups & consolidated members.
  static String buildGroupsSummaryCsv({
    required List<GroupEntity> groups,
    required List<ConsolidatedMemberEntity> members,
    required DebtSummary summary,
    String currencySymbol = 'ر.س',
  }) {
    final buffer = StringBuffer()..write(_utf8Bom);
    buffer.writeln(
      ['البند', 'التفاصيل', 'المبلغ', 'العملة', 'الحالة']
          .map(_csvCell)
          .join(','),
    );
    buffer.writeln([
      'ملخص الديون',
      'لك في ذمة الآخرين (${summary.personsOwingUser} أشخاص)',
      summary.totalOwedToUser.toStringAsFixed(2),
      currencySymbol,
      'لك',
    ].map(_csvCell).join(','));
    buffer.writeln([
      'ملخص الديون',
      'عليك للآخرين (${summary.personsUserOwes} أشخاص)',
      (-summary.totalUserOwes).toStringAsFixed(2),
      currencySymbol,
      'عليك',
    ].map(_csvCell).join(','));
    buffer.writeln([
      'صافي الموقف المالي',
      '${groups.length} مجموعات نشطة',
      summary.netPosition.toStringAsFixed(2),
      currencySymbol,
      summary.netPosition > 0
          ? 'موجب (لك)'
          : (summary.netPosition < 0 ? 'سالب (عليك)' : 'متزن'),
    ].map(_csvCell).join(','));

    buffer.writeln();
    buffer.writeln(
      ['العضو', 'المجموعات', 'صافي الرصيد', 'العملة', 'الحالة']
          .map(_csvCell)
          .join(','),
    );

    for (final member in members) {
      final groupList =
          member.memberships.map((m) => '${m.groupName}: ${Formatters.formatSignedCurrency(m.balance, currencySymbol: currencySymbol)}').join(' | ');
      final status = member.owesUser
          ? 'يَدين لك'
          : (member.userOwes ? 'عليك له' : 'متوازن');
      buffer.writeln([
        member.name,
        groupList,
        member.totalBalance.toStringAsFixed(2),
        currencySymbol,
        status,
      ].map(_csvCell).join(','));
    }

    return buffer.toString();
  }

  /// Generates a structured JSON snapshot of profile, budget, transactions, and groups.
  static String buildFullJsonExport({
    UserProfile? profile,
    BudgetSummary? summary,
    required List<TransactionItem> transactions,
    required List<GroupEntity> groups,
    required List<ConsolidatedMemberEntity> members,
    DebtSummary? debtSummary,
  }) {
    final payload = <String, dynamic>{
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'app_version': '1.0.0',
      if (profile != null)
        'profile': {
          'id': profile.id,
          'full_name': profile.fullName,
          'email': profile.email,
          'currency_code': profile.currencyCode,
          'currency_symbol': profile.currencySymbol,
          'monthly_budget_limit': profile.monthlyBudgetLimit,
          'current_available': profile.currentAvailable,
        },
      if (summary != null)
        'budget_summary': {
          'total_available': summary.totalAvailable,
          'total_spent': summary.totalSpent,
          'budget_limit': summary.budgetLimit,
          'month_trending': summary.monthTrending,
          'remaining_percentage': summary.remainingPercentage,
        },
      if (debtSummary != null)
        'debt_summary': {
          'total_owed_to_user': debtSummary.totalOwedToUser,
          'total_user_owes': debtSummary.totalUserOwes,
          'net_position': debtSummary.netPosition,
        },
      'transactions': transactions
          .map((tx) => {
                'id': tx.id,
                'title': tx.title,
                'amount': tx.amount,
                'category': tx.category,
                'type': tx.type.name,
                'payment_method': tx.paymentMethod,
                'date_time': tx.dateTime.toIso8601String(),
                'group_id': tx.groupId,
                'expense_id': tx.expenseId,
              })
          .toList(),
      'groups': groups
          .map((g) => {
                'id': g.id,
                'name': g.name,
                'type': g.type,
                'member_count': g.memberCount,
                'created_at': g.createdAt.toIso8601String(),
              })
          .toList(),
      'consolidated_members': members
          .map((m) => {
                'name': m.name,
                'total_balance': m.totalBalance,
                'memberships': m.memberships
                    .map((ms) => {
                          'member_id': ms.memberId,
                          'group_id': ms.groupId,
                          'group_name': ms.groupName,
                          'balance': ms.balance,
                          'note': ms.note,
                        })
                    .toList(),
              })
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }
}
