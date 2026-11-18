import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/security/app_lock_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/app_logo_widget.dart';

/// Offline-first quick PIN unlock screen shown on cold start when App Lock is enabled.
class AppLockScreen extends StatefulWidget {
  final IAppLockService? appLockService;
  final VoidCallback? onUnlocked;

  const AppLockScreen({
    super.key,
    this.appLockService,
    this.onUnlocked,
  });

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  static const int _pinLength = 4;
  String _enteredPin = '';
  String? _errorText;
  bool _isChecking = false;

  IAppLockService? get _service {
    if (widget.appLockService != null) return widget.appLockService;
    return sl.isRegistered<IAppLockService>() ? sl<IAppLockService>() : null;
  }

  void _onDigitTap(String digit) {
    if (_isChecking || _enteredPin.length >= _pinLength) return;
    setState(() {
      _enteredPin += digit;
      _errorText = null;
    });
    if (_enteredPin.length == _pinLength) {
      _verifyEnteredPin();
    }
  }

  void _onBackspace() {
    if (_isChecking || _enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorText = null;
    });
  }

  Future<void> _verifyEnteredPin() async {
    final service = _service;
    if (service == null) {
      _unlockSuccess();
      return;
    }

    final lockout = service.remainingLockout();
    if (lockout != null) {
      setState(() {
        _enteredPin = '';
        _errorText =
            'تم إيقاف المحاولات مؤقتاً لمدة ${lockout.inSeconds + 1} ثانية.';
      });
      return;
    }

    setState(() => _isChecking = true);
    final ok = await service.verifyPin(_enteredPin);
    if (!mounted) return;

    if (ok) {
      _unlockSuccess();
    } else {
      final postLockout = service.remainingLockout();
      setState(() {
        _isChecking = false;
        _enteredPin = '';
        _errorText = postLockout != null
            ? 'تجاوزت الحد المسموح. انتظر ${postLockout.inSeconds + 1} ثانية.'
            : 'رمز PIN غير صحيح، حاول مرة أخرى';
      });
    }
  }

  void _unlockSuccess() {
    if (widget.onUnlocked != null) {
      widget.onUnlocked!();
    } else if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppColors.emerald : AppColors.primary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.appBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                const Spacer(flex: 1),
                const AppLogoWidget(size: 68),
                const SizedBox(height: 18),
                Text(
                  'تطبيق حسبتك مقفل',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'أدخل رمز PIN المكون من 4 أرقام للوصول إلى محفظتك',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.appTextSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                // PIN indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pinLength, (index) {
                    final filled = index < _enteredPin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? primaryColor : Colors.transparent,
                        border: Border.all(
                          color: _errorText != null
                              ? AppColors.expense
                              : (filled ? primaryColor : context.appBorder),
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 24,
                  child: _errorText != null
                      ? Text(
                          _errorText!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.expense,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                const Spacer(flex: 1),
                _buildPinKeypad(context, primaryColor),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('نسيت رمز الدخول؟'),
                        content: const Text(
                          'حرصاً على خصوصيتك، رمز PIN محفوظ محلياً على جهازك فقط.\n\nيمكنك تسجيل الدخول عبر حسابك السحابي لاستعادة بياناتك المتزامنة.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('إلغاء'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              context.go('/login');
                            },
                            child: const Text('تسجيل الدخول السحابي'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Iconsax.shield_search, size: 18),
                  label: const Text('نسيت رمز الدخول؟'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinKeypad(BuildContext context, Color accentColor) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'back'],
    ];

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) {
                if (key.isEmpty) {
                  return const SizedBox(width: 72, height: 64);
                }
                if (key == 'back') {
                  return SizedBox(
                    width: 72,
                    height: 64,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(32),
                      onTap: _onBackspace,
                      child: Icon(
                        Icons.backspace_outlined,
                        color: context.appTextSecondary,
                        size: 24,
                      ),
                    ),
                  );
                }
                return SizedBox(
                  width: 72,
                  height: 64,
                  child: Material(
                    color: context.appCardBackground,
                    shape: CircleBorder(
                      side: BorderSide(color: context.appBorder),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _onDigitTap(key),
                      child: Center(
                        child: Text(
                          key,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: context.appTextPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
