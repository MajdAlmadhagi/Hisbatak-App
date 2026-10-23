/// [AppKeys] centralizes keys used across SharedPreferences and local cache storage.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class AppKeys {
  static const String hasSeenOnboarding = 'has_seen_onboarding';
  static const String isDarkMode = 'is_dark_mode';
  static const String biometricEnabled = 'biometric_enabled';
}
