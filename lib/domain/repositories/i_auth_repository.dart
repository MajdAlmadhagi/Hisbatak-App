import '../entities/auth_session.dart';

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
