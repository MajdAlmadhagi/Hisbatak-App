import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_keys.dart';

/// [IAppPreferencesDataSource] defines the contract for storing lightweight,
/// device-specific preferences like theme mode, biometric lock, and onboarding state.
///
/// SOLID Principles:
/// - Interface Segregation Principle (ISP): Separate preferences from SQLite database operations.
/// - Dependency Inversion Principle (DIP): High-level modules depend on this abstraction.
abstract class IAppPreferencesDataSource {
  Future<bool> hasSeenOnboarding();
  Future<void> setOnboardingCompleted({bool completed = true});

  Future<bool> isDarkMode();
  Future<void> setDarkMode(bool isDark);

  Future<bool> isBiometricEnabled();
  Future<void> setBiometricEnabled(bool enabled);

  Future<void> clearAllPreferences();
}

/// [AppPreferencesDataSourceImpl] concrete implementation backed by [SharedPreferences].
class AppPreferencesDataSourceImpl implements IAppPreferencesDataSource {
  final SharedPreferences sharedPreferences;

  AppPreferencesDataSourceImpl(this.sharedPreferences);

  @override
  Future<bool> hasSeenOnboarding() async {
    return sharedPreferences.getBool(AppKeys.hasSeenOnboarding) ?? false;
  }

  @override
  Future<void> setOnboardingCompleted({bool completed = true}) async {
    await sharedPreferences.setBool(AppKeys.hasSeenOnboarding, completed);
  }

  @override
  Future<bool> isDarkMode() async {
    final isDark = sharedPreferences.getBool(AppKeys.isDarkMode) ?? false;
    final appMode = isDark ? "Dark Mode" : "Light Mode";
    debugPrint('*********** Get AppTheme is currently: $appMode ************');
    return isDark;
  }

  @override
  Future<void> setDarkMode(bool isDark) async {
    await sharedPreferences.setBool(AppKeys.isDarkMode, isDark);

    final appMode = isDark ? "Dark Mode" : "Light Mode";
    debugPrint('*********** Set AppTheme is currently: $appMode ************');
  }

  @override
  Future<bool> isBiometricEnabled() async {
    return sharedPreferences.getBool(AppKeys.biometricEnabled) ?? true;
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    await sharedPreferences.setBool(AppKeys.biometricEnabled, enabled);
  }

  @override
  Future<void> clearAllPreferences() async {
    await sharedPreferences.clear();
  }
}
