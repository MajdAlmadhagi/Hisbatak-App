import '../../core/utils/id_generator.dart';
import '../../core/utils/validators.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/repositories/i_profile_repository.dart';
import '../datasources/auth/auth_local_data_source.dart';
import '../datasources/auth/auth_remote_data_source.dart';

/// [AuthRepositoryImpl] implements [IAuthRepository] and [ICloudAuthRepository]
/// handling both offline-first local identity and progressive cloud account claiming.
///
/// SOLID Principles:
/// - Dependency Inversion Principle (DIP): Implements domain interfaces.
/// - Open/Closed Principle (OCP): Uses pluggable [IAuthRemoteDataSource].
class AuthRepositoryImpl implements IAuthRepository, ICloudAuthRepository {
  final IAuthLocalDataSource localDataSource;
  final IProfileRepository profileRepository;
  final IAuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({
    required this.localDataSource,
    required this.profileRepository,
    IAuthRemoteDataSource? remoteDataSource,
  }) : remoteDataSource = remoteDataSource ?? HttpAuthRemoteDataSource();

  Future<String> _resolveStableUserId() async {
    final profile = await profileRepository.getUserProfile();
    if (profile.id.isNotEmpty && profile.id != 'user_me') {
      return profile.id;
    }
    final cached = await localDataSource.getCachedSession();
    if (cached != null &&
        cached.userId.isNotEmpty &&
        cached.userId != 'user_me') {
      return cached.userId;
    }
    return IdGenerator.uuidV4();
  }

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
    final stableUserId = await _resolveStableUserId();
    final existingProfile = await profileRepository.getUserProfile();

    if (mode == AuthConnectionMode.offline) {
      final displayName = identifier.trim().isNotEmpty
          ? identifier.trim()
          : (existingProfile.fullName.isNotEmpty
              ? existingProfile.fullName
              : 'مستخدم حسبتك');

      final session = AuthSession(
        userId: stableUserId,
        name: displayName,
        email: existingProfile.email,
        connectionMode: AuthConnectionMode.offline,
        token: null,
        createdAt: DateTime.now(),
        isConfigured: existingProfile.isConfigured,
      );

      if (rememberMe) {
        await localDataSource.cacheSession(session);
      }
      if (identifier.trim().isNotEmpty &&
          identifier.trim() != 'مستخدم حسبتك') {
        await _syncProfileIdentity(
          existingProfileId: stableUserId,
          name: displayName,
        );
      }
      return session;
    }

    // Online credential entry fallback (when email/phone + password is used)
    if (password.length < 4) {
      throw Exception('كلمة المرور يجب أن لا تقل عن 4 خانات');
    }

    final normalizedPhone = Validators.tryNormalizePhoneE164(identifier);
    final isEmail = identifier.contains('@');
    final displayName = existingProfile.fullName.isNotEmpty
        ? existingProfile.fullName
        : (isEmail ? identifier.split('@').first : identifier.trim());

    final session = AuthSession(
      userId: stableUserId,
      name: displayName.isNotEmpty ? displayName : 'مستخدم حسبتك',
      email: isEmail
          ? identifier.trim()
          : (normalizedPhone ?? existingProfile.email),
      connectionMode: AuthConnectionMode.online,
      token: 'local_cloud_${IdGenerator.uuidV4()}',
      createdAt: DateTime.now(),
      isConfigured: existingProfile.isConfigured,
    );

    if (rememberMe) {
      await localDataSource.cacheSession(session);
    }

    await _syncProfileIdentity(
      existingProfileId: stableUserId,
      name: displayName,
      email: isEmail ? identifier.trim() : null,
      phoneE164: normalizedPhone,
    );

