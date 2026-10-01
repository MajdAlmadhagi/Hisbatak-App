import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../models/app_models.dart';
import '../../domain/entities/expense_split_entity.dart';

/// Contract class for Profile Data Source (ISP)
abstract class IProfileLocalDataSource {
  Future<UserProfileModel> getUserProfile();
  Future<void> saveUserProfile(UserProfileModel profile);
  Future<void> updateBiometricSetting(bool enabled);
  Future<void> updateDarkModeSetting(bool isDark);

  ///Clear all data of database from device
  Future<void> clearAllData();
}

/// Concrete SQLite implementation for Profile Data Source (DIP)
class ProfileLocalDataSourceImpl implements IProfileLocalDataSource {
  final AppDatabase appDatabase;

  ProfileLocalDataSourceImpl(this.appDatabase);

  @override
  Future<UserProfileModel> getUserProfile() async {
    final db = await appDatabase.database;
    final results =
        await db.query('user_profile', where: 'id = ?', whereArgs: ['user_me']);
    if (results.isNotEmpty) {
      return UserProfileModel.fromMap(results.first);
    }
    // Default fallback
    return const UserProfileModel(
      id: 'user_me',
      fullName: 'مجد المذحجي',
      email: 'tariq.mansour@offline.local',
      currencyCode: 'SAR',
      currencySymbol: 'ر.س',
      monthlyBudgetLimit: 20000.0,
      currentAvailable: 14850.0,
      biometricEnabled: true,
      isDarkMode: false,
      isConfigured: true,
    );
  }

