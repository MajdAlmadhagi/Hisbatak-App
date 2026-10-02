import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'hisbatak_mark.dart';

/// [HisbatakLoader] is the app's loading indicator, built from the "ح" brand
/// mark. When the device asks to reduce motion, it shows the still mark.
///
/// ```dart
/// const Center(child: HisbatakLoader(size: 48))
/// ```
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class HisbatakLoader extends StatefulWidget {
  /// Height of the mark; the width follows the mark's aspect ratio.
  final double size;

  /// Color of the main pieces. Defaults to the theme's `onSurface`, so the
  /// mark is dark on light screens and white on dark ones.
  final Color? color;

  /// Color of the separated "share" piece.
  final Color accentColor;

  /// Paints a faint silhouette of the full mark behind the animation.
  final bool showTrack;

  /// Length of one full loop.
  final Duration duration;

  final String semanticsLabel;

  const HisbatakLoader({
    super.key,
    this.size = 48,
    this.color,
    this.accentColor = AppColors.brandGreen,
    this.showTrack = true,
    this.duration = const Duration(milliseconds: 2400),
    this.semanticsLabel = 'جارٍ التحميل',
  });

  @override
  State<HisbatakLoader> createState() => _HisbatakLoaderState();
}

class _HisbatakLoaderState extends State<HisbatakLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      // Setting the value also stops the controller; 0.5 is the fully drawn frame.
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant HisbatakLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      if (_controller.isAnimating) _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel,
      child: SizedBox(
        width: widget.size * HisbatakMarkPainter.aspectRatio,
        height: widget.size,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: HisbatakMarkPainter(
              color: widget.color ?? Theme.of(context).colorScheme.onSurface,
              accentColor: widget.accentColor,
              progress: _controller,
              showTrack: widget.showTrack,
            ),
          ),
        ),
      ),
    );
  }
}