    return session;
  }

  @override
  Future<AuthSession> signup({
    required String name,
    required String email,
    required String password,
    required AuthConnectionMode mode,
  }) async {
    await localDataSource.savePreferredConnectionMode(mode);
    final stableUserId = await _resolveStableUserId();

    if (mode == AuthConnectionMode.online && password.length < 6) {
      throw Exception('يجب أن تتكون كلمة المرور من 6 أحرف أو أرقام على الأقل');
    }

    final resolvedName = name.trim().isNotEmpty
        ? name.trim()
        : (mode == AuthConnectionMode.offline ? 'مستخدم محلي' : 'مستخدم سحابي');
    final normalizedPhone = Validators.tryNormalizePhoneE164(email);
    final trimmedEmail = email.trim();

    final session = AuthSession(
      userId: stableUserId,
      name: resolvedName,
      email: trimmedEmail,
      connectionMode: mode,
      token: mode == AuthConnectionMode.online
          ? 'local_cloud_${IdGenerator.uuidV4()}'
          : null,
      createdAt: DateTime.now(),
      isConfigured: false,
    );

    await localDataSource.cacheSession(session);
    await _syncProfileIdentity(
      existingProfileId: stableUserId,
      name: resolvedName,
      email: trimmedEmail.contains('@') ? trimmedEmail : null,
      phoneE164: normalizedPhone,
    );

    return session;
  }

  @override
  Future<OtpChallengeResult> requestPhoneOtp({
    required String phoneE164,
  }) {
    final normalized = Validators.normalizePhoneE164(phoneE164);
    return remoteDataSource.requestPhoneOtp(phoneE164: normalized);
  }

  @override
  Future<AuthSession> verifyPhoneOtp({
    required String phoneE164,
    required String code,
    String? challengeId,
    String? guestUserId,
  }) async {
    final normalizedPhone = Validators.normalizePhoneE164(phoneE164);
    final stableGuestId =
        IdGenerator.isUuid(guestUserId) ? guestUserId! : await _resolveStableUserId();

    final session = await remoteDataSource.verifyPhoneOtp(
      phoneE164: normalizedPhone,
      code: code,
      challengeId: challengeId,
      guestUserId: stableGuestId,
    );

    await localDataSource.savePreferredConnectionMode(AuthConnectionMode.online);
    await localDataSource.cacheSession(session);
    await _syncProfileIdentity(
      existingProfileId: session.userId,
      name: session.name,
      email: session.email.contains('@') ? session.email : null,
      phoneE164: normalizedPhone,
    );

    return session;
  }

  @override
  Future<AuthSession> signInWithSocial({
    required SocialAuthProvider provider,
    required String idToken,
    String? email,
    String? displayName,
    String? guestUserId,
  }) async {
    final stableGuestId =
        IdGenerator.isUuid(guestUserId) ? guestUserId! : await _resolveStableUserId();

    final session = await remoteDataSource.signInWithSocial(
      provider: provider,
      idToken: idToken,
      email: email,
      displayName: displayName,
      guestUserId: stableGuestId,
    );

    await localDataSource.savePreferredConnectionMode(AuthConnectionMode.online);
    await localDataSource.cacheSession(session);
    await _syncProfileIdentity(
      existingProfileId: session.userId,
      name: displayName ?? session.name,
      email: email ?? (session.email.contains('@') ? session.email : null),
    );

    return session;
  }

  @override
  Future<AuthSession> claimGuestAccount({
    required String guestUserId,
    required String phoneE164,
    required String otpCode,
    String? challengeId,
  }) async {
    final normalizedPhone = Validators.normalizePhoneE164(phoneE164);
    final stableGuestId =
        IdGenerator.isUuid(guestUserId) ? guestUserId : await _resolveStableUserId();

    final session = await remoteDataSource.claimGuestAccount(
      guestUserId: stableGuestId,
      phoneE164: normalizedPhone,
      otpCode: otpCode,
      challengeId: challengeId,
    );

    await localDataSource.savePreferredConnectionMode(AuthConnectionMode.online);
    await localDataSource.cacheSession(session);
    await _syncProfileIdentity(
      existingProfileId: session.userId,
      phoneE164: normalizedPhone,
    );

    return session;
  }

  Future<void> _syncProfileIdentity({
    required String existingProfileId,
    String? name,
    String? email,
    String? phoneE164,
  }) async {
    final current = await profileRepository.getUserProfile();
    final updated = current.copyWith(
      id: (current.id.isEmpty || current.id == 'user_me')
          ? existingProfileId
          : current.id,
      fullName: current.fullName.isEmpty && (name?.trim().isNotEmpty == true)
          ? name!.trim()
          : current.fullName,
      email: current.email.isEmpty && (email?.trim().isNotEmpty == true)
          ? email!.trim()
          : current.email,
      phoneE164: phoneE164 ?? current.phoneE164,
    );
    await profileRepository.saveUserProfile(updated);
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
