import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';

/// Informative dialogs and bottom sheets launched from [AboutAppScreen].
class AboutDialogs {
  AboutDialogs._();

  static void showRatingDialog(BuildContext parentContext) {
    int selectedRating = 5;

    showDialog(
      context: parentContext,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: context.appCardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: context.appBorder),
            ),
            title: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.warningSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.star_1,
                    color: AppColors.warning,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.rateAppTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ما مدى رضاك عن تجربة إدارة مصاريفك وتقسيم الفواتير مع حِسبَتك؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.appTextSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return IconButton(
                      onPressed: () {
                        setDialogState(() => selectedRating = starIndex);
                      },
                      icon: Icon(
                        Iconsax.star_1,
                        color: starIndex <= selectedRating
                            ? AppColors.warning
                            : AppColors.warning.withValues(alpha: 0.3),
                        size: 32,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedRating == 5
                      ? 'ممتاز جداً! شكراً لدعمك 💚'
                      : selectedRating >= 4
                          ? 'رائع! نسعى دائماً للأفضل 🌟'
                          : 'نعمل جاهدين لتحسين تجربتك 🛠️',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selectedRating >= 4
                        ? AppColors.emerald
                        : AppColors.warning,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'إلغاء',
                  style: TextStyle(color: context.appTextSecondary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.emerald,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      content: const Text(
                        'شكراً جزيلاً على تقييمك القيّم! رأيك يهمنا دائماً ✓',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  );
                },
                child: const Text(
                  'إرسال التقييم',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static void showPrivacyPledgeSheet(BuildContext context) {
    final isDark = context.isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appCardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: context.appBorder,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.emerald.withValues(alpha: 0.2)
                          : AppColors.mintSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Iconsax.shield_tick,
                      color: AppColors.emerald,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.privacyPledgeTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.appTextPrimary,
                          ),
                        ),
                        Text(
                          'ضمانات هندسة الـ Offline-First التامة',
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
              const SizedBox(height: 20),
              const _PrivacyPointCard(
                icon: Iconsax.cloud_cross,
                title: 'ملكية كاملة بدون فرض خوادم',
                description:
                    'تُحفظ جميع سجلاتك ومصاريفك وأرصدة مجموعاتك في قاعدة بيانات محلية على هاتفك أولاً، وتبقى المزامنة السحابية خياراً طوعياً عند تسجيلك برقم الهاتف.',
              ),
              const _PrivacyPointCard(
                icon: Iconsax.key,
                title: 'حماية محلية صارمة',
                description:
                    'مفاتيح الأمان ورمز القفل وسجلات SQLite محفوظة في مساحة التخزين المعزولة لنظام التشغيل على جهازك.',
              ),
              const _PrivacyPointCard(
                icon: Iconsax.user,
                title: 'بدون تتبع أو إعلانات',
                description:
                    'لا نستخدم أي مكتبات تتبع أو حزم إعلانية خارجية تجمع سلوك المستخدم أو موقعه الجغرافي.',
              ),
              const _PrivacyPointCard(
                icon: Iconsax.folder,
                title: 'سيادتك الكاملة على بياناتك',
                description:
                    'يمكنك تصدير كشوفات حسابك، أخذ نسخة احتياطية، أو مسح كافة البيانات نهائياً في أي وقت بنقرة واحدة.',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'فهمت ذلك، واستمر بثقة 🔒',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  static void showSupportDialog(BuildContext parentContext) {
    final isDark = parentContext.isDarkMode;

    showDialog(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        backgroundColor: parentContext.appCardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: parentContext.appBorder),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.emerald.withValues(alpha: 0.2)
                    : AppColors.mintSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Iconsax.sms,
                color: AppColors.emerald,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppStrings.supportAndFeedbackTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: parentContext.appTextPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'نسعد دائماً باقتراحاتكم واستفساراتكم لتطوير تجربة حِسبَتك المالية:',
              style: TextStyle(
                fontSize: 12,
                color: parentContext.appTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: parentContext.appSurfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: parentContext.appBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.sms_tracking,
                    size: 18,
                    color: AppColors.emerald,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'support@hisbatak.app',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: parentContext.appTextPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.copy, size: 18),
                    color: AppColors.emerald,
                    onPressed: () {
                      Clipboard.setData(
                        const ClipboardData(text: 'support@hisbatak.app'),
                      );
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        const SnackBar(
                          content: Text('تم نسخ البريد الإلكتروني! 📧'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'إغلاق',
              style: TextStyle(
                color: AppColors.emerald,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void showLicensesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appCardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.appBorder,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                AppStrings.termsAndLicensesTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'تراخيص البرمجيات وحقوق الملكية الفكرية',
                style: TextStyle(
                  fontSize: 12,
                  color: context.appTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              const _LicenseCard(
                title: 'Hisbatak App (حِسبَتك)',
                version: '${AppStrings.appFullVersion} (2026)',
                license: 'Proprietary Offline-First License © 2026',
              ),
              const _LicenseCard(
                title: 'Flutter Framework & Dart SDK',
                version: 'v3.x',
                license: 'BSD-3-Clause License (Google LLC)',
              ),
              const _LicenseCard(
                title: 'Tajawal & IBM Plex Arabic Fonts',
                version: 'OFL 1.1',
                license: 'SIL Open Font License',
              ),
              const _LicenseCard(
                title: 'SQLite Local Engine',
                version: '3.x',
                license: 'Public Domain',
              ),
              const _LicenseCard(
                title: 'Flutter BLoC & Clean Architecture',
                version: 'MIT',
                license: 'MIT License (Felix Angelov)',
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'إغلاق',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyPointCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PrivacyPointCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.emerald.withValues(alpha: 0.2)
                  : AppColors.mintSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.emerald, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: context.appTextSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LicenseCard extends StatelessWidget {
  final String title;
  final String version;
  final String license;

  const _LicenseCard({
    required this.title,
    required this.version,
    required this.license,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appSurfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  license,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.appTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              version,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.emerald,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
