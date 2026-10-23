import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// [CustomBottomSheet] is a reusable, theme-aware bottom sheet container designed
/// in accordance with the Stitch "Offline Arabic Fintech UI" design guidelines.
///
/// Features:
/// - Smooth rounded top corners (default radius 28).
/// - Adaptive light/dark styling via [ThemeContextExtension].
/// - Grab handle (pill indicator) for intuitive drag-to-dismiss affordance.
/// - Configurable header with icon badge, title, subtitle, and close button.
/// - Automatic keyboard insets avoidance ([viewInsets.bottom]).
/// - System bottom navigation / home bar safe area handling.
/// - Sticky footer support for primary and secondary action buttons.
/// - Built-in scrollable mode with [maxHeightFactor] constraints.
/// - Static convenience methods:
///     - [CustomBottomSheet.show]
///     - [CustomBottomSheet.showScrollable]
///     - [CustomBottomSheet.showConfirmation]
///
/// SOLID Principles:
/// - Single Responsibility Principle (SRP): Coordinates layout and theming for bottom sheets.
/// - Open/Closed Principle (OCP): Highly configurable via widgets, builders, and callbacks.
class CustomBottomSheet extends StatelessWidget {
  /// The main content of the bottom sheet.
  final Widget child;

  /// Header title text. If [titleWidget] is provided, this is ignored.
  final String? title;

  /// Custom widget for the header title. Overrides [title].
  final Widget? titleWidget;

  /// Optional header subtitle text. If [subtitleWidget] is provided, this is ignored.
  final String? subtitle;

  /// Custom widget for the header subtitle. Overrides [subtitle].
  final Widget? subtitleWidget;

  /// Optional icon displayed inside the header badge.
  final IconData? icon;

  /// Custom widget for the leading icon/avatar. Overrides [icon].
  final Widget? iconWidget;

  /// Custom color for the leading icon.
  final Color? iconColor;

  /// Custom background color for the leading icon badge.
  final Color? iconBackgroundColor;

  /// Custom leading widget replacing the entire icon container.
  final Widget? leading;

  /// Custom trailing widget replacing the default close button.
  final Widget? trailing;

  /// Whether to display a close button in the header. Default is true if header is shown.
  final bool showCloseButton;

  /// Callback executed when the close button is clicked. Default pops the modal.
  final VoidCallback? onClose;

  /// Completely custom header widget. Overrides all other header properties.
  final Widget? customHeader;

  /// Whether to display the top grab handle (pill). Default is true.
  final bool showDragHandle;

  /// Custom color for the drag handle.
  final Color? dragHandleColor;

  /// Sticky footer widget positioned at the bottom of the sheet, above keyboard & safe area.
  final Widget? footer;

  /// Content horizontal and vertical padding. Default: horizontal 20, top 16.
  final EdgeInsetsGeometry padding;

  /// Inner padding for the body content.
  final EdgeInsetsGeometry? contentPadding;

  /// Background color of the bottom sheet. Defaults to [context.appCardBackground].
  final Color? backgroundColor;

  /// Border radius for the top edges. Defaults to `BorderRadius.vertical(top: Radius.circular(28))`.
  final BorderRadiusGeometry? borderRadius;

  /// Optional custom border for the container (e.g. top border in dark mode).
  final BoxBorder? border;

  /// Maximum height of the bottom sheet as a fraction of the screen height (0.0 - 1.0).
  /// Defaults to 0.9 (90% of screen height).
  final double? maxHeightFactor;

  /// Minimum height of the bottom sheet.
  final double? minHeight;

  /// Whether the body should be wrapped in a [SingleChildScrollView].
  final bool isScrollable;

  /// Scroll physics for scrollable mode.
  final ScrollPhysics? physics;

  /// Scroll controller for scrollable mode.
  final ScrollController? scrollController;

  /// Whether to adjust bottom padding dynamically based on virtual keyboard insets.
  final bool handleKeyboardPadding;

  /// Whether to respect bottom safe area (home indicator/navigation bar).
  final bool handleSafeArea;

