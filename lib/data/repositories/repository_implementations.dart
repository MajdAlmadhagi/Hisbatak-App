import '../../domain/entities/budget_summary.dart';
import '../../domain/entities/expense_split_entity.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/transaction_item.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/i_budget_repository.dart';
import '../../domain/repositories/i_group_repository.dart';
import '../../domain/repositories/i_profile_repository.dart';
import '../datasources/auth/auth_local_data_source.dart';
import '../datasources/local_datasources.dart';
import '../datasources/preferences/app_preferences_data_source.dart';
import '../../core/utils/validators.dart';
import '../models/app_models.dart';

/// SOLID Principle: Dependency Inversion Principle (DIP) & Liskov Substitution Principle (LSP)
/// [ProfileRepositoryImpl] implements [IProfileRepository] using injected [IProfileLocalDataSource]
/// for SQLite business data and [IAppPreferencesDataSource] for SharedPreferences UI/device state.
class ProfileRepositoryImpl implements IProfileRepository {
  final IProfileLocalDataSource localDataSource;
  final IAppPreferencesDataSource preferencesDataSource;
  final IAuthLocalDataSource? authLocalDataSource;

  ProfileRepositoryImpl({
    required this.localDataSource,
    required this.preferencesDataSource,
    this.authLocalDataSource,
  });

  @override
  Future<UserProfile> getUserProfile() async {
    final profile = await localDataSource.getUserProfile();
    final isDark = await preferencesDataSource.isDarkMode();
    final biometric = await preferencesDataSource.isBiometricEnabled();
    return profile.copyWith(
      isDarkMode: isDark,
      biometricEnabled: biometric,
    );
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    final model = UserProfileModel(
      id: profile.id,
      fullName: profile.fullName,
      email: profile.email,
      phoneE164: profile.phoneE164,
      currencyCode: profile.currencyCode,
      currencySymbol: profile.currencySymbol,
      monthlyBudgetLimit: profile.monthlyBudgetLimit,
      currentAvailable: profile.currentAvailable,
      biometricEnabled: profile.biometricEnabled,
      isDarkMode: profile.isDarkMode,
      isConfigured: profile.isConfigured,
    );
    await localDataSource.saveUserProfile(model);
    if (profile.isConfigured) {
      await preferencesDataSource.setDarkMode(profile.isDarkMode);
      await preferencesDataSource.setBiometricEnabled(profile.biometricEnabled);
    }
  }

  @override
  Future<void> updateBiometricSetting(bool enabled) async {
    await preferencesDataSource.setBiometricEnabled(enabled);
  }

  @override
  Future<void> updateDarkModeSetting(bool isDark) async {
    await preferencesDataSource.setDarkMode(isDark);
  }

  @override
  Future<bool> isDarkMode() async {
    return await preferencesDataSource.isDarkMode();
  }

  @override
  Future<bool> isBiometricEnabled() async {
    return await preferencesDataSource.isBiometricEnabled();
  }

  @override
  Future<void> resetAllData() async {
    await localDataSource.clearAllData();
    await preferencesDataSource.clearAllPreferences();
    await authLocalDataSource?.clearSession();
  }

  @override
  Future<bool> hasSeenOnboarding() async {
    return await preferencesDataSource.hasSeenOnboarding();
  }

  @override
  Future<void> setOnboardingCompleted() async {
    await preferencesDataSource.setOnboardingCompleted(completed: true);
  }
}

/// SOLID Principle: Dependency Inversion Principle (DIP)
/// [BudgetRepositoryImpl] implements [IBudgetRepository] with real SQLite aggregations.
class BudgetRepositoryImpl implements IBudgetRepository {
  final IBudgetLocalDataSource localDataSource;
  final IProfileLocalDataSource profileDataSource;

  BudgetRepositoryImpl({
    required this.localDataSource,
    required this.profileDataSource,
  });

  @override
  Future<BudgetSummary> getBudgetSummary() async {
    final profile = await profileDataSource.getUserProfile();
    final now = DateTime.now();
    final monthlySpent = await localDataSource.getMonthlyExpensesTotal(month: now);
    final monthlyIncome = await localDataSource.getMonthlyIncomeTotal(month: now);
    final categories =
        await localDataSource.getMonthlyCategoryExpenses(month: now);

    final available = profile.currentAvailable;
    final limit = profile.monthlyBudgetLimit;
    final remainingPercent = limit > 0
        ? (((limit - monthlySpent) / limit) * 100.0).clamp(0.0, 100.0)
        : 0.0;
    final monthTrending = monthlyIncome - monthlySpent;

    return BudgetSummary(
      totalAvailable: available,
      totalSpent: monthlySpent,
      budgetLimit: limit,
      monthTrending: monthTrending,
      remainingPercentage: double.parse(remainingPercent.toStringAsFixed(1)),
      categories: categories,
    );
  }

  @override
  Future<List<TransactionItem>> getRecentTransactions({int limit = 10}) async {
    return await localDataSource.getTransactions(limit: limit);
  }

  @override
  Future<List<TransactionItem>> getAllTransactions() async {
    return await localDataSource.getTransactions(limit: null);
  }

