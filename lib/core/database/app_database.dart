import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// [AppDatabase] manages the local SQLite database lifecycle, schema creation,
/// and initial seed data for Hisbatak's offline-first architecture.
///
/// SOLID Principles:
/// - Single Responsibility Principle (SRP): Manages SQLite connection and migrations only.
/// - Open/Closed Principle (OCP): Schema version upgrades handled via standard onUpgrade hooks.
class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _database;

  AppDatabase._internal();

  ///Get database instance to access db operations (singleton pattern)
  ///This function is called/invoked every time the app is started
  Future<Database> get database async {
    //if the database is already initialized, return the database
    if (_database != null) return _database!;

    //otherwise, initialize the database and return it
    _database = await _initDatabase();
    return _database!;
  }

  ///Initialize database and create tables (will be triggered/invoked when the app is installed for the first time)
  Future<Database> _initDatabase() async {
    //get the database path that is in the application documents directory
    final dbPath = await getDatabasesPath();
    //join the database path with the database name
    final path = join(dbPath, 'hisbatak_offline.db');

    //open the database and create tables if not exists for first time , and upgrade the database if the version is greater than the current version
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Shared by onCreate and the v1 -> v2 upgrade, so fresh and upgraded
  // installs end up with exactly the same tables.
  static const _createUserProfileTable = '''
    CREATE TABLE user_profile (
      id TEXT PRIMARY KEY, -- always 'user_me'
      full_name TEXT NOT NULL,
      email TEXT NOT NULL,
      currency_code TEXT NOT NULL,
      currency_symbol TEXT NOT NULL,
      monthly_budget_limit REAL NOT NULL,
      current_available REAL NOT NULL,
      biometric_enabled INTEGER NOT NULL,
      is_dark_mode INTEGER NOT NULL,
      is_configured INTEGER NOT NULL
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
      updated_at TEXT NOT NULL, -- last local edit; the later edit wins a sync conflict
      deleted_at TEXT, -- set instead of deleting the row, so the deletion can sync
      is_synced INTEGER NOT NULL DEFAULT 0 -- 0: changed since the last sync
    )
  ''';

  // The group tables carry the same sync columns as transactions. They have
  // no foreign keys: rows pulled from the server can arrive in any order
  // (a member before its group). Member counts and balances aren't stored;
  // GroupLocalDataSourceImpl computes them.
  static const _createGroupsTable = '''
    CREATE TABLE groups (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      type TEXT NOT NULL, -- 'work', 'home', 'trip', 'other'
      icon_name TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      deleted_at TEXT,
      is_synced INTEGER NOT NULL DEFAULT 0
    )
  ''';

  static const _createGroupMembersTable = '''
    CREATE TABLE group_members (
      id TEXT PRIMARY KEY,
      group_id TEXT NOT NULL,
      name TEXT NOT NULL,
      avatar_url TEXT,
      note TEXT, -- latest activity, for display
      last_activity TEXT,
      updated_at TEXT NOT NULL,
      deleted_at TEXT,
      is_synced INTEGER NOT NULL DEFAULT 0
    )
  ''';

  static const _createGroupExpensesTable = '''
    CREATE TABLE group_expenses (
      id TEXT PRIMARY KEY,
      group_id TEXT NOT NULL,
      title TEXT NOT NULL,
      total_amount REAL NOT NULL,
      payer_id TEXT NOT NULL, -- 'user_me' when you paid
      payer_name TEXT NOT NULL,
      category TEXT NOT NULL,
      split_method TEXT NOT NULL, -- 'equal', 'percentage', 'custom'
      date_time TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      deleted_at TEXT,
      is_synced INTEGER NOT NULL DEFAULT 0
    )
  ''';

  // Each participant's share of a shared expense. Balances are computed from
  // these and from settlements, so two devices adding expenses offline both
  // count once they sync.
  static const _createExpenseSplitsTable = '''
    CREATE TABLE expense_splits (
      id TEXT PRIMARY KEY, -- '<expense_id>:<member_id>'
      expense_id TEXT NOT NULL,
      group_id TEXT NOT NULL,
      member_id TEXT NOT NULL, -- 'user_me' for you
      amount REAL NOT NULL,
      percentage REAL NOT NULL,
      is_payer INTEGER NOT NULL,
      updated_at TEXT NOT NULL,
      deleted_at TEXT,
      is_synced INTEGER NOT NULL DEFAULT 0
    )
  ''';

  static const _createSettlementsTable = '''
    CREATE TABLE settlements (
      id TEXT PRIMARY KEY,
      group_id TEXT NOT NULL,
      member_id TEXT NOT NULL,
      amount REAL NOT NULL, -- positive: the member paid you; negative: you paid the member
      date_time TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      deleted_at TEXT,
      is_synced INTEGER NOT NULL DEFAULT 0
    )
  ''';

  ///Function of creating tables (will be triggered/invoked when the app is installed for the first time)
  FutureOr<void> _onCreate(Database db, int version) async {
    // 1. User Profile Table
    await db.execute(_createUserProfileTable);

    // 2. Personal Transactions Table
    await db.execute(_createTransactionsTable);

    // 3. Groups Table
    await db.execute(_createGroupsTable);

    // 4. Group Members Table
    await db.execute(_createGroupMembersTable);

    // 5. Group Shared Expenses Table, with each participant's share and the settlements
    await db.execute(_createGroupExpensesTable);
    await db.execute(_createExpenseSplitsTable);
    await db.execute(_createSettlementsTable);

    // 6. Seed demo data matching the Stitch designs, in debug builds only:
    // real users start empty, and the demo rows must never sync to their accounts.
    if (kDebugMode) await _seedDatabase(db);
  }

  ///Upgrades a database created by an older app version, step by step.
  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _upgradeToV2(db);
    if (oldVersion < 3) await _upgradeToV3(db);
  }

  /// v2: makes the database ready for sync.
  /// - user_profile.id becomes TEXT (v1 declared INTEGER, which rejects 'user_me').
  /// - transactions gains updated_at, deleted_at, and a working is_synced flag.
  /// - stored dates move from device-local time to UTC.
  Future<void> _upgradeToV2(Database db) async {
    // SQLite can't change a column's type in place, so both tables are rebuilt.
    await db.execute('ALTER TABLE user_profile RENAME TO user_profile_v1');
    await db.execute(_createUserProfileTable);
    await db.execute('''
      INSERT INTO user_profile
      SELECT 'user_me', full_name, email, currency_code, currency_symbol, monthly_budget_limit,
             current_available, biometric_enabled, is_dark_mode, is_configured
      FROM user_profile_v1
      ORDER BY id = 'user_me' DESC
      LIMIT 1
    ''');
    await db.execute('DROP TABLE user_profile_v1');

    await db.execute('ALTER TABLE transactions RENAME TO transactions_v1');
    await db.execute(_createTransactionsTable);
    // is_synced = 0: nothing has ever reached the server, so every row uploads on the first sync.
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

  /// v3: group balances are computed from each expense's splits and from
  /// settlements instead of being stored, so expenses added on two devices
  /// offline both count once they sync.
  /// - new tables: expense_splits and settlements.
  /// - the group tables gain the sync columns and lose the stored
  ///   member_count and balance (both are computed now).
  /// - each member's stored balance carries over as an opening balance.
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

    // v2 never saved splits, so the old expenses add nothing to the computed
    // balances; the stored balance already includes them.
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

  /// Records a balance that existed before splits were saved (or a demo
  /// balance) as one past expense with a single split, so it adds up like any
  /// other expense: positive means the member owes you.
  static Future<void> _insertOpeningBalance(
    DatabaseExecutor db, {
    required String groupId,
    required String memberId,
    required String memberName,
    required double balance,
    required String at,
    required bool synced,
  }) async {
    if (balance == 0) return;
    final memberOwesYou = balance > 0;
    final expenseId = 'opening_${groupId}_$memberId';
    final debtorId = memberOwesYou ? memberId : 'user_me';
    final syncColumns = {'updated_at': at, 'deleted_at': null, 'is_synced': synced ? 1 : 0};

    await db.insert('group_expenses', {
      'id': expenseId,
      'group_id': groupId,
      'title': 'رصيد سابق',
      'total_amount': balance.abs(),
      'payer_id': memberOwesYou ? 'user_me' : memberId,
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

  /// v1 stored dates as DateTime.toIso8601String() of local times: no time
  /// zone in the string. Read on the same device, they still mean local time.
  Future<void> _convertDatesToUtc(Database db, String table, String column) async {
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

    // Seed Profile
    await db.insert('user_profile', {
      'id': 'user_me',
      'full_name': 'مجد المذحجي',
      'email': 'tariq.mansour@offline.local',
      'currency_code': 'SAR',
      'currency_symbol': 'ر.س',
      'monthly_budget_limit': 20000.0,
      'current_available': 14850.0,
      'biometric_enabled': 1,
      'is_dark_mode': 0,
      'is_configured': 1,
    });

    // Seed Personal Transactions matching Screen 2
    final now = DateTime.now();
    await db.insert('transactions', {
      'id': 'tx_1',
      'title': 'سوبرماركت الدانوب',
      'amount': 340.0,
      'category': 'بقالة وتموين',
      'category_icon': 'shopping_cart',
      'payment_method': 'مدى • من البطاقة',
      'date_time':
          DateTime(now.year, now.month, now.day, 16, 15).toUtc().toIso8601String(),
      'type': 'expense',
      'updated_at': seededAt,
      'is_synced': 1,
    });

    await db.insert('transactions', {
      'id': 'tx_2',
      'title': 'تحويل ميزانية شخصية',
      'amount': 4000.0,
      'category': 'إيداع نقدي',
      'category_icon': 'account_balance',
      'payment_method': 'مكتمل',
      'date_time':
          DateTime(now.year, now.month, now.day - 1, 9, 30).toUtc().toIso8601String(),
      'type': 'income',
      'updated_at': seededAt,
      'is_synced': 1,
    });

    await db.insert('transactions', {
      'id': 'tx_3',
      'title': 'قهوة مختصة',
      'amount': 28.0,
      'category': 'مطاعم ومقاهي',
      'category_icon': 'local_cafe',
      'payment_method': 'Apple Pay',
      'date_time':
          DateTime(now.year, now.month, now.day - 1, 8, 10).toUtc().toIso8601String(),
      'type': 'expense',
      'updated_at': seededAt,
      'is_synced': 1,
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
    });

    // Seed Groups matching Screen 3
    await db.insert('groups', {
      'id': 'grp_work',
      'name': 'زملاء العمل',
      'type': 'work',
      'icon_name': 'apartment',
      'created_at': DateTime(now.year, now.month, 1).toUtc().toIso8601String(),
      'updated_at': seededAt,
      'is_synced': 1,
    });

    await db.insert('groups', {
      'id': 'grp_home',
      'name': 'سكن الشباب',
      'type': 'home',
      'icon_name': 'home',
      'created_at': DateTime(now.year, now.month - 1, 15).toUtc().toIso8601String(),
      'updated_at': seededAt,
      'is_synced': 1,
    });

    await db.insert('groups', {
      'id': 'grp_trip',
      'name': 'رحلة أبها',
      'type': 'trip',
      'icon_name': 'hiking',
      'created_at': DateTime(now.year, now.month, 5).toUtc().toIso8601String(),
      'updated_at': seededAt,
      'is_synced': 1,
    });

    // Seed Members for 'grp_work' (matching exact UI debts from Screen 3).
    // Balances are computed, so each demo debt is seeded as an opening balance.
    const workMembers = [
      ('mem_1', 'خالد العتيبي', 120.0, 'غداء العمل الأخير', 'قبل يومين'), // خالد مدين لك بمبلغ 120
      ('mem_2', 'سارة الشمري', -50.0, 'طلب القهوة الأسبوعي', 'أمس'), // أنت مدين لها بمبلغ 50
      ('mem_3', 'فهد الدوسري', 200.0, 'تذاكر ورشة التقنية', '12 مايو'), // فهد مدين لك بمبلغ 200
      ('mem_4', 'أحمد ناصر', 0.0, 'تمت التسوية', 'الأسبوع الماضي'), // الحساب متوازن
    ];
    for (final (id, name, balance, note, lastActivity) in workMembers) {
      await db.insert('group_members', {
        'id': id,
        'group_id': 'grp_work',
        'name': name,
        'avatar_url': null,
        'note': note,
        'last_activity': lastActivity,
        'updated_at': seededAt,
        'is_synced': 1,
      });
      await _insertOpeningBalance(
        db,
        groupId: 'grp_work',
        memberId: id,
        memberName: name,
        balance: balance,
        at: seededAt,
        synced: true,
      );
    }
  }
}