  const CustomBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.subtitleWidget,
    this.icon,
    this.iconWidget,
    this.iconColor,
    this.iconBackgroundColor,
    this.leading,
    this.trailing,
    this.showCloseButton = true,
    this.onClose,
    this.customHeader,
    this.showDragHandle = true,
    this.dragHandleColor,
    this.footer,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.contentPadding,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.maxHeightFactor = 0.90,
    this.minHeight,
    this.isScrollable = false,
    this.physics,
    this.scrollController,
    this.handleKeyboardPadding = true,
    this.handleSafeArea = true,
  });

  // ---------------------------------------------------------------------------
  // Static Helper Methods
  // ---------------------------------------------------------------------------

  /// Displays a modal bottom sheet wrapping [CustomBottomSheet].
  ///
  /// Example:
  /// ```dart
  /// CustomBottomSheet.show<void>(
  ///   context: context,
  ///   title: 'إضافة عضو جديد',
  ///   icon: Iconsax.user_add,
  ///   child: MyFormWidget(),
  /// );
  /// ```
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    Widget? titleWidget,
    String? subtitle,
    Widget? subtitleWidget,
    IconData? icon,
    Widget? iconWidget,
    Color? iconColor,
    Color? iconBackgroundColor,
    Widget? leading,
    Widget? trailing,
    bool showCloseButton = true,
    VoidCallback? onClose,
    Widget? customHeader,
    Widget? footer,
    bool showDragHandle = true,
    Color? dragHandleColor,
    Color? backgroundColor,
    BorderRadiusGeometry? borderRadius,
    BoxBorder? border,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 20),
    EdgeInsetsGeometry? contentPadding,
    bool isScrollable = false,
    ScrollPhysics? physics,
    ScrollController? scrollController,
    double? maxHeightFactor = 0.90,
    double? minHeight,
    bool handleKeyboardPadding = true,
    bool handleSafeArea = true,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? barrierColor,
    RouteSettings? routeSettings,
    AnimationController? transitionAnimationController,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.54),
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      routeSettings: routeSettings,
      transitionAnimationController: transitionAnimationController,
      builder: (ctx) => CustomBottomSheet(
        title: title,
        titleWidget: titleWidget,
        subtitle: subtitle,
        subtitleWidget: subtitleWidget,
        icon: icon,
        iconWidget: iconWidget,
        iconColor: iconColor,
        iconBackgroundColor: iconBackgroundColor,
        leading: leading,
        trailing: trailing,
        showCloseButton: showCloseButton,
        onClose: onClose,
        customHeader: customHeader,
        showDragHandle: showDragHandle,
        dragHandleColor: dragHandleColor,
        footer: footer,
        padding: padding,
        contentPadding: contentPadding,
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        border: border,
        maxHeightFactor: maxHeightFactor,
        minHeight: minHeight,
        isScrollable: isScrollable,
        physics: physics,
        scrollController: scrollController,
        handleKeyboardPadding: handleKeyboardPadding,
        handleSafeArea: handleSafeArea,
        child: child,
      ),
    );
  }

  /// Displays a draggable scrollable modal bottom sheet with [DraggableScrollableSheet].
  ///
  /// Useful for long scrollable lists, transaction details, or multi-step views.
  static Future<T?> showScrollable<T>({
    required BuildContext context,
    required Widget Function(BuildContext context, ScrollController scrollController) builder,
    String? title,
    Widget? titleWidget,
    String? subtitle,
    Widget? subtitleWidget,
    IconData? icon,
    Widget? iconWidget,
    Color? iconColor,
    Color? iconBackgroundColor,
    Widget? leading,
    Widget? trailing,
    bool showCloseButton = true,
    VoidCallback? onClose,
    Widget? customHeader,
    Widget? footer,
    bool showDragHandle = true,
    Color? dragHandleColor,
    Color? backgroundColor,
    BorderRadiusGeometry? borderRadius,
    BoxBorder? border,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 20),
    double initialChildSize = 0.75,
    double minChildSize = 0.40,
    double maxChildSize = 0.95,
    bool snap = true,
    List<double>? snapSizes,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? barrierColor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.54),
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      builder: (ctx) {
        final isDark = ctx.isDarkMode;
        final sheetBg = backgroundColor ?? ctx.appCardBackground;
        final defaultRadius = borderRadius ?? const BorderRadius.vertical(top: Radius.circular(28));

        return DraggableScrollableSheet(
          initialChildSize: initialChildSize,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
          expand: false,
          snap: snap,
          snapSizes: snapSizes,
          builder: (sheetCtx, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: defaultRadius,
                border: border ??
                    Border.all(
                      color: ctx.appBorder.withValues(alpha: isDark ? 0.35 : 0.6),
                      width: 1,
                    ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  if (showDragHandle) ...[
                    const SizedBox(height: 12),
                    CustomBottomSheetGrabHandle(color: dragHandleColor),
                  ],

                  // Header
                  if (customHeader != null)
                    Padding(
                      padding: padding,
                      child: customHeader,
                    )
                  else if (title != null || titleWidget != null || icon != null || iconWidget != null || leading != null)
                    Padding(
                      padding: padding.add(const EdgeInsets.only(top: 14, bottom: 8)),
                      child: CustomBottomSheetHeader(
                        title: title,
                        titleWidget: titleWidget,
                        subtitle: subtitle,
                        subtitleWidget: subtitleWidget,
                        icon: icon,
                        iconWidget: iconWidget,
                        iconColor: iconColor,
                        iconBackgroundColor: iconBackgroundColor,
                        leading: leading,
                        trailing: trailing,
                        showCloseButton: showCloseButton,
                        onClose: onClose ?? () => Navigator.of(ctx).pop(),
                      ),
                    ),

                  // Divider under header
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: ctx.appBorder.withValues(alpha: 0.5),
                  ),

                  // Scrollable Body
                  Expanded(
                    child: builder(sheetCtx, scrollController),
                  ),

                  // Optional Footer
                  if (footer != null) ...[
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: ctx.appBorder.withValues(alpha: 0.5),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: padding.add(const EdgeInsets.symmetric(vertical: 12)),
                        child: footer,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Displays a styled confirmation bottom sheet (e.g. Delete, Confirm, Warning).
  ///
  /// Returns `true` if the positive action was clicked, or `false`/`null` if cancelled.
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
    IconData icon = Iconsax.warning_2,
    Color? iconColor,
    Color? iconBackgroundColor,
    Color? confirmButtonColor,
    Color? confirmTextColor,
    bool isDanger = false,
  }) {
    return show<bool>(
      context: context,
      title: title,
      icon: icon,
      iconColor: iconColor ?? (isDanger ? AppColors.expense : AppColors.primary),
      iconBackgroundColor: iconBackgroundColor ??
          (isDanger
              ? AppColors.expense.withValues(alpha: 0.15)
              : AppColors.mintSoft),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: context.appTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.appBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    cancelText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: context.appTextSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmButtonColor ??
                        (isDanger ? AppColors.expense : AppColors.primary),
                    foregroundColor: confirmTextColor ?? Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    confirmText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = handleKeyboardPadding ? mediaQuery.viewInsets.bottom : 0.0;
    final bottomSafeArea = handleSafeArea ? mediaQuery.padding.bottom : 0.0;

    final sheetBg = backgroundColor ?? context.appCardBackground;
    final defaultRadius = borderRadius ?? const BorderRadius.vertical(top: Radius.circular(28));

    final effectiveBottomPadding = bottomInset > 0
        ? bottomInset + 16.0
        : (bottomSafeArea > 0 ? bottomSafeArea + 12.0 : 24.0);

    final hasHeader = customHeader != null ||
        title != null ||
        titleWidget != null ||
        subtitle != null ||
        subtitleWidget != null ||
        icon != null ||
        iconWidget != null ||
        leading != null;

    Widget bodyWidget = child;
    if (contentPadding != null) {
      bodyWidget = Padding(
        padding: contentPadding!,
        child: bodyWidget,
      );
    }

    if (isScrollable) {
      bodyWidget = Flexible(
        child: SingleChildScrollView(
          controller: scrollController,
          physics: physics ?? const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: bodyWidget,
        ),
      );
    }

    Widget contentColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Top Drag Handle
        if (showDragHandle) ...[
          const SizedBox(height: 12),
          CustomBottomSheetGrabHandle(color: dragHandleColor),
          const SizedBox(height: 8),
        ] else
          const SizedBox(height: 16),

        // 2. Header
        if (hasHeader) ...[
          if (customHeader != null)
            customHeader!
          else
            CustomBottomSheetHeader(
              title: title,
              titleWidget: titleWidget,
              subtitle: subtitle,
              subtitleWidget: subtitleWidget,
              icon: icon,
              iconWidget: iconWidget,
              iconColor: iconColor,
              iconBackgroundColor: iconBackgroundColor,
              leading: leading,
              trailing: trailing,
              showCloseButton: showCloseButton,
              onClose: onClose ?? () => Navigator.of(context).pop(),
            ),
          const SizedBox(height: 18),
        ],

        // 3. Body
        bodyWidget,

        // 4. Sticky Footer
        if (footer != null) ...[
          const SizedBox(height: 16),
          footer!,
        ],
      ],
    );

    // Constrain height if maxHeightFactor is specified
    if (maxHeightFactor != null && maxHeightFactor! > 0) {
      final screenHeight = mediaQuery.size.height;
      contentColumn = ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenHeight * maxHeightFactor!,
          minHeight: minHeight ?? 0.0,
        ),
        child: contentColumn,
      );
    }

    return Container(
      padding: EdgeInsets.only(
        left: (padding as EdgeInsets).left,
        right: (padding as EdgeInsets).right,
        top: (padding as EdgeInsets).top > 0 ? (padding as EdgeInsets).top : 4,
        bottom: effectiveBottomPadding,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: defaultRadius,
        border: border ??
            Border.all(
              color: context.appBorder.withValues(alpha: isDark ? 0.35 : 0.6),
              width: 1,
            ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: contentColumn,
    );
  }
}

