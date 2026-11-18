import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/about_action_tiles.dart';
import 'widgets/about_dialogs_sheets.dart';
import 'widgets/about_hero_card.dart';

/// Presents an overview of the Hisbatak application, its offline-first
/// architecture, key features, privacy pledge, licenses, and support channels.
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
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

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
                'تطبيق حِسبَتك مُحدّث بالكامل! أنت تستخدم أحدث إصدار (${AppStrings.appFullVersion})',
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
        '🚀 جرّب تطبيق "حِسبَتك" - المحفظة الذكية وإدارة المصاريف بدون إنترنت مع مزامنة اختيارية وتقسيم فواتير احترافي!';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            color: context.appTextPrimary,
            size: 30,
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
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: InkWell(
              onTap: _handleShareApp,
              customBorder: const CircleBorder(),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.emerald.withValues(alpha: 0.1),
                child: const Icon(
                  Iconsax.share,
                  color: AppColors.emerald,
                  size: 19,
                ),
              ),
            ),
          ),
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
                const AboutHeroCard(),
                const SizedBox(height: 20),
                const AboutSectionHeader(
                  title: 'تطبيق حسبتك',
                  icon: Iconsax.lamp_on,
                ),
                const SizedBox(height: 10),
                const AboutMissionCard(),
                const SizedBox(height: 24),
                const AboutSectionHeader(
                  title: AppStrings.keyFeaturesTitle,
                  icon: Iconsax.magicpen,
                ),
                const SizedBox(height: 12),
                const AboutFeaturesSection(),
                const SizedBox(height: 24),
                const AboutSectionHeader(
                  title: 'التفاعل والدعم',
                  icon: Iconsax.driver,
                ),
                const SizedBox(height: 10),
                AboutActionsSection(
                  isCheckingUpdates: _isCheckingUpdates,
                  onPrivacyPledge: () =>
                      AboutDialogs.showPrivacyPledgeSheet(context),
                  onRateApp: () => AboutDialogs.showRatingDialog(context),
                  onShareApp: _handleShareApp,
                  onCheckUpdates: _handleCheckUpdates,
                  onShowLicenses: () => AboutDialogs.showLicensesSheet(context),
                  onShowSupport: () => AboutDialogs.showSupportDialog(context),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Text(
                    AppStrings.copyrightNotice,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: context.appTextMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
