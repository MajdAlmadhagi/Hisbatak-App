import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/constants/app_apis.dart';
import '../../../core/constants/app_keys.dart';
import '../../../core/database/app_database.dart';
import '../auth/auth_local_data_source.dart';

/// Result summary of a single Push/Pull sync execution.
class SyncSummary {
  final int pushedCount;
  final int pulledCount;
  final int pendingRemaining;
  final String syncedAtIso;
  final bool cloudConfigured;
  final String? errorMessage;

  const SyncSummary({
    required this.pushedCount,
    required this.pulledCount,
    required this.pendingRemaining,
    required this.syncedAtIso,
    required this.cloudConfigured,
    this.errorMessage,
  });

  bool get isSuccess => errorMessage == null;
}

/// Contract for transactional outbox Push/Pull cloud synchronization.
abstract class ISyncService {
  Future<SyncSummary> syncNow();
  Future<int> getPendingOutboxCount();
  Future<DateTime?> getLastSyncAt();
}

/// Offline-first Push/Pull sync engine backed by SQLite `sync_outbox` & `sync_state`.
class SyncServiceImpl implements ISyncService {
  static const Map<String, String> _entityTables = {
    'user_profile': 'user_profile',
    'transaction': 'transactions',
    'group': 'groups',
    'group_member': 'group_members',
    'group_expense': 'group_expenses',
    'expense_split': 'expense_splits',
    'settlement': 'settlements',
  };

  static const Map<String, Set<String>> _allowedColumns = {
    'user_profile': {
      'id',
      'full_name',
      'email',
      'phone_e164',
      'currency_code',
      'currency_symbol',
      'monthly_budget_limit',
      'current_available',
      'biometric_enabled',
      'is_dark_mode',
      'is_configured',
      'updated_at',
      'version',
    },
    'transactions': {
      'id',
      'title',
      'amount',
      'category',
      'category_icon',
      'payment_method',
      'date_time',
      'type',
      'group_id',
      'expense_id',
      'updated_at',
      'deleted_at',
      'is_synced',
      'version',
      'idempotency_key',
    },
    'groups': {
      'id',
      'name',
      'type',
      'icon_name',
      'created_at',
      'updated_at',
      'deleted_at',
      'is_synced',
      'version',
      'idempotency_key',
    },
    'group_members': {
      'id',
      'group_id',
      'name',
      'avatar_url',
      'phone_e164',
      'linked_user_id',
      'note',
      'last_activity',
      'updated_at',
      'deleted_at',
      'is_synced',
      'version',
      'idempotency_key',
    },
    'group_expenses': {
      'id',
      'group_id',
      'title',
      'total_amount',
      'payer_id',
      'payer_name',
      'category',
      'split_method',
      'date_time',
      'updated_at',
      'deleted_at',
      'is_synced',
      'version',
      'idempotency_key',
    },
    'expense_splits': {
      'id',
      'expense_id',
      'group_id',
      'member_id',
      'amount',
      'percentage',
      'is_payer',
      'updated_at',
      'deleted_at',
      'is_synced',
      'version',
      'idempotency_key',
    },
    'settlements': {
      'id',
      'group_id',
      'member_id',
      'amount',
      'date_time',
      'updated_at',
      'deleted_at',
      'is_synced',
      'version',
      'idempotency_key',
    },
  };

  final AppDatabase appDatabase;
  final SharedPreferences preferences;
  final IAuthLocalDataSource authLocalDataSource;
  final http.Client client;
  final String? baseUrlOverride;

  SyncServiceImpl({
    required this.appDatabase,
    required this.preferences,
    required this.authLocalDataSource,
    http.Client? client,
    this.baseUrlOverride,
  }) : client = client ?? http.Client();

  bool get _hasRemoteEndpoint =>
      (baseUrlOverride != null && baseUrlOverride!.trim().isNotEmpty) ||
      AppApis.isCloudConfigured;

