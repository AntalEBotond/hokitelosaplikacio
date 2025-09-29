import 'dart:math' as math;

import 'package:flutter/material.dart';

class CountdownRingPainter extends CustomPainter {
  const CountdownRingPainter({
    required this.progress,
    required this.trackColor,
    required this.glowColor,
  });

  final double progress;
  final Color trackColor;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    final stroke = math.max(3.0, radius * 0.08);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;

    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = glowColor.withOpacity(0.92)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final rect = Rect.fromCircle(center: center, radius: radius - stroke / 2);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, track);

    final sweep = (math.pi * 2) * progress.clamp(0, 1);
    if (sweep > 0) {
      canvas.drawArc(rect, -math.pi / 2, sweep, false, active);
    }
  }

  @override
  bool shouldRepaint(covariant CountdownRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.glowColor != glowColor;
  }
}
