import 'dart:math' as math;

import 'package:flutter/material.dart';

class HaloPainter extends CustomPainter {
  const HaloPainter({
    required this.rotation,
    required this.colors,
    required this.strength,
  });

  final double rotation;
  final List<Color> colors;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    final thickness = radius * (0.1 + 0.25 * strength);
    final blur = 4 + 12 * strength;
    final rect = Rect.fromCircle(center: center, radius: radius - thickness / 2);

    final shader = SweepGradient(
      colors: [...colors, colors.first],
      startAngle: rotation,
      endAngle: rotation + math.pi * 2,
    ).createShader(rect);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..shader = shader
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

    canvas.drawArc(rect, 0, math.pi * 2, false, paint);
  }

  @override
  bool shouldRepaint(covariant HaloPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.strength != strength ||
        oldDelegate.colors != colors;
  }
}
