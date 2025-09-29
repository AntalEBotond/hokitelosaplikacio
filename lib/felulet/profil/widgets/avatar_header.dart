import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../painters/countdown_ring_painter.dart';
import '../painters/halo_painter.dart';
import 'framed_avatar.dart';
import 'note_overlay.dart';

class AvatarHeader extends StatelessWidget {
  const AvatarHeader({
    super.key,
    required this.haloAnimation,
    required this.haloStrength,
    required this.reduceMotion,
    required this.frameStyle,
    required this.colorsForFrame,
    required this.avatarRadius,
    required this.avatarImage,
    required this.displayName,
    required this.statusNote,
    required this.statusProgress,
    required this.noteTextColor,
    required this.noteBgColor,
    required this.statusEmoji,
    required this.onAvatarTap,
    required this.onEditStatus,
    required this.onPickEmoji,
    required this.onFrameSwipe,
    required this.onRandomizeFrame,
    this.stickerAsset,
  });

  final Animation<double> haloAnimation;
  final double haloStrength;
  final bool reduceMotion;
  final String frameStyle;
  final List<Color> Function(String) colorsForFrame;
  final double avatarRadius;
  final ImageProvider? avatarImage;
  final String displayName;
  final String? statusNote;
  final double statusProgress;
  final Color noteTextColor;
  final Color noteBgColor;
  final String? statusEmoji;
  final VoidCallback onAvatarTap;
  final VoidCallback onEditStatus;
  final VoidCallback onPickEmoji;
  final ValueChanged<int> onFrameSwipe;
  final VoidCallback onRandomizeFrame;
  final String? stickerAsset;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 420;
    final bubbleSpace = isSmall ? 44.0 : 56.0;
    final tileWidth = avatarRadius * 2 + (isSmall ? 160 : 220);
    final haloSize = avatarRadius * 2 + 16;
    final stickerImage = _resolveSticker();

    return SizedBox(
      height: bubbleSpace + avatarRadius * 2 + 32,
      child: Center(
        child: SizedBox(
          width: tileWidth,
          height: bubbleSpace + avatarRadius * 2,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: bubbleSpace - 10,
                left: (tileWidth - haloSize) / 2,
                child: AnimatedBuilder(
                  animation: haloAnimation,
                  builder: (context, _) {
                    return CustomPaint(
                      size: Size.square(haloSize),
                      painter: HaloPainter(
                        rotation: reduceMotion ? 0 : haloAnimation.value * math.pi * 2,
                        colors: colorsForFrame(frameStyle),
                        strength: haloStrength,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: bubbleSpace,
                left: (tileWidth - avatarRadius * 2) / 2,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onAvatarTap();
                  },
                  onDoubleTap: () {
                    HapticFeedback.mediumImpact();
                    onRandomizeFrame();
                  },
                  onHorizontalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity.abs() > 60) {
                      onFrameSwipe(velocity < 0 ? 1 : -1);
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      FramedAvatar(
                        radius: avatarRadius,
                        image: avatarImage,
                        name: displayName,
                        frameStyle: frameStyle,
                        stickerImage: stickerImage,
                      ),
                      if (statusNote != null && statusNote!.isNotEmpty)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: CountdownRingPainter(
                                progress: statusProgress,
                                trackColor: Colors.white.withOpacity(0.14),
                                glowColor: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: bubbleSpace + avatarRadius * 2 - 38,
                left: (tileWidth + avatarRadius * 2) / 2 - 38,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ),
              if (statusNote != null && statusNote!.isNotEmpty)
                Positioned(
                  top: 6,
                  right: math.max(16, tileWidth * 0.18),
                  child: NoteOverlay(
                    text: statusNote!,
                    textColor: noteTextColor,
                    bgColor: noteBgColor,
                    emoji: statusEmoji,
                    onEdit: onEditStatus,
                    onPickEmoji: onPickEmoji,
                    maxWidth: isSmall ? 200 : 260,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider? _resolveSticker() {
    if (stickerAsset == null || stickerAsset!.isEmpty) return null;
    if (stickerAsset!.startsWith('http')) {
      return NetworkImage(stickerAsset!);
    }
    return AssetImage('assets/stickers/$stickerAsset');
  }
}
