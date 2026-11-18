import '../../domain/entities/user_profile.dart';
import '../../domain/entities/transaction_item.dart';
import '../../domain/entities/group_entity.dart';

/// SOLID Principle: Liskov Substitution Principle (LSP)
/// [UserProfileModel] extends [UserProfile] and can substitute it anywhere seamlessly.
class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.fullName,
    required super.email,
    super.phoneE164,
    required super.currencyCode,
    required super.currencySymbol,
    required super.monthlyBudgetLimit,
    required super.currentAvailable,
    required super.biometricEnabled,
    required super.isDarkMode,
    required super.isConfigured,
  });

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      email: map['email'] as String,
      phoneE164: map['phone_e164'] as String?,
      currencyCode: map['currency_code'] as String,
      currencySymbol: map['currency_symbol'] as String,
      monthlyBudgetLimit: (map['monthly_budget_limit'] as num).toDouble(),
      currentAvailable: (map['current_available'] as num).toDouble(),
      biometricEnabled: (map['biometric_enabled'] as int) == 1,
      isDarkMode: (map['is_dark_mode'] as int) == 1,
      isConfigured: (map['is_configured'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_e164': phoneE164,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'monthly_budget_limit': monthlyBudgetLimit,
      'current_available': currentAvailable,
      'biometric_enabled': biometricEnabled ? 1 : 0,
      'is_dark_mode': isDarkMode ? 1 : 0,
      'is_configured': isConfigured ? 1 : 0,
    };
  }
}

/// [TransactionModel] extends [TransactionItem] with SQLite serializations.
class TransactionModel extends TransactionItem {
  const TransactionModel({
    required super.id,
    required super.title,
    required super.amount,
    required super.category,
    required super.categoryIcon,
    required super.paymentMethod,
    required super.dateTime,
    required super.type,
    super.groupId,
    super.expenseId,
    super.groupName,
    super.memberNames = const [],
    required super.isSynced,
  });

  factory TransactionModel.fromEntity(TransactionItem item) {
    return TransactionModel(
      id: item.id,
      title: item.title,
      amount: item.amount,
      category: item.category,
      categoryIcon: item.categoryIcon,
      paymentMethod: item.paymentMethod,
      dateTime: item.dateTime,
      type: item.type,
      groupId: item.groupId,
      expenseId: item.expenseId,
      groupName: item.groupName,
      memberNames: item.memberNames,
      isSynced: item.isSynced,
    );
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    List<String> members = [];
    if (map['member_names'] != null &&
        (map['member_names'] as String).trim().isNotEmpty) {
      members = (map['member_names'] as String)
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return TransactionModel(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      categoryIcon: map['category_icon'] as String,
      paymentMethod: map['payment_method'] as String,
      // Stored in UTC; shown in the device's time zone.
      dateTime: DateTime.parse(map['date_time'] as String).toLocal(),
      type: (map['type'] == 'income')
          ? TransactionType.income
          : TransactionType.expense,
      groupId: map['group_id'] as String?,
      expenseId: map['expense_id'] as String?,
      groupName: map['group_name'] as String?,
      memberNames: members,
      isSynced: (map['is_synced'] as int) == 1,
    );
  }

  /// Normalized table columns; group_name and member_names are resolved live via JOINs.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'category_icon': categoryIcon,
      'payment_method': paymentMethod,
      'date_time': dateTime.toUtc().toIso8601String(),
      'type': (type == TransactionType.income) ? 'income' : 'expense',
      'group_id': groupId,
      'expense_id': expenseId,
      'is_synced': isSynced ? 1 : 0,
    };
  }
}

/// [GroupModel] extends [GroupEntity] with SQLite serializations.
class GroupModel extends GroupEntity {
  const GroupModel({
    required super.id,
    required super.name,
    required super.type,
    required super.iconName,
    required super.memberCount,
    required super.createdAt,
  });

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      iconName: map['icon_name'] as String,
      memberCount: map['member_count'] as int,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon_name': iconName,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}

/// [GroupMemberModel] extends [GroupMemberEntity] with SQLite serializations.
class GroupMemberModel extends GroupMemberEntity {
  const GroupMemberModel({
    required super.id,
    required super.groupId,
    required super.name,
    super.avatarUrl,
    super.phoneE164,
    super.linkedUserId,
    required super.balance,
    super.note,
    super.lastActivity,
  });

  factory GroupMemberModel.fromMap(Map<String, dynamic> map) {
    return GroupMemberModel(
      id: map['id'] as String,
      groupId: map['group_id'] as String,
      name: map['name'] as String,
      avatarUrl: map['avatar_url'] as String?,
      phoneE164: map['phone_e164'] as String?,
      linkedUserId: map['linked_user_id'] as String?,
      balance: (map['balance'] as num).toDouble(),
      note: map['note'] as String?,
      lastActivity: map['last_activity'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'name': name,
      'avatar_url': avatarUrl,
      'phone_e164': phoneE164,
      'linked_user_id': linkedUserId,
      'note': note,
      'last_activity': lastActivity,
    };
  }
}

/// [GroupMemberWithGroupModel] maps joined group members and groups from SQLite.
class GroupMemberWithGroupModel extends GroupMemberWithGroupEntity {
  const GroupMemberWithGroupModel({
    required super.id,
    required super.groupId,
    required super.groupName,
    required super.groupType,
    required super.groupIcon,
    required super.name,
    super.avatarUrl,
    super.phoneE164,
    super.linkedUserId,
    required super.balance,
    super.note,
    super.lastActivity,
  });

  factory GroupMemberWithGroupModel.fromMap(Map<String, dynamic> map) {
    return GroupMemberWithGroupModel(
      id: map['id'] as String,
      groupId: map['group_id'] as String,
      groupName: (map['group_name'] as String?) ?? '',
      groupType: (map['group_type'] as String?) ?? 'other',
      groupIcon: (map['group_icon'] as String?) ?? 'profile_2user',
      name: map['name'] as String,
      avatarUrl: map['avatar_url'] as String?,
      phoneE164: map['phone_e164'] as String?,
      linkedUserId: map['linked_user_id'] as String?,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      note: map['note'] as String?,
      lastActivity: map['last_activity'] as String?,
    );
  }
}
