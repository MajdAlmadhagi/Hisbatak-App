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
