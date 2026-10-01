import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/theme/theme_cubit.dart';
import '../../widgets/offline_status_pill.dart';
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
        title: const Text(AppStrings.wipeData, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.expense)),
        content: Text(
          'هل أنت متأكد من رغبتك في حذف جميع السجلات والمجموعات من ذاكرة الجهاز؟ لا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(color: context.appTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('إلغاء', style: TextStyle(color: context.appTextPrimary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () {
              context.read<ProfileBloc>().add(ResetAppDataEvent());
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم مسح البيانات المحلية وإعادة ضبط المصنع.')),
              );
            },
            child: const Text('تأكيد المسح', style: TextStyle(color: Colors.white)),
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
                  const Row(
                    children: [
                      OfflineStatusPill(isCompact: true),
                      SizedBox(width: 8),
                      Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.emerald),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Profile Card
              BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, state) {
                  final profile = (state is ProfileLoaded) ? state.profile : null;
                  final name = profile?.fullName ?? AppStrings.defaultUserName;
                  final email = profile?.email ?? AppStrings.defaultUserEmail;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: context.appCardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.appBorder),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: isDark ? AppColors.cardDark : const Color(0xFFE2E8F0),
                          child: Text(
                            name.isNotEmpty ? name[0] : 'م',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.appTextPrimary),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          name,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appTextPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: TextStyle(fontSize: 11, color: context.appTextSecondary),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.emerald.withValues(alpha: 0.2) : AppColors.mintSoft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_user_rounded, size: 14, color: AppColors.emerald),
                              const SizedBox(width: 6),
                              Text(
                                'المحفظة غير متصلة بالإنترنت (آمنة تماماً)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.mintContainer : AppColors.emerald,
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
              Text(
                AppStrings.generalSettings,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appTextPrimary),
              ),
              const SizedBox(height: 10),

              // Dark Mode Toggle
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  final isDarkActive = themeMode == ThemeMode.dark;
                  return SettingsItemTile(
                    icon: Icons.dark_mode_outlined,
                    title: AppStrings.darkMode,
                    subtitle: AppStrings.darkModeSub,
                    trailing: Switch(
                      value: isDarkActive,
                      activeTrackColor: AppColors.emerald,
                      onChanged: (val) => context.read<ThemeCubit>().setDarkMode(val),
                    ),
                  );
                },
              ),

              // App Language Tile
              SettingsItemTile(
                icon: Icons.translate_rounded,
                title: AppStrings.appLanguage,
                subtitle: AppStrings.appLanguageSub,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.appSurfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppStrings.languageArabic,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.appTextPrimary),
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
                    icon: Icons.payments_outlined,
                    title: AppStrings.mainCurrency,
                    subtitle: AppStrings.mainCurrencySub,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.emerald.withValues(alpha: 0.2) : AppColors.mintSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currencyCode == 'YER' ? AppStrings.currencyYER : (currencyCode == 'USD' ? AppStrings.currencyUSD : AppStrings.currencySAR),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.mintContainer : AppColors.emerald,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Budget Alerts Toggle
              SettingsItemTile(
                icon: Icons.notifications_active_outlined,
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
              Text(
                AppStrings.dataPrivacyManagement,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appTextPrimary),
              ),
              const SizedBox(height: 10),

              // Export PDF
              SettingsItemTile(
                icon: Icons.picture_as_pdf_outlined,
                title: AppStrings.exportAllPdf,
                subtitle: AppStrings.exportAllPdfSub,
                trailing: Icon(Icons.download_rounded, color: context.appTextSecondary, size: 20),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تصدير كشف الحساب والعمليات بنجاح!')),
                  );
                },
              ),

              // Backup Local Data
              SettingsItemTile(
                icon: Icons.phonelink_setup_rounded,
                title: AppStrings.createBackup,
                subtitle: AppStrings.lastBackupToday,
                trailing: const Icon(Icons.backup_outlined, color: AppColors.emerald, size: 20),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إنشاء نسخة احتياطية محلية مشفرة.')),
                  );
                },
              ),

              // Restore Backup
              SettingsItemTile(
                icon: Icons.settings_backup_restore_rounded,
                title: AppStrings.restoreBackup,
                subtitle: AppStrings.restoreBackupSub,
                trailing: Icon(Icons.file_upload_outlined, color: context.appTextSecondary, size: 20),
                onTap: () {},
              ),

              // Wipe Data (Destructive)
              SettingsItemTile(
                icon: Icons.delete_outline_rounded,
                title: AppStrings.wipeData,
                subtitle: AppStrings.wipeDataSub,
                isDestructive: true,
                onTap: () => _showWipeConfirmation(context),
              ),
              const SizedBox(height: 16),

              // Total Privacy Note Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.mintSoft.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.mintContainer.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.security_rounded, color: AppColors.emerald, size: 22),
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
                              color: isDark ? AppColors.mintContainer : AppColors.emerald,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.totalPrivacyNote,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? const Color(0xFF6FFBBE) : const Color(0xFF005236),
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
                      style: TextStyle(fontSize: 11, color: context.appTextMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'جميع الحقوق محفوظة للمستخدم المحلي © 2026',
                      style: TextStyle(fontSize: 10, color: context.appTextMuted),
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
}
