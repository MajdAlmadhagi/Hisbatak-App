import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/id_generator.dart';
import '../../core/utils/validators.dart';
import '../../domain/entities/budget_summary.dart';
import '../../domain/entities/expense_split_entity.dart';
import '../models/app_models.dart';

/// Contract class for Profile Data Source (ISP)
abstract class IProfileLocalDataSource {
  Future<UserProfileModel> getUserProfile();
  Future<void> saveUserProfile(UserProfileModel profile);

  /// Clear all user data from device database.
  Future<void> clearAllData();
}

/// Resolves the active local user id from `user_profile` (falls back to `'user_me'` before onboarding).
Future<String> resolveCurrentUserId(DatabaseExecutor db) async {
  final rows = await db.query('user_profile', columns: ['id'], limit: 1);
  if (rows.isNotEmpty) {
    final id = rows.first['id'] as String?;
    if (id != null && id.isNotEmpty) return id;
  }
  return 'user_me';
}

/// The current time as the database stores it: UTC ISO 8601.
String _nowUtc() => DateTime.now().toUtc().toIso8601String();

/// Stamped row payload for local-first writes that need cloud push.
Map<String, Object?> _editedLocally(
  Map<String, dynamic> row, {
  int? version,
  String? idempotencyKey,
}) =>
    {
      ...row,
      'updated_at': _nowUtc(),
      'deleted_at': null,
      'is_synced': 0,
      if (version != null) 'version': version,
      'idempotency_key': idempotencyKey ?? IdGenerator.uuidV4(),
    };

