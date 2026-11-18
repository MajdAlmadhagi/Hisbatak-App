import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/id_generator.dart';
import '../../../domain/entities/auth_session.dart';

abstract class IAuthLocalDataSource {
  Future<AuthSession?> getCachedSession();
  Future<void> cacheSession(AuthSession session);
  Future<void> clearSession();
  Future<AuthConnectionMode> getPreferredConnectionMode();
  Future<void> savePreferredConnectionMode(AuthConnectionMode mode);
}

class AuthLocalDataSourceImpl implements IAuthLocalDataSource {
  static const _keySession = 'hisbatak_auth_session';
  static const _keyConnectionMode = 'hisbatak_connection_mode';

  final SharedPreferences preferences;

  AuthLocalDataSourceImpl(this.preferences);

  @override
  Future<AuthSession?> getCachedSession() async {
    final raw = preferences.getString(_keySession);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final modeStr = map['connectionMode'] as String? ?? 'offline';
      return AuthSession(
        userId: (map['userId'] as String?)?.isNotEmpty == true &&
                map['userId'] != 'user_me'
            ? map['userId'] as String
            : IdGenerator.uuidV4(),
        name: map['name'] as String? ?? 'مستخدم حسبتك',
        email: map['email'] as String? ?? '',
        connectionMode: modeStr == 'online'
            ? AuthConnectionMode.online
            : AuthConnectionMode.offline,
        token: map['token'] as String?,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
        isConfigured: map['isConfigured'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cacheSession(AuthSession session) async {
    final map = {
      'userId': session.userId,
      'name': session.name,
      'email': session.email,
      'connectionMode':
          session.connectionMode == AuthConnectionMode.online ? 'online' : 'offline',
      'token': session.token,
      'createdAt': session.createdAt.toIso8601String(),
      'isConfigured': session.isConfigured,
    };
    await preferences.setString(_keySession, jsonEncode(map));
  }

  @override
  Future<void> clearSession() async {
    await preferences.remove(_keySession);
  }

  @override
  Future<AuthConnectionMode> getPreferredConnectionMode() async {
    final modeStr = preferences.getString(_keyConnectionMode);
    if (modeStr == 'online') {
      return AuthConnectionMode.online;
    }
    // Default to offline mode, honoring Hisbatak's offline-first architecture
    return AuthConnectionMode.offline;
  }

  @override
  Future<void> savePreferredConnectionMode(AuthConnectionMode mode) async {
    await preferences.setString(
      _keyConnectionMode,
      mode == AuthConnectionMode.online ? 'online' : 'offline',
    );
  }
}
