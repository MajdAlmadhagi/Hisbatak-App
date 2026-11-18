import 'package:equatable/equatable.dart';
import '../../../domain/entities/auth_session.dart';

enum AuthStatus {
  initial,
  loading,
  otpSent,
  authenticated,
  unauthenticated,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final AuthConnectionMode connectionMode;
  final AuthSession? session;
  final String? pendingPhoneE164;
  final String? otpChallengeId;
  final String? devOtpPreviewCode;
  final String? errorMessage;
  final String? successMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.connectionMode = AuthConnectionMode.offline,
    this.session,
    this.pendingPhoneE164,
    this.otpChallengeId,
    this.devOtpPreviewCode,
    this.errorMessage,
    this.successMessage,
  });

  bool get isOffline => connectionMode == AuthConnectionMode.offline;
  bool get isOnline => connectionMode == AuthConnectionMode.online;
  bool get isLoading => status == AuthStatus.loading;
  bool get isOtpSent => status == AuthStatus.otpSent;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    AuthConnectionMode? connectionMode,
    AuthSession? session,
    String? pendingPhoneE164,
    String? otpChallengeId,
    String? devOtpPreviewCode,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearOtpChallenge = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      connectionMode: connectionMode ?? this.connectionMode,
      session: session ?? this.session,
      pendingPhoneE164: clearOtpChallenge
          ? null
          : (pendingPhoneE164 ?? this.pendingPhoneE164),
      otpChallengeId:
          clearOtpChallenge ? null : (otpChallengeId ?? this.otpChallengeId),
      devOtpPreviewCode: clearOtpChallenge
          ? null
          : (devOtpPreviewCode ?? this.devOtpPreviewCode),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        connectionMode,
        session,
        pendingPhoneE164,
        otpChallengeId,
        devOtpPreviewCode,
        errorMessage,
        successMessage,
      ];
}
