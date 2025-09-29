import 'package:flutter/material.dart';

class ProfileQuickActions extends StatelessWidget {
  const ProfileQuickActions({
    super.key,
    required this.onFramePicker,
    required this.onRandomize,
    required this.onEditStatus,
  });

  final VoidCallback onFramePicker;
  final VoidCallback onRandomize;
  final VoidCallback onEditStatus;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _QuickActionButton(
          icon: Icons.palette_outlined,
          label: 'Keretek',
          onTap: onFramePicker,
        ),
        _QuickActionButton(
          icon: Icons.casino_outlined,
          label: 'Random',
          onTap: onRandomize,
        ),
        _QuickActionButton(
          icon: Icons.edit_note_outlined,
          label: 'Státusz',
          onTap: onEditStatus,
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(label, style: theme.textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}
