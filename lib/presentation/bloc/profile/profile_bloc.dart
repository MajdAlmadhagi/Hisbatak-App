import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/repositories/i_profile_repository.dart';
import '../../../domain/usecases/profile/profile_usecases.dart';

// EVENTS
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class LoadProfileEvent extends ProfileEvent {}

class SaveProfileEvent extends ProfileEvent {
  final UserProfile profile;
  const SaveProfileEvent(this.profile);
  @override
  List<Object?> get props => [profile];
}

class ToggleBiometricEvent extends ProfileEvent {
  final bool enabled;
  const ToggleBiometricEvent(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class ResetAppDataEvent extends ProfileEvent {}

// STATES
abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  const ProfileLoaded(this.profile);
  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
  @override
  List<Object?> get props => [message];
}

/// [ProfileBloc] handles state management for profile setup, biometric settings, and reset actions.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfileUseCase getProfileUseCase;
  final SaveProfileUseCase saveProfileUseCase;
  final IProfileRepository profileRepository;

  ProfileBloc({
    required this.getProfileUseCase,
    required this.saveProfileUseCase,
    required this.profileRepository,
  }) : super(ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<SaveProfileEvent>(_onSaveProfile);
    on<ToggleBiometricEvent>(_onToggleBiometric);
    on<ResetAppDataEvent>(_onResetAppData);
  }

  Future<void> _onLoadProfile(
    LoadProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final profile = await getProfileUseCase();
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError('فشل تحميل الملف الشخصي: $e'));
    }
  }

  Future<void> _onSaveProfile(
    SaveProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      await saveProfileUseCase(event.profile);
      emit(ProfileLoaded(event.profile));
    } catch (e) {
      emit(ProfileError('فشل حفظ الملف الشخصي: $e'));
    }
  }

  Future<void> _onToggleBiometric(
    ToggleBiometricEvent event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is ProfileLoaded) {
      final current = (state as ProfileLoaded).profile;
      final updated = current.copyWith(biometricEnabled: event.enabled);
      emit(ProfileLoaded(updated));
      await profileRepository.updateBiometricSetting(event.enabled);
    }
  }

  Future<void> _onResetAppData(
    ResetAppDataEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      await profileRepository.resetAllData();
      final profile = await getProfileUseCase();
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError('فشل مسح البيانات: $e'));
    }
  }
}
