import '../entities/auth_session.dart';

/// Supported external identity providers for progressive account linking.
enum SocialAuthProvider { google, apple }

/// Challenge metadata returned when requesting a phone OTP code.
class OtpChallengeResult {
  final String phoneE164;
  final String challengeId;
  final int expiresInSeconds;

  /// Populated only when cloud backend is not configured (local preview flow).
  final String? previewCode;

  const OtpChallengeResult({
    required this.phoneE164,
    required this.challengeId,
    this.expiresInSeconds = 180,
    this.previewCode,
  });
}

/// [IAuthRepository] defines the authentication contract for Hisbatak.
///
/// SOLID Principles:
/// - Interface Segregation Principle (ISP): Focused strictly on authentication actions.
/// - Dependency Inversion Principle (DIP): Presentation and Use Cases depend on this abstraction.
abstract class IAuthRepository {
  /// Fetches currently active session if one exists.
  Future<AuthSession?> getCurrentSession();

  /// Logs in using either offline credentials/quick local entry or online cloud credentials.
  Future<AuthSession> login({
    required String identifier,
    required String password,
    required AuthConnectionMode mode,
    bool rememberMe = true,
  });

  /// Registers a new account either as a local offline vault or an online cloud account.
  Future<AuthSession> signup({
    required String name,
    required String email,
    required String password,
    required AuthConnectionMode mode,
  });

  /// Terminates the current session.
  Future<void> logout();

  /// Retrieves user's preferred connection mode (offline vs online).
  Future<AuthConnectionMode> getPreferredConnectionMode();

  /// Saves the user's preferred connection mode.
  Future<void> setPreferredConnectionMode(AuthConnectionMode mode);
}

/// Progressive cloud authentication & guest-account claiming contract (ISP).
abstract class ICloudAuthRepository {
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
