import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/qr_matrix_generator.dart';
import '../../domain/entities/user_profile.dart';
import 'hisbatak_mark.dart';

/// [ProfileQrCodeButton] renders a sleek, modern fintech QR code button
/// placed beside the user profile card. Tapping it opens the interactive
/// QR code bottom sheet.
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
    final btnWidth = width ?? (showLabel ? 78.0 : size);
    final btnHeight = height ?? (showLabel ? 70.0 : size);

    return Tooltip(
      message: 'رمز QR للهوية والمشاركة',
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.scan_barcode,
                  color: isDark ? AppColors.mintContainer : AppColors.emerald,
                  size: showLabel ? 26 : 30,
                ),
                if (showLabel) ...[
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            isDark ? AppColors.mintContainer : AppColors.emerald,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
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

/// Displays an interactive modal bottom sheet presenting a real ISO/IEC 18004
/// scannable QR code carrying the user's `hisbatak://u/<uuid>` identity URI.
void showProfileQrBottomSheet(
  BuildContext context, {
  UserProfile? profile,
}) {
  final isDark = context.isDarkMode;
  final name = profile?.fullName.trim().isNotEmpty == true
      ? profile!.fullName.trim()
      : 'مستخدم حِسبَتك';
  final phone = profile?.phoneE164?.trim();
  final subtitle = phone != null && phone.isNotEmpty
      ? phone
      : (profile?.email.trim().isNotEmpty == true
          ? profile!.email
          : 'حساب محلي مستقل');
  final walletId = profile?.id.isNotEmpty == true
      ? profile!.id
      : 'HIS-${(name.hashCode.abs() % 90000 + 10000)}';
  final qrPayload = phone != null && phone.isNotEmpty
      ? 'hisbatak://u/$walletId?p=${Uri.encodeComponent(phone)}'
      : 'hisbatak://u/$walletId';

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
                        'بطاقة الهوية والـ QR الرقمية',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.appTextPrimary,
                        ),
                      ),
                      Text(
                        'امسح الرمز لإضافة الصديق وتوحيد حسابه عبر المجموعات',
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
            Center(
              child: Container(
                padding: const EdgeInsets.all(18),
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
                    SizedBox(
                      width: 196,
                      height: 196,
                      child: CustomPaint(
                        painter: HisbatakQrCodePainter(
                          data: qrPayload,
                          foregroundColor: const Color(0xFF0F172A),
                          accentColor: AppColors.emerald,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mintSoft,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.mintContainer),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.shield_tick,
                            size: 12,
                            color: AppColors.emerald,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'رمز قياسي ISO • جاهز للمسح الفوري',
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
                          subtitle,
                          textDirection: phone != null && phone.isNotEmpty
                              ? TextDirection.ltr
                              : null,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.appTextSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 118),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
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
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.emerald,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
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
                            'تم نسخ معرّف الحساب بنجاح! 📋',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Iconsax.copy,
                      size: 16,
                      color: AppColors.emerald,
                    ),
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
                          '💳 معرّف حِسبَتك: $qrPayload\n👤 الاسم: $name${phone != null ? '\n📱 الهاتف: $phone' : ''}';
                      Clipboard.setData(ClipboardData(text: shareData));
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            'تم نسخ رابط وبطاقة الهوية للمشاركة! ✨',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Iconsax.share,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'نسخ رابط الهوية',
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

/// [HisbatakQrCodePainter] renders an ISO/IEC 18004 scannable QR Code matrix
/// generated via [QrMatrixGenerator] with rounded corner finder eyes and the
/// Hisbatak "ح" emblem embedded inside the ECC-safe central badge.
class HisbatakQrCodePainter extends CustomPainter {
  final String data;
  final Color foregroundColor;
  final Color accentColor;
  final List<List<bool>> _matrix;

  HisbatakQrCodePainter({
    required this.data,
    this.foregroundColor = const Color(0xFF0F172A),
    this.accentColor = const Color(0xFF006C49),
  }) : _matrix = QrMatrixGenerator.generate(
          data,
          errorCorrection: QrErrorCorrectionLevel.high,
        );

  /// Exposes the underlying generated matrix for verification and testing.
  List<List<bool>> get matrix => _matrix;

  @override
  void paint(Canvas canvas, Size size) {
    final int gridSize = _matrix.length;
    if (gridSize == 0) return;

    // 1-module quiet zone around the ISO matrix so edge contrast stays crisp.
    final int totalGrid = gridSize + 2;
    final double cellSize = size.width / totalGrid;
    final double origin = cellSize;

    final darkPaint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.fill;

    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    void drawFinderEye(double startX, double startY) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(startX, startY, cellSize * 7, cellSize * 7),
          Radius.circular(cellSize * 1.4),
        ),
        accentPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            startX + cellSize,
            startY + cellSize,
            cellSize * 5,
            cellSize * 5,
          ),
          Radius.circular(cellSize * 0.9),
        ),
        Paint()..color = Colors.white,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            startX + cellSize * 2,
            startY + cellSize * 2,
            cellSize * 3,
            cellSize * 3,
          ),
          Radius.circular(cellSize * 0.7),
        ),
        accentPaint,
      );
    }

    drawFinderEye(origin, origin);
    drawFinderEye(origin + cellSize * (gridSize - 7), origin);
    drawFinderEye(origin, origin + cellSize * (gridSize - 7));

    // Keep central ~7x7 area clear for the ECC-protected emblem badge.
    final int mid = gridSize ~/ 2;
    const int centerHalfSpan = 3;

    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        // Skip the 3 finder regions (7x7) drawn cleanly above.
        if (row < 7 && col < 7) continue;
        if (row < 7 && col >= gridSize - 7) continue;
        if (row >= gridSize - 7 && col < 7) continue;

        if ((row - mid).abs() <= centerHalfSpan &&
            (col - mid).abs() <= centerHalfSpan) {
          continue;
        }

        if (_matrix[row][col]) {
          final double x = origin + col * cellSize;
          final double y = origin + row * cellSize;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                x + cellSize * 0.08,
                y + cellSize * 0.08,
                cellSize * 0.84,
                cellSize * 0.84,
              ),
              Radius.circular(cellSize * 0.24),
            ),
            darkPaint,
          );
        }
      }
    }

    // Center white halo + navy squircle + crisp "ح" brand mark
    final double badgeSize = cellSize * 7.2;
    final double badgeOffset = (size.width - badgeSize) / 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeOffset, badgeOffset, badgeSize, badgeSize),
        Radius.circular(badgeSize * 0.26),
      ),
      Paint()..color = Colors.white,
    );

    final double innerMargin = cellSize * 0.6;
    final Rect navyRect = Rect.fromLTWH(
      badgeOffset + innerMargin,
      badgeOffset + innerMargin,
      badgeSize - innerMargin * 2,
      badgeSize - innerMargin * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(navyRect, Radius.circular(badgeSize * 0.22)),
      Paint()..color = AppColors.brandNavy,
    );

    final double markPad = navyRect.width * 0.22;
    final Rect markRect = Rect.fromLTWH(
      navyRect.left + markPad,
      navyRect.top + markPad,
      navyRect.width - markPad * 2,
      navyRect.height - markPad * 2,
    );
    HisbatakMarkPainter.paintMark(
      canvas,
      markRect,
      color: Colors.white,
      accentColor: AppColors.brandGreen,
    );
  }

  @override
  bool shouldRepaint(covariant HisbatakQrCodePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.foregroundColor != foregroundColor ||
        oldDelegate.accentColor != accentColor;
  }
}
