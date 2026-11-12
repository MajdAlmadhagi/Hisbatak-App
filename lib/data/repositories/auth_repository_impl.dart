import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/repositories/i_profile_repository.dart';
import '../datasources/auth/auth_local_data_source.dart';

/// [AuthRepositoryImpl] implements [IAuthRepository] handling both offline-first
/// and online authentication modes.
///
/// Designed to easily swap in the remote API once backend endpoints are available.
///
/// SOLID Principles:
/// - Dependency Inversion Principle (DIP): Implements domain interface.
/// - Open/Closed Principle (OCP): Ready for remote API integration without breaking consumers.
class AuthRepositoryImpl implements IAuthRepository {
  final IAuthLocalDataSource localDataSource;
  final IProfileRepository profileRepository;

  AuthRepositoryImpl({
    required this.localDataSource,
    required this.profileRepository,
  });

  @override
  Future<AuthSession?> getCurrentSession() async {
    return localDataSource.getCachedSession();
  }

  @override
  Future<AuthSession> login({
    required String identifier,
    required String password,
    required AuthConnectionMode mode,
    bool rememberMe = true,
  }) async {
    await localDataSource.savePreferredConnectionMode(mode);

    if (mode == AuthConnectionMode.offline) {
      // Offline mode login: zero server dependency, instant access
      final existingProfile = await profileRepository.getUserProfile();
      final displayName = identifier.trim().isNotEmpty
          ? identifier.trim()
          : (existingProfile.fullName.isNotEmpty
              ? existingProfile.fullName
              : 'مستخدم محلي');

      final session = AuthSession(
        userId: existingProfile.id.isNotEmpty ? existingProfile.id : 'user_local_offline',
        name: displayName,
        email: existingProfile.email.isNotEmpty ? existingProfile.email : '',
        connectionMode: AuthConnectionMode.offline,
        token: null,
        createdAt: DateTime.now(),
        isConfigured: existingProfile.isConfigured,
      );

      if (rememberMe) {
        await localDataSource.cacheSession(session);
      }
      return session;
    } else {
      // Online mode login: simulate network latency & prepare for REST/GraphQL API
      await Future.delayed(const Duration(milliseconds: 900));

      if (password.length < 4) {
        throw Exception('كلمة المرور يجب أن لا تقل عن 4 خانات');
      }

      final existingProfile = await profileRepository.getUserProfile();
      final displayName = existingProfile.fullName.isNotEmpty
          ? existingProfile.fullName
          : (identifier.contains('@') ? identifier.split('@').first : identifier);

      final session = AuthSession(
        userId: 'user_online_${DateTime.now().millisecondsSinceEpoch}',
        name: displayName,
        email: identifier.contains('@') ? identifier : existingProfile.email,
        connectionMode: AuthConnectionMode.online,
        token: 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        isConfigured: existingProfile.isConfigured,
      );

      if (rememberMe) {
        await localDataSource.cacheSession(session);
      }

      // Sync name & email to profile if empty
      if (existingProfile.fullName.isEmpty || existingProfile.email.isEmpty) {
        await profileRepository.saveUserProfile(
          existingProfile.copyWith(
            fullName: displayName,
            email: session.email,
          ),
        );
      }

      return session;
    }
  }

  @override
  Future<AuthSession> signup({
    required String name,
    required String email,
    required String password,
    required AuthConnectionMode mode,
  }) async {
    await localDataSource.savePreferredConnectionMode(mode);

    if (mode == AuthConnectionMode.offline) {
      // Quick local offline vault setup
      final session = AuthSession(
        userId: 'user_local_${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim().isNotEmpty ? name.trim() : 'مستخدم محلي',
        email: email.trim(),
        connectionMode: AuthConnectionMode.offline,
        token: null,
        createdAt: DateTime.now(),
        isConfigured: false,
      );

      await localDataSource.cacheSession(session);

      // Pre-fill profile
      final current = await profileRepository.getUserProfile();
      await profileRepository.saveUserProfile(
        current.copyWith(
          fullName: session.name,
          email: session.email,
        ),
      );

      return session;
    } else {
      // Online cloud registration
      await Future.delayed(const Duration(milliseconds: 1100));

      if (password.length < 6) {
        throw Exception('يجب أن تتكون كلمة المرور من 6 أحرف أو أرقام على الأقل');
      }

      final session = AuthSession(
        userId: 'user_cloud_${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim().isNotEmpty ? name.trim() : 'مستخدم سحابي',
        email: email.trim(),
        connectionMode: AuthConnectionMode.online,
        token: 'mock_jwt_token_cloud_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        isConfigured: false,
      );

      await localDataSource.cacheSession(session);

      final current = await profileRepository.getUserProfile();
      await profileRepository.saveUserProfile(
        current.copyWith(
          fullName: session.name,
          email: session.email,
        ),
      );

      return session;
    }
  }

  @override
  Future<void> logout() async {
    await localDataSource.clearSession();
  }

  @override
  Future<AuthConnectionMode> getPreferredConnectionMode() {
    return localDataSource.getPreferredConnectionMode();
  }

  @override
  Future<void> setPreferredConnectionMode(AuthConnectionMode mode) {
    return localDataSource.savePreferredConnectionMode(mode);
  }
}
