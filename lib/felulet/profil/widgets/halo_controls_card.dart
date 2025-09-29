import 'package:flutter/material.dart';

class HaloControlsCard extends StatelessWidget {
  const HaloControlsCard({
    super.key,
    required this.haloStrength,
    required this.reduceMotion,
    required this.onHaloChanged,
    required this.onReduceMotionChanged,
  });

  final double haloStrength;
  final bool reduceMotion;
  final ValueChanged<double> onHaloChanged;
  final ValueChanged<bool> onReduceMotionChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_fix_high_outlined, size: 20),
              const SizedBox(width: 10),
              Text('Halo beállítás', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text('${(haloStrength * 100).round()}%'),
            ],
          ),
          Slider(
            value: haloStrength,
            onChanged: onHaloChanged,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mozgás csökkentése'),
            subtitle: const Text('Állítsd le az animációkat energiatakarékossághoz.'),
            value: reduceMotion,
            onChanged: onReduceMotionChanged,
          ),
        ],
      ),
    );
  }
}
