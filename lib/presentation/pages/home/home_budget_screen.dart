import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/datasources/preferences/app_preferences_data_source.dart';
import '../../../data/datasources/sync/sync_service.dart';
import '../../../domain/entities/budget_summary.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/budget/budget_bloc.dart';
import '../../bloc/groups/groups_bloc.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/theme/theme_cubit.dart';
import '../../widgets/budget_card.dart';
import '../../widgets/custom_app_button.dart';
import '../../widgets/hisbatak_loader.dart';
import '../../widgets/offline_status_pill.dart';
import '../../widgets/profile_currency_extension.dart';
import '../../widgets/transaction_details_dialog.dart';
import '../../widgets/transaction_list_tile.dart';

/// [HomeBudgetScreen] renders the personal budget and analytics dashboard.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class HomeBudgetScreen extends StatelessWidget {
  const HomeBudgetScreen({super.key});

  String _buildSmartInsight(BudgetSummary summary, String currencySymbol) {
    if (summary.budgetLimit > 0 && summary.totalSpent > 0) {
      final spentRatio = (summary.totalSpent / summary.budgetLimit) * 100;
      if (spentRatio >= 100) {
        return 'تجاوز إنفاقك حد الميزانية الشهري بنسبة ${(spentRatio - 100).toStringAsFixed(0)}%؛ يُنصح بمراجعة المصروفات غير الضرورية.';
      }
      if (spentRatio >= 80) {
        return 'تنبيه ذكي: استهلكت ${spentRatio.toStringAsFixed(0)}% من ميزانيتك، والمتبقي ${Formatters.formatCurrency(summary.totalAvailable, currencySymbol: currencySymbol)}.';
      }
    }

    if (summary.categories.isNotEmpty) {
      final topCat = summary.categories.first;
      return 'أعلى إنفاق هذا الشهر في "${topCat.categoryName}" بنسبة ${topCat.percentage.round()}% (${Formatters.formatCurrency(topCat.amount, currencySymbol: currencySymbol)}).';
    }

    return AppStrings.walletAiDescription;
  }

  void _showSyncStatusSheet(
    BuildContext context, {
    required bool isOnlineMode,
    required int pendingSyncCount,
  }) {
    final isDark = context.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isOnlineMode
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_off_rounded,
                    color: AppColors.emerald,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOnlineMode
                            ? 'حالة المزامنة السحابية'
                            : 'الوضع المحلي الآمن (Offline-First)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: context.appTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pendingSyncCount > 0
                            ? 'يوجد $pendingSyncCount عمليات محلية جاهزة للمزامنة.'
                            : 'جميع السجلات المحلية محدّثة ومنسّقة بالكامل.',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (_) {
                var isSyncing = false;
                return StatefulBuilder(
                  builder: (buttonCtx, setBtnState) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isSyncing
                        ? null
                        : () async {
                            setBtnState(() => isSyncing = true);
                            SyncSummary? summary;
                            if (sl.isRegistered<ISyncService>()) {
                              summary = await sl<ISyncService>().syncNow();
                            }
                            if (!context.mounted) return;
                            context
                                .read<BudgetBloc>()
                                .add(LoadBudgetDashboardEvent());
                            context.read<GroupsBloc>().add(LoadGroupsEvent());
                            context.read<ProfileBloc>().add(LoadProfileEvent());
                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                            }
                            final msg = summary == null
                                ? 'تم تحديث السجلات المحلية بنجاح ✓'
                                : (!summary.isSuccess
                                    ? summary.errorMessage!
                                    : (summary.cloudConfigured
                                        ? 'تمت المزامنة: رفع ${summary.pushedCount} وسحب ${summary.pulledCount} ✓'
                                        : (summary.pendingRemaining > 0
                                            ? 'محفوظ محلياً (${summary.pendingRemaining} عمليات جاهزة عند الربط السحابي) ✓'
                                            : 'جميع السجلات المحلية محدثة بنجاح ✓')));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor:
                                    (summary != null && !summary.isSuccess)
                                        ? AppColors.expense
                                        : AppColors.emerald,
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.sync_rounded, size: 18),
                    label: Text(
                      isOnlineMode
                          ? 'مزامنة السجلات الآن'
                          : 'تحديث السجلات الآن',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
                  },
                );
              },
            ),
            if (!isOnlineMode) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.push('/login');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: context.appBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'ربط حساب للمزامنة السحابية',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showNotificationsSheet(
    BuildContext context, {
    required BudgetLoaded state,
    required int pendingSyncCount,
  }) async {
    final activeCurrency = context.readCurrencySymbol();
    bool alertsEnabled = true;
    if (sl.isRegistered<IAppPreferencesDataSource>()) {
      alertsEnabled =
          await sl<IAppPreferencesDataSource>().isBudgetAlertsEnabled();
    }
    if (!context.mounted) return;

    final List<({String title, String body, Color color, IconData icon})>
        alerts = [];

    if (alertsEnabled && state.summary.budgetLimit > 0) {
      final ratio =
          (state.summary.totalSpent / state.summary.budgetLimit) * 100;
      if (ratio >= 80) {
        alerts.add((
          title: ratio >= 100
              ? 'تجاوز الحد الشهري للميزانية'
              : 'اقتربت من الحد الشهري (${ratio.toStringAsFixed(0)}%)',
          body:
              'صرفت ${Formatters.formatCurrency(state.summary.totalSpent, currencySymbol: activeCurrency)} من أصل ${Formatters.formatCurrency(state.summary.budgetLimit, currencySymbol: activeCurrency)}.',
          color: ratio >= 100 ? AppColors.expense : AppColors.warning,
          icon: Iconsax.warning_2,
        ));
      }
    }

    if (state.summary.totalAvailable < 0) {
      alerts.add((
        title: 'الرصيد المتاح بالسالب',
        body:
            'الرصيد المتاح الحالي ${Formatters.formatSignedCurrency(state.summary.totalAvailable, currencySymbol: activeCurrency)}.',
        color: AppColors.expense,
        icon: Iconsax.wallet_minus,
      ));
    }

    if (pendingSyncCount > 0) {
      alerts.add((
        title: 'عمليات بانتظار المزامنة',
        body: 'لديك $pendingSyncCount عمليات محفوظة محلياً بانتظار المزامنة.',
        color: AppColors.emerald,
        icon: Iconsax.cloud_notif,
      ));
    }

    final isDark = context.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'التنبيهات المالية',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (alerts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.appSurfaceVariant.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.tick_circle, color: AppColors.emerald),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        alertsEnabled
                            ? 'لا توجد تنبيهات نشطة حالياً — ميزانيتك في النطاق الآمن ✓'
                            : 'تنبيهات الميزانية متوقفة حالياً من الإعدادات.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...alerts.map(
                (alert) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: alert.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: alert.color.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(alert.icon, color: alert.color, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: context.appTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              alert.body,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: context.appTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appBackground,
      child: SafeArea(
        child: BlocBuilder<BudgetBloc, BudgetState>(
          builder: (context, state) {
            if (state is BudgetLoading) {
              return const Center(child: HisbatakLoader());
            } else if (state is BudgetLoaded) {
              return _buildContent(context, state);
            } else if (state is BudgetError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, BudgetLoaded state) {
    final isDark = context.isDarkMode;
    final activeCurrency = context.watchCurrencySymbol();
    final lastTransactions = state.allTransactions.take(5);
    final pendingSyncCount =
        state.allTransactions.where((tx) => !tx.isSynced).length;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final isOnlineMode = authState.isOnline;

        return RefreshIndicator(
          onRefresh: () async {
            if (isOnlineMode && sl.isRegistered<ISyncService>()) {
              await sl<ISyncService>().syncNow();
            }
            if (!context.mounted) return;
            context.read<BudgetBloc>().add(LoadBudgetDashboardEvent());
            context.read<GroupsBloc>().add(LoadGroupsEvent());
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: User Profile Greeting & Status
                BlocBuilder<ProfileBloc, ProfileState>(
                  builder: (context, profileState) {
                    final userName = (profileState is ProfileLoaded &&
                            profileState.profile.fullName.trim().isNotEmpty)
                        ? profileState.profile.fullName.trim()
                        : AppStrings.defaultUserName;
                    return Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: isDark
                                  ? AppColors.cardDark
                                  : const Color(0xFFE2E8F0),
                              child: Text(
                                userName.isNotEmpty ? userName[0] : 'م',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: context.appTextPrimary,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.emerald,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.primaryDark
                                        : Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppHelpers.greetingMessage(),
                                style: TextStyle(
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.bold,
                                  color: context.appTextPrimary,
                                ),
                              ),
                              Text(
                                userName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: context.appTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppStrings.homeAndBudget,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.appTextSecondary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        CustomAppButton(
                          icon: Icons.sync_rounded,
                          onPressed: () => _showSyncStatusSheet(
                            context,
                            isOnlineMode: isOnlineMode,
                            pendingSyncCount: pendingSyncCount,
                          ),
                        ),
                        const SizedBox(width: 8),
                        CustomAppButton(
                          icon: Iconsax.notification,
                          onPressed: () => _showNotificationsSheet(
                            context,
                            state: state,
                            pendingSyncCount: pendingSyncCount,
                          ),
                        ),
                        const SizedBox(width: 8),
                        BlocBuilder<ThemeCubit, ThemeMode>(
                          builder: (context, themeModeState) {
                            final isDarkActive = themeModeState ==
                                    ThemeMode.dark ||
                                (themeModeState == ThemeMode.system &&
                                    MediaQuery.platformBrightnessOf(context) ==
                                        Brightness.dark);

                            return ThemeSwitcher(
                              builder: (switcherContext) {
                                return CustomAppButton(
                                  icon: isDarkActive
                                      ? Iconsax.sun_1
                                      : Iconsax.moon,
                                  onPressed: () {
                                    final nextTheme = isDarkActive
                                        ? AppTheme.lightTheme
                                        : AppTheme.darkTheme;

                                    ThemeSwitcher.of(switcherContext)
                                        .changeTheme(
                                      theme: nextTheme,
                                      isReversed: isDarkActive,
                                    );

                                    context
                                        .read<ThemeCubit>()
                                        .setDarkMode(!isDarkActive);
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Top Connection & Sync Status Banner
                OfflineTopBanner(
                  isOnlineMode: isOnlineMode,
                  pendingSyncCount: pendingSyncCount,
                  onSyncTap: () => _showSyncStatusSheet(
                    context,
                    isOnlineMode: isOnlineMode,
                    pendingSyncCount: pendingSyncCount,
                  ),
                ),
                const SizedBox(height: 16),

                // Budget Summary Card
                BudgetCard(
                  summary: state.summary,
                  currencySymbol: activeCurrency,
                ),
                const SizedBox(height: 16),

                // Wallet Smart Insight Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.appCardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.appBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.emerald.withValues(alpha: 0.2)
                              : AppColors.mintSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Iconsax.magicpen,
                          color: AppColors.emerald,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Iconsax.magicpen,
                                  size: 14,
                                  color: AppColors.emerald,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  AppStrings.walletAiTitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.mintContainer
                                        : AppColors.emerald,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _buildSmartInsight(
                                state.summary,
                                activeCurrency,
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                color: context.appTextPrimary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Recent Transactions Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.recentTransactions,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.appTextPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/all-transactions'),
                      child: const Text(
                        AppStrings.viewAll,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.emerald,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Transactions List
                if (state.recentTransactions.isEmpty) ...[
                  const Center(
                    child: Text(
                      AppStrings.noTransactions,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else ...[
                  ...lastTransactions.map(
                    (tx) => TransactionListTile(
                      item: tx,
                      currencySymbol: activeCurrency,
                      onTap: () => TransactionDetailsDialog.show(context, tx),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Bottom Security Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardDark
                        : AppColors.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.shield_tick,
                        color: AppColors.emerald,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.budgetUnderControl,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: context.appTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppStrings.budgetControlSub,
                              style: TextStyle(
                                fontSize: 10,
                                color: context.appTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