// =============================================================================
// SUB-COMPONENTS
// =============================================================================

/// [CustomBottomSheetGrabHandle] renders the visual pill handle centered at the top.
class CustomBottomSheetGrabHandle extends StatelessWidget {
  final Color? color;
  final double width;
  final double height;
  final double borderRadius;

  const CustomBottomSheetGrabHandle({
    super.key,
    this.color,
    this.width = 44.0,
    this.height = 4.0,
    this.borderRadius = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color ?? context.appBorder,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// [CustomBottomSheetHeader] renders the standard top bar with icon badge, title,
/// subtitle, and dismiss button.
class CustomBottomSheetHeader extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final Widget? subtitleWidget;
  final IconData? icon;
  final Widget? iconWidget;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Widget? leading;
  final Widget? trailing;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const CustomBottomSheetHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.subtitleWidget,
    this.icon,
    this.iconWidget,
    this.iconColor,
    this.iconBackgroundColor,
    this.leading,
    this.trailing,
    this.showCloseButton = true,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    // Resolve leading
    Widget? effectiveLeading = leading;
    if (effectiveLeading == null && (icon != null || iconWidget != null)) {
      final defaultBg = isDark
          ? AppColors.emerald.withValues(alpha: 0.2)
          : AppColors.mintFixed;
      final defaultIconColor =
          isDark ? AppColors.mintContainer : AppColors.primary;

      effectiveLeading = Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: iconBackgroundColor ?? defaultBg,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: iconWidget ??
            Icon(
              icon,
              color: iconColor ?? defaultIconColor,
              size: 22,
            ),
      );
    }

    // Resolve trailing
    Widget? effectiveTrailing = trailing;
    if (effectiveTrailing == null && showCloseButton) {
      effectiveTrailing = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onClose ?? () => Navigator.of(context).pop(),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              Iconsax.close_circle,
              color: context.appTextSecondary,
              size: 24,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        if (effectiveLeading != null) ...[
          effectiveLeading,
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (titleWidget != null)
                titleWidget!
              else if (title != null)
                Text(
                  title!,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                    height: 1.2,
                  ),
                ),
              if (subtitleWidget != null) ...[
                const SizedBox(height: 3),
                subtitleWidget!,
              ] else if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.appTextSecondary,
                    height: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (effectiveTrailing != null) ...[
          const SizedBox(width: 8),
          effectiveTrailing,
        ],
      ],
    );
  }
}
