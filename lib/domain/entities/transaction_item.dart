import 'package:equatable/equatable.dart';

enum TransactionType { expense, income }

/// [TransactionItem] represents a personal financial transaction.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
/// Encapsulates transaction domain entity data.
class TransactionItem extends Equatable {
  final String id;
  final String title;
  final double amount;
  final String category;
  final String categoryIcon;
  final String paymentMethod;
  final DateTime dateTime;
  final TransactionType type;
  final String? groupId;
  final String? expenseId;
  final String? groupName;
  final List<String> memberNames;
  final bool isSynced;

  const TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.categoryIcon,
    required this.paymentMethod,
    required this.dateTime,
    required this.type,
    this.groupId,
    this.expenseId,
    this.groupName,
    this.memberNames = const [],
    required this.isSynced,
  });

  bool get isExpense => type == TransactionType.expense;
  bool get hasGroup =>
      (groupName != null && groupName!.isNotEmpty) ||
      (groupId != null && groupId!.isNotEmpty);

  TransactionItem copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    String? categoryIcon,
    String? paymentMethod,
    DateTime? dateTime,
    TransactionType? type,
    String? groupId,
    String? expenseId,
    String? groupName,
    List<String>? memberNames,
    bool? isSynced,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      dateTime: dateTime ?? this.dateTime,
      type: type ?? this.type,
      groupId: groupId ?? this.groupId,
      expenseId: expenseId ?? this.expenseId,
      groupName: groupName ?? this.groupName,
      memberNames: memberNames ?? this.memberNames,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        amount,
        category,
        categoryIcon,
        paymentMethod,
        dateTime,
        type,
        groupId,
        expenseId,
        groupName,
        memberNames,
        isSynced,
      ];
}
