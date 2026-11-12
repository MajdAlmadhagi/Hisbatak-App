import 'package:equatable/equatable.dart';
import '../../../domain/entities/auth_session.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Checks existing session and loads preferred connection mode.
class CheckAuthStatusEvent extends AuthEvent {}

/// Switches connection mode (Offline vs Online).
class SwitchConnectionModeEvent extends AuthEvent {
  final AuthConnectionMode mode;

  const SwitchConnectionModeEvent(this.mode);

  @override
  List<Object?> get props => [mode];
}

/// Dispatched when user submits login form.
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

/// Dispatched when user clicks quick offline access button.
class QuickOfflineAccessEvent extends AuthEvent {
  final String? localName;

  const QuickOfflineAccessEvent({this.localName});

  @override
  List<Object?> get props => [localName];
}

/// Dispatched when user submits signup form.
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

/// Clears any error message.
class ClearAuthErrorEvent extends AuthEvent {}

/// Logs user out.
class LogoutAuthEvent extends AuthEvent {}