  @override
  Future<void> addTransaction(TransactionItem transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    await localDataSource.addTransaction(model);
  }

  @override
  Future<void> updateTransaction(TransactionItem transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    await localDataSource.updateTransaction(model);
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    await localDataSource.deleteTransaction(transactionId);
  }
}

/// SOLID Principle: Dependency Inversion Principle (DIP)
/// [GroupRepositoryImpl] implements [IGroupRepository].
class GroupRepositoryImpl implements IGroupRepository {
  final IGroupLocalDataSource localDataSource;

  GroupRepositoryImpl(this.localDataSource);

  @override
  Future<List<GroupEntity>> getGroups() async {
    return await localDataSource.getGroups();
  }

  @override
  Future<GroupEntity?> getGroupById(String groupId) async {
    return await localDataSource.getGroupById(groupId);
  }

  @override
  Future<List<GroupMemberEntity>> getGroupMembers(String groupId) async {
    return await localDataSource.getGroupMembers(groupId);
  }

  @override
  Future<DebtSummary> getAggregatedDebtSummary() async {
    final groups = await localDataSource.getGroups();
    double totalOwedToUser = 0.0;
    int personsOwing = 0;
    double totalUserOwes = 0.0;
    int personsOwed = 0;

    for (final g in groups) {
      final members = await localDataSource.getGroupMembers(g.id);
      for (final m in members) {
        if (m.balance > 0) {
          totalOwedToUser += m.balance;
          personsOwing++;
        } else if (m.balance < 0) {
          totalUserOwes += m.balance.abs();
          personsOwed++;
        }
      }
    }

    final net = totalOwedToUser - totalUserOwes;

    return DebtSummary(
      totalOwedToUser: totalOwedToUser,
      personsOwingUser: personsOwing,
      totalUserOwes: totalUserOwes,
      personsUserOwes: personsOwed,
      netPosition: net,
    );
  }

  @override
  Future<void> addGroup(GroupEntity group) async {
    final model = GroupModel(
      id: group.id,
      name: group.name,
      type: group.type,
      iconName: group.iconName,
      memberCount: group.memberCount,
      createdAt: group.createdAt,
    );
    await localDataSource.addGroup(model);
  }

  @override
  Future<void> addGroupMember(GroupMemberEntity member) async {
    final model = GroupMemberModel(
      id: member.id,
      groupId: member.groupId,
      name: member.name,
      avatarUrl: member.avatarUrl,
      phoneE164: member.phoneE164,
      linkedUserId: member.linkedUserId,
      balance: member.balance,
      note: member.note,
      lastActivity: member.lastActivity,
    );
    await localDataSource.addGroupMember(model);
  }

  @override
  Future<void> addGroupExpense(GroupExpense expense) async {
    await localDataSource.addGroupExpense(expense);
  }

  @override
  Future<void> settleMemberBalance({
    required String memberId,
    required String groupId,
  }) async {
    await localDataSource.settleMemberBalance(memberId, groupId);
  }

  @override
  Future<List<GroupMemberWithGroupEntity>> getAllGroupMembers() async {
    return await localDataSource.getAllGroupMembers();
  }

  @override
  Future<List<ConsolidatedMemberEntity>> getConsolidatedMembers() async {
    final rawMembers = await localDataSource.getAllGroupMembers();
    final Map<String, List<GroupMemberWithGroupEntity>> grouped = {};

    for (final member in rawMembers) {
      final linkedId = member.linkedUserId?.trim();
      final normalizedPhone = Validators.tryNormalizePhoneE164(member.phoneE164);
      final key = (linkedId != null && linkedId.isNotEmpty)
          ? 'uid:$linkedId'
          : (normalizedPhone != null
              ? 'phone:$normalizedPhone'
              : 'name:${member.name.trim().toLowerCase()}');
      grouped.putIfAbsent(key, () => []).add(member);
    }

    final List<ConsolidatedMemberEntity> consolidated = [];
    grouped.forEach((_, items) {
      String? phoneE164;
      String? linkedUserId;
      String? avatarUrl;
      for (final item in items) {
        phoneE164 ??= Validators.tryNormalizePhoneE164(item.phoneE164) ??
            (item.phoneE164?.trim().isNotEmpty == true
                ? item.phoneE164!.trim()
                : null);
        linkedUserId ??= item.linkedUserId?.trim().isNotEmpty == true
            ? item.linkedUserId!.trim()
            : null;
        avatarUrl ??= item.avatarUrl;
      }

      final memberships = items
          .map((item) => MemberGroupMembership(
                memberId: item.id,
                groupId: item.groupId,
                groupName: item.groupName,
                groupType: item.groupType,
                groupIcon: item.groupIcon,
                balance: item.balance,
                note: item.note,
                lastActivity: item.lastActivity,
              ))
          .toList();

      consolidated.add(ConsolidatedMemberEntity(
        name: items.first.name.trim(),
        avatarUrl: avatarUrl,
        phoneE164: phoneE164,
        linkedUserId: linkedUserId,
        memberships: memberships,
      ));
    });

    return consolidated;
  }
}
