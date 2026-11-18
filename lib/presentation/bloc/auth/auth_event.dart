import 'package:equatable/equatable.dart';
import '../../../domain/entities/auth_session.dart';
import '../../../domain/repositories/i_auth_repository.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Checks if a session already exists when app starts.
class CheckAuthStatusEvent extends AuthEvent {}

/// Switches between offline local mode and online cloud sync mode.
class SwitchConnectionModeEvent extends AuthEvent {
  final AuthConnectionMode mode;

  const SwitchConnectionModeEvent(this.mode);

  @override
  List<Object?> get props => [mode];
}

/// Submits login request (works seamlessly for both Offline & Online).
class LoginSubmittedEvent extends AuthEvent {
  final String identifier;
  final String password;
  final bool rememberMe;

  const LoginSubmittedEvent({
    required this.identifier,
    required this.password,
    this.rememberMe = true,
  });

  @override
  List<Object?> get props => [identifier, password, rememberMe];
}

/// Quick passwordless offline access for users who want zero friction.
class QuickOfflineAccessEvent extends AuthEvent {
  final String? localName;

  const QuickOfflineAccessEvent({this.localName});

  @override
  List<Object?> get props => [localName];
}

/// Submits signup request (creates local vault or cloud account).
class SignupSubmittedEvent extends AuthEvent {
  final String name;
  final String email;
  final String password;

  const SignupSubmittedEvent({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, password];
}

/// Requests a Phone OTP challenge for passwordless cloud sign-in or claiming.
class RequestPhoneOtpEvent extends AuthEvent {
  final String phoneNumber;

  const RequestPhoneOtpEvent({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

/// Verifies the submitted OTP code to create or resume a cloud session.
class VerifyPhoneOtpEvent extends AuthEvent {
  final String phoneNumber;
  final String code;
  final String? challengeId;

  const VerifyPhoneOtpEvent({
    required this.phoneNumber,
    required this.code,
    this.challengeId,
  });

  @override
  List<Object?> get props => [phoneNumber, code, challengeId];
}

/// Exchanges a social provider token while preserving local guest UUID identity.
class SocialSignInEvent extends AuthEvent {
  final SocialAuthProvider provider;
  final String idToken;
  final String? email;
  final String? displayName;

  const SocialSignInEvent({
    required this.provider,
    required this.idToken,
    this.email,
    this.displayName,
  });

  @override
  List<Object?> get props => [provider, idToken, email, displayName];
}

/// Upgrades an existing offline guest wallet to a synced cloud account via OTP.
class LinkCloudAccountEvent extends AuthEvent {
  final String phoneNumber;
  final String code;
  final String? challengeId;

  const LinkCloudAccountEvent({
    required this.phoneNumber,
    required this.code,
    this.challengeId,
  });

  @override
  List<Object?> get props => [phoneNumber, code, challengeId];
}

/// Clears any error banners cleanly.
class ClearAuthErrorEvent extends AuthEvent {}

/// Logs out and resets session.
class LogoutAuthEvent extends AuthEvent {}
