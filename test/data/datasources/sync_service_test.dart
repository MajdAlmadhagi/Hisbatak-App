import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisbatak_app/core/database/app_database.dart';
import 'package:hisbatak_app/data/datasources/auth/auth_local_data_source.dart';
import 'package:hisbatak_app/data/datasources/sync/sync_service.dart';
import 'package:hisbatak_app/domain/entities/auth_session.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class _InMemoryDatabase extends Fake implements Database, Transaction {
  final Map<String, List<Map<String, Object?>>> tables = {
    'sync_outbox': [],
    'sync_state': [],
    'user_profile': [],
    'transactions': [],
    'groups': [],
    'group_members': [],
    'group_expenses': [],
    'expense_splits': [],
    'settlements': [],
  };

  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action, {
    bool? exclusive,
  }) {
    return action(this);
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    if (sql.contains('sync_outbox') && sql.contains('COUNT(*)')) {
      final cnt = tables['sync_outbox']!
          .where((r) => r['status'] == 'pending' || r['status'] == 'failed')
          .length;
      return [
        {'cnt': cnt},
      ];
    }
    return [];
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    var rows = List<Map<String, Object?>>.from(tables[table] ?? const []);
    if (where != null) {
      if (where == "status IN ('pending', 'failed')") {
        rows = rows
            .where((r) => r['status'] == 'pending' || r['status'] == 'failed')
            .toList();
      } else if (where == 'key = ?' && whereArgs != null) {
        rows = rows.where((r) => r['key'] == whereArgs.first).toList();
      } else if (where == 'id = ?' && whereArgs != null) {
        rows = rows.where((r) => r['id'] == whereArgs.first).toList();
      }
    }
    if (limit != null && rows.length > limit) {
      rows = rows.sublist(0, limit);
    }
    return rows.map((r) => Map<String, Object?>.from(r)).toList();
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final list = tables.putIfAbsent(table, () => []);
    final keyCol = table == 'sync_state' ? 'key' : 'id';
    final keyVal = values[keyCol];
    final existingIdx = list.indexWhere((r) => r[keyCol] == keyVal);
    if (existingIdx != -1 && conflictAlgorithm == ConflictAlgorithm.replace) {
      list[existingIdx] = Map<String, Object?>.from(values);
    } else {
      list.add(Map<String, Object?>.from(values));
    }
    return 1;
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final list = tables[table] ?? [];
    int updated = 0;
    for (final row in list) {
      if (where == 'id = ?' && whereArgs != null && row['id'] == whereArgs[0]) {
        row.addAll(values);
        updated++;
      }
    }
    return updated;
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final list = tables[table] ?? [];
    final before = list.length;
    if (where == 'entity_type = ? AND entity_id = ? AND status = ?' &&
        whereArgs != null) {
      list.removeWhere(
        (r) =>
            r['entity_type'] == whereArgs[0] &&
            r['entity_id'] == whereArgs[1] &&
            r['status'] == whereArgs[2],
      );
    }
    return before - list.length;
  }
}

class _FakeAppDatabase extends Fake implements AppDatabase {
  final _InMemoryDatabase db;
  _FakeAppDatabase(this.db);

  @override
  Future<Database> get database async => db;
}

class _FakeAuthLocalDataSource implements IAuthLocalDataSource {
  AuthSession? session;
  AuthConnectionMode mode = AuthConnectionMode.online;

  _FakeAuthLocalDataSource(this.session);

  @override
  Future<void> cacheSession(AuthSession session) async => this.session = session;

  @override
  Future<void> clearSession() async => session = null;

  @override
  Future<AuthSession?> getCachedSession() async => session;

  @override
  Future<AuthConnectionMode> getPreferredConnectionMode() async => mode;

  @override
  Future<void> savePreferredConnectionMode(AuthConnectionMode mode) async =>
      this.mode = mode;
}

