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
    required super.isSynced,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      categoryIcon: map['category_icon'] as String,
      paymentMethod: map['payment_method'] as String,
      // Stored in UTC; shown in the device's time zone.
      dateTime: DateTime.parse(map['date_time'] as String).toLocal(),
      type: (map['type'] == 'income') ? TransactionType.income : TransactionType.expense,
      isSynced: (map['is_synced'] as int) == 1,
    );
  }

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
      // Computed by the query that reads groups, not stored.
      memberCount: map['member_count'] as int,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  /// The stored columns; memberCount is computed from group_members.
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
      // Computed from expense_splits and settlements by the query that reads members.
      balance: (map['balance'] as num).toDouble(),
      note: map['note'] as String?,
      lastActivity: map['last_activity'] as String?,
    );
  }

  /// The stored columns; balance is computed.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'name': name,
      'avatar_url': avatarUrl,
      'note': note,
      'last_activity': lastActivity,
    };
  }
}
