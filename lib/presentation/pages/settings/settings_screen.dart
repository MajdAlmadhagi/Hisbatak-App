import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/security/app_lock_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/utils/report_exporter.dart';
import '../../../core/utils/validators.dart';
import '../../../data/datasources/preferences/app_preferences_data_source.dart';
import '../../../data/datasources/sync/sync_service.dart';
import '../../../domain/entities/budget_summary.dart';
import '../../../domain/entities/group_entity.dart';
import '../../../domain/entities/transaction_item.dart';
import '../../../domain/entities/user_profile.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/budget/budget_bloc.dart';
import '../../bloc/groups/groups_bloc.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/theme/theme_cubit.dart';
import '../../widgets/profile_qr_code_widget.dart';
import '../../widgets/report_export_sheet.dart';
import '../../widgets/settings_item_tile.dart';

/// [SettingsScreen] renders user preferences, security, and local/cloud data management.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _budgetAlertsEnabled = true;
  bool _biometricPrefEnabled = false;
  int _pendingSyncCount = 0;
  bool _isSyncing = false;

  static const List<Map<String, String>> _supportedCurrencies = [
    {'code': 'SAR', 'symbol': 'ر.س', 'name': AppStrings.currencySAR},
    {'code': 'YER', 'symbol': 'ر.ي', 'name': AppStrings.currencyYER},
    {'code': 'USD', 'symbol': r'$', 'name': AppStrings.currencyUSD},
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    bool alerts = _budgetAlertsEnabled;
    bool bio = _biometricPrefEnabled;
    int pending = 0;

    if (sl.isRegistered<IAppPreferencesDataSource>()) {
      final prefs = sl<IAppPreferencesDataSource>();
      alerts = await prefs.isBudgetAlertsEnabled();
      bio = await prefs.isBiometricEnabled();
    }
    if (sl.isRegistered<ISyncService>()) {
      pending = await sl<ISyncService>().getPendingOutboxCount();
    }

    if (!mounted) return;
    setState(() {
      _budgetAlertsEnabled = alerts;
      _biometricPrefEnabled = bio;
      _pendingSyncCount = pending;
    });
  }

  Future<void> _triggerManualSync() async {
    if (_isSyncing || !sl.isRegistered<ISyncService>()) return;
    setState(() => _isSyncing = true);
    final summary = await sl<ISyncService>().syncNow();
    if (!mounted) return;
    setState(() {
      _isSyncing = false;
      _pendingSyncCount = summary.pendingRemaining;
    });
    context.read<BudgetBloc>().add(LoadBudgetDashboardEvent());
    context.read<GroupsBloc>().add(LoadGroupsEvent());
    context.read<ProfileBloc>().add(LoadProfileEvent());

    final msg = !summary.isSuccess
        ? summary.errorMessage!
        : (summary.cloudConfigured
            ? 'تمت المزامنة: رفع ${summary.pushedCount} وسحب ${summary.pulledCount} ✓'
            : (summary.pendingRemaining > 0
                ? 'محفوظ محلياً (${summary.pendingRemaining} عمليات جاهزة للمزامنة) ✓'
                : 'جميع البيانات المحلية محدثة بنجاح ✓'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            summary.isSuccess ? AppColors.emerald : AppColors.expense,
      ),
    );
  }

  Future<void> _toggleBudgetAlerts(bool enabled) async {
    setState(() => _budgetAlertsEnabled = enabled);
    if (sl.isRegistered<IAppPreferencesDataSource>()) {
      await sl<IAppPreferencesDataSource>().setBudgetAlertsEnabled(enabled);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'تم تفعيل تنبيهات الميزانية ✓'
              : 'تم إيقاف تنبيهات الميزانية.',
        ),
        backgroundColor: AppColors.emerald,
      ),
    );
  }

  Future<void> _toggleBiometricLock(bool enabled) async {
    final lockService =
        sl.isRegistered<IAppLockService>() ? sl<IAppLockService>() : null;

    if (enabled) {
      if (lockService != null) {
        final pin = await _showSetupPinDialog();
        if (pin == null) return;
        await lockService.setPin(pin);
      }
    } else if (lockService != null && lockService.isLockEnabled()) {
      final confirmed = await _showVerifyPinDialog(lockService);
      if (!confirmed) return;
      await lockService.disableLock();
    }

    if (!mounted) return;
    setState(() => _biometricPrefEnabled = enabled);
    context.read<ProfileBloc>().add(ToggleBiometricEvent(enabled));
    if (sl.isRegistered<IAppPreferencesDataSource>()) {
      await sl<IAppPreferencesDataSource>().setBiometricEnabled(enabled);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'تم تفعيل قفل التطبيق برمز PIN ✓'
              : 'تم إيقاف قفل التطبيق.',
        ),
        backgroundColor: AppColors.emerald,
      ),
    );
  }

  Future<String?> _showSetupPinDialog() async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعيين رمز قفل التطبيق (PIN)'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'سيُطلب هذا الرمز لفتح محفظتك على هذا الجهاز سواء كنت متصلاً بالإنترنت أو بدون إنترنت.',
                  style: TextStyle(fontSize: 12, color: ctx.appTextSecondary),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'أدخل رمز PIN من 4 أرقام',
                    counterText: '',
                  ),
                  validator: (v) => Validators.validatePin(v),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: confirmController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'تأكيد رمز PIN',
                    counterText: '',
                  ),
                  validator: (v) {
                    final err = Validators.validatePin(v);
                    if (err != null) return err;
                    if (Validators.normalizeDigits(v!.trim()) !=
                        Validators.normalizeDigits(pinController.text.trim())) {
                      return 'الرمزان غير متطابقين';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(ctx).pop(
                    Validators.normalizeDigits(pinController.text.trim()),
                  );
                }
              },
              child: const Text('حفظ وتفعيل'),
            ),
          ],
        ),
      ),
    );
    pinController.dispose();
    confirmController.dispose();
    return result;
  }

  Future<bool> _showVerifyPinDialog(IAppLockService lockService) async {
    final pinController = TextEditingController();
    String? errorMsg;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد رمز القفل لإلغاء التفعيل'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'أدخل رمز PIN الحالي',
                    errorText: errorMsg,
                    counterText: '',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final ok = await lockService.verifyPin(pinController.text);
                  if (!ctx.mounted) return;
                  if (ok) {
                    Navigator.of(ctx).pop(true);
                  } else {
                    setDialogState(() {
                      errorMsg = 'الرمز غير صحيح';
                    });
                  }
                },
                child: const Text('تأكيد'),
              ),
            ],
          ),
        ),
      ),
    );
    pinController.dispose();
    return result ?? false;
  }

  void _showCurrencyPicker(BuildContext context, UserProfile? profile) {
    final isDark = context.isDarkMode;
    final currentCode = profile?.currencyCode ?? 'SAR';

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
              AppStrings.mainCurrency,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.mainCurrencySub,
              style: TextStyle(fontSize: 12, color: context.appTextSecondary),
            ),
            const SizedBox(height: 14),
            ..._supportedCurrencies.map((currency) {
              final code = currency['code']!;
              final symbol = currency['symbol']!;
              final name = currency['name']!;
              final isSelected = code == currentCode;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    final baseProfile = profile ??
                        UserProfile(
                          id: IdGenerator.uuidV4(),
                          fullName: AppStrings.defaultUserName,
                          email: AppStrings.defaultUserEmail,
                          currencyCode: 'SAR',
                          currencySymbol: 'ر.س',
                          monthlyBudgetLimit: 20000,
                          currentAvailable: 20000,
                          biometricEnabled: false,
                          isDarkMode: false,
                          isConfigured: true,
                        );
                    context.read<ProfileBloc>().add(
                          SaveProfileEvent(
                            baseProfile.copyWith(
                              currencyCode: code,
                              currencySymbol: symbol,
                            ),
                          ),
                        );
                    context.read<BudgetBloc>().add(LoadBudgetDashboardEvent());
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم اعتماد "$name" عملةً رئيسية ✓'),
                        backgroundColor: AppColors.emerald,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.emerald.withValues(alpha: 0.12)
                          : context.appSurfaceVariant.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.emerald
                            : context.appBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mintFixed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            symbol,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF005236),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$name ($code)',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: context.appTextPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Iconsax.tick_circle,
                            color: AppColors.emerald,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _openExportReportSheet(BuildContext context, UserProfile? profile) {
    final currencySymbol = profile?.currencySymbol ?? 'ر.س';

    final budgetState = context.read<BudgetBloc>().state;
    final List<TransactionItem> transactions = budgetState is BudgetLoaded
        ? budgetState.allTransactions
        : <TransactionItem>[];
    final BudgetSummary? budgetSummary =
        budgetState is BudgetLoaded ? budgetState.summary : null;

    final groupsState = context.read<GroupsBloc>().state;
    final List<GroupEntity> groups =
        groupsState is GroupsLoaded ? groupsState.groups : <GroupEntity>[];
    final List<ConsolidatedMemberEntity> members =
        groupsState is GroupsLoaded
            ? groupsState.allMembers
            : <ConsolidatedMemberEntity>[];
    final DebtSummary? debtSummary =
        groupsState is GroupsLoaded ? groupsState.debtSummary : null;

    final txCsv = ReportExporter.buildTransactionsCsv(
      transactions,
      currencySymbol: currencySymbol,
    );
    final groupsCsv = debtSummary != null
        ? ReportExporter.buildGroupsSummaryCsv(
            groups: groups,
            members: members,
            summary: debtSummary,
            currencySymbol: currencySymbol,
          )
        : '';
    final fullJson = ReportExporter.buildFullJsonExport(
      profile: profile,
      summary: budgetSummary,
      transactions: transactions,
      groups: groups,
      members: members,
      debtSummary: debtSummary,
    );

    ReportExportSheet.show(
      context,
      title: 'تصدير كشف الحساب والنسخة المحلية',
      subtitle:
          '${transactions.length} عملية مالية • ${groups.length} مجموعات • ${members.length} أعضاء',
      formats: [
        ReportExportFormatOption(label: 'CSV العمليات', content: txCsv),
        if (groupsCsv.isNotEmpty)
          ReportExportFormatOption(label: 'CSV المجموعات', content: groupsCsv),
        ReportExportFormatOption(label: 'JSON نسخة كاملة', content: fullJson),
      ],
    );
  }

  void _showWipeConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appCardBackground,
        title: const Text(
          AppStrings.wipeData,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.expense,
          ),
        ),
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
            onPressed: () async {
              if (sl.isRegistered<IAppLockService>()) {
                await sl<IAppLockService>().disableLock();
              }
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              if (!context.mounted) return;
              context.read<ProfileBloc>().add(ResetAppDataEvent());
              context.read<AuthBloc>().add(LogoutAuthEvent());
              context.read<ThemeCubit>().resetToSystem();
              context.read<BudgetBloc>().add(LoadBudgetDashboardEvent());
              context.read<GroupsBloc>().add(LoadGroupsEvent());
              setState(() {
                _budgetAlertsEnabled = true;
                _biometricPrefEnabled = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم مسح البيانات المحلية وإعادة ضبط المصنع.'),
                ),
              );
              context.go('/onboarding');
            },
            child: const Text(
              'تأكيد المسح',
              style: TextStyle(color: Colors.white),
            ),
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
                ],
              ),
              const SizedBox(height: 16),

              // Profile Card
              BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, state) {
                  final profile =
                      (state is ProfileLoaded) ? state.profile : null;
                  final name = (profile != null &&
                          profile.fullName.trim().isNotEmpty)
                      ? profile.fullName.trim()
                      : AppStrings.defaultUserName;
                  final email = (profile != null &&
                          profile.phoneE164 != null &&
                          profile.phoneE164!.trim().isNotEmpty)
                      ? profile.phoneE164!.trim()
                      : ((profile != null && profile.email.trim().isNotEmpty)
                          ? profile.email.trim()
                          : AppStrings.defaultUserEmail);

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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
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
                            ProfileQrCodeButton(
                              profile: profile,
                              width: 90,
                              height: 75,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, authState) {
                            final isOnline = authState.isOnline;
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
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
                                  Icon(
                                    isOnline
                                        ? Iconsax.cloud_connection
                                        : Iconsax.shield_tick,
                                    size: 15,
                                    color: AppColors.emerald,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isOnline
                                          ? 'حسابك مربوط سحابياً والمحفظة محمية محلياً'
                                          : 'حِسبَتك يعمل محلياً بدون إنترنت (آمن ومحمي 100%)',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.mintContainer
                                            : AppColors.emerald,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap:
                                        _isSyncing ? null : _triggerManualSync,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.emerald
                                            .withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        _isSyncing
                                            ? 'جاري...'
                                            : (_pendingSyncCount > 0
                                                ? 'مزامنة ($_pendingSyncCount)'
                                                : 'مزامنة'),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.emerald,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
                  final isDarkActive = themeMode == ThemeMode.dark ||
                      (themeMode == ThemeMode.system &&
                          MediaQuery.platformBrightnessOf(context) ==
                              Brightness.dark);
                  return ThemeSwitcher(
                    clipper: const ThemeSwitcherCircleClipper(),
                    builder: (switcherContext) {
                      return SettingsItemTile(
                        icon: Iconsax.moon,
                        title: AppStrings.darkMode,
                        subtitle: AppStrings.darkModeSub,
                        trailing: Switch(
                          value: isDarkActive,
                          activeTrackColor: AppColors.emerald,
                          onChanged: (val) {
                            final nextTheme =
                                val ? AppTheme.darkTheme : AppTheme.lightTheme;
                            ThemeSwitcher.of(switcherContext).changeTheme(
                              theme: nextTheme,
                            );
                            context.read<ThemeCubit>().setDarkMode(val);
                          },
                        ),
                      );
                    },
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
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
              ),

              // Main Currency Picker Tile
              BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, profileState) {
                  final profile = profileState is ProfileLoaded
                      ? profileState.profile
                      : null;
                  final currencyCode = profile?.currencyCode ?? 'SAR';

                  return SettingsItemTile(
                    icon: Iconsax.money_3,
                    title: AppStrings.mainCurrency,
                    subtitle: AppStrings.mainCurrencySub,
                    onTap: () => _showCurrencyPicker(context, profile),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
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

              // Budget Alerts Toggle (Persisted)
              SettingsItemTile(
                icon: Iconsax.notification,
                title: AppStrings.budgetAlerts,
                subtitle: AppStrings.budgetAlertsSub,
                trailing: Switch(
                  value: _budgetAlertsEnabled,
                  activeTrackColor: AppColors.emerald,
                  onChanged: _toggleBudgetAlerts,
                ),
              ),
              const SizedBox(height: 20),

              // Data & Privacy Management Section
              _buildSectionTitle(AppStrings.dataPrivacyManagement, context),
              const SizedBox(height: 10),

              // App Lock / Biometrics Toggle
              BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, profileState) {
                  final isLockEnabled = (profileState is ProfileLoaded)
                      ? profileState.profile.biometricEnabled
                      : _biometricPrefEnabled;
                  return SettingsItemTile(
                    icon: Iconsax.finger_scan,
                    title: AppStrings.fingerprint,
                    subtitle: AppStrings.fingerprintSub,
                    trailing: Switch(
                      value: isLockEnabled,
                      activeTrackColor: AppColors.emerald,
                      onChanged: _toggleBiometricLock,
                    ),
                  );
                },
              ),

              // Real CSV / JSON Export
              BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, profileState) {
                  final profile = profileState is ProfileLoaded
                      ? profileState.profile
                      : null;
                  return SettingsItemTile(
                    icon: Iconsax.document_text,
                    title: AppStrings.exportAllPdf,
                    subtitle: AppStrings.exportAllPdfSub,
                    trailing: Icon(
                      Iconsax.document_download,
                      color: context.appTextSecondary,
                      size: 20,
                    ),
                    onTap: () => _openExportReportSheet(context, profile),
                  );
                },
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

              SettingsItemTile(
                icon: Iconsax.info_circle,
                title: AppStrings.aboutApp,
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
                onTap: () => AppHelpers.showLogoutDialog(
                  context,
                  onConfirm: () {
                    context.read<AuthBloc>().add(LogoutAuthEvent());
                    context.go('/login');
                  },
                ),
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
                        : AppColors.mintContainer.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Iconsax.security_safe,
                      color: AppColors.emerald,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'خصوصية أولاً وبياناتك في أمان',
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
                      'حِسبَتك • ${AppStrings.appVersion} (Offline-First)',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.appTextMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'جميع الحقوق محفوظة لـ MsmDev © 2026',
                      style: TextStyle(
                        fontSize: 10,
                        color: context.appTextMuted,
                        fontWeight: FontWeight.bold,
                      ),
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
            color: context.appTextPrimary,
          ),
        ),
      ],
    );
  }
}
