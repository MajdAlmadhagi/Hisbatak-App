import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../theme/app_theme.dart';

class AppHelpers {
  /// Function to return user greeting message based on time of day and Friday blessings
  static String greetingMessage() {
    final DateTime currentDateTime = DateTime.now();
    final int currentWeekDay = currentDateTime.weekday;
    final int currentHour = currentDateTime.hour;
    debugPrint('=============current hour :$currentHour===========');

    if (currentWeekDay == DateTime.friday) {
      return 'جمعة مباركة';
    }
    //if its not friday
    else {
      //On Morning
      if (currentHour >= 0 && currentHour < 12) {
        return 'صباح الخير 🌞';
      }
      //On Evening
      return 'مساء الخير';
    }
  }

  /// Displays a modern, beautifully styled confirmation dialog for logging out.
  ///
  /// Can be passed a custom [onConfirm] callback. If [onConfirm] is omitted,
  /// it gracefully exits the application via [SystemNavigator.pop].
  static Future<bool?> showLogoutDialog(
    BuildContext context, {
    VoidCallback? onConfirm,
    String? title,
    String? message,
    String? confirmText,
    String? cancelText,
  }) {
    final isDark = context.isDarkMode;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appCardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: context.appBorder),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        title: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF3B1219) : const Color(0xFFFFF1F2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF7F1D1D)
                      : const Color(0xFFFECDD3),
                ),
              ),
              child: const Icon(
                Iconsax.logout,
                color: AppColors.expense,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title ?? AppStrings.logoutConfirmTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.appTextPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          message ?? AppStrings.logoutConfirmMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            color: context.appTextSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: context.appBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(
                    cancelText ?? AppStrings.cancel,
                    style: TextStyle(
                      color: context.appTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.expense,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop(true);
                    if (onConfirm != null) {
                      onConfirm();
                    } else {
                      SystemNavigator.pop();
                    }
                  },
                  child: Text(
                    confirmText ?? AppStrings.logout,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
