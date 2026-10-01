import 'package:get_it/get_it.dart';
import '../database/app_database.dart';
import '../../data/datasources/local_datasources.dart';
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

final sl = GetIt.instance;

/// [initDependencyInjection] registers all singletons, factories, and BLoCs.
///
/// SOLID Principle: Dependency Inversion Principle (DIP)
/// Decouples concrete class construction from consumer widgets and components.
Future<void> initDependencyInjection() async {
  // 1. Core Database
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase.instance);

  // 2. Data Sources
  sl.registerLazySingleton<IProfileLocalDataSource>(
    () => ProfileLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<IBudgetLocalDataSource>(
    () => BudgetLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<IGroupLocalDataSource>(
    () => GroupLocalDataSourceImpl(sl()),
  );

  // 3. Repositories
  sl.registerLazySingleton<IProfileRepository>(
    () => ProfileRepositoryImpl(sl()),
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
  sl.registerLazySingleton(() => SettleBalanceUseCase(sl()));

  // 5. Presentation BLoCs & Cubits
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
      settleBalanceUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => ThemeCubit(profileRepository: sl()),
  );
}
