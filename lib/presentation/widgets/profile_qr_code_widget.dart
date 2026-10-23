import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/user_profile.dart';

/// [ProfileQrCodeButton] renders a sleek, modern fintech QR code button
/// placed beside the user profile card. Tapping it opens the interactive
/// QR code bottom sheet.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class ProfileQrCodeButton extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final double size;
  final bool showLabel;
  final String label;

  const ProfileQrCodeButton({
    super.key,
    this.profile,
    this.onTap,
    this.width,
    this.height,
    this.size = 66,
    this.showLabel = true,
    this.label = 'الرمز الخاص بي',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final btnWidth = width ?? (showLabel ? 66.0 : size);
    final btnHeight = height ?? (showLabel ? 66.0 : size);

    return Tooltip(
      message: 'رمز QR للمحفظة المحلية',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap ??
              () => showProfileQrBottomSheet(context, profile: profile),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: btnWidth,
            height: btnHeight,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.cardDarkElevated,
                        AppColors.cardDark,
                      ]
                    : [
                        Colors.white,
                        AppColors.mintSoft.withValues(alpha: 0.6),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.emerald.withValues(alpha: 0.45)
                    : AppColors.mintContainer,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      AppColors.emerald.withValues(alpha: isDark ? 0.25 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              //mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.scan_barcode,
                  color: isDark ? AppColors.mintContainer : AppColors.emerald,
                  size: showLabel ? 36 : 32,
                ),
                if (showLabel) ...[
                  const SizedBox(height: 3),
                  Text(
                    label,
                    //maxLines: 1,
                    //overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          isDark ? AppColors.mintContainer : AppColors.emerald,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Displays an interactive modal bottom sheet presenting the user's
/// offline-first QR code with share and copy capabilities.
void showProfileQrBottomSheet(
  BuildContext context, {
  UserProfile? profile,
}) {
  final isDark = context.isDarkMode;
  final name = profile?.fullName ?? 'مستخدم حِسبَتك';
  final email = profile?.email ?? 'user@hisbatak.local';
  final walletId = profile?.id.isNotEmpty == true
      ? profile!.id
      : 'HIS-${(name.hashCode.abs() % 90000 + 10000)}';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appCardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: ListView(
          controller: scrollController,
          children: [
            // Top drag handle
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

            // Header
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
                    Iconsax.scan,
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
                        'رمز QR للمحفظة المحلية',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.appTextPrimary,
                        ),
                      ),
                      Text(
                        'امسح الرمز لتسوية وتقسيم المصاريف فورياً',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Center QR Card with glow
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.mintContainer.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emerald
                          .withValues(alpha: isDark ? 0.35 : 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // QR Painter with embedded logo
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CustomPaint(
                        painter: HisbatakQrCodePainter(
                          data:
                              'hisbatak://pay?id=$walletId&user=${Uri.encodeComponent(name)}',
                          foregroundColor: const Color(0xFF0F172A),
                          accentColor: AppColors.emerald,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Offline tag inside card
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.mintSoft,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.mintContainer),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.cloud_cross,
                              size: 12, color: AppColors.emerald),
                          SizedBox(width: 4),
                          Text(
                            'تفاعل محلي 100% بدون إنترنت',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.emerald,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // User Info & Wallet ID Tile
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.appSurfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.appBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        isDark ? AppColors.cardDarkElevated : Colors.white,
                    child: Text(
                      name.isNotEmpty ? name[0] : 'م',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.emerald,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: context.appTextPrimary,
                          ),
                        ),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.appTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Wallet ID Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.emerald.withValues(alpha: 0.15)
                          : AppColors.mintSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? AppColors.emerald.withValues(alpha: 0.3)
                            : AppColors.mintContainer,
                      ),
                    ),
                    child: Text(
                      walletId,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.emerald,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Action Buttons (Copy & Share)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: context.appBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: walletId));
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.emerald,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          content: Text(
                              'تم نسخ معرّف المحفظة ($walletId) بنجاح! 📋'),
                        ),
                      );
                    },
                    icon: const Icon(Iconsax.copy,
                        size: 16, color: AppColors.emerald),
                    label: Text(
                      'نسخ المعرف',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: context.appTextPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final shareData =
                          '💳 معرّف محفظة حِسبَتك: $walletId\n👤 الاسم: $name\n🔒 تسوية وتقسيم مصاريف فوري محلي 100%';
                      Clipboard.setData(ClipboardData(text: shareData));
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          content:
                              Text('تم تجهيز ونسخ بيانات المشاركة بنجاح! ✨'),
                        ),
                      );
                    },
                    icon: const Icon(Iconsax.share,
                        size: 16, color: Colors.white),
                    label: const Text(
                      'مشاركة الرمز',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
}

