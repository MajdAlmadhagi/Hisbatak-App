import '../../entities/user_profile.dart';
import '../../repositories/i_profile_repository.dart';

/// [GetProfileUseCase] retrieves the active offline profile.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class GetProfileUseCase {
  final IProfileRepository repository;

  GetProfileUseCase(this.repository);

  Future<UserProfile> call() async {
    return await repository.getUserProfile();
  }
}

/// [SaveProfileUseCase] persists changes to the offline profile.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class SaveProfileUseCase {
  final IProfileRepository repository;

  SaveProfileUseCase(this.repository);

  Future<void> call(UserProfile profile) async {
    return await repository.saveUserProfile(profile);
  }
}
