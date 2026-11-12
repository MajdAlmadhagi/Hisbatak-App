import 'package:equatable/equatable.dart';

/// Connection mode options for Hisbatak:
/// - [offline]: Local-first, zero cloud dependencies, data stored 100% on device.
/// - [online]: Cloud-synced, multi-device backup, and online group sync.
enum AuthConnectionMode {
  offline,
  online,
}

/// [AuthSession] represents the authenticated state and session context.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
/// Represents the pure domain model for authentication sessions.
class AuthSession extends Equatable {
  final String userId;
  final String name;
  final String email;
  final AuthConnectionMode connectionMode;
  final String? token;
  final DateTime createdAt;
  final bool isConfigured;

  const AuthSession({
    required this.userId,
    required this.name,
    required this.email,
    required this.connectionMode,
    this.token,
    required this.createdAt,
    this.isConfigured = false,
  });

  bool get isOffline => connectionMode == AuthConnectionMode.offline;
  bool get isOnline => connectionMode == AuthConnectionMode.online;

  AuthSession copyWith({
    String? userId,
    String? name,
    String? email,
    AuthConnectionMode? connectionMode,
    String? token,
    DateTime? createdAt,
    bool? isConfigured,
  }) {
    return AuthSession(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      connectionMode: connectionMode ?? this.connectionMode,
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        name,
        email,
        connectionMode,
        token,
        createdAt,
        isConfigured,
      ];
}
