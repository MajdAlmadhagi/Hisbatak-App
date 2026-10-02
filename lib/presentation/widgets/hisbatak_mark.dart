import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// [HisbatakMark] renders the Hisbatak brand mark: the letter "ح" split into
/// three pieces, where the separated green piece stands for "your share".
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class HisbatakMark extends StatelessWidget {
  /// Height of the mark; the width follows the mark's aspect ratio.
  final double size;

  /// Color of the main pieces. Defaults to the theme's `onSurface`.
  final Color? color;

  /// Color of the separated "share" piece.
  final Color accentColor;

  const HisbatakMark({
    super.key,
    this.size = 56,
    this.color,
    this.accentColor = AppColors.brandGreen,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * HisbatakMarkPainter.aspectRatio,
      height: size,
      child: CustomPaint(
        painter: HisbatakMarkPainter(
          color: color ?? Theme.of(context).colorScheme.onSurface,
          accentColor: accentColor,
        ),
      ),
    );
  }
}

/// When one piece of the mark draws in and retracts, as fractions of a loop.
class _Timing {
  final double drawStart;
  final double drawEnd;
  final double eraseStart;
  final double eraseEnd;

  const _Timing(this.drawStart, this.drawEnd, this.eraseStart, this.eraseEnd);

  /// The visible part of the stroke at loop position [t], as (start, end)
  /// fractions of its length.
  (double, double) visibleAt(double t) {
    if (t < drawStart || t >= eraseEnd) return (0, 0);
    if (t < drawEnd) {
      return (0, Curves.easeInOutCubic.transform((t - drawStart) / (drawEnd - drawStart)));
    }
    if (t < eraseStart) return (0, 1);
    return (Curves.easeInOutCubic.transform((t - eraseStart) / (eraseEnd - eraseStart)), 1);
  }
}

/// Paints the "ح" mark, either complete or, when given a [progress]
/// animation, as the loader: the pieces draw in one after another, the green
/// piece nudges outward, then they retract in the same order.
///
/// The geometry is the same 1024-unit design grid as the launcher icon in
/// assets, so the logo looks identical everywhere it appears.
class HisbatakMarkPainter extends CustomPainter {
  final Color color;
  final Color accentColor;

  /// Position in the loader loop (0 to 1). Null paints the complete mark.
  final Animation<double>? progress;

  /// Paints a faint silhouette of the full mark behind the animation.
  final bool showTrack;

  HisbatakMarkPainter({
    required this.color,
    required this.accentColor,
    this.progress,
    this.showTrack = false,
  }) : super(repaint: progress);

  static const Rect _bounds = Rect.fromLTWH(275, 255, 436, 660);
  static double get aspectRatio => _bounds.width / _bounds.height;
  static const double _strokeWidth = 110;
  static final Rect _bowl = Rect.fromCircle(center: const Offset(540, 650), radius: 210);

  static double _deg(double degrees) => degrees * math.pi / 180;

  /// Head stroke, diagonal, and the first sliver of the bowl.
  static final Path _head = Path()
    ..moveTo(400, 310)
    ..lineTo(650, 310)
    ..lineTo(521.7, 440.8)
    ..arcTo(_bowl, _deg(-95), _deg(-25.5), false);
  static final Path _bowlArc = Path()..addArc(_bowl, _deg(-129.5), _deg(-100.5));
  static final Path _share = Path()..addArc(_bowl, _deg(-242), _deg(-68));

  static final PathMetric _headMetric = _head.computeMetrics().first;
  static final PathMetric _bowlMetric = _bowlArc.computeMetrics().first;
  static final PathMetric _shareMetric = _share.computeMetrics().first;

  static const _headTiming = _Timing(0.00, 0.28, 0.66, 0.86);
  static const _bowlTiming = _Timing(0.14, 0.40, 0.72, 0.92);
  static const _shareTiming = _Timing(0.30, 0.48, 0.78, 0.98);

  /// How far the share piece moves outward at the peak of its nudge.
  static const Offset _nudge = Offset(2.5, 24);

  static double _nudgeAmount(double t) {
    if (t < 0.48 || t >= 0.66) return 0;
    if (t < 0.56) return Curves.easeOutCubic.transform((t - 0.48) / 0.08);
    return 1 - Curves.easeInOutCubic.transform((t - 0.56) / 0.10);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / _bounds.width, size.height / _bounds.height);
    canvas
      ..save()
      ..translate(
        (size.width - _bounds.width * scale) / 2,
        (size.height - _bounds.height * scale) / 2,
      )
      ..scale(scale)
      ..translate(-_bounds.left, -_bounds.top);

    final main = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final accent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..color = accentColor;

    final animation = progress;
    if (animation == null) {
      canvas
        ..drawPath(_head, main)
        ..drawPath(_bowlArc, main)
        ..drawPath(_share, accent)
        ..restore();
      return;
    }

    if (showTrack) {
      final track = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.1);
      canvas
        ..drawPath(_head, track)
        ..drawPath(_bowlArc, track)
        ..drawPath(_share, track);
    }

    final t = animation.value;
    _drawPiece(canvas, _headMetric, _headTiming.visibleAt(t), main);
    _drawPiece(canvas, _bowlMetric, _bowlTiming.visibleAt(t), main);
    final nudge = _nudgeAmount(t);
    canvas
      ..save()
      ..translate(_nudge.dx * nudge, _nudge.dy * nudge);
    _drawPiece(canvas, _shareMetric, _shareTiming.visibleAt(t), accent);
    canvas
      ..restore()
      ..restore();
  }

  void _drawPiece(Canvas canvas, PathMetric metric, (double, double) range, Paint paint) {
    final (start, end) = range;
    if (end <= start) return;
    canvas.drawPath(metric.extractPath(start * metric.length, end * metric.length), paint);
  }

  @override
  bool shouldRepaint(HisbatakMarkPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.showTrack != showTrack ||
      oldDelegate.progress != progress;
}
