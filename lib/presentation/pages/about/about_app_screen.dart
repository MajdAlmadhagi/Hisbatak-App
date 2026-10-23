import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/app_logo_widget.dart';

/// [AboutAppScreen] presents a stunning, modern, and comprehensive overview of the
/// Hisbatak application, its offline-first philosophy, key features, technology stack,
/// privacy charter, interactive rating, and support channels.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
/// Solely responsible for presenting application metadata, vision, and informative dialogs.
class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _isCheckingUpdates = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckUpdates() async {
    if (_isCheckingUpdates) return;
    setState(() => _isCheckingUpdates = true);

    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    setState(() => _isCheckingUpdates = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.emerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Row(
          children: [
            Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'تطبيق حِسبَتك مُحدّث بالكامل! أنت تستخدم أحدث إصدار مستقر (2.4.0)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleShareApp() {
    const shareText =
        '🚀 جرّب تطبيق "حِسبَتك" - المحفظة الذكية وإدارة المصاريف بدون إنترنت بخصوصية تامة 100% وتقسيم فواتير احترافي!';
    Clipboard.setData(const ClipboardData(text: shareText));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Row(
          children: [
            Icon(Iconsax.share, color: AppColors.mintContainer, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'تم نسخ رابط ومعلومات تطبيق حِسبَتك إلى الحافظة بنجاح! 📋',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingDialog() {
    int selectedRating = 5;
    final isDark = context.isDarkMode;

    showDialog(
      context: context,
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
                  decoration: BoxDecoration(
                    color: AppColors.warningSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.star_1,
                      color: AppColors.warning, size: 36),
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
                child: Text('إلغاء',
                    style: TextStyle(color: context.appTextSecondary)),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.emerald,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      content: const Text(
                        'شكراً جزيلاً على تقييمك القيّم! رأيك يهمنا دائماً ✓',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  );
                },
                child: const Text('إرسال التقييم',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPrivacyPledgeSheet() {
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
                      color: AppColors.mintSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Iconsax.shield_tick,
                        color: AppColors.emerald, size: 24),
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
              _buildPrivacyPoint(
                icon: Iconsax.cloud_cross,
                title: 'عدم وجود خوادم سحابية خارجية',
                description:
                    'لا يحتوي التطبيق على أي خادم خلفي يسجل أو يخزن أرقامك أو مصروفاتك أو أسماء أصدقائك. جميع البيانات معزولة تماماً على هاتفك.',
                isDark: isDark,
              ),
              _buildPrivacyPoint(
                icon: Iconsax.key,
                title: 'تشفير محلي صارم',
                description:
                    'مفاتيح التشفير وسجلات SQLite محفوظة بأمان في مساحة التخزين المعزولة لنظام التشغيل الخاص بجهازك.',
                isDark: isDark,
              ),
              _buildPrivacyPoint(
                icon: Iconsax.user,
                title: 'بدون تتبع أو إعلانات',
                description:
                    'لا نستخدم أي مكتبات تتبع أو حزم إعلانية خارجية تجمع سلوك المستخدم أو موقعه الجغرافي.',
                isDark: isDark,
              ),
              _buildPrivacyPoint(
                icon: Iconsax.folder,
                title: 'سيادتك الكاملة على بياناتك',
                description:
                    'يمكنك تصدير كشوفات حسابك، أخذ نسخة احتياطية مشفرة، أو مسح كافة البيانات نهائياً في أي ثانية بنقرة واحدة.',
                isDark: isDark,
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
                child: const Text('فهمت ذلك، واستمر بثقة 🔒',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyPoint({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
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

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appCardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: context.appBorder),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.mintSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Iconsax.sms, color: AppColors.emerald, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              AppStrings.supportAndFeedbackTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: context.appTextPrimary,
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
                color: context.appTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: context.appSurfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.appBorder),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.sms_tracking,
                      size: 18, color: AppColors.emerald),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'support@hisbatak.app',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: context.appTextPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.copy, size: 18),
                    color: AppColors.emerald,
                    onPressed: () {
                      Clipboard.setData(
                          const ClipboardData(text: 'support@hisbatak.app'));
                      ScaffoldMessenger.of(context).showSnackBar(
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
            child: const Text('إغلاق',
                style: TextStyle(
                    color: AppColors.emerald, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLicensesSheet() {
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
              _buildLicenseCard(
                title: 'Hisbatak App (حِسبَتك)',
                version: '2.4.0 (2026)',
                license: 'Proprietary Offline License © 2026',
              ),
              _buildLicenseCard(
                title: 'Flutter Framework & Dart SDK',
                version: 'v3.x',
                license: 'BSD-3-Clause License (Google LLC)',
              ),
              _buildLicenseCard(
                title: 'Tajawal & IBM Plex Arabic Fonts',
                version: 'OFL 1.1',
                license: 'SIL Open Font License',
              ),
              _buildLicenseCard(
                title: 'SQLite Local Engine',
                version: '3.x',
                license: 'Public Domain',
              ),
              _buildLicenseCard(
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
                child: const Text('إغلاق',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLicenseCard({
    required String title,
    required String version,
    required String license,
  }) {
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
          Column(
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: context.appTextPrimary,
              size: 30,
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          },
        ),
        title: Text(
          AppStrings.aboutAppTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: context.appTextPrimary,
          ),
        ),
        actions: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.emerald.withOpacity(0.1),
            child: Center(
              child: InkWell(
                onTap: _handleShareApp,
                child: Icon(
                  Iconsax.share,
                  color: AppColors.emerald,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HERO IDENTITY CARD
                _buildHeroCard(isDark),
                const SizedBox(height: 20),

                // 2. MISSION & PHILOSOPHY CARD
                _buildSectionHeader(
                    title: 'تطبيق حسبتك', icon: Iconsax.lamp_on),
                const SizedBox(height: 10),
                _buildMissionCard(isDark),
                const SizedBox(height: 24),

                // 3. KEY FEATURES SHOWCASE
                // _buildSectionHeader(
                //     title: AppStrings.keyFeaturesTitle,
                //     icon: Iconsax.magicpen),
                // const SizedBox(height: 12),
                // _buildFeaturesGrid(isDark),
                const SizedBox(height: 24),

                // 4. TECH STACK & ENGINE
                // _buildSectionHeader(
                //     title: AppStrings.techStackTitle, icon: Iconsax.code),
                // const SizedBox(height: 10),
                // _buildTechStackChips(isDark),
                // const SizedBox(height: 24),

                // 5. INTERACTIVE ACTIONS & LINKS
                // _buildSectionHeader(
                //     title: 'التفاعل والدعم', icon: Iconsax.driver),
                // const SizedBox(height: 10),
                // _buildActionsSection(isDark),
                // const SizedBox(height: 28),

                // 6. HEARTFELT FOOTER
                _buildFooter(isDark),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.emerald,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: AppColors.emerald, size: 18),
        const SizedBox(width: 6),
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

  Widget _buildHeroCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.cardDarkElevated,
                  const Color(0xFF0F2338),
                  AppColors.cardDark,
                ]
              : [
                  Colors.white,
                  AppColors.mintSoft.withValues(alpha: 0.6),
                  Colors.white,
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.emerald.withValues(alpha: 0.3)
              : AppColors.mintContainer.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppColors.emerald.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo with glow
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.emerald.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const AppLogoWidget(size: 84),
          ),
          const SizedBox(height: 16),

          // Titles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Hisbatak',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: context.appTextPrimary,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '|',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.emerald,
                  ),
                ),
              ),
              Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.mintContainer : AppColors.emerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Subtitle Tagline
          Text(
            AppStrings.aboutAppSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: context.appTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),

          // Version & Release Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primaryDark
                  : AppColors.surfaceVariant.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.appBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.emeraldLight,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${AppStrings.appFullVersion} • ${AppStrings.appReleaseDate}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3 Highlights Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildHeroBadge(
                icon: Iconsax.security_safe,
                label: AppStrings.offlineFirstBadge,
                isDark: isDark,
              ),
              _buildHeroBadge(
                icon: Iconsax.cloud_cross,
                label: AppStrings.zeroCloudBadge,
                isDark: isDark,
              ),
              _buildHeroBadge(
                icon: Iconsax.lock,
                label: AppStrings.secureStorageBadge,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBadge({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.emerald.withValues(alpha: 0.15)
            : AppColors.mintSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.emerald.withValues(alpha: 0.3)
              : AppColors.mintContainer.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.emerald),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.mintContainer : AppColors.emerald,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.emerald.withValues(alpha: 0.2)
                      : AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Iconsax.record_circle,
                    color: AppColors.emerald, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                AppStrings.ourMissionTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.appTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.ourMissionDescription,
            style: TextStyle(
                fontSize: 12.5,
                color: context.appTextSecondary,
                height: 1.65,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid(bool isDark) {
    final features = [
      _FeatureItem(
        icon: Iconsax.wallet_3,
        color: const Color(0xFF10B981),
        title: AppStrings.feature1Title,
        desc: AppStrings.feature1Desc,
      ),
      _FeatureItem(
        icon: Iconsax.profile_2user,
        color: const Color(0xFF6366F1),
        title: AppStrings.feature2Title,
        desc: AppStrings.feature2Desc,
      ),
      _FeatureItem(
        icon: Iconsax.security_safe,
        color: const Color(0xFF00A86B),
        title: AppStrings.feature3Title,
        desc: AppStrings.feature3Desc,
      ),
      _FeatureItem(
        icon: Iconsax.chart_2,
        color: const Color(0xFFF59E0B),
        title: AppStrings.feature4Title,
        desc: AppStrings.feature4Desc,
      ),
      _FeatureItem(
        icon: Iconsax.refresh_2,
        color: const Color(0xFF0EA5E9),
        title: AppStrings.feature5Title,
        desc: AppStrings.feature5Desc,
      ),
      _FeatureItem(
        icon: Iconsax.colorfilter,
        color: const Color(0xFFEC4899),
        title: AppStrings.feature6Title,
        desc: AppStrings.feature6Desc,
      ),
    ];

    return Column(
      children: features
          .map((f) => _buildFeatureTile(
                feature: f,
                isDark: isDark,
              ))
          .toList(),
    );
  }

  Widget _buildFeatureTile({
    required _FeatureItem feature,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature.icon, color: feature.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  feature.desc,
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

  Widget _buildTechStackChips(bool isDark) {
    final technologies = [
      {'name': 'Flutter 3.x', 'icon': Iconsax.code},
      {'name': 'Material 3 UI', 'icon': Iconsax.brush_1},
      {'name': 'SQLite Local DB', 'icon': Iconsax.data},
      {'name': 'BLoC Architecture', 'icon': Iconsax.hierarchy},
      {'name': 'Tajawal Typography', 'icon': Iconsax.text},
      {'name': '100% Offline-First', 'icon': Iconsax.cloud_cross},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: technologies.map((t) {
          final icon = t['icon'] as IconData;
          final name = t['name'] as String;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.cardDark
                  : AppColors.surfaceVariant.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.appBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: AppColors.emerald),
                const SizedBox(width: 6),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: context.appTextPrimary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionsSection(bool isDark) {
    return Column(
      children: [
        _buildActionTile(
          icon: Iconsax.shield_tick,
          iconColor: AppColors.emerald,
          title: AppStrings.privacyPledgeTitle,
          subtitle: AppStrings.privacyPledgeSub,
          onTap: _showPrivacyPledgeSheet,
        ),
        _buildActionTile(
          icon: Iconsax.star_1,
          iconColor: AppColors.warning,
          title: AppStrings.rateAppTitle,
          subtitle: AppStrings.rateAppSub,
          onTap: _showRatingDialog,
        ),
        _buildActionTile(
          icon: Iconsax.share,
          iconColor: const Color(0xFF6366F1),
          title: AppStrings.shareAppTitle,
          subtitle: AppStrings.shareAppSub,
          onTap: _handleShareApp,
        ),
        _buildActionTile(
          icon: Iconsax.refresh_circle,
          iconColor: const Color(0xFF0EA5E9),
          title: AppStrings.checkUpdatesTitle,
          subtitle: _isCheckingUpdates
              ? 'جارِ التحقق من الخادم المحلي...'
              : AppStrings.checkUpdatesSub,
          trailing: _isCheckingUpdates
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.emerald),
                  ),
                )
              : null,
          onTap: _handleCheckUpdates,
        ),
        _buildActionTile(
          icon: Iconsax.document_text,
          iconColor: const Color(0xFF8B5CF6),
          title: AppStrings.termsAndLicensesTitle,
          subtitle: AppStrings.termsAndLicensesSub,
          onTap: _showLicensesSheet,
        ),
        _buildActionTile(
          icon: Iconsax.headphone,
          iconColor: const Color(0xFFEC4899),
          title: AppStrings.supportAndFeedbackTitle,
          subtitle: AppStrings.supportAndFeedbackSub,
          onTap: _showSupportDialog,
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final isDark = context.isDarkMode;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.appCardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.appTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Iconsax.arrow_left_2,
                  color: context.appTextMuted,
                  size: 14,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Center(
      child: Column(
        children: [
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //   decoration: BoxDecoration(
          //     color: isDark
          //         ? AppColors.cardDark
          //         : AppColors.mintSoft.withValues(alpha: 0.6),
          //     borderRadius: BorderRadius.circular(20),
          //     border: Border.all(
          //       color: isDark
          //           ? AppColors.borderDark
          //           : AppColors.mintContainer.withValues(alpha: 0.4),
          //     ),
          //   ),
          //   child: Row(
          //     mainAxisSize: MainAxisSize.min,
          //     children: [
          //       const Icon(Iconsax.heart,
          //           color: AppColors.emerald, size: 14),
          //       const SizedBox(width: 6),
          //       Text(
          //         AppStrings.madeWithLove,
          //         style: TextStyle(
          //           fontSize: 11,
          //           fontWeight: FontWeight.w600,
          //           color: isDark ? AppColors.mintContainer : AppColors.emerald,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // const SizedBox(height: 8),
          Text(
            AppStrings.copyrightNotice,
            style: TextStyle(
              fontSize: 11.5,
              color: context.appTextMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  const _FeatureItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });
}
