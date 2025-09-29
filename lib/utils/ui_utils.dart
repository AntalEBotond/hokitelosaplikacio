import 'package:flutter/material.dart';

class UiUtils {
  static String normalizeUploadUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return 'https://$url';
  }

  static String normalizeSocial(String prefKey, String input) {
    final value = input.trim();
    if (value.isEmpty) return '';
    final isUrl = value.startsWith('http://') || value.startsWith('https://');
    String username = value.startsWith('@') ? value.substring(1) : value;
    if (isUrl) return value;
    switch (prefKey) {
      case 'profile_facebook':
        return 'https://facebook.com/$username';
      case 'profile_instagram':
        return 'https://instagram.com/$username';
      case 'profile_tiktok':
        if (username.contains('/')) return 'https://tiktok.com/$username';
        return 'https://www.tiktok.com/@$username';
      case 'profile_youtube':
        if (username.startsWith('@')) return 'https://youtube.com/$username';
        if (username.startsWith('UC')) return 'https://youtube.com/channel/$username';
        return 'https://youtube.com/@$username';
      default:
        return value;
    }
  }
}

extension ThemeDataX on ThemeData {
  Color overlayColor(double opacity) => colorScheme.surface.withOpacity(opacity);
}
