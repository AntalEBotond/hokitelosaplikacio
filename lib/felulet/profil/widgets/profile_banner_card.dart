import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileBannerCard extends StatelessWidget {
  const ProfileBannerCard({
    super.key,
    required this.image,
    required this.onPick,
    required this.onDelete,
  });

  final ImageProvider? image;
  final Future<void> Function(ImageSource source) onPick;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wallpaper, size: 18),
              const SizedBox(width: 8),
              Text(
                'Banner',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () => _showOptions(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 3 / 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.04)),
                child: image != null
                    ? Image(image: image!, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          'Adj hozzá egy borítóképet',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galériából'),
              onTap: () {
                Navigator.pop(context);
                onPick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Fénykép készítése'),
              onTap: () {
                Navigator.pop(context);
                onPick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Banner törlése'),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
