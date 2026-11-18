import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/profile/profile_bloc.dart';

/// Safe helpers to read or watch the active user's currency symbol from [ProfileBloc].
extension ProfileCurrencyContext on BuildContext {
  /// Watches [ProfileBloc] for currency updates when available in the widget tree.
  String watchCurrencySymbol({String fallback = 'ر.س'}) {
    try {
      final state = BlocProvider.of<ProfileBloc>(this, listen: true).state;
      if (state is ProfileLoaded &&
          state.profile.currencySymbol.trim().isNotEmpty) {
        return state.profile.currencySymbol;
      }
    } catch (_) {
      // Standalone widget tests may omit ProfileBloc from the tree.
    }
    return fallback;
  }

  /// Reads the active currency symbol without subscribing to rebuilds.
  String readCurrencySymbol({String fallback = 'ر.س'}) {
    try {
      final state = BlocProvider.of<ProfileBloc>(this, listen: false).state;
      if (state is ProfileLoaded &&
          state.profile.currencySymbol.trim().isNotEmpty) {
        return state.profile.currencySymbol;
      }
    } catch (_) {}
    return fallback;
  }
}
