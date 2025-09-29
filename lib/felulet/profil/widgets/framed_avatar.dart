import 'dart:math' as math;

import 'package:flutter/material.dart';

class FramedAvatar extends StatelessWidget {
  const FramedAvatar({
    super.key,
    required this.radius,
    this.image,
    this.name,
    required this.frameStyle,
    this.stickerImage,
  });

  final double radius;
  final ImageProvider? image;
  final String? name;
  final String frameStyle;
  final ImageProvider? stickerImage;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsForStyle(context, frameStyle);
    final hasSticker = stickerImage != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: CircleAvatar(
            backgroundImage: image,
            backgroundColor: Colors.black12,
            child: image == null ? _initials(name) : null,
          ),
        ),
        if (hasSticker)
          Positioned(
            right: -6,
            bottom: -6,
            child: Container(
              width: math.max(48, radius * 0.9),
              height: math.max(48, radius * 0.9),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              padding: const EdgeInsets.all(6),
              child: Image(image: stickerImage!, fit: BoxFit.contain),
            ),
          ),
      ],
    );
  }

  Widget _initials(String? name) {
    final text = (name ?? '')
        .split(' ')
        .where((element) => element.isNotEmpty)
        .take(2)
        .map((e) => e[0])
        .join()
        .toUpperCase();
    return Text(text.isEmpty ? '?' : text, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600));
  }

  List<Color> _colorsForStyle(BuildContext context, String style) {
    switch (style) {
      case 'glow-emerald':
        return const [Color(0xFF00E676), Color(0xFF2ECC71)];
      case 'glow-azure':
        return const [Color(0xFF03A9F4), Color(0xFF40C4FF)];
      case 'glow-magenta':
        return const [Color(0xFFFF4081), Color(0xFFE040FB)];
      case 'neon-cyan':
        return const [Color(0xFF00E5FF), Color(0xFF18FFFF)];
      case 'neon-amber':
        return const [Color(0xFFFFD740), Color(0xFFFFAB00)];
      case 'outline-ice':
        return const [Color(0xFF90CAF9), Color(0xFFE3F2FD)];
      case 'outline-coral':
        return const [Color(0xFFFFAB91), Color(0xFFFF7043)];
      case 'ring-lime':
        return const [Color(0xFFB9F6CA), Color(0xFF76FF03)];
      case 'ring-violet':
        return const [Color(0xFFB388FF), Color(0xFF7C4DFF)];
      case 'gradient-sunset':
        return const [Color(0xFFFF512F), Color(0xFFF09819)];
      case 'gradient-ocean':
        return const [Color(0xFF36D1DC), Color(0xFF5B86E5)];
      case 'gradient-aurora':
        return const [Color(0xFF00C9FF), Color(0xFF92FE9D)];
      case 'gradient-plasma':
        return const [Color(0xFF12C2E9), Color(0xFFC471ED), Color(0xFFF64F59)];
      case 'gradient-gold':
        return const [Color(0xFFFFD700), Color(0xFFFFB300)];
      case 'gradient-silver':
        return const [Color(0xFFBEC2C6), Color(0xFFE5E4E2)];
      case 'rainbow':
        return const [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple];
      default:
        final color = Theme.of(context).colorScheme.primary;
        return [color.withOpacity(0.8), color.withOpacity(0.4)];
    }
  }
}