/// Enqueues an atomic change into `sync_outbox` within the active transaction.
/// Coalesces any un-pushed `'pending'` entry for the same `(entityType, entityId)`.
Future<void> _enqueueOutbox(
  DatabaseExecutor txn, {
  required String entityType,
  required String entityId,
  required String operation,
  required Map<String, dynamic> payload,
  required String idempotencyKey,
}) async {
  final now = _nowUtc();
  await txn.delete(
    'sync_outbox',
    where: 'entity_type = ? AND entity_id = ? AND status = ?',
    whereArgs: [entityType, entityId, 'pending'],
  );
  await txn.insert(
    'sync_outbox',
    {
      'id': IdGenerator.uuidV4(),
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'payload_json': jsonEncode(payload),
      'idempotency_key': idempotencyKey,
      'retry_count': 0,
      'last_error': null,
      'status': 'pending',
      'created_at': now,
      'updated_at': now,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<int> _nextEntityVersion(
  DatabaseExecutor txn,
  String table,
  String id,
) async {
  final rows = await txn.query(
    table,
    columns: ['version'],
    where: 'id = ?',
    whereArgs: [id],
    limit: 1,
  );
  if (rows.isEmpty) return 1;
  return ((rows.first['version'] as int?) ?? 1) + 1;
}

/// Concrete SQLite implementation for Profile Data Source (DIP)
class ProfileLocalDataSourceImpl implements IProfileLocalDataSource {
  final AppDatabase appDatabase;
  String? _ephemeralGuestId;

  ProfileLocalDataSourceImpl(this.appDatabase);

  String _getOrCreateGuestUuid() => _ephemeralGuestId ??= IdGenerator.uuidV4();

  @override
  Future<UserProfileModel> getUserProfile() async {
    final db = await appDatabase.database;
    final results = await db.query('user_profile', limit: 1);
    if (results.isNotEmpty) {
      final profile = UserProfileModel.fromMap(results.first);
      if (profile.id != 'user_me' && profile.id.isNotEmpty) {
        _ephemeralGuestId = profile.id;
      }
      return profile;
    }
    // Fresh install: not configured yet, provide stable UUIDv4 for setup.
    return UserProfileModel(
      id: _getOrCreateGuestUuid(),
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
    await db.transaction((txn) async {
      final existing = await txn.query('user_profile', limit: 1);
      final existingId =
          existing.isNotEmpty ? existing.first['id'] as String? : null;
      final existingVersion =
          existing.isNotEmpty ? ((existing.first['version'] as int?) ?? 1) : 0;

      final needsNewUuid = profile.id.isEmpty || profile.id == 'user_me';
      final resolvedId = !needsNewUuid
          ? profile.id
          : (existingId != null &&
                  existingId.isNotEmpty &&
                  existingId != 'user_me'
              ? existingId
              : _getOrCreateGuestUuid());
      _ephemeralGuestId = resolvedId;

      final normalizedPhone = Validators.tryNormalizePhoneE164(profile.phoneE164);
      final now = _nowUtc();
      final nextVersion = existingVersion + 1;
      final row = {
        ...profile.toMap(),
        'id': resolvedId,
        'phone_e164': normalizedPhone,
        'updated_at': now,
        'version': nextVersion,
      };

      // Migrate any legacy 'user_me' owner references created before UUID identity.
      if (existingId == 'user_me' || profile.id == 'user_me') {
        await txn.update(
          'group_expenses',
          {'payer_id': resolvedId},
          where: 'payer_id = ?',
          whereArgs: const ['user_me'],
        );
        await txn.update(
          'expense_splits',
          {'member_id': resolvedId},
          where: 'member_id = ?',
          whereArgs: const ['user_me'],
        );
      }

      await txn.delete('user_profile');
      await txn.insert(
        'user_profile',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await _enqueueOutbox(
        txn,
        entityType: 'user_profile',
        entityId: resolvedId,
        operation: 'upsert',
        payload: row,
        idempotencyKey: IdGenerator.uuidV4(),
      );
    });
  }

  @override
  Future<void> clearAllData() async {
    final db = await appDatabase.database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('group_members');
      await txn.delete('groups');
      await txn.delete('group_expenses');
      await txn.delete('expense_splits');
      await txn.delete('settlements');
      await txn.delete('user_profile');
      await txn.delete('sync_outbox');
      await txn.delete('sync_state');
    });
    _ephemeralGuestId = null;
  }
}

/// Contract for Budget Data Source (ISP)
abstract class IBudgetLocalDataSource {
  Future<List<TransactionModel>> getTransactions({int? limit});
  Future<void> addTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
  Future<double> getTotalExpenses();
  Future<double> getMonthlyExpensesTotal({DateTime? month});
  Future<double> getMonthlyIncomeTotal({DateTime? month});
  Future<List<CategoryExpense>> getMonthlyCategoryExpenses({DateTime? month});
}

/// Concrete SQLite implementation for Budget Data Source (DIP)
class BudgetLocalDataSourceImpl implements IBudgetLocalDataSource {
  final AppDatabase appDatabase;

  BudgetLocalDataSourceImpl(this.appDatabase);

  static const Map<String, int> _categoryColors = {
    'مطاعم ومقاهي': 0xFFEF4444,
    'مطاعم وكافيهات': 0xFFEF4444,
    'بقالة وتموين': 0xFF10B981,
    'تموين ومقاضي': 0xFF10B981,
    'فواتير ومسكن': 0xFF1E293B,
    'ترفيه وتسوق': 0xFF6366F1,
    'ترفية وتسوق': 0xFF6366F1,
    'نقل ومواصلات': 0xFFF59E0B,
    'بنزين وطاقة': 0xFFEA580C,
    'مياه وكهرباء': 0xFF06B6D4,
    'الأنترنت والهاتف': 0xFF3B82F6,
    'تعليم وجامعات': 0xFF8B5CF6,
    'تسوية مجموعة': 0xFF14B8A6,
  };

  static const List<int> _fallbackPalette = [
    0xFF10B981,
    0xFF6366F1,
    0xFFF59E0B,
    0xFFEF4444,
    0xFF06B6D4,
    0xFFEC4899,
    0xFF8B5CF6,
  ];

  (String, String) _monthBoundsUtc(DateTime? month) {
    final target = month ?? DateTime.now();
    final start =
        DateTime(target.year, target.month, 1).toUtc().toIso8601String();
    final end =
        DateTime(target.year, target.month + 1, 1).toUtc().toIso8601String();
    return (start, end);
  }

  @override
  Future<List<TransactionModel>> getTransactions({int? limit}) async {
    final db = await appDatabase.database;
    final currentUserId = await resolveCurrentUserId(db);
    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final results = await db.rawQuery('''
      SELECT 
        t.*,
        g.name AS group_name,
        (
          SELECT GROUP_CONCAT(m.name, ', ')
          FROM expense_splits s
          JOIN group_members m ON m.id = s.member_id AND m.group_id = s.group_id
          WHERE s.expense_id = t.expense_id 
            AND s.deleted_at IS NULL 
            AND m.deleted_at IS NULL
            AND s.member_id != ?
        ) AS member_names
      FROM transactions t
      LEFT JOIN groups g ON g.id = t.group_id AND g.deleted_at IS NULL
      WHERE t.deleted_at IS NULL
      ORDER BY t.date_time DESC
      $limitClause
    ''', [currentUserId]);
    return results.map((m) => TransactionModel.fromMap(m)).toList();
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    final db = await appDatabase.database;
    await db.transaction((txn) async {
      final idemKey = IdGenerator.uuidV4();
      final row = _editedLocally(
        transaction.toMap(),
        version: 1,
        idempotencyKey: idemKey,
      );
      await txn.insert(
        'transactions',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _enqueueOutbox(
        txn,
        entityType: 'transaction',
        entityId: transaction.id,
        operation: 'upsert',
        payload: row,
        idempotencyKey: idemKey,
      );

      final userId = await resolveCurrentUserId(txn);
      final profileRes = await txn.query(
        'user_profile',
        where: 'id = ?',
        whereArgs: [userId],
      );
      if (profileRes.isNotEmpty) {
        double current =
            (profileRes.first['current_available'] as num).toDouble();
        if (transaction.type.name == 'expense') {
          current -= transaction.amount;
        } else {
          current += transaction.amount;
        }
        await txn.update(
          'user_profile',
          {
            'current_available': current,
            'updated_at': _nowUtc(),
          },
          where: 'id = ?',
          whereArgs: [userId],
        );
      }
    });
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    final db = await appDatabase.database;
    await db.transaction((txn) async {
      final oldTxRes = await txn.query(
        'transactions',
        where: 'id = ? AND deleted_at IS NULL',
        whereArgs: [transaction.id],
      );
      int nextVersion = 1;
      if (oldTxRes.isNotEmpty) {
        final oldTx = oldTxRes.first;
        nextVersion = ((oldTx['version'] as int?) ?? 1) + 1;
        final oldAmount = (oldTx['amount'] as num).toDouble();
        final oldType = oldTx['type'] as String;

        final userId = await resolveCurrentUserId(txn);
        final profileRes = await txn.query(
          'user_profile',
          where: 'id = ?',
          whereArgs: [userId],
        );
        if (profileRes.isNotEmpty) {
          double current =
              (profileRes.first['current_available'] as num).toDouble();
          if (oldType == 'expense') {
            current += oldAmount;
          } else {
            current -= oldAmount;
          }
          if (transaction.type.name == 'expense') {
            current -= transaction.amount;
          } else {
            current += transaction.amount;
          }
          await txn.update(
            'user_profile',
            {
              'current_available': current,
              'updated_at': _nowUtc(),
            },
            where: 'id = ?',
            whereArgs: [userId],
          );
        }
      }

      final now = _nowUtc();
      final idemKey = IdGenerator.uuidV4();
      final updatedRow = _editedLocally(
        transaction.toMap(),
        version: nextVersion,
        idempotencyKey: idemKey,
      );
      await txn.update(
        'transactions',
        updatedRow,
        where: 'id = ? AND deleted_at IS NULL',
        whereArgs: [transaction.id],
      );
      await _enqueueOutbox(
        txn,
        entityType: 'transaction',
        entityId: transaction.id,
        operation: 'upsert',
        payload: updatedRow,
        idempotencyKey: idemKey,
      );

      if (transaction.expenseId != null && transaction.expenseId!.isNotEmpty) {
        final nextExpVersion =
            await _nextEntityVersion(txn, 'group_expenses', transaction.expenseId!);
        final expIdemKey = IdGenerator.uuidV4();
        await txn.update(
          'group_expenses',
          {
            'title': transaction.title,
            'category': transaction.category,
            'updated_at': now,
            'is_synced': 0,
            'version': nextExpVersion,
            'idempotency_key': expIdemKey,
          },
          where: 'id = ? AND deleted_at IS NULL',
          whereArgs: [transaction.expenseId],
        );
        final expRows = await txn.query(
          'group_expenses',
          where: 'id = ?',
          whereArgs: [transaction.expenseId],
          limit: 1,
        );
        if (expRows.isNotEmpty) {
          await _enqueueOutbox(
            txn,
            entityType: 'group_expense',
            entityId: transaction.expenseId!,
            operation: 'upsert',
            payload: expRows.first,
            idempotencyKey: expIdemKey,
          );
        }
      }
    });
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final db = await appDatabase.database;
    await db.transaction((txn) async {
      final oldTxRes = await txn.query(
        'transactions',
        where: 'id = ? AND deleted_at IS NULL',
        whereArgs: [id],
      );
      if (oldTxRes.isNotEmpty) {
        final oldTx = oldTxRes.first;
        final nextVersion = ((oldTx['version'] as int?) ?? 1) + 1;
        final oldAmount = (oldTx['amount'] as num).toDouble();
        final oldType = oldTx['type'] as String;
        final expenseId = oldTx['expense_id'] as String?;

        final userId = await resolveCurrentUserId(txn);
        final profileRes = await txn.query(
          'user_profile',
          where: 'id = ?',
          whereArgs: [userId],
        );
        if (profileRes.isNotEmpty) {
          double current =
              (profileRes.first['current_available'] as num).toDouble();
          if (oldType == 'expense') {
            current += oldAmount;
          } else {
            current -= oldAmount;
          }
          await txn.update(
            'user_profile',
            {
              'current_available': current,
              'updated_at': _nowUtc(),
            },
            where: 'id = ?',
            whereArgs: [userId],
          );
        }

        final now = _nowUtc();
        final txIdemKey = IdGenerator.uuidV4();
        await txn.update(
          'transactions',
          {
            'deleted_at': now,
            'updated_at': now,
            'is_synced': 0,
            'version': nextVersion,
            'idempotency_key': txIdemKey,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        await _enqueueOutbox(
          txn,
          entityType: 'transaction',
          entityId: id,
          operation: 'delete',
          payload: {
            'id': id,
            'deleted_at': now,
            'updated_at': now,
            'version': nextVersion,
          },
          idempotencyKey: txIdemKey,
        );

        if (expenseId != null && expenseId.isNotEmpty) {
          final nextExpVersion =
              await _nextEntityVersion(txn, 'group_expenses', expenseId);
          final expIdemKey = IdGenerator.uuidV4();
          await txn.update(
            'group_expenses',
            {
              'deleted_at': now,
              'updated_at': now,
              'is_synced': 0,
              'version': nextExpVersion,
              'idempotency_key': expIdemKey,
            },
            where: 'id = ?',
            whereArgs: [expenseId],
          );
          await _enqueueOutbox(
            txn,
            entityType: 'group_expense',
            entityId: expenseId,
            operation: 'delete',
            payload: {
              'id': expenseId,
              'deleted_at': now,
              'updated_at': now,
              'version': nextExpVersion,
            },
            idempotencyKey: expIdemKey,
          );

          final splitRows = await txn.query(
            'expense_splits',
            columns: ['id', 'version'],
            where: 'expense_id = ?',
            whereArgs: [expenseId],
          );
          for (final s in splitRows) {
            final splitId = s['id'] as String;
            final splitVer = ((s['version'] as int?) ?? 1) + 1;
            final splitIdem = IdGenerator.uuidV4();
            await txn.update(
              'expense_splits',
              {
                'deleted_at': now,
                'updated_at': now,
                'is_synced': 0,
                'version': splitVer,
                'idempotency_key': splitIdem,
              },
              where: 'id = ?',
              whereArgs: [splitId],
            );
            await _enqueueOutbox(
              txn,
              entityType: 'expense_split',
              entityId: splitId,
              operation: 'delete',
              payload: {
                'id': splitId,
                'expense_id': expenseId,
                'deleted_at': now,
                'updated_at': now,
                'version': splitVer,
              },
              idempotencyKey: splitIdem,
            );
          }
        }
      }
    });
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

  @override
  Future<double> getMonthlyExpensesTotal({DateTime? month}) async {
    final db = await appDatabase.database;
    final (startUtc, endUtc) = _monthBoundsUtc(month);
    final results = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE type = 'expense'
        AND deleted_at IS NULL
        AND date_time >= ?
        AND date_time < ?
      ''',
      [startUtc, endUtc],
    );
    if (results.isNotEmpty && results.first['total'] != null) {
      return (results.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  @override
  Future<double> getMonthlyIncomeTotal({DateTime? month}) async {
    final db = await appDatabase.database;
    final (startUtc, endUtc) = _monthBoundsUtc(month);
    final results = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE type = 'income'
        AND deleted_at IS NULL
        AND date_time >= ?
        AND date_time < ?
      ''',
      [startUtc, endUtc],
    );
    if (results.isNotEmpty && results.first['total'] != null) {
      return (results.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  @override
  Future<List<CategoryExpense>> getMonthlyCategoryExpenses({
    DateTime? month,
  }) async {
    final db = await appDatabase.database;
    final userId = await resolveCurrentUserId(db);
    final (startUtc, endUtc) = _monthBoundsUtc(month);

    final rows = await db.rawQuery(
      '''
      SELECT 
        t.category AS category_name,
        SUM(
          CASE
            WHEN t.expense_id IS NOT NULL AND EXISTS (
              SELECT 1 FROM expense_splits s0
              WHERE s0.expense_id = t.expense_id AND s0.deleted_at IS NULL
            ) THEN COALESCE((
              SELECT s.amount FROM expense_splits s
              WHERE s.expense_id = t.expense_id
                AND s.member_id = ?
                AND s.deleted_at IS NULL
              LIMIT 1
            ), 0)
            ELSE t.amount
          END
        ) AS total_amount
      FROM transactions t
      WHERE t.type = 'expense'
        AND t.deleted_at IS NULL
        AND t.date_time >= ?
        AND t.date_time < ?
      GROUP BY t.category
      HAVING total_amount > 0
      ORDER BY total_amount DESC
      ''',
      [userId, startUtc, endUtc],
    );

    if (rows.isEmpty) return const [];

    final grandTotal = rows.fold<double>(
      0.0,
      (sum, row) => sum + ((row['total_amount'] as num?)?.toDouble() ?? 0.0),
    );
    if (grandTotal <= 0) return const [];

    final List<CategoryExpense> categories = [];
    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final name = (row['category_name'] as String?) ?? 'مصروفات أخرى';
      final amount = (row['total_amount'] as num).toDouble();
      final pct = (amount / grandTotal) * 100.0;
      final colorValue = _categoryColors[name] ??
          _fallbackPalette[i % _fallbackPalette.length];
      categories.add(
        CategoryExpense(
          categoryName: name,
          amount: double.parse(amount.toStringAsFixed(2)),
          percentage: double.parse(pct.toStringAsFixed(1)),
          colorValue: colorValue,
        ),
      );
    }
    return categories;
  }
}

/// Contract for Group Data Source (ISP)
abstract class IGroupLocalDataSource {
  Future<List<GroupModel>> getGroups();
  Future<GroupModel?> getGroupById(String groupId);
  Future<List<GroupMemberModel>> getGroupMembers(String groupId);
  Future<void> addGroup(GroupModel group);
  Future<void> addGroupMember(GroupMemberModel member);
  Future<void> addGroupExpense(GroupExpense expense);
  Future<void> settleMemberBalance(String memberId, String groupId);
  Future<List<GroupMemberWithGroupModel>> getAllGroupMembers();
}

/// Parameterized balance calculation for member `m` relative to current user (`?`, `?`).
String buildMemberBalanceSql() => '''
  ROUND(
      COALESCE((SELECT SUM(s.amount) FROM expense_splits s
                JOIN group_expenses e ON e.id = s.expense_id
                WHERE s.member_id = m.id AND s.group_id = m.group_id AND s.is_payer = 0
                  AND e.payer_id = ?
                  AND s.deleted_at IS NULL AND e.deleted_at IS NULL), 0)
    - COALESCE((SELECT SUM(s.amount) FROM expense_splits s
                JOIN group_expenses e ON e.id = s.expense_id
                WHERE s.member_id = ? AND s.group_id = m.group_id AND s.is_payer = 0
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
    final userId = await resolveCurrentUserId(db);
    final balanceExpr = buildMemberBalanceSql();
    final results = await db.rawQuery('''
      SELECT m.*, $balanceExpr AS balance
      FROM group_members m
      WHERE m.group_id = ? AND m.deleted_at IS NULL
    ''', [userId, userId, groupId]);
    return results.map((m) => GroupMemberModel.fromMap(m)).toList();
  }

  @override
  Future<List<GroupMemberWithGroupModel>> getAllGroupMembers() async {
    final db = await appDatabase.database;
    final userId = await resolveCurrentUserId(db);
    final balanceExpr = buildMemberBalanceSql();
    final results = await db.rawQuery('''
      SELECT m.*, g.name AS group_name, g.type AS group_type, g.icon_name AS group_icon, $balanceExpr AS balance
      FROM group_members m
      JOIN groups g ON g.id = m.group_id
      WHERE m.deleted_at IS NULL AND g.deleted_at IS NULL
      ORDER BY m.name COLLATE NOCASE ASC, g.created_at ASC
    ''', [userId, userId]);
    return results.map((m) => GroupMemberWithGroupModel.fromMap(m)).toList();
  }

  @override
  Future<void> addGroup(GroupModel group) async {
    final db = await appDatabase.database;
    await db.transaction((txn) async {
      final idemKey = IdGenerator.uuidV4();
      final row = _editedLocally(
        group.toMap(),
        version: 1,
        idempotencyKey: idemKey,
      );
      await txn.insert(
        'groups',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _enqueueOutbox(
        txn,
        entityType: 'group',
        entityId: group.id,
        operation: 'upsert',
        payload: row,
        idempotencyKey: idemKey,
      );
    });
  }

  @override
  Future<void> addGroupMember(GroupMemberModel member) async {
    final db = await appDatabase.database;
    await db.transaction((txn) async {
      final normalizedPhone = Validators.tryNormalizePhoneE164(member.phoneE164);
      String? linkedUserId = member.linkedUserId;
      if (linkedUserId == null && normalizedPhone != null) {
        final existingLink = await txn.query(
          'group_members',
          columns: ['linked_user_id'],
          where:
              'phone_e164 = ? AND linked_user_id IS NOT NULL AND deleted_at IS NULL',
          whereArgs: [normalizedPhone],
          limit: 1,
        );
        if (existingLink.isNotEmpty) {
          linkedUserId = existingLink.first['linked_user_id'] as String?;
        }
      }

      final idemKey = IdGenerator.uuidV4();
      final row = _editedLocally(
        {
          ...member.toMap(),
          'phone_e164': normalizedPhone,
          'linked_user_id': linkedUserId,
        },
        version: 1,
        idempotencyKey: idemKey,
      );
      await txn.insert(
        'group_members',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _enqueueOutbox(
        txn,
        entityType: 'group_member',
        entityId: member.id,
        operation: 'upsert',
        payload: row,
        idempotencyKey: idemKey,
      );
    });
  }

  Future<void> _updateMemberAndEnqueue(
    DatabaseExecutor txn, {
    required String memberId,
    required String groupId,
    required String note,
    required String lastActivity,
  }) async {
    final nextVersion = await _nextEntityVersion(txn, 'group_members', memberId);
    final idemKey = IdGenerator.uuidV4();
    await txn.update(
      'group_members',
      _editedLocally(
        {'note': note, 'last_activity': lastActivity},
        version: nextVersion,
        idempotencyKey: idemKey,
      ),
      where: 'id = ? AND group_id = ? AND deleted_at IS NULL',
      whereArgs: [memberId, groupId],
    );
    final updated = await txn.query(
      'group_members',
      where: 'id = ? AND group_id = ? AND deleted_at IS NULL',
      whereArgs: [memberId, groupId],
      limit: 1,
    );
    if (updated.isNotEmpty) {
      await _enqueueOutbox(
        txn,
        entityType: 'group_member',
        entityId: memberId,
        operation: 'upsert',
        payload: updated.first,
        idempotencyKey: idemKey,
      );
    }
  }

  @override
  Future<void> addGroupExpense(GroupExpense expense) async {
    final db = await appDatabase.database;
    await db.transaction((txn) async {
      final expIdemKey = IdGenerator.uuidV4();
      final expRow = _editedLocally(
        {
          'id': expense.id,
          'group_id': expense.groupId,
          'title': expense.title,
          'total_amount': expense.totalAmount,
          'payer_id': expense.payerId,
          'payer_name': expense.payerName,
          'category': expense.category,
          'split_method': expense.splitMethod.name,
          'date_time': expense.dateTime.toUtc().toIso8601String(),
        },
        version: 1,
        idempotencyKey: expIdemKey,
      );
      await txn.insert('group_expenses', expRow);
      await _enqueueOutbox(
        txn,
        entityType: 'group_expense',
        entityId: expense.id,
        operation: 'upsert',
        payload: expRow,
        idempotencyKey: expIdemKey,
      );

      for (final split in expense.splits) {
        final splitId = '${expense.id}:${split.memberId}';
        final splitIdemKey = IdGenerator.uuidV4();
        final splitRow = _editedLocally(
          {
            'id': splitId,
            'expense_id': expense.id,
            'group_id': expense.groupId,
            'member_id': split.memberId,
            'amount': split.amount,
            'percentage': split.percentage,
            'is_payer': split.isPayer ? 1 : 0,
          },
          version: 1,
          idempotencyKey: splitIdemKey,
        );
        await txn.insert('expense_splits', splitRow);
        await _enqueueOutbox(
          txn,
          entityType: 'expense_split',
          entityId: splitId,
          operation: 'upsert',
          payload: splitRow,
          idempotencyKey: splitIdemKey,
        );

        if (!split.isPayer) {
          await _updateMemberAndEnqueue(
            txn,
            memberId: split.memberId,
            groupId: expense.groupId,
            note: expense.title,
            lastActivity: 'اليوم',
          );
        }
      }
    });
  }

  @override
  Future<void> settleMemberBalance(String memberId, String groupId) async {
    final db = await appDatabase.database;
    await db.transaction((txn) async {
      final userId = await resolveCurrentUserId(txn);
      final balanceExpr = buildMemberBalanceSql();
      final result = await txn.rawQuery('''
        SELECT m.name AS member_name, $balanceExpr AS balance
        FROM group_members m
        WHERE m.id = ? AND m.group_id = ?
      ''', [userId, userId, memberId, groupId]);
      if (result.isEmpty) return;

      final balance = (result.first['balance'] as num).toDouble();
      final memberName = (result.first['member_name'] as String?) ?? 'عضو';

      if (balance != 0) {
        final now = _nowUtc();
        final settlementId = IdGenerator.prefixed('stl');
        final stlIdemKey = IdGenerator.uuidV4();
        final stlRow = _editedLocally(
          {
            'id': settlementId,
            'group_id': groupId,
            'member_id': memberId,
            'amount': balance,
            'date_time': now,
          },
          version: 1,
          idempotencyKey: stlIdemKey,
        );
        await txn.insert('settlements', stlRow);
        await _enqueueOutbox(
          txn,
          entityType: 'settlement',
          entityId: settlementId,
          operation: 'upsert',
          payload: stlRow,
          idempotencyKey: stlIdemKey,
        );

        // Update wallet available cash and record settlement transaction
        final profileRes = await txn.query(
          'user_profile',
          where: 'id = ?',
          whereArgs: [userId],
        );
        if (profileRes.isNotEmpty) {
          final currentAvailable =
              (profileRes.first['current_available'] as num).toDouble();
          await txn.update(
            'user_profile',
            {
              'current_available': currentAvailable + balance,
              'updated_at': now,
            },
            where: 'id = ?',
            whereArgs: [userId],
          );
        }

        final isIncoming = balance > 0;
        final txId = IdGenerator.prefixed('tx_stl');
        final txIdemKey = IdGenerator.uuidV4();
        final txRow = _editedLocally(
          {
            'id': txId,
            'title': isIncoming
                ? 'تحصيل تسوية من $memberName'
                : 'سداد تسوية إلى $memberName',
            'amount': balance.abs(),
            'category': 'تسوية مجموعة',
            'category_icon': 'account_balance',
            'payment_method': 'تسوية مجموعة',
            'date_time': now,
            'type': isIncoming ? 'income' : 'expense',
            'group_id': groupId,
            'expense_id': null,
          },
          version: 1,
          idempotencyKey: txIdemKey,
        );
        await txn.insert('transactions', txRow);
        await _enqueueOutbox(
          txn,
          entityType: 'transaction',
          entityId: txId,
          operation: 'upsert',
          payload: txRow,
          idempotencyKey: txIdemKey,
        );
      }

      await _updateMemberAndEnqueue(
        txn,
        memberId: memberId,
        groupId: groupId,
        note: 'تمت التسوية بنجاح',
        lastActivity: 'اليوم',
      );
    });
  }
}
