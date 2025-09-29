import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialButtonsRow extends StatelessWidget {
  const SocialButtonsRow({
    super.key,
    required this.facebook,
    required this.instagram,
    required this.tiktok,
    required this.youtube,
    required this.onEdit,
    required this.onOpen,
  });

  final String? facebook;
  final String? instagram;
  final String? tiktok;
  final String? youtube;
  final Future<void> Function(String title, String prefKey, String? current) onEdit;
  final Future<void> Function(String? url) onOpen;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 22,
      runSpacing: 14,
      alignment: WrapAlignment.center,
      children: [
        _SocialButton(
          icon: FontAwesomeIcons.facebookF,
          color: const Color(0xFF1877F2),
          title: 'Facebook',
          link: facebook,
          prefKey: 'profile_facebook',
          onEdit: onEdit,
          onOpen: onOpen,
        ),
        _SocialButton(
          icon: FontAwesomeIcons.instagram,
          gradient: const LinearGradient(
            colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF), Color(0xFF515BD4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          title: 'Instagram',
          link: instagram,
          prefKey: 'profile_instagram',
          onEdit: onEdit,
          onOpen: onOpen,
        ),
        _SocialButton(
          icon: FontAwesomeIcons.tiktok,
          color: Colors.black,
          title: 'TikTok',
          link: tiktok,
          prefKey: 'profile_tiktok',
          onEdit: onEdit,
          onOpen: onOpen,
        ),
        _SocialButton(
          icon: FontAwesomeIcons.youtube,
          color: const Color(0xFFFF0000),
          title: 'YouTube',
          link: youtube,
          prefKey: 'profile_youtube',
          onEdit: onEdit,
          onOpen: onOpen,
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.title,
    required this.prefKey,
    required this.onEdit,
    required this.onOpen,
    this.link,
    this.color,
    this.gradient,
  });

  final IconData icon;
  final String title;
  final String prefKey;
  final String? link;
  final Color? color;
  final LinearGradient? gradient;
  final Future<void> Function(String title, String prefKey, String? current) onEdit;
  final Future<void> Function(String? url) onOpen;

  @override
  Widget build(BuildContext context) {
    final enabled = link != null && link!.isNotEmpty;
    final decoration = gradient != null
        ? BoxDecoration(
            gradient: gradient,
            shape: BoxShape.circle,
            boxShadow: enabled ? [const BoxShadow(color: Color(0x44000000), blurRadius: 12, offset: Offset(0, 4))] : [],
          )
        : BoxDecoration(
            color: enabled ? color ?? Theme.of(context).colorScheme.primary : Colors.grey.shade700,
            shape: BoxShape.circle,
            boxShadow: enabled && color != null
                ? [BoxShadow(color: color!.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))]
                : [],
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: enabled ? () => onOpen(link) : null,
          onLongPress: enabled
              ? () async {
                  await Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$title link másolva.')),
                  );
                }
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 60,
            height: 60,
            decoration: decoration,
            alignment: Alignment.center,
            child: FaIcon(icon, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              tooltip: '$title szerkesztése',
              onPressed: () => onEdit(title, prefKey, link),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 18),
              tooltip: '$title megnyitása',
              onPressed: enabled ? () => onOpen(link) : null,
            ),
          ],
        ),
      ],
    );
  }
}
