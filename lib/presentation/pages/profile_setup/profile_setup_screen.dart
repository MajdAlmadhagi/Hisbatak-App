import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hisbatak_app/presentation/widgets/custom_text_form_field_card.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/security/app_lock_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/user_profile.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/budget/budget_bloc.dart';
import '../../bloc/groups/groups_bloc.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/theme/theme_cubit.dart';

/// [ProfileSetupScreen] configures user identity, currency, monthly budget,
/// optional normalized phone, avatar color/initials, and optional quick PIN lock.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _budgetController =
      TextEditingController(text: '20000');
  final TextEditingController _pinController = TextEditingController();

  String _selectedCurrency = 'YER';
  bool _enablePinLock = false;
  int _selectedAvatarColorIndex = 0;

  static const List<Color> _avatarPalette = [
    AppColors.brandNavy,
    AppColors.emerald,
    Color(0xFF0284C7),
    Color(0xFF7C3AED),
    Color(0xFFEA580C),
  ];

  final List<Map<String, String>> _currencies = [
    {'code': 'YER', 'symbol': 'ر.ي', 'name': AppStrings.currencyYER},
    {'code': 'SAR', 'symbol': 'ر.س', 'name': AppStrings.currencySAR},
    {'code': 'USD', 'symbol': r'$', 'name': AppStrings.currencyUSD},
  ];

  @override
  void initState() {
    super.initState();
    _prefillFromState();
  }

  void _prefillFromState() {
    try {
      final profileState = context.read<ProfileBloc>().state;
      if (profileState is ProfileLoaded) {
        final p = profileState.profile;
        if (p.fullName.isNotEmpty) _nameController.text = p.fullName;
        if (p.phoneE164 != null && p.phoneE164!.isNotEmpty) {
          _phoneNumberController.text = p.phoneE164!;
        }
        if (p.monthlyBudgetLimit > 0) {
          _budgetController.text = p.monthlyBudgetLimit.toStringAsFixed(0);
        }
        if (_currencies.any((c) => c['code'] == p.currencyCode)) {
          _selectedCurrency = p.currencyCode;
        }
      }
      final authState = context.read<AuthBloc>().state;
      if (authState.session != null) {
        final sName = authState.session!.name.trim();
        if (sName.isNotEmpty &&
            sName != 'مستخدم حسبتك' &&
            sName != 'مستخدم محلي' &&
            sName != 'مستخدم سحابي') {
          _nameController.text = sName;
        }
      }
      if (_phoneNumberController.text.isEmpty &&
          authState.pendingPhoneE164 != null) {
        _phoneNumberController.text = authState.pendingPhoneE164!;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneNumberController.dispose();
    _budgetController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  String _computeInitials(String rawName) {
    final trimmed = rawName.trim();
    if (trimmed.isEmpty) return 'ح';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts[1].characters.first}'
        .toUpperCase();
  }

  Future<void> _onSaveAndStart() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final phoneError = Validators.validatePhone(_phoneNumberController.text);
    if (phoneError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(phoneError),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    if (_enablePinLock) {
      final pinError = Validators.validatePin(_pinController.text);
      if (pinError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pinError),
            backgroundColor: AppColors.expense,
          ),
        );
        return;
      }
      if (sl.isRegistered<IAppLockService>()) {
        await sl<IAppLockService>().setPin(_pinController.text.trim());
      }
    }

    if (!mounted) return;
    final currencyInfo = _currencies.firstWhere(
      (c) => c['code'] == _selectedCurrency,
      orElse: () => _currencies.first,
    );

    final parsedBudget =
        double.tryParse(Validators.normalizeDigits(_budgetController.text.trim()));
    final monthlyBudget =
        (parsedBudget != null && parsedBudget > 0) ? parsedBudget : 20000.0;

    final profileState = context.read<ProfileBloc>().state;
    final existingId = profileState is ProfileLoaded &&
            profileState.profile.id.isNotEmpty &&
            profileState.profile.id != 'user_me'
        ? profileState.profile.id
        : IdGenerator.uuidV4();

    final isDarkNow = context.isDarkMode;
    final profile = UserProfile(
      id: existingId,
      fullName: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : AppStrings.defaultUserName,
      email: AppStrings.defaultUserEmail,
      phoneE164: Validators.tryNormalizePhoneE164(_phoneNumberController.text),
      currencyCode: _selectedCurrency,
      currencySymbol: currencyInfo['symbol']!,
      monthlyBudgetLimit: monthlyBudget,
      currentAvailable: monthlyBudget,
      biometricEnabled: _enablePinLock,
      isDarkMode: isDarkNow,
      isConfigured: true,
    );

    await context.read<ProfileBloc>().saveProfileUseCase(profile);
    if (!mounted) return;
    context.read<ProfileBloc>().add(LoadProfileEvent());
    try {
      context.read<BudgetBloc>().add(LoadBudgetDashboardEvent());
    } catch (_) {}
    try {
      context.read<GroupsBloc>().add(LoadGroupsEvent());
    } catch (_) {}
    try {
      context.read<ThemeCubit>().setDarkMode(isDarkNow);
    } catch (_) {}
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final selectedAvatarColor = _avatarPalette[_selectedAvatarColorIndex];

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.emerald.withValues(alpha: 0.25)
                        : AppColors.mintSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppStrings.stepOne,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.mintContainer : AppColors.emerald,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.setupWorkspaceTitle,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.setupWorkspaceSubtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.appTextSecondary,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),

                // Interactive Initials & Color Avatar Picker
                Center(
                  child: Column(
                    children: [
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _nameController,
                        builder: (context, value, _) {
                          final initials = _computeInitials(value.text);
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: selectedAvatarColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: selectedAvatarColor.withValues(
                                    alpha: 0.28,
                                  ),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_avatarPalette.length, (idx) {
                          final swatch = _avatarPalette[idx];
                          final isSelected = idx == _selectedAvatarColorIndex;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedAvatarColorIndex = idx),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              width: isSelected ? 26 : 22,
                              height: isSelected ? 26 : 22,
                              decoration: BoxDecoration(
                                color: swatch,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? context.appTextPrimary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                CustomTextFormFieldCard(
                  controller: _nameController,
                  label: AppStrings.fullNameLabel,
                  icon: Iconsax.user,
                ),
                const SizedBox(height: 10),

                CustomTextFormFieldCard(
                  controller: _phoneNumberController,
                  label: '${AppStrings.phoneNumberLabel} (اختياري للمزامنة)',
                  icon: Iconsax.call,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),

                CustomTextFormFieldCard(
                  controller: _budgetController,
                  label: 'حد الميزانية الشهرية (${currencySymbolPreview()})',
                  icon: Iconsax.wallet_money,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),

                // Currency Selection
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.appCardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.appBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.defaultCurrencyLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: context.appTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              context.appSurfaceVariant.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: context.appBorder.withValues(alpha: 0.6),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCurrency,
                            isExpanded: true,
                            icon: Icon(
                              Iconsax.arrow_down_1,
                              color: context.appTextSecondary,
                            ),
                            dropdownColor: context.appCardBackground,
                            borderRadius: BorderRadius.circular(16),
                            elevation: 3,
                            items: _currencies.map((currency) {
                              final isCurrent =
                                  currency['code'] == _selectedCurrency;
                              return DropdownMenuItem<String>(
                                value: currency['code'],
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isCurrent
                                            ? AppColors.mintFixed
                                            : context.appSurfaceVariant,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        currency['code']!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isCurrent
                                              ? const Color(0xFF005236)
                                              : context.appTextSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        currency['name']!,
                                        style: TextStyle(
                                          fontWeight: isCurrent
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: context.appTextPrimary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() => _selectedCurrency = newValue);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'خيارات شائعة:',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.appTextMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _currencies.map((c) {
                                final isSelected =
                                    c['code'] == _selectedCurrency;
                                return GestureDetector(
                                  onTap: () => setState(
                                    () => _selectedCurrency = c['code']!,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (isDark
                                              ? AppColors.emerald
                                              : AppColors.primary)
                                          : context.appSurfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${c['code']} (${c['symbol']})',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : context.appTextPrimary,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Optional Quick PIN App Lock Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.appCardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.appBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.appSurfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Iconsax.lock_1,
                              color: context.appTextPrimary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'قفل التطبيق برمز PIN',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: context.appTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'رمز من 4 أرقام لحماية محفظتك على هذا الجهاز',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: context.appTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _enablePinLock,
                            activeTrackColor: AppColors.emerald,
                            onChanged: (val) =>
                                setState(() => _enablePinLock = val),
                          ),
                        ],
                      ),
                      if (_enablePinLock) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 4,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(color: context.appTextPrimary),
                          decoration: InputDecoration(
                            labelText: 'أدخل رمز PIN من 4 أرقام',
                            counterText: '',
                            filled: true,
                            fillColor: context.appSurfaceVariant,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.appBorder),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _onSaveAndStart,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.startNow,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Iconsax.arrow_left_2, size: 21),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String currencySymbolPreview() {
    return _currencies.firstWhere(
      (c) => c['code'] == _selectedCurrency,
      orElse: () => _currencies.first,
    )['symbol']!;
  }
}
