import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../utils/id_generator.dart';

/// [AppDatabase] manages the local SQLite database lifecycle, schema creation,
/// migrations up to v7, sync outbox tables, and debug seed data.
///
/// SOLID Principles:
/// - Single Responsibility Principle (SRP): Manages SQLite connection and migrations only.
/// - Open/Closed Principle (OCP): Schema version upgrades handled via standard onUpgrade hooks.
class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _database;

  AppDatabase._internal();

  /// Get database instance to access db operations (singleton pattern).
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database and open at version 7.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'hisbatak_offline.db');

    return await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  static const _createUserProfileTable = '''
    CREATE TABLE user_profile (
      id TEXT PRIMARY KEY, -- stable UUIDv4 identity
      full_name TEXT NOT NULL,
      email TEXT NOT NULL,
      phone_e164 TEXT,
      currency_code TEXT NOT NULL,
      currency_symbol TEXT NOT NULL,
      monthly_budget_limit REAL NOT NULL,
      current_available REAL NOT NULL,
      biometric_enabled INTEGER NOT NULL,
      is_dark_mode INTEGER NOT NULL,
      is_configured INTEGER NOT NULL,
      updated_at TEXT NOT NULL DEFAULT '',
      version INTEGER NOT NULL DEFAULT 1
    )
  ''';

  // All dates are UTC ISO 8601 strings ("2026-10-02T09:15:00.000Z").
  static const _createTransactionsTable = '''
    CREATE TABLE transactions (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      amount REAL NOT NULL,
      category TEXT NOT NULL,
      category_icon TEXT NOT NULL,
      payment_method TEXT NOT NULL,
      date_time TEXT NOT NULL,
      type TEXT NOT NULL, -- 'expense' or 'income'
      group_id TEXT,
      expense_id TEXT,
      updated_at TEXT NOT NULL,
      deleted_at TEXT,
      is_synced INTEGER NOT NULL DEFAULT 0,
      version INTEGER NOT NULL DEFAULT 1,
      idempotency_key TEXT
    )
  ''';

  static const _createGroupsTable = '''
    CREATE TABLE groups (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      icon_name TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      deleted_at TEXT,
      is_synced INTEGER NOT NULL DEFAULT 0,
      version INTEGER NOT NULL DEFAULT 1,
      idempotency_key TEXT
    )
  ''';

  static const _createGroupMembersTable = '''
    CREATE TABLE group_members (
      id TEXT PRIMARY KEY,
      group_id TEXT NOT NULL,
      name TEXT NOT NULL,
      avatar_url TEXT,
      phone_e164 TEXT,
      linked_user_id TEXT,
      note TEXT,
      last_activity TEXT,
      updated_at TEXT NOT NULL,
      deleted_at TEXT,
      is_synced INTEGER NOT NULL DEFAULT 0,
      version INTEGER NOT NULL DEFAULT 1,
      idempotency_key TEXT
    )
  ''';

  static const _createGroupExpensesTable = '''
    CREATE TABLE group_expenses (
      id TEXT PRIMARY KEY,
      group_id TEXT NOT NULL,
      title TEXT NOT NULL,
      total_amount REAL NOT NULL,
      payer_id TEXT NOT NULL,
      payer_name TEXT NOT NULL,
      category TEXT NOT NULL,
      split_method TEXT NOT NULL,
      date_time TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      deleted_at TEXT,
      is_synced INTEGER NOT NULL DEFAULT 0,
      version INTEGER NOT NULL DEFAULT 1,
      idempotency_key TEXT
    )
  ''';

  static const _createExpenseSplitsTable = '''
    CREATE TABLE expense_splits (
      id TEXT PRIMARY KEY,
      expense_id TEXT NOT NULL,
      group_id TEXT NOT NULL,
      member_id TEXT NOT NULL,
      amount REAL NOT NULL,
      percentage REAL NOT NULL,
      is_payer INTEGER NOT NULL,
      updated_at TEXT NOT NULL,
      deleted_at TEXT,
      is_synced INTEGER NOT NULL DEFAULT 0,
      version INTEGER NOT NULL DEFAULT 1,
      idempotency_key TEXT
    )
  ''';

  static const _createSettlementsTable = '''
    CREATE TABLE settlements (
      id TEXT PRIMARY KEY,
      group_id TEXT NOT NULL,
      member_id TEXT NOT NULL,
      amount REAL NOT NULL,
      date_time TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      deleted_at TEXT,
      is_synced INTEGER NOT NULL DEFAULT 0,
      version INTEGER NOT NULL DEFAULT 1,
      idempotency_key TEXT
    )
  ''';

  static const _createSyncOutboxTable = '''
    CREATE TABLE IF NOT EXISTS sync_outbox (
      id TEXT PRIMARY KEY,
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      operation TEXT NOT NULL,
      payload_json TEXT NOT NULL,
      idempotency_key TEXT NOT NULL,
      retry_count INTEGER NOT NULL DEFAULT 0,
      last_error TEXT,
      status TEXT NOT NULL DEFAULT 'pending',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const _createSyncStateTable = '''
    CREATE TABLE IF NOT EXISTS sync_state (
      key TEXT PRIMARY KEY,
      value TEXT,
      updated_at TEXT NOT NULL
    )
  ''';

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute(_createUserProfileTable);
    await db.execute(_createTransactionsTable);
    await db.execute(_createGroupsTable);
    await db.execute(_createGroupMembersTable);
    await db.execute(_createGroupExpensesTable);
    await db.execute(_createExpenseSplitsTable);
    await db.execute(_createSettlementsTable);
    await db.execute(_createSyncOutboxTable);
    await db.execute(_createSyncStateTable);
    await _ensureIndexes(db);

    debugPrint('=========Database v7 tables created successfully============');

    if (kDebugMode) await _seedDatabase(db);
  }

  /// Upgrades a database created by an older app version, step by step.
  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _upgradeToV2(db);
    if (oldVersion < 3) await _upgradeToV3(db);
    if (oldVersion < 4) await _upgradeToV4(db);
    if (oldVersion < 5) await _upgradeToV5(db);
    if (oldVersion < 6) await _upgradeToV6(db);
    if (oldVersion < 7) await _upgradeToV7(db);

    debugPrint('===========Database tables upgraded successfully============');
  }

  Future<void> _safeExecute(Database db, String sql) async {
    try {
      await db.execute(sql);
    } catch (_) {}
  }

  Future<void> _ensureIndexes(Database db) async {
    await _safeExecute(
      db,
      'CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON group_members(group_id)',
    );
    await _safeExecute(
      db,
      'CREATE INDEX IF NOT EXISTS idx_group_members_name ON group_members(name)',
    );
    await _safeExecute(
      db,
      'CREATE INDEX IF NOT EXISTS idx_group_members_phone ON group_members(phone_e164)',
    );
    await _safeExecute(
      db,
      'CREATE INDEX IF NOT EXISTS idx_group_members_linked_user ON group_members(linked_user_id)',
    );
    await _safeExecute(
      db,
      'CREATE INDEX IF NOT EXISTS idx_sync_outbox_status ON sync_outbox(status, created_at)',
    );
  }

  FutureOr<void> _onOpen(Database db) async {
    await _safeExecute(db, 'ALTER TABLE transactions ADD COLUMN group_id TEXT');
    await _safeExecute(db, 'ALTER TABLE transactions ADD COLUMN expense_id TEXT');
    await _safeExecute(db, 'ALTER TABLE user_profile ADD COLUMN phone_e164 TEXT');
    await _safeExecute(db, 'ALTER TABLE group_members ADD COLUMN phone_e164 TEXT');
    await _safeExecute(db, 'ALTER TABLE group_members ADD COLUMN linked_user_id TEXT');
    await _safeExecute(db, _createSyncOutboxTable);
    await _safeExecute(db, _createSyncStateTable);
    await _ensureIndexes(db);
  }

  /// v2: makes the database ready for sync.
  Future<void> _upgradeToV2(Database db) async {
    await db.execute('ALTER TABLE user_profile RENAME TO user_profile_v1');
    await db.execute(_createUserProfileTable);
    await db.execute('''
      INSERT INTO user_profile (
        id, full_name, email, currency_code, currency_symbol,
        monthly_budget_limit, current_available, biometric_enabled,
        is_dark_mode, is_configured
      )
      SELECT 'user_me', full_name, email, currency_code, currency_symbol,
             monthly_budget_limit, current_available, biometric_enabled,
             is_dark_mode, is_configured
      FROM user_profile_v1
      ORDER BY id = 'user_me' DESC
      LIMIT 1
    ''');
    await db.execute('DROP TABLE user_profile_v1');

    await db.execute('ALTER TABLE transactions RENAME TO transactions_v1');
    await db.execute(_createTransactionsTable);
    await db.rawInsert('''
      INSERT INTO transactions (id, title, amount, category, category_icon, payment_method,
                                date_time, type, updated_at, deleted_at, is_synced)
      SELECT id, title, amount, category, category_icon, payment_method,
             date_time, type, ?, NULL, 0
      FROM transactions_v1
    ''', [DateTime.now().toUtc().toIso8601String()]);
    await db.execute('DROP TABLE transactions_v1');

    await _convertDatesToUtc(db, 'transactions', 'date_time');
    await _convertDatesToUtc(db, 'groups', 'created_at');
    await _convertDatesToUtc(db, 'group_expenses', 'date_time');
  }

  /// v3: computed group balances from splits and settlements.
  Future<void> _upgradeToV3(Database db) async {
    final now = DateTime.now().toUtc().toIso8601String();

    await db.execute('ALTER TABLE groups RENAME TO groups_v2');
    await db.execute(_createGroupsTable);
    await db.rawInsert('''
      INSERT INTO groups (id, name, type, icon_name, created_at, updated_at, deleted_at, is_synced)
      SELECT id, name, type, icon_name, created_at, ?, NULL, 0
      FROM groups_v2
    ''', [now]);

    await db.execute('ALTER TABLE group_members RENAME TO group_members_v2');
    await db.execute(_createGroupMembersTable);
    await db.rawInsert('''
      INSERT INTO group_members (id, group_id, name, avatar_url, note, last_activity,
                                 updated_at, deleted_at, is_synced)
      SELECT id, group_id, name, avatar_url, note, last_activity, ?, NULL, 0
      FROM group_members_v2
    ''', [now]);

    await db.execute('ALTER TABLE group_expenses RENAME TO group_expenses_v2');
    await db.execute(_createGroupExpensesTable);
    await db.rawInsert('''
      INSERT INTO group_expenses (id, group_id, title, total_amount, payer_id, payer_name,
                                  category, split_method, date_time, updated_at, deleted_at, is_synced)
      SELECT id, group_id, title, total_amount, payer_id, payer_name,
             category, split_method, date_time, ?, NULL, 0
      FROM group_expenses_v2
    ''', [now]);

    await db.execute(_createExpenseSplitsTable);
    await db.execute(_createSettlementsTable);

    final balances = await db.query(
      'group_members_v2',
      columns: ['id', 'group_id', 'name', 'balance'],
      where: 'balance != 0',
    );
    for (final member in balances) {
      await _insertOpeningBalance(
        db,
        groupId: member['group_id'] as String,
        memberId: member['id'] as String,
        memberName: member['name'] as String,
        balance: (member['balance'] as num).toDouble(),
        at: now,
        synced: false,
      );
    }

    await db.execute('DROP TABLE group_expenses_v2');
    await db.execute('DROP TABLE group_members_v2');
    await db.execute('DROP TABLE groups_v2');
  }

  /// v4: Add group_id and expense_id foreign key references to transactions table.
  Future<void> _upgradeToV4(Database db) async {
    await _safeExecute(db, 'ALTER TABLE transactions ADD COLUMN group_id TEXT');
    await _safeExecute(db, 'ALTER TABLE transactions ADD COLUMN expense_id TEXT');
  }

  /// v5: Ensure group_id and expense_id columns exist on transactions table.
  Future<void> _upgradeToV5(Database db) async {
    await _safeExecute(db, 'ALTER TABLE transactions ADD COLUMN group_id TEXT');
    await _safeExecute(db, 'ALTER TABLE transactions ADD COLUMN expense_id TEXT');
  }

  /// v6: Add indexes on group_members for fast cross-group member aggregation and lookups.
  Future<void> _upgradeToV6(Database db) async {
    await _safeExecute(
      db,
      'CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON group_members(group_id)',
    );
    await _safeExecute(
      db,
      'CREATE INDEX IF NOT EXISTS idx_group_members_name ON group_members(name)',
    );
  }

  /// v7: Replace legacy `'user_me'` identity with persistent UUIDv4, add phone E.164,
  /// shadow-member linking (`linked_user_id`), versioning, idempotency keys, and outbox/sync_state tables.
  Future<void> _upgradeToV7(Database db) async {
    await _safeExecute(db, 'ALTER TABLE user_profile ADD COLUMN phone_e164 TEXT');
    await _safeExecute(
      db,
      "ALTER TABLE user_profile ADD COLUMN updated_at TEXT NOT NULL DEFAULT ''",
    );
    await _safeExecute(
      db,
      'ALTER TABLE user_profile ADD COLUMN version INTEGER NOT NULL DEFAULT 1',
    );

    await _safeExecute(db, 'ALTER TABLE group_members ADD COLUMN phone_e164 TEXT');
    await _safeExecute(db, 'ALTER TABLE group_members ADD COLUMN linked_user_id TEXT');

    const syncTables = [
      'transactions',
      'groups',
      'group_members',
      'group_expenses',
      'expense_splits',
      'settlements',
    ];
    for (final table in syncTables) {
      await _safeExecute(
        db,
        'ALTER TABLE $table ADD COLUMN version INTEGER NOT NULL DEFAULT 1',
      );
      await _safeExecute(
        db,
        'ALTER TABLE $table ADD COLUMN idempotency_key TEXT',
      );
    }

    await db.execute(_createSyncOutboxTable);
    await db.execute(_createSyncStateTable);
    await _ensureIndexes(db);

    // Replace legacy `'user_me'` user id cleanly across profile, expenses, and splits.
    final profiles = await db.query('user_profile', columns: ['id'], limit: 1);
    if (profiles.isNotEmpty) {
      final currentId = profiles.first['id'] as String?;
      if (currentId == null || currentId.isEmpty || currentId == 'user_me') {
        final migratedUuid = IdGenerator.uuidV4();
        final now = DateTime.now().toUtc().toIso8601String();
        await db.update(
          'user_profile',
          {'id': migratedUuid, 'updated_at': now},
          where: 'id = ?',
          whereArgs: [currentId ?? 'user_me'],
        );
        await db.rawUpdate(
          "UPDATE group_expenses SET payer_id = ? WHERE payer_id = 'user_me'",
          [migratedUuid],
        );
        await db.rawUpdate(
          "UPDATE expense_splits SET member_id = ?, id = REPLACE(id, ':user_me', ':' || ?) WHERE member_id = 'user_me'",
          [migratedUuid, migratedUuid],
        );
      }
    }
  }

  static Future<void> _insertOpeningBalance(
    DatabaseExecutor db, {
    required String groupId,
    required String memberId,
    required String memberName,
    required double balance,
    required String at,
    required bool synced,
    String currentUserId = 'user_me',
  }) async {
    if (balance == 0) return;
    final memberOwesYou = balance > 0;
    final expenseId = 'opening_${groupId}_$memberId';
    final debtorId = memberOwesYou ? memberId : currentUserId;
    final syncColumns = {
      'updated_at': at,
      'deleted_at': null,
      'is_synced': synced ? 1 : 0,
      'version': 1,
    };

    await db.insert('group_expenses', {
      'id': expenseId,
      'group_id': groupId,
      'title': 'رصيد سابق',
      'total_amount': balance.abs(),
      'payer_id': memberOwesYou ? currentUserId : memberId,
      'payer_name': memberOwesYou ? 'أنت' : memberName,
      'category': 'رصيد سابق',
      'split_method': 'custom',
      'date_time': at,
      ...syncColumns,
    });
    await db.insert('expense_splits', {
      'id': '$expenseId:$debtorId',
      'expense_id': expenseId,
      'group_id': groupId,
      'member_id': debtorId,
      'amount': balance.abs(),
      'percentage': 100.0,
      'is_payer': 0,
      ...syncColumns,
    });
  }

  Future<void> _convertDatesToUtc(
    Database db,
    String table,
    String column,
  ) async {
    final rows = await db.query(table, columns: ['id', column]);
    for (final row in rows) {
      final value = row[column] as String?;
      if (value == null || value.endsWith('Z')) continue;
      await db.update(
        table,
        {column: DateTime.parse(value).toUtc().toIso8601String()},
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }

  Future<void> _seedDatabase(Database db) async {
    final seededAt = DateTime.now().toUtc().toIso8601String();
    final demoUserId = IdGenerator.uuidV4();

    // Seed Profile
    await db.insert('user_profile', {
      'id': demoUserId,
      'full_name': 'مجد المذحجي',
      'email': 'tariq.mansour@offline.local',
      'phone_e164': '+967770000000',
      'currency_code': 'SAR',
      'currency_symbol': 'ر.س',
      'monthly_budget_limit': 20000.0,
      'current_available': 14850.0,
      'biometric_enabled': 1,
      'is_dark_mode': 0,
      'is_configured': 1,
      'updated_at': seededAt,
      'version': 1,
    });

    final now = DateTime.now();
    await db.insert('transactions', {
      'id': 'tx_1',
      'title': 'سوبرماركت الدانوب',
      'amount': 340.0,
      'category': 'بقالة وتموين',
      'category_icon': 'shopping_cart',
      'payment_method': 'فاتورة مشتركة',
      'date_time': DateTime(now.year, now.month, now.day, 16, 15)
          .toUtc()
          .toIso8601String(),
      'type': 'expense',
      'group_id': 'grp_work',
      'expense_id': 'exp_danube_1',
      'updated_at': seededAt,
      'is_synced': 1,
      'version': 1,
    });

    await db.insert('transactions', {
      'id': 'tx_2',
      'title': 'تحويل ميزانية شخصية',
      'amount': 4000.0,
      'category': 'إيداع نقدي',
      'category_icon': 'account_balance',
      'payment_method': 'مكتمل',
      'date_time': DateTime(now.year, now.month, now.day - 1, 9, 30)
          .toUtc()
          .toIso8601String(),
      'type': 'income',
      'updated_at': seededAt,
      'is_synced': 1,
      'version': 1,
    });

    await db.insert('transactions', {
      'id': 'tx_3',
      'title': 'قهوة مختصة',
      'amount': 28.0,
      'category': 'مطاعم ومقاهي',
      'category_icon': 'local_cafe',
      'payment_method': 'Apple Pay',
      'date_time': DateTime(now.year, now.month, now.day - 1, 8, 10)
          .toUtc()
          .toIso8601String(),
      'type': 'expense',
      'updated_at': seededAt,
      'is_synced': 1,
      'version': 1,
    });

    await db.insert('transactions', {
      'id': 'tx_4',
      'title': 'اشتراك إنترنت منزلي',
      'amount': 290.0,
      'category': 'فواتير ومسكن',
      'category_icon': 'wifi',
      'payment_method': 'سداد آلي',
      'date_time': DateTime(now.year, 6, 22, 11, 00).toUtc().toIso8601String(),
      'type': 'expense',
      'updated_at': seededAt,
      'is_synced': 1,
      'version': 1,
    });

    // Seed Groups
    await db.insert('groups', {
      'id': 'grp_work',
      'name': 'زملاء العمل',
      'type': 'work',
      'icon_name': 'apartment',
      'created_at': DateTime(now.year, now.month, 1).toUtc().toIso8601String(),
      'updated_at': seededAt,
      'is_synced': 1,
      'version': 1,
    });

    await db.insert('groups', {
      'id': 'grp_home',
      'name': 'سكن الشباب',
      'type': 'home',
      'icon_name': 'home',
      'created_at':
          DateTime(now.year, now.month - 1, 15).toUtc().toIso8601String(),
      'updated_at': seededAt,
      'is_synced': 1,
      'version': 1,
    });

    await db.insert('groups', {
      'id': 'grp_trip',
      'name': 'رحلة أبها',
      'type': 'trip',
      'icon_name': 'hiking',
      'created_at': DateTime(now.year, now.month, 5).toUtc().toIso8601String(),
      'updated_at': seededAt,
      'is_synced': 1,
      'version': 1,
    });

    const workMembers = [
      ('mem_1', 'خالد العتيبي', 120.0, 'غداء العمل الأخير', 'قبل يومين', '+966501112233'),
      ('mem_2', 'سارة الشمري', -50.0, 'طلب القهوة الأسبوعي', 'أمس', '+966504445566'),
      ('mem_3', 'فهد الدوسري', 200.0, 'تذاكر ورشة التقنية', '12 مايو', '+966507778899'),
      ('mem_4', 'أحمد ناصر', 0.0, 'تمت التسوية', 'الأسبوع الماضي', null),
    ];
    for (final (id, name, balance, note, lastActivity, phone) in workMembers) {
      await db.insert('group_members', {
        'id': id,
        'group_id': 'grp_work',
        'name': name,
        'avatar_url': null,
        'phone_e164': phone,
        'linked_user_id': null,
        'note': note,
        'last_activity': lastActivity,
        'updated_at': seededAt,
        'is_synced': 1,
        'version': 1,
      });
      await _insertOpeningBalance(
        db,
        groupId: 'grp_work',
        memberId: id,
        memberName: name,
        balance: balance,
        at: seededAt,
        synced: true,
        currentUserId: demoUserId,
      );
    }

    await db.insert('group_expenses', {
      'id': 'exp_danube_1',
      'group_id': 'grp_work',
      'title': 'سوبرماركت الدانوب',
      'total_amount': 340.0,
      'payer_id': demoUserId,
      'payer_name': 'أنت',
      'category': 'بقالة وتموين',
      'split_method': 'equal',
      'date_time': DateTime(now.year, now.month, now.day, 16, 15)
          .toUtc()
          .toIso8601String(),
      'updated_at': seededAt,
      'is_synced': 1,
      'version': 1,
    });
    await db.insert('expense_splits', {
      'id': 'exp_danube_1:$demoUserId',
      'expense_id': 'exp_danube_1',
      'group_id': 'grp_work',
      'member_id': demoUserId,
      'amount': 113.34,
      'percentage': 33.34,
      'is_payer': 1,
      'updated_at': seededAt,
      'is_synced': 1,
      'version': 1,
    });
    await db.insert('expense_splits', {
      'id': 'exp_danube_1:mem_1',
      'expense_id': 'exp_danube_1',
      'group_id': 'grp_work',
      'member_id': 'mem_1',
      'amount': 113.33,
      'percentage': 33.33,
      'is_payer': 0,
      'updated_at': seededAt,
      'is_synced': 1,
      'version': 1,
    });
    await db.insert('expense_splits', {
      'id': 'exp_danube_1:mem_2',
      'expense_id': 'exp_danube_1',
      'group_id': 'grp_work',
      'member_id': 'mem_2',
      'amount': 113.33,
      'percentage': 33.33,
      'is_payer': 0,
      'updated_at': seededAt,
      'is_synced': 1,
      'version': 1,
    });
  }
}