void main() {
  late _InMemoryDatabase db;
  late SharedPreferences prefs;

  final onlineSession = AuthSession(
    userId: '550e8400-e29b-41d4-a716-446655440000',
    name: 'أحمد علي',
    email: '+967770000000@phone.hisbatak.app',
    connectionMode: AuthConnectionMode.online,
    token: 'jwt_test_token',
    createdAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = _InMemoryDatabase();
  });

  group('SyncServiceImpl', () {
    test('returns cloudConfigured=false gracefully when no endpoint configured',
        () async {
      db.tables['sync_outbox']!.add({
        'id': 'out_1',
        'entity_type': 'transaction',
        'entity_id': 'tx_1',
        'operation': 'upsert',
        'payload_json': '{}',
        'idempotency_key': 'idem_1',
        'status': 'pending',
        'retry_count': 0,
        'created_at': '2026-11-01T10:00:00Z',
        'updated_at': '2026-11-01T10:00:00Z',
      });

      final service = SyncServiceImpl(
        appDatabase: _FakeAppDatabase(db),
        preferences: prefs,
        authLocalDataSource: _FakeAuthLocalDataSource(onlineSession),
        client: MockClient((_) async => http.Response('{}', 200)),
      );

      final summary = await service.syncNow();
      expect(summary.cloudConfigured, isFalse);
      expect(summary.pushedCount, 0);
      expect(summary.pendingRemaining, 1);
      expect(summary.isSuccess, isTrue);
    });

    test(
        'pushes outbox items, marks synced, pulls remote updates, and applies LWW conflicts',
        () async {
      // Seed pending local transaction tx_push
      db.tables['transactions']!.add({
        'id': 'tx_push',
        'title': 'قهوة محلية',
        'amount': 15.0,
        'is_synced': 0,
        'version': 1,
        'updated_at': '2026-11-12T10:00:00Z',
      });
      db.tables['sync_outbox']!.add({
        'id': 'out_push_1',
        'entity_type': 'transaction',
        'entity_id': 'tx_push',
        'operation': 'upsert',
        'payload_json': jsonEncode({'id': 'tx_push', 'amount': 15.0}),
        'idempotency_key': 'idem_push_1',
        'status': 'pending',
        'retry_count': 0,
        'created_at': '2026-11-12T10:00:00Z',
        'updated_at': '2026-11-12T10:00:00Z',
      });

      // Local unpushed edit tx_conflict that must win same-version timestamp tie
      db.tables['transactions']!.add({
        'id': 'tx_conflict',
        'title': 'نسختي الأحدث',
        'amount': 99.0,
        'is_synced': 0,
        'version': 2,
        'updated_at': '2026-11-12T12:00:00Z',
      });

      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer jwt_test_token');
        if (request.url.path.endsWith('/sync/push')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect((body['operations'] as List).length, 1);
          return http.Response(
            jsonEncode({
              'acknowledged_ids': ['out_push_1'],
            }),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path.endsWith('/sync/pull')) {
          return http.Response(
            jsonEncode({
              'next_cursor': 'cursor_42',
              'changes': [
                {
                  'entity_type': 'transaction',
                  'data': {
                    'id': 'tx_remote_new',
                    'title': 'عشاء مشترك',
                    'amount': 120.0,
                    'category': 'مطاعم',
                    'category_icon': 'local_cafe',
                    'payment_method': 'نقدي',
                    'date_time': '2026-11-12T13:00:00Z',
                    'type': 'expense',
                    'version': 1,
                    'updated_at': '2026-11-12T13:00:00Z',
                  },
                },
                {
                  // Stale remote version=2 same timestamp should NOT overwrite unpushed local edit
                  'entity_type': 'transaction',
                  'data': {
                    'id': 'tx_conflict',
                    'title': 'نسخة قديمة من الخادم',
                    'amount': 50.0,
                    'version': 2,
                    'updated_at': '2026-11-12T12:00:00Z',
                  },
                },
              ],
            }),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = SyncServiceImpl(
        appDatabase: _FakeAppDatabase(db),
        preferences: prefs,
        authLocalDataSource: _FakeAuthLocalDataSource(onlineSession),
        client: client,
        baseUrlOverride: 'https://api.example.com',
      );

      final summary = await service.syncNow();
      expect(summary.isSuccess, isTrue, reason: summary.errorMessage);
      expect(summary.cloudConfigured, isTrue);
      expect(summary.pushedCount, 1);
      expect(summary.pulledCount, 1); // tx_remote_new applied; tx_conflict preserved
      expect(summary.pendingRemaining, 0);

      final pushedTx = db.tables['transactions']!
          .firstWhere((r) => r['id'] == 'tx_push');
      expect(pushedTx['is_synced'], 1);

      final outboxRow = db.tables['sync_outbox']!
          .firstWhere((r) => r['id'] == 'out_push_1');
      expect(outboxRow['status'], 'synced');

      final conflictTx = db.tables['transactions']!
          .firstWhere((r) => r['id'] == 'tx_conflict');
      expect(conflictTx['title'], 'نسختي الأحدث');

      final cursorRow = db.tables['sync_state']!
          .firstWhere((r) => r['key'] == 'pull_cursor');
      expect(cursorRow['value'], 'cursor_42');
    });

    test('marks outbox items as failed and increments retry_count on HTTP 500',
        () async {
      db.tables['sync_outbox']!.add({
        'id': 'out_err',
        'entity_type': 'transaction',
        'entity_id': 'tx_err',
        'operation': 'upsert',
        'payload_json': '{}',
        'idempotency_key': 'idem_err',
        'status': 'pending',
        'retry_count': 0,
        'created_at': '2026-11-12T10:00:00Z',
        'updated_at': '2026-11-12T10:00:00Z',
      });

      final service = SyncServiceImpl(
        appDatabase: _FakeAppDatabase(db),
        preferences: prefs,
        authLocalDataSource: _FakeAuthLocalDataSource(onlineSession),
        client: MockClient((_) async => http.Response('Server Error', 500)),
        baseUrlOverride: 'https://api.example.com',
      );

      final summary = await service.syncNow();
      expect(summary.isSuccess, isFalse);
      expect(summary.pendingRemaining, 1);

      final row = db.tables['sync_outbox']!.first;
      expect(row['status'], 'failed');
      expect(row['retry_count'], 1);
      expect(row['last_error'], 'HTTP 500');
    });
  });
}
