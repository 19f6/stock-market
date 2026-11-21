import 'package:flutter/material.dart';

/// A tiny real-time line drawn from a rolling list of recent prices.
class Sparkline extends StatelessWidget {
  final List<double> points;
  final Color color;
  final double strokeWidth;
  const Sparkline({
    super.key,
    required this.points,
    required this.color,
    this.strokeWidth = 1.6,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparkPainter(points, color, strokeWidth),
      size: Size.infinite,
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> points;
  final Color color;
  final double strokeWidth;
  _SparkPainter(this.points, this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    var lo = points.first, hi = points.first;
    for (final p in points) {
      if (p < lo) lo = p;
      if (p > hi) hi = p;
    }
    final span = (hi - lo).abs() < 1e-9 ? 1.0 : hi - lo;
    final dx = size.width / (points.length - 1);
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = dx * i;
      final y = size.height - ((points[i] - lo) / span) * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.points != points || old.color != color;
}
