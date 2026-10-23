import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hisbatak_app/presentation/widgets/custom_bottom_sheet.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_helpers.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/theme/theme_cubit.dart';
import '../../widgets/profile_qr_code_widget.dart';
import '../../widgets/settings_item_tile.dart';

/// [SettingsScreen] renders user preferences, security, and offline data management matching Stitch Screen 5.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showWipeConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appCardBackground,
        title: const Text(AppStrings.wipeData,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.expense)),
        content: Text(
          'هل أنت متأكد من رغبتك في حذف جميع السجلات والمجموعات من ذاكرة الجهاز؟ لا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(color: context.appTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                Text('إلغاء', style: TextStyle(color: context.appTextPrimary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () {
              context.read<ProfileBloc>().add(ResetAppDataEvent());
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('تم مسح البيانات المحلية وإعادة ضبط المصنع.')),
              );
            },
            child: const Text('تأكيد المسح',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      color: context.appBackground,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.settingsAndPreferences,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.appTextPrimary,
                    ),
                  ),
                  // const Row(
                  //   children: [
                  //     // OfflineStatusPill(isCompact: true),
                  //     // SizedBox(width: 8),
                  //     Icon(Iconsax.lock,
                  //         size: 18, color: AppColors.emerald),
                  //   ],
                  // ),
                ],
              ),
              const SizedBox(height: 16),

              // Profile Card (Modern Fintech Layout)
              BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, state) {
                  final profile =
                      (state is ProfileLoaded) ? state.profile : null;
                  final name = profile?.fullName ?? AppStrings.defaultUserName;
                  final email = profile?.email ?? AppStrings.defaultUserEmail;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.appCardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.appBorder),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.25)
                              : AppColors.emerald.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Top Row: Avatar + User Info + QR Code Action Button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 1. Glowing Profile Avatar
                            Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.mintContainer,
                                    AppColors.emeraldLight,
                                    Color(0xFF10B981),
                                    AppColors.emerald,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark
                                            ? AppColors.mintContainer
                                            : AppColors.emeraldLight)
                                        .withValues(
                                            alpha: isDark ? 0.45 : 0.25),
                                    blurRadius: 14,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.appCardBackground,
                                ),
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: isDark
                                      ? AppColors.cardDark
                                      : const Color(0xFFE2E8F0),
                                  child: Text(
                                    name.isNotEmpty ? name[0] : 'م',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppColors.mintContainer
                                          : AppColors.emerald,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // 2. User Details (Name & Email)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: context.appTextPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: context.appTextSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // 3. Modern QR Code Action Button
                            ProfileQrCodeButton(
                              profile: profile,
                              width: 90,
                              height: 75,
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Bottom Security & Offline Status Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.cardDark
                                : AppColors.mintSoft.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.mintContainer
                                      .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Iconsax.shield_tick,
                                  size: 15, color: AppColors.emerald),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'حسبتك غير متصل بالإنترنت (آمن ومحمية محلياً 100%)',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.mintContainer
                                        : AppColors.emerald,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // General Settings Section
              _buildSectionTitle(AppStrings.generalSettings, context),

              const SizedBox(height: 10),

              // Dark Mode Toggle
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  final isDarkActive = themeMode == ThemeMode.dark;
                  return SettingsItemTile(
                    icon: Iconsax.moon,
                    title: AppStrings.darkMode,
                    subtitle: AppStrings.darkModeSub,
                    trailing: Switch(
                      value: isDarkActive,
                      activeTrackColor: AppColors.emerald,
                      onChanged: (val) =>
                          context.read<ThemeCubit>().setDarkMode(val),
                    ),
                  );
                },
              ),

              // App Language Tile
              SettingsItemTile(
                icon: Iconsax.global,
                title: AppStrings.appLanguage,
                subtitle: AppStrings.appLanguageSub,
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.appSurfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppStrings.languageArabic,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: context.appTextPrimary),
                  ),
                ),
              ),

              // Main Currency Tile
              BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, profileState) {
                  final currencyCode = (profileState is ProfileLoaded)
                      ? profileState.profile.currencyCode
                      : 'SAR';
                  return SettingsItemTile(
                    icon: Iconsax.money_3,
                    title: AppStrings.mainCurrency,
                    subtitle: AppStrings.mainCurrencySub,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.emerald.withValues(alpha: 0.2)
                            : AppColors.mintSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currencyCode == 'YER'
                            ? AppStrings.currencyYER
                            : (currencyCode == 'USD'
                                ? AppStrings.currencyUSD
                                : AppStrings.currencySAR),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.mintContainer
                              : AppColors.emerald,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // SettingsItemTile(
              //   onTap: (){
              //               const CustomBottomSheet(title: AppStrings.mainCurrency,

              //               child: ,);

              //   },
              //   icon: Iconsax.money_3,
              //   title: AppStrings.mainCurrency,
              //   subtitle: AppStrings.mainCurrencySub,
              //   trailing: Container(
              //     padding:
              //         const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              //     decoration: BoxDecoration(
              //       color: context.appSurfaceVariant,
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //     child: Text(
              //       AppStrings.languageArabic,
              //       style: TextStyle(
              //           fontSize: 11,
              //           fontWeight: FontWeight.bold,
              //           color: context.appTextPrimary),
              //     ),

              //   ),
              // ),

              // Budget Alerts Toggle
              SettingsItemTile(
                icon: Iconsax.notification,
                title: AppStrings.budgetAlerts,
                subtitle: AppStrings.budgetAlertsSub,
                trailing: Switch(
                  value: true,
                  activeTrackColor: AppColors.emerald,
                  onChanged: (val) {},
                ),
              ),
              const SizedBox(height: 20),

              // Data & Privacy Management Section
              _buildSectionTitle(AppStrings.dataPrivacyManagement, context),

              const SizedBox(height: 10),

              // Biometrics Toggle
              SettingsItemTile(
                icon: Iconsax.finger_scan,
                title: AppStrings.fingerprint,
                subtitle: AppStrings.fingerprintSub,
                trailing: Switch(
                  value: true,
                  activeTrackColor: AppColors.emerald,
                  onChanged: (val) {},
                ),
              ),

              // Export PDF
              SettingsItemTile(
                icon: Iconsax.document_text,
                title: AppStrings.exportAllPdf,
                subtitle: AppStrings.exportAllPdfSub,
                trailing: Icon(Iconsax.document_download,
                    color: context.appTextSecondary, size: 20),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('تم تصدير كشف الحساب والعمليات بنجاح!')),
                  );
                },
              ),

              // Backup Local Data
              SettingsItemTile(
                icon: Iconsax.mobile,
                title: AppStrings.createBackup,
                subtitle: AppStrings.lastBackupToday,
                trailing: const Icon(Iconsax.cloud_connection,
                    color: AppColors.emerald, size: 20),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('تم إنشاء نسخة احتياطية محلية مشفرة.')),
                  );
                },
              ),

              // Restore Backup
              SettingsItemTile(
                icon: Iconsax.refresh_2,
                title: AppStrings.restoreBackup,
                subtitle: AppStrings.restoreBackupSub,
                trailing: Icon(Iconsax.document_upload,
                    color: context.appTextSecondary, size: 20),
                onTap: () {},
              ),

              // Wipe Data (Destructive)
              SettingsItemTile(
                icon: Iconsax.trash,
                title: AppStrings.wipeData,
                subtitle: AppStrings.wipeDataSub,
                isDestructive: true,
                onTap: () => _showWipeConfirmation(context),
              ),
              const SizedBox(height: 16),

              _buildSectionTitle(AppStrings.others, context),
              const SizedBox(height: 10),

              // SettingsItemTile(
              //   icon: Iconsax.discover,
              //   title: AppStrings.onboardingAppTour,
              //   subtitle: AppStrings.onboardingAppTourSub,
              //   trailing: Icon(
              //     Iconsax.arrow_left_2,
              //     size: 14,
              //     color: context.appTextMuted,
              //   ),
              //   onTap: () => context.push('/onboarding'),
              // ),

              SettingsItemTile(
                icon: Iconsax.info_circle,
                title: AppStrings.aboutApp,
                // subtitle: 'الإصدار، الميزات، وفلسفة الخصوصية',
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: context.appTextMuted,
                ),
                onTap: () => context.push('/about'),
              ),

              SettingsItemTile(
                icon: Iconsax.logout,
                title: AppStrings.logout,
                isDestructive: true,
                // trailing: Icon(
                //   Iconsax.arrow_left_2,
                //   size: 14,
                //   color: isDark ? const Color(0xFFF87171) : AppColors.expense,
                // ),
                onTap: () => AppHelpers.showLogoutDialog(context),
              ),

              // Total Privacy Note Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardDark
                      : AppColors.mintSoft.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.mintContainer.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Iconsax.security_safe,
                        color: AppColors.emerald, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'خصوصية تامة بدون سحابة',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.mintContainer
                                  : AppColors.emerald,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.totalPrivacyNote,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                              color: isDark
                                  ? const Color(0xFF6FFBBE)
                                  : const Color(0xFF005236),
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

              // App Version
              Center(
                child: Column(
                  children: [
                    Text(
                      'حِسبَتك ${AppStrings.appVersion} (Offline-First Build)',
                      style: TextStyle(
                          fontSize: 11,
                          color: context.appTextMuted,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'جميع الحقوق محفوظة لMsmDev © 2026',
                      style: TextStyle(
                          fontSize: 10,
                          color: context.appTextMuted,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Row(
      children: [
        Container(
          height: 16.6,
          width: 4,
          // color: AppColors.emerald,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: AppColors.emerald,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          title,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: context.appTextPrimary),
        ),
      ],
    );
  }
}