  @override
  Future<void> saveUserProfile(UserProfileModel profile) async {
    final db = await appDatabase.database;
    await db.insert(
      'user_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateBiometricSetting(bool enabled) async {
    final db = await appDatabase.database;
    await db.update(
      'user_profile',
      {'biometric_enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: ['user_me'],
    );
  }

  @override
  Future<void> updateDarkModeSetting(bool isDark) async {
    final db = await appDatabase.database;
    await db.update(
      'user_profile',
      {'is_dark_mode': isDark ? 1 : 0},
      where: 'id = ?',
      whereArgs: ['user_me'],
    );
  }

  @override
  Future<void> clearAllData() async {
    final db = await appDatabase.database;
    await db.delete('transactions');
    await db.delete('group_members');
    await db.delete('groups');
    await db.delete('group_expenses');
  }
}

/// Contract for Budget Data Source (ISP)
abstract class IBudgetLocalDataSource {
  Future<List<TransactionModel>> getTransactions({int? limit});
  Future<void> addTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
  Future<double> getTotalExpenses();
}

/// Concrete SQLite implementation for Budget Data Source (DIP)
class BudgetLocalDataSourceImpl implements IBudgetLocalDataSource {
  final AppDatabase appDatabase;

  BudgetLocalDataSourceImpl(this.appDatabase);

  @override
  Future<List<TransactionModel>> getTransactions({int? limit}) async {
    final db = await appDatabase.database;
    final results = await db.query(
      'transactions',
      orderBy: 'date_time DESC',
      limit: limit,
    );
    return results.map((m) => TransactionModel.fromMap(m)).toList();
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    final db = await appDatabase.database;
    await db.insert('transactions', transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);

    // Update profile available budget accordingly
    final profileRes =
        await db.query('user_profile', where: 'id = ?', whereArgs: ['user_me']);
    if (profileRes.isNotEmpty) {
      double current =
          (profileRes.first['current_available'] as num).toDouble();
      if (transaction.type.name == 'expense') {
        current -= transaction.amount;
      } else {
        current += transaction.amount;
      }
      await db.update('user_profile', {'current_available': current},
          where: 'id = ?', whereArgs: ['user_me']);
    }
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    final db = await appDatabase.database;
    final oldTxRes = await db.query('transactions', where: 'id = ?', whereArgs: [transaction.id]);
    if (oldTxRes.isNotEmpty) {
      final oldTx = oldTxRes.first;
      final oldAmount = (oldTx['amount'] as num).toDouble();
      final oldType = oldTx['type'] as String;

      // Adjust profile available budget
      final profileRes = await db.query('user_profile', where: 'id = ?', whereArgs: ['user_me']);
      if (profileRes.isNotEmpty) {
        double current = (profileRes.first['current_available'] as num).toDouble();
        // Revert old transaction effect
        if (oldType == 'expense') {
          current += oldAmount;
        } else {
          current -= oldAmount;
        }
        // Apply new transaction effect
        if (transaction.type.name == 'expense') {
          current -= transaction.amount;
        } else {
          current += transaction.amount;
        }
        await db.update('user_profile', {'current_available': current}, where: 'id = ?', whereArgs: ['user_me']);
      }
    }

    await db.update('transactions', transaction.toMap(), where: 'id = ?', whereArgs: [transaction.id]);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final db = await appDatabase.database;
    final oldTxRes = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    if (oldTxRes.isNotEmpty) {
      final oldTx = oldTxRes.first;
      final oldAmount = (oldTx['amount'] as num).toDouble();
      final oldType = oldTx['type'] as String;

      // Revert transaction effect from available balance
      final profileRes = await db.query('user_profile', where: 'id = ?', whereArgs: ['user_me']);
      if (profileRes.isNotEmpty) {
        double current = (profileRes.first['current_available'] as num).toDouble();
        if (oldType == 'expense') {
          current += oldAmount;
        } else {
          current -= oldAmount;
        }
        await db.update('user_profile', {'current_available': current}, where: 'id = ?', whereArgs: ['user_me']);
      }
    }

    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<double> getTotalExpenses() async {
    final db = await appDatabase.database;
    final results = await db.rawQuery(
      "SELECT SUM(amount) as total FROM transactions WHERE type = 'expense'",
    );
    if (results.isNotEmpty && results.first['total'] != null) {
      return (results.first['total'] as num).toDouble();
    }
    return 0.0;
  }
}

/// Contract for Group Data Source (ISP)
abstract class IGroupLocalDataSource {
  Future<List<GroupModel>> getGroups();
  Future<GroupModel?> getGroupById(String groupId);
  Future<List<GroupMemberModel>> getGroupMembers(String groupId);
  Future<void> addGroup(GroupModel group);
  Future<void> addGroupExpense(GroupExpense expense);
  Future<void> settleMemberBalance(String memberId, String groupId);
}

/// Concrete SQLite implementation for Group Data Source (DIP)
class GroupLocalDataSourceImpl implements IGroupLocalDataSource {
  final AppDatabase appDatabase;

  GroupLocalDataSourceImpl(this.appDatabase);

  @override
  Future<List<GroupModel>> getGroups() async {
    final db = await appDatabase.database;
    final results = await db.query('groups', orderBy: 'created_at ASC');
    return results.map((m) => GroupModel.fromMap(m)).toList();
  }

  @override
  Future<GroupModel?> getGroupById(String groupId) async {
    final db = await appDatabase.database;
    final results =
        await db.query('groups', where: 'id = ?', whereArgs: [groupId]);
    if (results.isNotEmpty) {
      return GroupModel.fromMap(results.first);
    }
    return null;
  }

  @override
  Future<List<GroupMemberModel>> getGroupMembers(String groupId) async {
    final db = await appDatabase.database;
    final results = await db
        .query('group_members', where: 'group_id = ?', whereArgs: [groupId]);
    return results.map((m) => GroupMemberModel.fromMap(m)).toList();
  }

  @override
  Future<void> addGroup(GroupModel group) async {
    final db = await appDatabase.database;
    await db.insert('groups', group.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> addGroupExpense(GroupExpense expense) async {
    final db = await appDatabase.database;
    await db.insert('group_expenses', {
      'id': expense.id,
      'group_id': expense.groupId,
      'title': expense.title,
      'total_amount': expense.totalAmount,
      'payer_id': expense.payerId,
      'payer_name': expense.payerName,
      'category': expense.category,
      'split_method': expense.splitMethod.name,
      'date_time': expense.dateTime.toIso8601String(),
    });

    // Update balances for participants: each other member owes the payer their split
    for (final split in expense.splits) {
      if (!split.isPayer) {
        final memberRes = await db.query('group_members',
            where: 'id = ?', whereArgs: [split.memberId]);
        if (memberRes.isNotEmpty) {
          final currentBal = (memberRes.first['balance'] as num).toDouble();
          final updatedBal =
              currentBal + split.amount; // Member now owes user more
          await db.update(
            'group_members',
            {
              'balance': updatedBal,
              'note': expense.title,
              'last_activity': 'اليوم',
            },
            where: 'id = ?',
            whereArgs: [split.memberId],
          );
        }
      }
    }
  }

  @override
  Future<void> settleMemberBalance(String memberId, String groupId) async {
    final db = await appDatabase.database;
    await db.update(
      'group_members',
      {
        'balance': 0.0,
        'note': 'تمت التسوية بنجاح',
        'last_activity': 'اليوم',
      },
      where: 'id = ? AND group_id = ?',
      whereArgs: [memberId, groupId],
    );
  }
}
