import 'package:flutter/widgets.dart';

class I18n {
  static const Map<String, String> _defaults = {
    'profile': 'Profil',
    'name': 'Név',
    'description': 'Leírás',
    'avatar_frame': 'Avatar keret',
    'social_media': 'Social media',
    'sticker': 'Matrica',
    'remove': 'Eltávolítás',
    'not_authenticated': 'Nem vagy bejelentkezve.',
    'profile_saved': 'Profil mentve.',
    'save_failed': 'Mentés sikertelen',
    'upload_error': 'Feltöltési hiba',
    'avatar_updated': 'Avatar frissítve.',
    'banner_updated': 'Banner frissítve.',
    'avatar_delete_failed': 'Avatar törlése nem sikerült',
    'banner_delete_failed': 'Banner törlése nem sikerült',
    'image_load_error': 'Nem sikerült betölteni a képet',
    'edit': 'Szerkesztés',
    'link_hint': 'Link vagy @felhasználónév',
    'cancel': 'Mégse',
    'save': 'Mentés',
    'missing_link': 'Nincs beállított link.',
    'invalid_url': 'Érvénytelen URL.',
    'cannot_launch': 'Nem sikerült megnyitni a linket.',
    'pick_from_gallery': 'Galériából',
    'take_photo': 'Fénykép készítése',
    'delete_avatar': 'Avatar törlése',
    'no_stickers': 'Nincsenek matricák az assets/stickers mappában.',
    'frame_picker': 'Keretválasztó',
    'search_frames': 'Keresés...',
    'unsaved_changes': 'Mentetlen módosítások',
    'leave_without_save': 'Elhagyod az oldalt mentés nélkül?',
    'stay': 'Maradok',
    'leave': 'Kilépés',
  };

  static String t(BuildContext context, String key) {
    return _defaults[key] ?? key;
  }
}
