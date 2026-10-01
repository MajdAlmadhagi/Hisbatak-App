import '../entities/user_profile.dart';

/// [IProfileRepository] defines the contract for accessing and updating local user profile.
///
/// SOLID Principles:
/// - Interface Segregation Principle (ISP): Specific to user profile operations only.
/// - Dependency Inversion Principle (DIP): Presentation and Use Cases depend on this abstraction.
abstract class IProfileRepository {
  Future<UserProfile> getUserProfile();
  Future<void> saveUserProfile(UserProfile profile);
  Future<void> updateBiometricSetting(bool enabled);
  Future<void> updateDarkModeSetting(bool isDark);
  Future<void> resetAllData();
}
