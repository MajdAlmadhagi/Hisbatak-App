import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_apis.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/auth_session.dart';
import '../../../domain/repositories/i_auth_repository.dart';

/// Remote API contract for Phone OTP, Social Sign-In, and Guest Account Claiming.
abstract class IAuthRemoteDataSource {
  Future<OtpChallengeResult> requestPhoneOtp({required String phoneE164});

  Future<AuthSession> verifyPhoneOtp({
    required String phoneE164,
    required String code,
    String? challengeId,
    String? guestUserId,
  });

  Future<AuthSession> signInWithSocial({
    required SocialAuthProvider provider,
    required String idToken,
    String? email,
    String? displayName,
    String? guestUserId,
  });

  Future<AuthSession> claimGuestAccount({
    required String guestUserId,
    required String phoneE164,
    required String otpCode,
    String? challengeId,
  });
}

/// HTTP-backed cloud authentication data source with graceful offline-preview
/// fallback when `HISBATAK_API_BASE_URL` is not configured.
class HttpAuthRemoteDataSource implements IAuthRemoteDataSource {
  static const String _previewOtpCode = '123456';

  final http.Client client;
  final String? baseUrlOverride;

  HttpAuthRemoteDataSource({
    http.Client? client,
    this.baseUrlOverride,
  }) : client = client ?? http.Client();

  bool get _hasRemoteEndpoint =>
      (baseUrlOverride != null && baseUrlOverride!.trim().isNotEmpty) ||
      AppApis.isCloudConfigured;

  @override
  Future<OtpChallengeResult> requestPhoneOtp({
    required String phoneE164,
  }) async {
    final normalizedPhone = Validators.normalizePhoneE164(phoneE164);

    if (!_hasRemoteEndpoint) {
      return OtpChallengeResult(
        phoneE164: normalizedPhone,
        challengeId: IdGenerator.prefixed('otp'),
        expiresInSeconds: 180,
        previewCode: _previewOtpCode,
      );
    }

    final json = await _postJson(
      AppApis.requestOtpUrl(baseUrlOverride),
      {'phone_e164': normalizedPhone},
    );
    return OtpChallengeResult(
      phoneE164: (json['phone_e164'] as String?) ?? normalizedPhone,
      challengeId:
          (json['challenge_id'] as String?) ?? IdGenerator.prefixed('otp'),
      expiresInSeconds: (json['expires_in'] as num?)?.toInt() ?? 180,
      previewCode: json['preview_code'] as String?,
    );
  }

  @override
  Future<AuthSession> verifyPhoneOtp({
    required String phoneE164,
    required String code,
    String? challengeId,
    String? guestUserId,
  }) async {
    final normalizedPhone = Validators.normalizePhoneE164(phoneE164);
    final normalizedCode = Validators.normalizeDigits(code.trim());
    if (normalizedCode.length < 4) {
      throw Exception('يرجى إدخال رمز التحقق المكون من 6 أرقام.');
    }

    if (!_hasRemoteEndpoint) {
      if (normalizedCode != _previewOtpCode) {
        throw Exception('رمز التحقق غير صحيح (الرمز التجريبي: $_previewOtpCode).');
      }
      final stableUid = IdGenerator.isUuid(guestUserId)
          ? guestUserId!
          : IdGenerator.uuidV4();
      return AuthSession(
        userId: stableUid,
        name: 'حساب $normalizedPhone',
        email: normalizedPhone,
        connectionMode: AuthConnectionMode.online,
        token: 'preview_jwt_${IdGenerator.uuidV4()}',
        createdAt: DateTime.now(),
        isConfigured: true,
      );
    }

    final json = await _postJson(
      AppApis.verifyOtpUrl(baseUrlOverride),
      {
        'phone_e164': normalizedPhone,
        'code': normalizedCode,
        if (challengeId != null) 'challenge_id': challengeId,
        if (guestUserId != null) 'guest_user_id': guestUserId,
      },
    );
    return _sessionFromJson(json, fallbackUserId: guestUserId);
  }

