import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../widgets/hisbatak_loader.dart';

/// [SplashScreen] renders the initial startup screen matching Stitch Screen 1 (شاشة البداية - قِسمة).
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _navigateWhenReady();
  }

  /// Shortest time the splash stays up, so it reads as a deliberate screen
  /// rather than a flash: about when the loader finishes drawing the "ح".
  static const _minimumDisplay = Duration(milliseconds: 1600);

  /// Upper bound if the local database never answers.
  static const _maximumWait = Duration(seconds: 10);

  /// Leaves as soon as the profile has loaded (and the minimum time has
  /// passed): to home if it is configured, otherwise to profile setup.
  Future<void> _navigateWhenReady() async {
    final profileState = _waitForProfile(context.read<ProfileBloc>());
    await Future<void>.delayed(_minimumDisplay);
    final state = await profileState;
    if (!mounted) return;
    if (state is ProfileLoaded && state.profile.isConfigured) {
      context.go('/home');
    } else {
      context.go('/setup-profile');
    }
  }

  Future<ProfileState> _waitForProfile(ProfileBloc bloc) {
    bool isSettled(ProfileState state) =>
        state is ProfileLoaded || state is ProfileError;
    if (isSettled(bloc.state)) return Future.value(bloc.state);
    return bloc.stream
        .firstWhere(isSettled)
        .timeout(_maximumWait, onTimeout: () => bloc.state);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Same navy as the native launch screen, so the handoff is seamless.
      backgroundColor: AppColors.brandNavy,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Offline Ready Badge
                    const Row(
                      children: [
                        Icon(Icons.wifi_off_rounded,
                            size: 16, color: Color(0xFF6CF8BB)),
                        SizedBox(width: 6),
                        Text(
                          AppStrings.offlineReady,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6CF8BB),
                          ),
                        ),
                      ],
                    ),

                    // Version Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            AppStrings.appVersion,
                            style:
                                TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                          SizedBox(width: 6),
                          CircleAvatar(
                              radius: 3, backgroundColor: Color(0xFF10B981)),
                        ],
                      ),
                    ),
                  ],
                ),

                // Center Branding & Logo
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      // The animated "ح" is both the logo and the loading indicator.
                      const HisbatakLoader(size: 110, color: Colors.white),
                      const SizedBox(height: 28),

                      // Title
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Hisbatak',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '|',
                              style: TextStyle(
                                  fontSize: 22, color: AppColors.emeraldLight),
                            ),
                          ),
                          Text(
                            AppStrings.appName,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Tagline
                      const Text(
                        AppStrings.appTagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Encryption Pill
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF192339),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color:
                                const Color(0xFF6CF8BB).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 16, color: Color(0xFF10B981)),
                          SizedBox(width: 8),
                          Text(
                            AppStrings.encryptedLocal,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      AppStrings.appSubTagline,
                      style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
