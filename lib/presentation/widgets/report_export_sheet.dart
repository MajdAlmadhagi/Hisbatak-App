import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// [ReportExportFormatOption] represents a selectable export format inside [ReportExportSheet].
class ReportExportFormatOption {
  final String label;
  final String content;

  const ReportExportFormatOption({
    required this.label,
    required this.content,
  });
}

/// Interactive preview and copy sheet for CSV/JSON reports across Groups & Settings.
class ReportExportSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<ReportExportFormatOption> formats;

  const ReportExportSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.formats,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<ReportExportFormatOption> formats,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportExportSheet(
        title: title,
        subtitle: subtitle,
        formats: formats,
      ),
    );
  }

  @override
  State<ReportExportSheet> createState() => _ReportExportSheetState();
}

class _ReportExportSheetState extends State<ReportExportSheet> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final activeOption = widget.formats[_selectedIndex];
    final previewLines =
        activeOption.content.replaceFirst('\uFEFF', '').split('\n').take(16).join('\n');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.document_download,
                  color: AppColors.emerald,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
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
          if (widget.formats.length > 1) ...[
            const SizedBox(height: 14),
            Row(
              children: List.generate(widget.formats.length, (i) {
                final selected = i == _selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(widget.formats[i].label),
                    selected: selected,
                    selectedColor: AppColors.emerald.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? (isDark ? AppColors.mintContainer : AppColors.emerald)
                          : context.appTextSecondary,
                    ),
                    onSelected: (_) => setState(() => _selectedIndex = i),
                  ),
                );
              }),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.appSurfaceVariant.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.appBorder),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                previewLines,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.45,
                  color: context.appTextPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: BorderSide(color: context.appBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'إغلاق',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: activeOption.content),
                    );
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم نسخ التقرير بصيغة ${activeOption.label} إلى الحافظة بنجاح!',
                        ),
                        backgroundColor: AppColors.emerald,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Iconsax.copy, size: 18),
                  label: const Text(
                    'نسخ التقرير كاملاً',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
