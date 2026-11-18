import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../security/app_lock_service.dart';
import '../../data/datasources/auth/auth_remote_data_source.dart';
import '../../data/datasources/sync/sync_service.dart';
import '../../data/datasources/local_datasources.dart';
import '../../data/datasources/preferences/app_preferences_data_source.dart';
import '../../data/repositories/repository_implementations.dart';
import '../../domain/repositories/i_profile_repository.dart';
import '../../domain/repositories/i_budget_repository.dart';
import '../../domain/repositories/i_group_repository.dart';
import '../../domain/usecases/profile/profile_usecases.dart';
import '../../domain/usecases/budget/budget_usecases.dart';
import '../../domain/usecases/groups/group_usecases.dart';
import '../../presentation/bloc/profile/profile_bloc.dart';
import '../../presentation/bloc/budget/budget_bloc.dart';
import '../../presentation/bloc/groups/groups_bloc.dart';
import '../../presentation/bloc/theme/theme_cubit.dart';
import '../../data/datasources/auth/auth_local_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/usecases/auth/auth_usecases.dart';
import '../../presentation/bloc/auth/auth_bloc.dart';

final sl = GetIt.instance;

/// [initDependencyInjection] registers all singletons, factories, and BLoCs.
///
/// SOLID Principle: Dependency Inversion Principle (DIP)
/// Decouples concrete class construction from consumer widgets and components.
Future<void> initDependencyInjection() async {
  // 1. SharedPreferences (UI & Device Preferences)
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<IAppPreferencesDataSource>(
    () => AppPreferencesDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<IAppLockService>(
    () => AppLockServiceImpl(sl()),
  );

  // 2. Core SQLite Database
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase.instance);

  // 3. Data Sources
  sl.registerLazySingleton<IProfileLocalDataSource>(
    () => ProfileLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<IBudgetLocalDataSource>(
    () => BudgetLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<IGroupLocalDataSource>(
    () => GroupLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<IAuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<IAuthRemoteDataSource>(
    () => HttpAuthRemoteDataSource(),
  );
  sl.registerLazySingleton<ISyncService>(
    () => SyncServiceImpl(
      appDatabase: sl(),
      preferences: sl(),
      authLocalDataSource: sl(),
    ),
  );

  // 4. Repositories
  sl.registerLazySingleton<IProfileRepository>(
    () => ProfileRepositoryImpl(
      localDataSource: sl(),
      preferencesDataSource: sl(),
      authLocalDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<IBudgetRepository>(
    () => BudgetRepositoryImpl(
      localDataSource: sl(),
      profileDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<IGroupRepository>(
    () => GroupRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<AuthRepositoryImpl>(
    () => AuthRepositoryImpl(
      localDataSource: sl(),
      profileRepository: sl(),
      remoteDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<IAuthRepository>(() => sl<AuthRepositoryImpl>());
  sl.registerLazySingleton<ICloudAuthRepository>(() => sl<AuthRepositoryImpl>());

  // 4. Use Cases
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => SaveProfileUseCase(sl()));
  sl.registerLazySingleton(() => GetBudgetSummaryUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => GetAllTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => AddTransactionUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTransactionUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTransactionUseCase(sl()));
  sl.registerLazySingleton(() => GetGroupsUseCase(sl()));
  sl.registerLazySingleton(() => GetGroupMembersUseCase(sl()));
  sl.registerLazySingleton(() => GetDebtSummaryUseCase(sl()));
  sl.registerLazySingleton(() => AddGroupExpenseUseCase(sl()));
  sl.registerLazySingleton(() => AddGroupMemberUseCase(sl()));
  sl.registerLazySingleton(() => AddGroupUseCase(sl()));
  sl.registerLazySingleton(() => SettleBalanceUseCase(sl()));
  sl.registerLazySingleton(() => GetConsolidatedMembersUseCase(sl()));
  sl.registerLazySingleton(() => GetAllGroupMembersUseCase(sl()));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => SignupUseCase(sl()));
  sl.registerLazySingleton(() => GetAuthSessionUseCase(sl()));
  sl.registerLazySingleton(() => GetPreferredModeUseCase(sl()));
  sl.registerLazySingleton(() => SetPreferredModeUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));

  // 5. Presentation BLoCs & Cubits
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      signupUseCase: sl(),
      getAuthSessionUseCase: sl(),
      getPreferredModeUseCase: sl(),
      setPreferredModeUseCase: sl(),
      logoutUseCase: sl(),
      cloudAuthRepository: sl(),
    ),
  );

  sl.registerFactory(
    () => ProfileBloc(
      getProfileUseCase: sl(),
      saveProfileUseCase: sl(),
      profileRepository: sl(),
    ),
  );

  sl.registerFactory(
    () => BudgetBloc(
      getBudgetSummaryUseCase: sl(),
      getTransactionsUseCase: sl(),
      getAllTransactionsUseCase: sl(),
      addTransactionUseCase: sl(),
      updateTransactionUseCase: sl(),
      deleteTransactionUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => GroupsBloc(
      getGroupsUseCase: sl(),
      getGroupMembersUseCase: sl(),
      getDebtSummaryUseCase: sl(),
      addGroupExpenseUseCase: sl(),
      addGroupMemberUseCase: sl(),
      addGroupUseCase: sl(),
      settleBalanceUseCase: sl(),
      getConsolidatedMembersUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => ThemeCubit(profileRepository: sl()),
  );
}
