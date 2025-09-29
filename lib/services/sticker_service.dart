import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class Sticker {
  const Sticker({this.asset, this.url});

  final String? asset;
  final String? url;
}

class StickerService {
  Future<List<Sticker>> loadStickers() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = jsonDecode(manifestContent) as Map<String, dynamic>;
      final entries = manifestMap.keys
          .where((key) => key.startsWith('assets/stickers/') &&
              (key.endsWith('.png') || key.endsWith('.webp') || key.endsWith('.svg')))
          .toList()
        ..sort();
      return entries.map((path) => Sticker(asset: path.split('assets/stickers/').last)).toList();
    } catch (_) {
      return const [];
    }
  }
}
