import 'package:flutter/material.dart';
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
    // No profile yet (a fresh install): not configured, so the splash
    // screen sends the user to profile setup.
    return const UserProfileModel(
      id: 'user_me',
      fullName: '',
      email: '',
      currencyCode: 'YER',
      currencySymbol: 'ر.ي',
      monthlyBudgetLimit: 0.0,
      currentAvailable: 0.0,
      biometricEnabled: false,
      isDarkMode: false,
      isConfigured: false,
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
    await db.delete('expense_splits');
    await db.delete('settlements');
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

/// The current time as the database stores it: UTC ISO 8601.
String _nowUtc() => DateTime.now().toUtc().toIso8601String();

/// A transaction row edited on this device: stamped with the edit time and
/// flagged so the next sync uploads it.
Map<String, Object?> _editedLocally(Map<String, dynamic> row) => {
      ...row,
      'updated_at': _nowUtc(),
      'deleted_at': null,
      'is_synced': 0,
    };

/// Concrete SQLite implementation for Budget Data Source (DIP)
///
/// Deleted transactions stay in the table with deleted_at set until the
/// deletion syncs, so every query here skips them.
class BudgetLocalDataSourceImpl implements IBudgetLocalDataSource {
  final AppDatabase appDatabase;

  BudgetLocalDataSourceImpl(this.appDatabase);

  @override
  Future<List<TransactionModel>> getTransactions({int? limit}) async {
    final db = await appDatabase.database;
    final results = await db.query(
      'transactions',
      where: 'deleted_at IS NULL',
      orderBy: 'date_time DESC',
      limit: limit,
    );
    return results.map((m) => TransactionModel.fromMap(m)).toList();
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    final db = await appDatabase.database;
    await db.insert('transactions', _editedLocally(transaction.toMap()),
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
    final oldTxRes = await db.query('transactions',
        where: 'id = ? AND deleted_at IS NULL', whereArgs: [transaction.id]);
    if (oldTxRes.isNotEmpty) {
      final oldTx = oldTxRes.first;
      final oldAmount = (oldTx['amount'] as num).toDouble();
      final oldType = oldTx['type'] as String;

      // Adjust profile available budget
      final profileRes = await db
          .query('user_profile', where: 'id = ?', whereArgs: ['user_me']);
      if (profileRes.isNotEmpty) {
        double current =
            (profileRes.first['current_available'] as num).toDouble();
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
        await db.update('user_profile', {'current_available': current},
            where: 'id = ?', whereArgs: ['user_me']);
      }
    }

    await db.update('transactions', _editedLocally(transaction.toMap()),
        where: 'id = ? AND deleted_at IS NULL', whereArgs: [transaction.id]);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final db = await appDatabase.database;
    final oldTxRes = await db.query('transactions',
        where: 'id = ? AND deleted_at IS NULL', whereArgs: [id]);
    if (oldTxRes.isNotEmpty) {
      final oldTx = oldTxRes.first;
      final oldAmount = (oldTx['amount'] as num).toDouble();
      final oldType = oldTx['type'] as String;

      // Revert transaction effect from available balance
      final profileRes = await db
          .query('user_profile', where: 'id = ?', whereArgs: ['user_me']);
      if (profileRes.isNotEmpty) {
        double current =
            (profileRes.first['current_available'] as num).toDouble();
        if (oldType == 'expense') {
          current += oldAmount;
        } else {
          current -= oldAmount;
        }
        await db.update('user_profile', {'current_available': current},
            where: 'id = ?', whereArgs: ['user_me']);
      }

      // Mark instead of delete, so the deletion reaches the server and other devices.
      final now = _nowUtc();
      await db.update(
        'transactions',
        {'deleted_at': now, 'updated_at': now, 'is_synced': 0},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  @override
  Future<double> getTotalExpenses() async {
    final db = await appDatabase.database;
    final results = await db.rawQuery(
      "SELECT SUM(amount) as total FROM transactions WHERE type = 'expense' AND deleted_at IS NULL",
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

/// What member `m` owes you, rounded to 2 decimals (negative: you owe them):
/// their shares of expenses you paid, minus your shares of expenses they
/// paid, minus what was settled. Computed from the saved splits and
/// settlements rather than stored, so changes from several devices add up.
const memberBalanceSql = '''
  ROUND(
      COALESCE((SELECT SUM(s.amount) FROM expense_splits s
                JOIN group_expenses e ON e.id = s.expense_id
                WHERE s.member_id = m.id AND s.group_id = m.group_id AND s.is_payer = 0
                  AND e.payer_id = 'user_me'
                  AND s.deleted_at IS NULL AND e.deleted_at IS NULL), 0)
    - COALESCE((SELECT SUM(s.amount) FROM expense_splits s
                JOIN group_expenses e ON e.id = s.expense_id
                WHERE s.member_id = 'user_me' AND s.group_id = m.group_id AND s.is_payer = 0
                  AND e.payer_id = m.id
                  AND s.deleted_at IS NULL AND e.deleted_at IS NULL), 0)
    - COALESCE((SELECT SUM(t.amount) FROM settlements t
                WHERE t.member_id = m.id AND t.group_id = m.group_id
                  AND t.deleted_at IS NULL), 0),
    2)
''';

/// Groups with their live member count; deleted groups are skipped.
const _groupsWithMemberCountSql = '''
  SELECT g.*,
         (SELECT COUNT(*) FROM group_members m
          WHERE m.group_id = g.id AND m.deleted_at IS NULL) AS member_count
  FROM groups g
  WHERE g.deleted_at IS NULL
''';

/// Concrete SQLite implementation for Group Data Source (DIP)
///
/// Member counts and balances are computed on read; adding an expense saves
/// each participant's split, and settling saves a settlement.
class GroupLocalDataSourceImpl implements IGroupLocalDataSource {
  final AppDatabase appDatabase;

  GroupLocalDataSourceImpl(this.appDatabase);

  @override
  Future<List<GroupModel>> getGroups() async {
    final db = await appDatabase.database;
    final results =
        await db.rawQuery('$_groupsWithMemberCountSql ORDER BY g.created_at ASC');
    return results.map((m) => GroupModel.fromMap(m)).toList();
  }

  @override
  Future<GroupModel?> getGroupById(String groupId) async {
    final db = await appDatabase.database;
    final results =
        await db.rawQuery('$_groupsWithMemberCountSql AND g.id = ?', [groupId]);
    if (results.isNotEmpty) {
      return GroupModel.fromMap(results.first);
    }
    return null;
  }

  @override
  Future<List<GroupMemberModel>> getGroupMembers(String groupId) async {
    final db = await appDatabase.database;
    final results = await db.rawQuery('''
      SELECT m.*, $memberBalanceSql AS balance
      FROM group_members m
      WHERE m.group_id = ? AND m.deleted_at IS NULL
    ''', [groupId]);
    return results.map((m) => GroupMemberModel.fromMap(m)).toList();
  }

  @override
  Future<void> addGroup(GroupModel group) async {
    final db = await appDatabase.database;
    await db.insert('groups', _editedLocally(group.toMap()),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> addGroupExpense(GroupExpense expense) async {
    final db = await appDatabase.database;
    await db.transaction((txn) async {
      await txn.insert('group_expenses', _editedLocally({
        'id': expense.id,
        'group_id': expense.groupId,
        'title': expense.title,
        'total_amount': expense.totalAmount,
        'payer_id': expense.payerId,
        'payer_name': expense.payerName,
        'category': expense.category,
        'split_method': expense.splitMethod.name,
        'date_time': expense.dateTime.toUtc().toIso8601String(),
      }));

      // Each participant's share, the payer's included; balances add these up.
      for (final split in expense.splits) {
        await txn.insert('expense_splits', _editedLocally({
          'id': '${expense.id}:${split.memberId}',
          'expense_id': expense.id,
          'group_id': expense.groupId,
          'member_id': split.memberId,
          'amount': split.amount,
          'percentage': split.percentage,
          'is_payer': split.isPayer ? 1 : 0,
        }));

        if (!split.isPayer) {
          await txn.update(
            'group_members',
            _editedLocally({'note': expense.title, 'last_activity': 'اليوم'}),
            where: 'id = ? AND group_id = ? AND deleted_at IS NULL',
            whereArgs: [split.memberId, expense.groupId],
          );
        }
      }
    });
  }

  @override
  Future<void> settleMemberBalance(String memberId, String groupId) async {
    final db = await appDatabase.database;
    await db.transaction((txn) async {
      final result = await txn.rawQuery('''
        SELECT $memberBalanceSql AS balance
        FROM group_members m
        WHERE m.id = ? AND m.group_id = ?
      ''', [memberId, groupId]);
      if (result.isEmpty) return;
      final balance = (result.first['balance'] as num).toDouble();

      // Settling records a payment for the whole balance, which brings it to 0.
      if (balance != 0) {
        await txn.insert('settlements', _editedLocally({
          'id': 'stl_${DateTime.now().microsecondsSinceEpoch}',
          'group_id': groupId,
          'member_id': memberId,
          'amount': balance,
          'date_time': _nowUtc(),
        }));
      }
      await txn.update(
        'group_members',
        _editedLocally({'note': 'تمت التسوية بنجاح', 'last_activity': 'اليوم'}),
        where: 'id = ? AND group_id = ? AND deleted_at IS NULL',
        whereArgs: [memberId, groupId],
      );
    });
  }
}
