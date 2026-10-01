import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/di/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'presentation/bloc/budget/budget_bloc.dart';
import 'presentation/bloc/groups/groups_bloc.dart';
import 'presentation/bloc/profile/profile_bloc.dart';
import 'presentation/bloc/theme/theme_cubit.dart';
import 'presentation/routes/app_router.dart';

void main() async {
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
          return MaterialApp.router(
            title: 'Hisbatak - حِسبَتك',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
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
              return Directionality(
                textDirection: TextDirection.rtl,
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
