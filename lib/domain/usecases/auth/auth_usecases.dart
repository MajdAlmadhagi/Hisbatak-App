import '../../entities/auth_session.dart';
import '../../repositories/i_auth_repository.dart';

/// [LoginUseCase] executes authentication with connection mode awareness.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class LoginUseCase {
  final IAuthRepository repository;

  LoginUseCase(this.repository);

  Future<AuthSession> call({
    required String identifier,
    required String password,
    required AuthConnectionMode mode,
    bool rememberMe = true,
  }) {
    return repository.login(
      identifier: identifier,
      password: password,
      mode: mode,
      rememberMe: rememberMe,
    );
  }
}

/// [SignupUseCase] registers a new user either locally or in cloud.
class SignupUseCase {
  final IAuthRepository repository;

  SignupUseCase(this.repository);

  Future<AuthSession> call({
    required String name,
    required String email,
    required String password,
    required AuthConnectionMode mode,
  }) {
    return repository.signup(
      name: name,
      email: email,
      password: password,
      mode: mode,
    );
  }
}

/// [GetAuthSessionUseCase] checks current active authentication session.
class GetAuthSessionUseCase {
  final IAuthRepository repository;

  GetAuthSessionUseCase(this.repository);

  Future<AuthSession?> call() {
    return repository.getCurrentSession();
  }
}

/// [GetPreferredModeUseCase] gets preferred connection mode (offline/online).
class GetPreferredModeUseCase {
  final IAuthRepository repository;

  GetPreferredModeUseCase(this.repository);

  Future<AuthConnectionMode> call() {
    return repository.getPreferredConnectionMode();
  }
}

/// [SetPreferredModeUseCase] updates preferred connection mode.
class SetPreferredModeUseCase {
  final IAuthRepository repository;

  SetPreferredModeUseCase(this.repository);

  Future<void> call(AuthConnectionMode mode) {
    return repository.setPreferredConnectionMode(mode);
  }
}

/// [LogoutUseCase] logs out the active session.
class LogoutUseCase {
  final IAuthRepository repository;

  LogoutUseCase(this.repository);

  Future<void> call() {
    return repository.logout();
  }
}
