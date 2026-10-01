import 'package:equatable/equatable.dart';

enum SplitMethod { equal, percentage, custom }

/// [ParticipantSplit] represents each member's computed share of an expense.
class ParticipantSplit extends Equatable {
  final String memberId;
  final String memberName;
  final double amount;
  final double percentage;
  final bool isPayer;

  const ParticipantSplit({
    required this.memberId,
    required this.memberName,
    required this.amount,
    required this.percentage,
    this.isPayer = false,
  });

  ParticipantSplit copyWith({
    String? memberId,
    String? memberName,
    double? amount,
    double? percentage,
    bool? isPayer,
  }) {
    return ParticipantSplit(
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
      isPayer: isPayer ?? this.isPayer,
    );
  }

  @override
  List<Object?> get props => [memberId, memberName, amount, percentage, isPayer];
}

/// [GroupExpense] represents an added expense to be saved and split.
class GroupExpense extends Equatable {
  final String id;
  final String groupId;
  final String title;
  final double totalAmount;
  final String payerId;
  final String payerName;
  final String category;
  final SplitMethod splitMethod;
  final List<ParticipantSplit> splits;
  final DateTime dateTime;

  const GroupExpense({
    required this.id,
    required this.groupId,
    required this.title,
    required this.totalAmount,
    required this.payerId,
    required this.payerName,
    required this.category,
    required this.splitMethod,
    required this.splits,
    required this.dateTime,
  });

  @override
  List<Object?> get props => [
        id,
        groupId,
        title,
        totalAmount,
        payerId,
        payerName,
        category,
        splitMethod,
        splits,
        dateTime,
      ];
}

/// SOLID Principle: Strategy Pattern & Open/Closed Principle (OCP)
/// [ISplitCalculationStrategy] allows adding new splitting algorithms without modifying existing logic.
abstract class ISplitCalculationStrategy {
  List<ParticipantSplit> calculateSplits({
    required double totalAmount,
    required List<String> memberIds,
    required Map<String, String> memberNames,
    required String payerId,
    Map<String, double>? customValues,
  });
}

/// Strategy for equal splitting (بالتساوي)
class EqualSplitStrategy implements ISplitCalculationStrategy {
  @override
  List<ParticipantSplit> calculateSplits({
    required double totalAmount,
    required List<String> memberIds,
    required Map<String, String> memberNames,
    required String payerId,
    Map<String, double>? customValues,
  }) {
    if (memberIds.isEmpty) return [];
    final count = memberIds.length;
    final share = (totalAmount / count);
    final percent = 100.0 / count;

    return memberIds.map((id) {
      return ParticipantSplit(
        memberId: id,
        memberName: memberNames[id] ?? id,
        amount: share,
        percentage: percent,
        isPayer: id == payerId,
      );
    }).toList();
  }
}

/// Strategy for percentage splitting (بالنسبة %)
class PercentageSplitStrategy implements ISplitCalculationStrategy {
  @override
  List<ParticipantSplit> calculateSplits({
    required double totalAmount,
    required List<String> memberIds,
    required Map<String, String> memberNames,
    required String payerId,
    Map<String, double>? customValues,
  }) {
    if (memberIds.isEmpty) return [];
    return memberIds.map((id) {
      final pct = customValues?[id] ?? (100.0 / memberIds.length);
      final share = (totalAmount * (pct / 100.0));
      return ParticipantSplit(
        memberId: id,
        memberName: memberNames[id] ?? id,
        amount: share,
        percentage: pct,
        isPayer: id == payerId,
      );
    }).toList();
  }
}