  @override
  Future<AuthSession> signInWithSocial({
    required SocialAuthProvider provider,
    required String idToken,
    String? email,
    String? displayName,
    String? guestUserId,
  }) async {
    if (!_hasRemoteEndpoint) {
      final stableUid = IdGenerator.isUuid(guestUserId)
          ? guestUserId!
          : IdGenerator.uuidV4();
      return AuthSession(
        userId: stableUid,
        name: (displayName != null && displayName.trim().isNotEmpty)
            ? displayName.trim()
            : 'مستخدم ${provider.name}',
        email: (email != null && email.trim().isNotEmpty)
            ? email.trim()
            : '${provider.name}@hisbatak.cloud',
        connectionMode: AuthConnectionMode.online,
        token: 'preview_social_${IdGenerator.uuidV4()}',
        createdAt: DateTime.now(),
        isConfigured: true,
      );
    }

    final json = await _postJson(
      AppApis.socialAuthUrl(baseUrlOverride),
      {
        'provider': provider.name,
        'id_token': idToken,
        if (email != null) 'email': email,
        if (displayName != null) 'display_name': displayName,
        if (guestUserId != null) 'guest_user_id': guestUserId,
      },
    );
    return _sessionFromJson(json, fallbackUserId: guestUserId);
  }

  @override
  Future<AuthSession> claimGuestAccount({
    required String guestUserId,
    required String phoneE164,
    required String otpCode,
    String? challengeId,
  }) async {
    final normalizedPhone = Validators.normalizePhoneE164(phoneE164);
    final normalizedCode = Validators.normalizeDigits(otpCode.trim());
    if (normalizedCode.length < 4) {
      throw Exception('يرجى إدخال رمز التحقق لتأكيد ربط المحفظة.');
    }

    if (!_hasRemoteEndpoint) {
      if (normalizedCode != _previewOtpCode) {
        throw Exception('رمز التحقق غير صحيح (الرمز التجريبي: $_previewOtpCode).');
      }
      final stableUid = IdGenerator.isUuid(guestUserId)
          ? guestUserId
          : IdGenerator.uuidV4();
      return AuthSession(
        userId: stableUid,
        name: 'محفظة مرتبطة ($normalizedPhone)',
        email: normalizedPhone,
        connectionMode: AuthConnectionMode.online,
        token: 'preview_claimed_${IdGenerator.uuidV4()}',
        createdAt: DateTime.now(),
        isConfigured: true,
      );
    }

    final json = await _postJson(
      AppApis.claimGuestUrl(baseUrlOverride),
      {
        'guest_user_id': guestUserId,
        'phone_e164': normalizedPhone,
        'code': normalizedCode,
        if (challengeId != null) 'challenge_id': challengeId,
      },
    );
    return _sessionFromJson(json, fallbackUserId: guestUserId);
  }

  Future<Map<String, dynamic>> _postJson(
    String url,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await client
          .post(
            Uri.parse(url),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(AppApis.requestTimeout);

      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final msg = (decoded['message'] as String?) ??
            (decoded['error'] as String?) ??
            'تعذر إتمام الطلب (${response.statusCode})';
        throw Exception(msg);
      }
      return decoded;
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('تعذر الاتصال بخادم المزامنة: $e');
    }
  }

  AuthSession _sessionFromJson(
    Map<String, dynamic> json, {
    String? fallbackUserId,
  }) {
    final user = (json['user'] as Map<String, dynamic>?) ?? json;
    final uid = (user['id'] as String?) ??
        (user['user_id'] as String?) ??
        (IdGenerator.isUuid(fallbackUserId)
            ? fallbackUserId!
            : IdGenerator.uuidV4());
    return AuthSession(
      userId: uid,
      name: (user['name'] as String?) ??
          (user['full_name'] as String?) ??
          'مستخدم حسبتك',
      email: (user['phone_e164'] as String?) ??
          (user['email'] as String?) ??
          '',
      connectionMode: AuthConnectionMode.online,
      token: (json['access_token'] as String?) ?? (json['token'] as String?),
      createdAt: DateTime.now(),
      isConfigured: true,
    );
  }
}
