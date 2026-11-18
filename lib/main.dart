import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/di/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'presentation/bloc/budget/budget_bloc.dart';
import 'presentation/bloc/groups/groups_bloc.dart';
import 'presentation/bloc/profile/profile_bloc.dart';
import 'presentation/bloc/theme/theme_cubit.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_event.dart';
import 'presentation/routes/app_router.dart';

void main() async {
  // Ensure all of await function done before run app
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Dependency Injection Container (SOLID: Dependency Inversion Principle)
  await di.initDependencyInjection();

  runApp(const HisbatakApp());
}

/// [HisbatakApp] is the root widget configuring Clean Architecture BLoCs,
/// theme switching, RTL localization, and GoRouter navigation.
///
/// SOLID Principles:
/// - Single Responsibility Principle (SRP): App bootstrapping and root configuration.
/// - Open/Closed Principle (OCP): New global providers can be attached without changing app logic.
class HisbatakApp extends StatelessWidget {
  const HisbatakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => di.sl<AuthBloc>()..add(CheckAuthStatusEvent()),
        ),
        BlocProvider<ProfileBloc>(
          create: (_) => di.sl<ProfileBloc>()..add(LoadProfileEvent()),
        ),
        BlocProvider<BudgetBloc>(
          create: (_) => di.sl<BudgetBloc>()..add(LoadBudgetDashboardEvent()),
        ),
        BlocProvider<GroupsBloc>(
          create: (_) => di.sl<GroupsBloc>()..add(LoadGroupsEvent()),
        ),
        BlocProvider<ThemeCubit>(
          create: (_) => di.sl<ThemeCubit>(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          final platformBrightness = MediaQuery.platformBrightnessOf(context);
          final isDark = themeMode == ThemeMode.dark ||
              (themeMode == ThemeMode.system &&
                  platformBrightness == Brightness.dark);
          final resolvedTheme =
              isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
          return ThemeProvider(
            //to create smooth theme animation during change theme
            initTheme: resolvedTheme,
            builder: (context, currentTheme) {
              return MaterialApp.router(
                title: 'Hisbatak - حِسبَتك',
                debugShowCheckedModeBanner: false,
                theme: resolvedTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                routerConfig: AppRouter.router,
                // Native Arabic RTL Support
                locale: const Locale('ar', 'SA'),
                supportedLocales: const [
                  Locale('ar', 'SA'),
                  Locale('en', 'US'),
                ],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                builder: (context, child) {
                  return ThemeSwitchingArea(
                    child: child ?? const SizedBox.shrink(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
