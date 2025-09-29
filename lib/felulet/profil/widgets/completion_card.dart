import 'package:flutter/material.dart';

class CompletionCard extends StatelessWidget {
  const CompletionCard({super.key, required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final progress = percent.clamp(0, 1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Profil készültség: ${(progress * 100).round()}%'),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            height: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.1),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