  @override
  Future<int> getPendingOutboxCount() async {
    final db = await appDatabase.database;
    final rows = await db.rawQuery(
      "SELECT COUNT(*) AS cnt FROM sync_outbox WHERE status IN ('pending', 'failed')",
    );
    if (rows.isEmpty) return 0;
    return (rows.first['cnt'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<DateTime?> getLastSyncAt() async {
    final prefVal = preferences.getString(AppKeys.lastSyncAt);
    if (prefVal != null && prefVal.isNotEmpty) {
      return DateTime.tryParse(prefVal);
    }
    final db = await appDatabase.database;
    final rows = await db.query(
      'sync_state',
      where: 'key = ?',
      whereArgs: const ['last_sync_at'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['value'] as String?;
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  @override
  Future<SyncSummary> syncNow() async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final db = await appDatabase.database;
    final initialPending = await getPendingOutboxCount();

    if (!_hasRemoteEndpoint) {
      return SyncSummary(
        pushedCount: 0,
        pulledCount: 0,
        pendingRemaining: initialPending,
        syncedAtIso: nowIso,
        cloudConfigured: false,
      );
    }

    final session = await authLocalDataSource.getCachedSession();
    if (session == null || !session.isOnline || (session.token?.isEmpty ?? true)) {
      return SyncSummary(
        pushedCount: 0,
        pulledCount: 0,
        pendingRemaining: initialPending,
        syncedAtIso: nowIso,
        cloudConfigured: true,
        errorMessage: 'يرجى ربط حساب سحابي أولاً لتشغيل المزامنة.',
      );
    }

    try {
      final pushedCount = await _pushOutbox(db, session.userId, session.token!);
      final pulledCount = await _pullRemoteChanges(db, session.token!);
      await _saveSyncState(db, 'last_sync_at', nowIso);
      await preferences.setString(AppKeys.lastSyncAt, nowIso);
      final remaining = await getPendingOutboxCount();

      return SyncSummary(
        pushedCount: pushedCount,
        pulledCount: pulledCount,
        pendingRemaining: remaining,
        syncedAtIso: nowIso,
        cloudConfigured: true,
      );
    } catch (e) {
      final remaining = await getPendingOutboxCount();
      return SyncSummary(
        pushedCount: 0,
        pulledCount: 0,
        pendingRemaining: remaining,
        syncedAtIso: nowIso,
        cloudConfigured: true,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<int> _pushOutbox(
    Database db,
    String userId,
    String token,
  ) async {
    final pendingRows = await db.query(
      'sync_outbox',
      where: "status IN ('pending', 'failed')",
      orderBy: 'created_at ASC',
      limit: 100,
    );
    if (pendingRows.isEmpty) return 0;

    final operations = pendingRows.map((row) {
      Map<String, dynamic> decodedPayload;
      try {
        decodedPayload =
            jsonDecode(row['payload_json'] as String) as Map<String, dynamic>;
      } catch (_) {
        decodedPayload = <String, dynamic>{};
      }
      return {
        'outbox_id': row['id'],
        'entity_type': row['entity_type'],
        'entity_id': row['entity_id'],
        'operation': row['operation'],
        'idempotency_key': row['idempotency_key'],
        'payload': decodedPayload,
      };
    }).toList();

    final response = await client
        .post(
          Uri.parse(AppApis.syncPushUrl(baseUrlOverride)),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'user_id': userId,
            'operations': operations,
          }),
        )
        .timeout(AppApis.requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      await db.transaction((txn) async {
        for (final row in pendingRows) {
          final retries = ((row['retry_count'] as int?) ?? 0) + 1;
          await txn.update(
            'sync_outbox',
            {
              'status': 'failed',
              'retry_count': retries,
              'last_error': 'HTTP ${response.statusCode}',
              'updated_at': nowIso,
            },
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        }
      });
      throw Exception('تعذر دفع التغييرات للخادم (${response.statusCode}).');
    }

    final decoded = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};
    final rawAck = decoded['acknowledged_ids'] as List<dynamic>?;
    final ackIds = rawAck != null
        ? rawAck.map((e) => e.toString()).toSet()
        : pendingRows.map((r) => r['id'] as String).toSet();

    final nowIso = DateTime.now().toUtc().toIso8601String();
    var pushed = 0;

    await db.transaction((txn) async {
      for (final row in pendingRows) {
        final outboxId = row['id'] as String;
        if (!ackIds.contains(outboxId)) continue;

        final entityType = row['entity_type'] as String;
        final entityId = row['entity_id'] as String;
        final table = _entityTables[entityType];

        await txn.update(
          'sync_outbox',
          {
            'status': 'synced',
            'last_error': null,
            'updated_at': nowIso,
          },
          where: 'id = ?',
          whereArgs: [outboxId],
        );

        if (table != null && table != 'user_profile') {
          await txn.update(
            table,
            {'is_synced': 1},
            where: 'id = ?',
            whereArgs: [entityId],
          );
        }
        pushed += 1;
      }
    });

    return pushed;
  }

  Future<int> _pullRemoteChanges(Database db, String token) async {
    final cursorRows = await db.query(
      'sync_state',
      where: 'key = ?',
      whereArgs: const ['pull_cursor'],
      limit: 1,
    );
    final cursor =
        cursorRows.isNotEmpty ? cursorRows.first['value'] as String? : null;

    final response = await client
        .get(
          Uri.parse(
            AppApis.syncPullUrl(cursor: cursor, baseOverride: baseUrlOverride),
          ),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(AppApis.requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('تعذر جلب التحديثات من الخادم (${response.statusCode}).');
    }

    final decoded = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};
    final changes = (decoded['changes'] as List<dynamic>?) ?? const [];
    final nextCursor = decoded['next_cursor'] as String?;

    var applied = 0;
    await db.transaction((txn) async {
      for (final item in changes) {
        if (item is! Map<String, dynamic>) continue;
        final entityType = item['entity_type'] as String?;
        final table = entityType != null ? _entityTables[entityType] : null;
        final allowed = table != null ? _allowedColumns[table] : null;
        final data = item['data'] as Map<String, dynamic>?;
        if (table == null || allowed == null || data == null) continue;

        final entityId = data['id'] as String?;
        if (entityId == null || entityId.isEmpty) continue;

        final localRows = await txn.query(
          table,
          columns: table == 'user_profile'
              ? const ['version', 'updated_at']
              : const ['version', 'updated_at', 'is_synced'],
          where: 'id = ?',
          whereArgs: [entityId],
          limit: 1,
        );

        final localRow = localRows.isNotEmpty ? localRows.first : null;
        if (!_shouldRemoteWin(localRow, data)) {
          continue;
        }

        final sanitized = <String, Object?>{};
        for (final entry in data.entries) {
          if (allowed.contains(entry.key)) {
            sanitized[entry.key] = entry.value;
          }
        }
        if (table != 'user_profile') {
          sanitized['is_synced'] = 1;
        }
        sanitized.putIfAbsent(
          'updated_at',
          () => DateTime.now().toUtc().toIso8601String(),
        );

        await txn.insert(
          table,
          sanitized,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        await txn.delete(
          'sync_outbox',
          where: 'entity_type = ? AND entity_id = ? AND status = ?',
          whereArgs: [entityType, entityId, 'pending'],
        );
        applied += 1;
      }

      if (nextCursor != null && nextCursor.isNotEmpty) {
        await _saveSyncState(txn, 'pull_cursor', nextCursor);
      }
    });

    return applied;
  }

  bool _shouldRemoteWin(
    Map<String, dynamic>? localRow,
    Map<String, dynamic> remoteRow,
  ) {
    if (localRow == null) return true;

    final localVersion = (localRow['version'] as int?) ?? 1;
    final remoteVersion = (remoteRow['version'] as num?)?.toInt() ?? 1;
    if (remoteVersion != localVersion) {
      return remoteVersion > localVersion;
    }

    final localUpdated = (localRow['updated_at'] as String?) ?? '';
    final remoteUpdated = (remoteRow['updated_at'] as String?) ?? '';
    final localIsSynced = (localRow['is_synced'] as int?) ?? 1;

    final cmp = remoteUpdated.compareTo(localUpdated);
    if (localIsSynced == 0) {
      // Unpushed local edits win ties at the same version unless strictly newer remotely.
      return cmp > 0;
    }
    return cmp >= 0;
  }

  Future<void> _saveSyncState(
    DatabaseExecutor db,
    String key,
    String value,
  ) async {
    await db.insert(
      'sync_state',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
