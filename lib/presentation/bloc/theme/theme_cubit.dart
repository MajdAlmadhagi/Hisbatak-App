import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/i_profile_repository.dart';

/// [ThemeCubit] manages ThemeMode (System default on first launch, then Light vs Dark)
/// for the application.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class ThemeCubit extends Cubit<ThemeMode> {
  final IProfileRepository profileRepository;

  ThemeCubit({required this.profileRepository}) : super(ThemeMode.system) {
    loadSavedTheme();
  }

  Future<void> loadSavedTheme() async {
    try {
      final profile = await profileRepository.getUserProfile();
      if (!profile.isConfigured) {
        emit(ThemeMode.system);
        return;
      }
      emit(profile.isDarkMode ? ThemeMode.dark : ThemeMode.light);
    } catch (_) {}
  }

  void setDarkMode(bool isDark) {
    emit(isDark ? ThemeMode.dark : ThemeMode.light);
    profileRepository.updateDarkModeSetting(isDark);
  }

  void resetToSystem() {
    emit(ThemeMode.system);
  }

  void toggleTheme() {
    final bool currentlyDark = state == ThemeMode.dark ||
        (state == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    setDarkMode(!currentlyDark);
  }
}