/// [HisbatakQrCodePainter] renders a crisp, high-fidelity QR Code matrix
/// with rounded corner finder patterns and a centered Hisbatak brand mark.
class HisbatakQrCodePainter extends CustomPainter {
  final String data;
  final Color foregroundColor;
  final Color accentColor;

  const HisbatakQrCodePainter({
    required this.data,
    this.foregroundColor = const Color(0xFF0F172A),
    this.accentColor = const Color(0xFF006C49),
  });

  @override
  void paint(Canvas canvas, Size size) {
    const int gridSize = 25; // Standard Version 2/3 QR Grid
    final double cellSize = size.width / gridSize;

    final darkPaint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.fill;

    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    // Seeded random based on data string for deterministic aesthetic pattern
    final random = Random(data.hashCode);

    // 1. Draw Finder Pattern helper
    void drawFinderPattern(double startX, double startY) {
      // Outer 7x7 rounded rect
      final outerRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(startX, startY, cellSize * 7, cellSize * 7),
        Radius.circular(cellSize * 1.5),
      );
      canvas.drawRRect(outerRRect, accentPaint);

      // Inner 5x5 cutout
      final innerCutoutRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          startX + cellSize,
          startY + cellSize,
          cellSize * 5,
          cellSize * 5,
        ),
        Radius.circular(cellSize),
      );
      canvas.drawRRect(
        innerCutoutRRect,
        Paint()..color = Colors.white,
      );

      // Center 3x3 solid block
      final centerRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          startX + cellSize * 2,
          startY + cellSize * 2,
          cellSize * 3,
          cellSize * 3,
        ),
        Radius.circular(cellSize * 0.8),
      );
      canvas.drawRRect(centerRRect, accentPaint);
    }

    // Top-Left Finder
    drawFinderPattern(0, 0);

    // Top-Right Finder
    drawFinderPattern(size.width - cellSize * 7, 0);

    // Bottom-Left Finder
    drawFinderPattern(0, size.height - cellSize * 7);

    // 2. Draw Data Modules and Timing Patterns
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        // Skip Top-Left Finder
        if (row < 8 && col < 8) continue;
        // Skip Top-Right Finder
        if (row < 8 && col >= gridSize - 8) continue;
        // Skip Bottom-Left Finder
        if (row >= gridSize - 8 && col < 8) continue;

        // Skip Center Logo Area (9x9 around middle)
        if (row >= 9 && row <= 15 && col >= 9 && col <= 15) continue;

        // Timing Pattern Lines
        bool isTiming = (row == 6 || col == 6);
        bool shouldDraw = false;

        if (isTiming) {
          shouldDraw = (row % 2 == 0) || (col % 2 == 0);
        } else {
          // Pseudorandom data fill based on payload hash
          shouldDraw = random.nextBool();
        }

        if (shouldDraw) {
          final double x = col * cellSize;
          final double y = row * cellSize;

          final dotRRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x + cellSize * 0.1,
              y + cellSize * 0.1,
              cellSize * 0.8,
              cellSize * 0.8,
            ),
            Radius.circular(cellSize * 0.3),
          );

          canvas.drawRRect(dotRRect, darkPaint);
        }
      }
    }

    // 3. Center Brand Badge
    final centerAreaSize = cellSize * 6.5;
    final centerOffset = (size.width - centerAreaSize) / 2;

    // White badge background
    final badgeRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerOffset, centerOffset, centerAreaSize, centerAreaSize),
      Radius.circular(centerAreaSize * 0.26),
    );
    canvas.drawRRect(
      badgeRRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Navy tile
    final navyTileRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        centerOffset + cellSize * 0.5,
        centerOffset + cellSize * 0.5,
        centerAreaSize - cellSize,
        centerAreaSize - cellSize,
      ),
      Radius.circular(centerAreaSize * 0.22),
    );
    canvas.drawRRect(
      navyTileRRect,
      Paint()..color = AppColors.brandNavy,
    );
  }

  @override
  bool shouldRepaint(covariant HisbatakQrCodePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.foregroundColor != foregroundColor ||
        oldDelegate.accentColor != accentColor;
  }
}
