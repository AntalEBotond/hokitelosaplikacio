import 'package:flutter/material.dart';

class FramePreviewStrip extends StatelessWidget {
  const FramePreviewStrip({
    super.key,
    required this.styles,
    required this.selected,
    required this.image,
    required this.name,
    required this.onSelected,
    required this.colorsFor,
  });

  final List<String> styles;
  final String selected;
  final ImageProvider? image;
  final String name;
  final ValueChanged<String> onSelected;
  final List<Color> Function(String) colorsFor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: styles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final style = styles[index];
          final isSelected = style == selected;
          return GestureDetector(
            onTap: () => onSelected(style),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 96,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white.withOpacity(0.08),
                  width: isSelected ? 2 : 1,
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: image,
                    backgroundColor: Colors.black12,
                    child: image == null
                        ? Text(
                            _initials(name),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colorsFor(style)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    style,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _initials(String name) {
    final text = name
        .split(' ')
        .where((element) => element.isNotEmpty)
        .take(2)
        .map((e) => e[0])
        .join()
        .toUpperCase();
    return text.isEmpty ? '?' : text;
  }
}
