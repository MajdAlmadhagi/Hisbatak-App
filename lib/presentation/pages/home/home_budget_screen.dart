import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hisbatak_app/core/utils/app_helpers.dart';
import 'package:hisbatak_app/presentation/bloc/theme/theme_cubit.dart';
import 'package:hisbatak_app/presentation/widgets/custom_app_button.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../bloc/budget/budget_bloc.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../widgets/budget_card.dart';
import '../../widgets/hisbatak_loader.dart';
import '../../widgets/offline_status_pill.dart';
import '../../widgets/transaction_details_dialog.dart';
import '../../widgets/transaction_list_tile.dart';

/// [HomeBudgetScreen] renders the personal budget and analytics dashboard matching Stitch Screen 2.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class HomeBudgetScreen extends StatelessWidget {
  const HomeBudgetScreen({super.key});

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
    final lastTransactions = state.allTransactions.take(5);

    return RefreshIndicator(
      onRefresh: () async {
        context.read<BudgetBloc>().add(LoadBudgetDashboardEvent());
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: User Profile Greeting & Status
            BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, profileState) {
                final userName = (profileState is ProfileLoaded)
                    ? profileState.profile.fullName
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
                                color: context.appTextPrimary),
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
                                  width: 1.5),
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
                            '${AppHelpers.greetingMessage()}',
                            style: TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.bold,
                              color: context.appTextPrimary,
                            ),
                          ),
                          // const SizedBox(height: 1),
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
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    //const OfflineStatusPill(isCompact: true),
                    const SizedBox(width: 8),
                    // IconButton(
                    //   icon: Icon(Iconsax.search_normal,
                    //       size: 20, color: context.appTextPrimary),
                    //   onPressed: () {},
                    //   padding: EdgeInsets.zero,
                    //   constraints: const BoxConstraints(),
                    // ),

                    CustomAppButton(
                      icon: Icons.sync_rounded,
                      onPressed: () {},
//text: '',
                    ),
                    const SizedBox(width: 8),

                    CustomAppButton(
                      icon: Iconsax.notification,
                      onPressed: () {},
//text: '',
                    ),

                    const SizedBox(width: 8),

                    BlocBuilder<ThemeCubit, ThemeMode>(
                      builder: (context, themeModeState) {
                        final isDarkActive = themeModeState == ThemeMode.dark;

                        return ThemeSwitcher(
                          // clipper: const ThemeSwitcherCircleClipper(),
                          builder: (switcherContext) {
                            return CustomAppButton(
                              icon: isDarkActive ? Iconsax.sun_1 : Iconsax.moon,
                              onPressed: () {
                                final nextTheme = isDarkActive
                                    ? AppTheme.lightTheme
                                    : AppTheme.darkTheme;

                                ThemeSwitcher.of(switcherContext).changeTheme(
                                    theme: nextTheme, isReversed: isDarkActive);

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

            // Top Offline Status Banner
            const OfflineTopBanner(),
            const SizedBox(height: 16),

            // Budget Summary Card
            BudgetCard(summary: state.summary),
            const SizedBox(height: 16),

            // Wallet AI Insight Card
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
                    child: const Icon(Iconsax.magicpen,
                        color: AppColors.emerald, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Iconsax.magicpen,
                                size: 14, color: AppColors.emerald),
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
                          AppStrings.walletAiDescription,
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
                        color: AppColors.emerald),
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
                    // color: AppColors.emerald
                  ),
                ),
              ),
            ] else ...[
              ...lastTransactions.map((tx) => TransactionListTile(
                    item: tx,
                    onTap: () => TransactionDetailsDialog.show(context, tx),
                  )),
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
                  const Icon(Iconsax.shield_tick,
                      color: AppColors.emerald, size: 20),
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
                              color: context.appTextPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.budgetControlSub,
                          style: TextStyle(
                              fontSize: 10, color: context.appTextSecondary),
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
  }
}
