import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hisbatak_app/presentation/widgets/custom_text_form_field_card.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/user_profile.dart';
import '../../bloc/profile/profile_bloc.dart';

/// [ProfileSetupScreen] implements local workspace setup matching Stitch Screen 6.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  String _selectedCurrency = 'YER';
  bool _biometricEnabled = true;

  final List<Map<String, String>> _currencies = [
    {'code': 'YER', 'symbol': 'ر.ي', 'name': AppStrings.currencyYER},
    {'code': 'SAR', 'symbol': 'ر.س', 'name': AppStrings.currencySAR},
    {'code': 'USD', 'symbol': r'$', 'name': AppStrings.currencyUSD},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _onSaveAndStart() {
    final currencyInfo = _currencies.firstWhere(
      (c) => c['code'] == _selectedCurrency,
      orElse: () => _currencies.first,
    );

    // This screen has no budget field yet, so a new user starts from a
    // default monthly budget with nothing spent.
    const monthlyBudget = 20000.0;

    final profile = UserProfile(
      id: 'user_me',
      fullName: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : AppStrings.defaultUserName,
      email: AppStrings.defaultUserEmail,
      currencyCode: _selectedCurrency,
      currencySymbol: currencyInfo['symbol']!,
      monthlyBudgetLimit: monthlyBudget,
      currentAvailable: monthlyBudget,
      biometricEnabled: _biometricEnabled,
      isDarkMode: false,
      isConfigured: true,
    );

    context.read<ProfileBloc>().add(SaveProfileEvent(profile));
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.emerald.withValues(alpha: 0.2)
                      : AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppStrings.stepOne,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.mintContainer : AppColors.emerald,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                AppStrings.setupWorkspaceTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Text(
                AppStrings.setupWorkspaceSubtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: context.appTextSecondary,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Avatar Container
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.person,
                                size: 48, color: AppColors.textSecondary),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      AppStrings.localAvatar,
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Card 1: Full Name
              CustomTextFormFieldCard(
                  controller: _nameController,
                  label: AppStrings.fullNameLabel,
                  icon: Icons.person_outline),
              const SizedBox(height: 10),

              CustomTextFormFieldCard(
                  controller: _phoneNumberController,
                  label: AppStrings.phoneNumberLabel,
                  icon: Icons.phone),

              const SizedBox(height: 14),

              // Card 2: Currency Selection
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
                          color: context.appTextPrimary),
                    ),
                    const SizedBox(height: 8),

                    // Dropdown Display
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.6),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCurrency,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary,
                          ),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 3,
                          selectedItemBuilder: (BuildContext context) {
                            return _currencies.map<Widget>((currency) {
                              return Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.mintFixed,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      currency['code']!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF005236),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      currency['name']!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList();
                          },
                          items: _currencies.map((currency) {
                            final isCurrent =
                                currency['code'] == _selectedCurrency;
                            return DropdownMenuItem<String>(
                              value: currency['code'],
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? AppColors.mintFixed
                                          : AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      currency['code']!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isCurrent
                                            ? const Color(0xFF005236)
                                            : AppColors.textSecondary,
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
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  if (isCurrent)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.emerald,
                                      size: 18,
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedCurrency = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Common Chips
                    Row(
                      children: [
                        const Text(
                          'خيارات شائعة:',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            children: _currencies.map((c) {
                              final isSelected = c['code'] == _selectedCurrency;
                              if (c['code'] == 'USD') {
                                return const SizedBox.shrink();
                              }
                              return GestureDetector(
                                onTap: () => setState(
                                    () => _selectedCurrency = c['code']!),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${c['code']} (${c['symbol']})',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
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

              // Card 3: Biometric / Face ID
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.appCardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.appBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.appSurfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.fingerprint_rounded,
                          color: context.appTextPrimary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.biometricProtection,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: context.appTextPrimary),
                          ),
                          SizedBox(height: 2),
                          Text(
                            AppStrings.biometricSubtitle,
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _biometricEnabled,
                      activeTrackColor: AppColors.emerald,
                      onChanged: (val) =>
                          setState(() => _biometricEnabled = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Start Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _onSaveAndStart,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppStrings.startNow,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 21),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // No Account Needed Footer
              const Center(
                child: Text(
                  AppStrings.noAccountNeeded,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
