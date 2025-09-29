import 'package:flutter/material.dart';

class ProfileSaveBar extends StatelessWidget {
  const ProfileSaveBar({
    super.key,
    required this.visible,
    required this.saving,
    required this.onDiscard,
    required this.onSave,
  });

  final bool visible;
  final bool saving;
  final VoidCallback onDiscard;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 240),
        offset: visible ? Offset.zero : const Offset(0, 1),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 240),
          opacity: visible ? 1 : 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).colorScheme.surface,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Vannak mentetlen módosítások.')),
                    TextButton(onPressed: onDiscard, child: const Text('Visszaállítás')),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: saving ? null : onSave,
                      icon: saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: Text(saving ? 'Mentés...' : 'Mentés'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
