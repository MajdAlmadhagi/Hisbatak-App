import '../../entities/group_entity.dart';
import '../../entities/expense_split_entity.dart';
import '../../repositories/i_group_repository.dart';

/// [GetGroupsUseCase] retrieves all active groups.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class GetGroupsUseCase {
  final IGroupRepository repository;

  GetGroupsUseCase(this.repository);

  Future<List<GroupEntity>> call() async {
    return await repository.getGroups();
  }
}

/// [GetGroupMembersUseCase] retrieves members and debt balances for a given group.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class GetGroupMembersUseCase {
  final IGroupRepository repository;

  GetGroupMembersUseCase(this.repository);

  Future<List<GroupMemberEntity>> call(String groupId) async {
    return await repository.getGroupMembers(groupId);
  }
}

/// [GetDebtSummaryUseCase] retrieves aggregated debt metrics across all groups.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class GetDebtSummaryUseCase {
  final IGroupRepository repository;

  GetDebtSummaryUseCase(this.repository);

  Future<DebtSummary> call() async {
    return await repository.getAggregatedDebtSummary();
  }
}

/// [AddGroupExpenseUseCase] records a shared bill and updates members' debt balances.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class AddGroupExpenseUseCase {
  final IGroupRepository repository;

  AddGroupExpenseUseCase(this.repository);

  Future<void> call(GroupExpense expense) async {
    return await repository.addGroupExpense(expense);
  }
}

/// [AddGroupUseCase] creates a new group.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class AddGroupUseCase {
  final IGroupRepository repository;

  AddGroupUseCase(this.repository);

  Future<void> call(GroupEntity group) async {
    return await repository.addGroup(group);
  }
}

/// [AddGroupMemberUseCase] registers a new member within a group.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class AddGroupMemberUseCase {
  final IGroupRepository repository;

  AddGroupMemberUseCase(this.repository);

  Future<void> call(GroupMemberEntity member) async {
    return await repository.addGroupMember(member);
  }
}

/// [SettleBalanceUseCase] balances a member debt to zero upon settlement.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class SettleBalanceUseCase {
  final IGroupRepository repository;

  SettleBalanceUseCase(this.repository);

  Future<void> call({required String memberId, required String groupId}) async {
    return await repository.settleMemberBalance(memberId: memberId, groupId: groupId);
  }
}

/// [GetConsolidatedMembersUseCase] retrieves all members grouped across all separated groups.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class GetConsolidatedMembersUseCase {
  final IGroupRepository repository;

  GetConsolidatedMembersUseCase(this.repository);

  Future<List<ConsolidatedMemberEntity>> call() async {
    return await repository.getConsolidatedMembers();
  }
}

/// [GetAllGroupMembersUseCase] retrieves all raw memberships joined with their group data.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class GetAllGroupMembersUseCase {
  final IGroupRepository repository;

  GetAllGroupMembersUseCase(this.repository);

  Future<List<GroupMemberWithGroupEntity>> call() async {
    return await repository.getAllGroupMembers();
  }
}


