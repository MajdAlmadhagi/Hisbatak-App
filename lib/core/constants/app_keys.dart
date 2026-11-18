/// [AppKeys] centralizes keys used across SharedPreferences and local cache storage.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class AppKeys {
  static const String hasSeenOnboarding = 'has_seen_onboarding';
  static const String isDarkMode = 'is_dark_mode';
  static const String biometricEnabled = 'biometric_enabled';
  static const String budgetAlertsEnabled = 'budget_alerts_enabled';
  static const String appPinHash = 'app_pin_hash';
  static const String appPinSalt = 'app_pin_salt';
  static const String appLockEnabled = 'app_lock_enabled';
  static const String lastSyncAt = 'last_sync_at';
}
