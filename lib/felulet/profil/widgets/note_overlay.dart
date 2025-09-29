import 'package:flutter/material.dart';

class NoteOverlay extends StatelessWidget {
  const NoteOverlay({
    super.key,
    required this.text,
    required this.textColor,
    required this.bgColor,
    this.emoji,
    required this.onEdit,
    required this.onPickEmoji,
    this.maxWidth = 220,
  });

  final String text;
  final Color textColor;
  final Color bgColor;
  final String? emoji;
  final VoidCallback onEdit;
  final VoidCallback onPickEmoji;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (emoji != null && emoji!.isNotEmpty)
                    Text(emoji!, style: const TextStyle(fontSize: 20)),
                  if (emoji != null && emoji!.isNotEmpty) const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    color: textColor,
                    onPressed: onEdit,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: onPickEmoji,
                icon: const Icon(Icons.emoji_emotions_outlined, size: 16),
                label: const Text('Emoji'),
                style: TextButton.styleFrom(foregroundColor: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
