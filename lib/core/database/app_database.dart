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
      version: 2,
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

  ///Function of creating tables (will be triggered/invoked when the app is installed for the first time)
  FutureOr<void> _onCreate(Database db, int version) async {
    // 1. User Profile Table
    await db.execute(_createUserProfileTable);

    // 2. Personal Transactions Table
    await db.execute(_createTransactionsTable);

    // 3. Groups Table
    await db.execute('''
      CREATE TABLE groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        member_count INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 4. Group Members Table
    await db.execute('''
      CREATE TABLE group_members (
        id TEXT PRIMARY KEY,
        group_id TEXT NOT NULL,
        name TEXT NOT NULL,
        avatar_url TEXT,
        balance REAL NOT NULL, -- positive: owes user, negative: user owes them, 0: balanced
        note TEXT,
        last_activity TEXT,
        FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
      )
    ''');

    // 5. Group Shared Expenses Table
    await db.execute('''
      CREATE TABLE group_expenses (
        id TEXT PRIMARY KEY,
        group_id TEXT NOT NULL,
        title TEXT NOT NULL,
        total_amount REAL NOT NULL,
        payer_id TEXT NOT NULL,
        payer_name TEXT NOT NULL,
        category TEXT NOT NULL,
        split_method TEXT NOT NULL, -- 'equal', 'percentage', 'custom'
        date_time TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
      )
    ''');

    // 6. Seed demo data matching the Stitch designs, in debug builds only:
    // real users start empty, and the demo rows must never sync to their accounts.
    if (kDebugMode) await _seedDatabase(db);
  }

  ///Upgrades a database created by an older app version, step by step.
  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _upgradeToV2(db);
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
      'member_count': 4,
      'created_at': DateTime(now.year, now.month, 1).toUtc().toIso8601String(),
    });

    await db.insert('groups', {
      'id': 'grp_home',
      'name': 'سكن الشباب',
      'type': 'home',
      'icon_name': 'home',
      'member_count': 3,
      'created_at': DateTime(now.year, now.month - 1, 15).toUtc().toIso8601String(),
    });

    await db.insert('groups', {
      'id': 'grp_trip',
      'name': 'رحلة أبها',
      'type': 'trip',
      'icon_name': 'hiking',
      'member_count': 5,
      'created_at': DateTime(now.year, now.month, 5).toUtc().toIso8601String(),
    });

    // Seed Members for 'grp_work' (matching exact UI debts from Screen 3)
    await db.insert('group_members', {
      'id': 'mem_1',
      'group_id': 'grp_work',
      'name': 'خالد العتيبي',
      'avatar_url': null,
      'balance': 120.0, // خالد مدين لك بمبلغ 120
      'note': 'غداء العمل الأخير',
      'last_activity': 'قبل يومين',
    });

    await db.insert('group_members', {
      'id': 'mem_2',
      'group_id': 'grp_work',
      'name': 'سارة الشمري',
      'avatar_url': null,
      'balance': -50.0, // أنت مدين لها بمبلغ 50
      'note': 'طلب القهوة الأسبوعي',
      'last_activity': 'أمس',
    });

    await db.insert('group_members', {
      'id': 'mem_3',
      'group_id': 'grp_work',
      'name': 'فهد الدوسري',
      'avatar_url': null,
      'balance': 200.0, // فهد مدين لك بمبلغ 200
      'note': 'تذاكر ورشة التقنية',
      'last_activity': '12 مايو',
    });

    await db.insert('group_members', {
      'id': 'mem_4',
      'group_id': 'grp_work',
      'name': 'أحمد ناصر',
      'avatar_url': null,
      'balance': 0.0, // الحساب متوازن
      'note': 'تمت التسوية',
      'last_activity': 'الأسبوع الماضي',
    });
  }
}
