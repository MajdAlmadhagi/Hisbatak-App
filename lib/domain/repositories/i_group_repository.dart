import '../entities/group_entity.dart';
import '../entities/expense_split_entity.dart';

/// [IGroupRepository] defines collaborative bill splitting, member debts, and settlements.
///
/// SOLID Principles:
/// - Interface Segregation Principle (ISP): Granular contract for group calculations.
/// - Dependency Inversion Principle (DIP): Clean interface isolating business operations from SQLite.
abstract class IGroupRepository {
  Future<List<GroupEntity>> getGroups();
  Future<GroupEntity?> getGroupById(String groupId);
  Future<List<GroupMemberEntity>> getGroupMembers(String groupId);
  Future<DebtSummary> getAggregatedDebtSummary();
  Future<void> addGroup(GroupEntity group);
  Future<void> addGroupExpense(GroupExpense expense);
  Future<void> settleMemberBalance({required String memberId, required String groupId});
}
