import 'package:equatable/equatable.dart';

/// [GroupEntity] represents a bill splitting group (e.g. Work colleagues, Youth Apartment, Abha Trip).
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class GroupEntity extends Equatable {
  final String id;
  final String name;
  final String type; // 'work', 'home', 'trip', 'other'
  final String iconName;
  final int memberCount;
  final DateTime createdAt;

  const GroupEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.iconName,
    required this.memberCount,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, type, iconName, memberCount, createdAt];
}

/// [GroupMemberEntity] captures member identity, debt/credit balance, and recent activity notes.
class GroupMemberEntity extends Equatable {
  final String id;
  final String groupId;
  final String name;
  final String? avatarUrl;
  final double balance; // > 0: owes user (يَدين لك), < 0: user owes them (أنت مدين لها), == 0: balanced
  final String? note;
  final String? lastActivity;

  const GroupMemberEntity({
    required this.id,
    required this.groupId,
    required this.name,
    this.avatarUrl,
    required this.balance,
    this.note,
    this.lastActivity,
  });

  bool get owesUser => balance > 0;
  bool get userOwes => balance < 0;
  bool get isBalanced => balance == 0;

  @override
  List<Object?> get props => [id, groupId, name, avatarUrl, balance, note, lastActivity];
}

/// [DebtSummary] summarizes aggregated group balances across all members.
class DebtSummary extends Equatable {
  final double totalOwedToUser; // لك في ذمة الآخرين
  final int personsOwingUser;   // من شخصين
  final double totalUserOwes;   // عليك للآخرين
  final int personsUserOwes;    // لشخص واحد
  final double netPosition;     // صافي الموقف المالي

  const DebtSummary({
    required this.totalOwedToUser,
    required this.personsOwingUser,
    required this.totalUserOwes,
    required this.personsUserOwes,
    required this.netPosition,
  });

  @override
  List<Object?> get props => [
        totalOwedToUser,
        personsOwingUser,
        totalUserOwes,
        personsUserOwes,
        netPosition,
      ];
}

/// [GroupMemberWithGroupEntity] represents a member joined with their group information.
class GroupMemberWithGroupEntity extends Equatable {
  final String id;
  final String groupId;
  final String groupName;
  final String groupType;
  final String groupIcon;
  final String name;
  final String? avatarUrl;
  final double balance;
  final String? note;
  final String? lastActivity;

  const GroupMemberWithGroupEntity({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.groupType,
    required this.groupIcon,
    required this.name,
    this.avatarUrl,
    required this.balance,
    this.note,
    this.lastActivity,
  });

  bool get owesUser => balance > 0;
  bool get userOwes => balance < 0;
  bool get isBalanced => balance == 0;

  @override
  List<Object?> get props => [
        id,
        groupId,
        groupName,
        groupType,
        groupIcon,
        name,
        avatarUrl,
        balance,
        note,
        lastActivity,
      ];
}

/// [MemberGroupMembership] holds details of a specific member's belonging to a particular group.
class MemberGroupMembership extends Equatable {
  final String memberId;
  final String groupId;
  final String groupName;
  final String groupType;
  final String groupIcon;
  final double balance;
  final String? note;
  final String? lastActivity;

  const MemberGroupMembership({
    required this.memberId,
    required this.groupId,
    required this.groupName,
    required this.groupType,
    required this.groupIcon,
    required this.balance,
    this.note,
    this.lastActivity,
  });

  bool get owesUser => balance > 0.01;
  bool get userOwes => balance < -0.01;
  bool get isBalanced => !owesUser && !userOwes;

  @override
  List<Object?> get props => [
        memberId,
        groupId,
        groupName,
        groupType,
        groupIcon,
        balance,
        note,
        lastActivity,
      ];
}

/// [ConsolidatedMemberEntity] consolidates a member person across multiple groups.
///
/// Tracks all group memberships, aggregated balance, and available groups to join.
class ConsolidatedMemberEntity extends Equatable {
  final String name;
  final String? avatarUrl;
  final List<MemberGroupMembership> memberships;

  const ConsolidatedMemberEntity({
    required this.name,
    this.avatarUrl,
    required this.memberships,
  });

  double get totalBalance =>
      memberships.fold(0.0, (sum, m) => sum + m.balance);

  bool get owesUser => totalBalance > 0.01;
  bool get userOwes => totalBalance < -0.01;
  bool get isBalanced => !owesUser && !userOwes;

  int get groupsCount => memberships.length;

  List<String> get groupNames =>
      memberships.map((m) => m.groupName).toList();

  bool isInGroup(String groupId) =>
      memberships.any((m) => m.groupId == groupId);

  List<GroupEntity> availableGroups(List<GroupEntity> allGroups) {
    return allGroups.where((g) => !isInGroup(g.id)).toList();
  }

  @override
  List<Object?> get props => [name, avatarUrl, memberships];
}

