import 'package:equatable/equatable.dart';
import '../../../domain/entities/auth_session.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final AuthConnectionMode connectionMode;
  final AuthSession? session;
  final String? errorMessage;
  final String? successMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.connectionMode = AuthConnectionMode.offline,
    this.session,
    this.errorMessage,
    this.successMessage,
  });

  bool get isOffline => connectionMode == AuthConnectionMode.offline;
  bool get isOnline => connectionMode == AuthConnectionMode.online;
  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    AuthConnectionMode? connectionMode,
    AuthSession? session,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      connectionMode: connectionMode ?? this.connectionMode,
      session: session ?? this.session,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        connectionMode,
        session,
        errorMessage,
        successMessage,
      ];
}
