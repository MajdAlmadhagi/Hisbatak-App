import 'package:equatable/equatable.dart';

/// [UserProfile] is a pure business domain entity representing the user profile.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
/// Represents business model independent of data sources or UI frameworks.
class UserProfile extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String currencyCode;
  final String currencySymbol;
  final double monthlyBudgetLimit;
  final double currentAvailable;
  final bool biometricEnabled;
  final bool isDarkMode;
  final bool isConfigured;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.currencyCode,
    required this.currencySymbol,
    required this.monthlyBudgetLimit,
    required this.currentAvailable,
    required this.biometricEnabled,
    required this.isDarkMode,
    required this.isConfigured,
  });

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? currencyCode,
    String? currencySymbol,
    double? monthlyBudgetLimit,
    double? currentAvailable,
    bool? biometricEnabled,
    bool? isDarkMode,
    bool? isConfigured,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      monthlyBudgetLimit: monthlyBudgetLimit ?? this.monthlyBudgetLimit,
      currentAvailable: currentAvailable ?? this.currentAvailable,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        currencyCode,
        currencySymbol,
        monthlyBudgetLimit,
        currentAvailable,
        biometricEnabled,
        isDarkMode,
        isConfigured,
      ];
}
