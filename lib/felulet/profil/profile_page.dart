import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../services/sticker_service.dart';
import '../../utils/i18n.dart';
import '../../utils/ui_utils.dart';
import 'painters/countdown_ring_painter.dart';
import 'painters/halo_painter.dart';
import 'widgets/avatar_header.dart';
import 'widgets/completion_card.dart';
import 'widgets/frame_preview_strip.dart';
import 'widgets/halo_controls_card.dart';
import 'widgets/note_editor_page.dart';
import 'widgets/note_overlay.dart';
import 'widgets/profile_banner_card.dart';
import 'widgets/profile_quick_actions.dart';
import 'widgets/profile_save_bar.dart';
import 'widgets/social_buttons.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  // Avatar + banner state
  String? _avatarPath;
  Uint8List? _avatarBytes;
  String? _avatarUrl;
  String _avatarFrame = 'none';
  String? _avatarStickerAsset;
  String? _bannerPath;
  Uint8List? _bannerBytes;
  String? _bannerUrl;

  // Profile metadata
  String? _facebook;
  String? _instagram;
  String? _tiktok;
  String? _youtube;
  String? _statusNote;
  DateTime? _statusNoteExpires;
  String? _statusEmoji;
  Color _noteTextColor = Colors.white;
  Color _noteBgColor = const Color(0xDD000000);
  double _haloStrength = 0.65;
  bool _reduceMotion = false;
  bool _dirty = false;

  // Backend token + saving
  String? _authToken;
  bool _loading = true;
  bool _saving = false;
  Timer? _autoSaveTimer;
  Timer? _statusTicker;

  // Debounce controllers
  Timer? _nameDebounce;
  Timer? _descDebounce;

  // Animation
  late final AnimationController _haloCtrl;
  String? _frameTempPreview;

  // Sticker cache
  List<Sticker> _stickers = const [];

  static const List<String> _frameStyles = [
    'none',
    'glow-emerald',
    'glow-azure',
    'glow-magenta',
    'neon-cyan',
    'neon-amber',
    'outline-ice',
    'outline-coral',
    'ring-lime',
    'ring-violet',
    'gradient-sunset',
    'gradient-ocean',
    'gradient-aurora',
    'gradient-plasma',
    'gradient-gold',
    'gradient-silver',
    'rainbow',
  ];

  static const Map<String, List<String>> _frameCategories = {
    'All': [],
    'Glow': ['glow-'],
    'Neon': ['neon-'],
    'Outline': ['outline-'],
    'Ring': ['ring-'],
    'Gradient': ['gradient-', 'rainbow'],
  };

  @override
  void initState() {
    super.initState();
    _haloCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
    _loadProfile();
    _nameCtrl.addListener(_onNameChanged);
    _descCtrl.addListener(_onDescriptionChanged);
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onNameChanged);
    _descCtrl.removeListener(_onDescriptionChanged);
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _nameDebounce?.cancel();
    _descDebounce?.cancel();
    _autoSaveTimer?.cancel();
    _statusTicker?.cancel();
    _haloCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');

    if (_authToken == null) {
      _loadLocalSnapshot(prefs);
      return;
    }

    try {
      final api = ApiService();
      final data = await api.getProfile(_authToken!);
      if (!mounted) return;
      setState(() {
        _nameCtrl.text = (data['full_name'] ?? prefs.getString('profile_name') ?? '') as String;
        _descCtrl.text = (data['description'] ?? prefs.getString('profile_description') ?? '') as String;
        _facebook = data['social_facebook'] as String? ?? prefs.getString('profile_facebook');
        _instagram = data['social_instagram'] as String? ?? prefs.getString('profile_instagram');
        _tiktok = data['social_tiktok'] as String? ?? prefs.getString('profile_tiktok');
        _youtube = data['social_youtube'] as String? ?? prefs.getString('profile_youtube');
        _avatarUrl = data['avatar_url'] as String? ?? prefs.getString('profile_avatar_url');
        _bannerUrl = data['banner_url'] as String? ?? prefs.getString('profile_banner_url');
        _avatarFrame = (data['avatar_frame'] as String?) ?? prefs.getString('profile_avatar_frame') ?? 'none';
        _avatarStickerAsset = data['avatar_sticker'] as String? ?? prefs.getString('profile_avatar_sticker_asset');
        _statusNote = data['status_note'] as String? ?? prefs.getString('profile_status_note');
        final se = data['status_note_expires'] as String? ?? prefs.getString('profile_status_note_expires');
        _statusNoteExpires = se != null ? DateTime.tryParse(se) : null;
        _statusEmoji = data['status_note_emoji'] as String? ?? prefs.getString('profile_status_note_emoji');
        _noteTextColor = _colorFromHex(data['status_note_color'] as String?) ?? _colorFromHex(prefs.getString('profile_status_note_color')) ?? _noteTextColor;
        _noteBgColor = _colorFromHex(data['status_note_bg'] as String?) ?? _colorFromHex(prefs.getString('profile_status_note_bg')) ?? _noteBgColor;
        _haloStrength = double.tryParse(data['halo_strength']?.toString() ?? '') ?? prefs.getDouble('profile_halo_strength') ?? _haloStrength;
        _reduceMotion = (data['reduce_motion'] == true) || prefs.getBool('profile_reduce_motion') == true;
        _loading = false;
        _dirty = false;
      });
      _restoreLocalImages(prefs);
      _startStatusTicker();
    } on ApiException catch (e) {
      if (!mounted) return;
      _loadLocalSnapshot(prefs);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profil betöltése sikertelen: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      _loadLocalSnapshot(prefs);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profil betöltése sikertelen: $e')));
    }
  }

  void _loadLocalSnapshot(SharedPreferences prefs) {
    if (!mounted) return;
    setState(() {
      if (kIsWeb) {
        final b64 = prefs.getString('profile_avatar_b64');
        _avatarBytes = (b64 != null && b64.isNotEmpty) ? base64Decode(b64) : null;
        final bannerB64 = prefs.getString('profile_banner_b64');
        _bannerBytes = (bannerB64 != null && bannerB64.isNotEmpty) ? base64Decode(bannerB64) : null;
      } else {
        _avatarPath = prefs.getString('profile_avatar');
        _bannerPath = prefs.getString('profile_banner');
      }
      _avatarUrl = prefs.getString('profile_avatar_url');
      _bannerUrl = prefs.getString('profile_banner_url');
      _avatarFrame = prefs.getString('profile_avatar_frame') ?? 'none';
      _avatarStickerAsset = prefs.getString('profile_avatar_sticker_asset');
      _nameCtrl.text = prefs.getString('profile_name') ?? '';
      _descCtrl.text = prefs.getString('profile_description') ?? '';
      _facebook = prefs.getString('profile_facebook');
      _instagram = prefs.getString('profile_instagram');
      _tiktok = prefs.getString('profile_tiktok');
      _youtube = prefs.getString('profile_youtube');
      _statusNote = prefs.getString('profile_status_note');
      final expires = prefs.getString('profile_status_note_expires');
      _statusNoteExpires = expires != null ? DateTime.tryParse(expires) : null;
      _statusEmoji = prefs.getString('profile_status_note_emoji');
      _noteTextColor = _colorFromHex(prefs.getString('profile_status_note_color')) ?? _noteTextColor;
      _noteBgColor = _colorFromHex(prefs.getString('profile_status_note_bg')) ?? _noteBgColor;
      _haloStrength = prefs.getDouble('profile_halo_strength') ?? _haloStrength;
      _reduceMotion = prefs.getBool('profile_reduce_motion') ?? _reduceMotion;
      _loading = false;
      _dirty = false;
    });
    _restoreLocalImages(prefs);
    _startStatusTicker();
  }

  void _restoreLocalImages(SharedPreferences prefs) {
    if (kIsWeb) {
      final avatar = prefs.getString('profile_avatar_b64');
      final banner = prefs.getString('profile_banner_b64');
      setState(() {
        _avatarBytes = (avatar != null && avatar.isNotEmpty) ? base64Decode(avatar) : _avatarBytes;
        _bannerBytes = (banner != null && banner.isNotEmpty) ? base64Decode(banner) : _bannerBytes;
      });
    } else {
      setState(() {
        _avatarPath = prefs.getString('profile_avatar') ?? _avatarPath;
        _bannerPath = prefs.getString('profile_banner') ?? _bannerPath;
      });
    }
    if (_reduceMotion) {
      _haloCtrl.stop();
    } else if (!_haloCtrl.isAnimating) {
      _haloCtrl.repeat();
    }
  }

  void _startStatusTicker() {
    _statusTicker?.cancel();
    if (_statusNoteExpires == null) return;
    _statusTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_statusNoteExpires != null && DateTime.now().isAfter(_statusNoteExpires!)) {
        setState(() => _statusNoteExpires = null);
        _statusTicker?.cancel();
      } else {
        setState(() {});
      }
    });
  }

  void _onNameChanged() {
    _markDirty();
    _nameDebounce?.cancel();
    _nameDebounce = Timer(const Duration(milliseconds: 300), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_name', _nameCtrl.text);
    });
  }

  void _onDescriptionChanged() {
    _markDirty();
    _descDebounce?.cancel();
    _descDebounce = Timer(const Duration(milliseconds: 400), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_description', _descCtrl.text);
    });
  }

  void _markDirty() {
    if (_dirty) {
      _scheduleAutoSave();
      return;
    }
    setState(() => _dirty = true);
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    if (_authToken == null) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _dirty && !_saving) {
        _saveProfileToServer(silent: true);
      }
    });
  }

  Future<void> _saveProfileToServer({bool silent = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = _authToken ?? prefs.getString('auth_token');
    if (token == null) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(I18n.t(context, 'not_authenticated'))));
      }
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final api = ApiService();
      final payload = <String, dynamic>{
        'full_name': _nameCtrl.text,
        'description': _descCtrl.text,
        'social_facebook': _facebook,
        'social_instagram': _instagram,
        'social_tiktok': _tiktok,
        'social_youtube': _youtube,
        'avatar_frame': _avatarFrame,
        'avatar_sticker': _avatarStickerAsset,
        if (_statusNote != null && _statusNote!.isNotEmpty) 'status_note': _statusNote,
        if (_statusNoteExpires != null) 'status_note_expires': _statusNoteExpires!.toIso8601String(),
        'status_note_color': _noteTextColor.value.toRadixString(16),
        'status_note_bg': _noteBgColor.value.toRadixString(16),
        if (_statusEmoji != null && _statusEmoji!.isNotEmpty) 'status_note_emoji': _statusEmoji,
        'halo_strength': _haloStrength,
        'reduce_motion': _reduceMotion,
      };

      final updated = await api.updateProfile(token, payload);

      await prefs.setString('profile_name', updated['full_name']?.toString() ?? _nameCtrl.text);
      await prefs.setString('profile_description', updated['description']?.toString() ?? _descCtrl.text);
      _persistString(prefs, 'profile_facebook', updated['social_facebook']);
      _persistString(prefs, 'profile_instagram', updated['social_instagram']);
      _persistString(prefs, 'profile_tiktok', updated['social_tiktok']);
      _persistString(prefs, 'profile_youtube', updated['social_youtube']);
      _persistString(prefs, 'profile_avatar_url', updated['avatar_url']);
      _persistString(prefs, 'profile_banner_url', updated['banner_url']);
      _persistString(prefs, 'profile_avatar_frame', updated['avatar_frame'] ?? _avatarFrame);
      _persistString(prefs, 'profile_avatar_sticker_asset', updated['avatar_sticker']);
      _persistString(prefs, 'profile_status_note', updated['status_note']);
      _persistString(prefs, 'profile_status_note_expires', updated['status_note_expires']);
      _persistString(prefs, 'profile_status_note_emoji', updated['status_note_emoji']);
      _persistString(prefs, 'profile_status_note_color', updated['status_note_color']);
      _persistString(prefs, 'profile_status_note_bg', updated['status_note_bg']);
      await prefs.setDouble('profile_halo_strength', _haloStrength);
      await prefs.setBool('profile_reduce_motion', _reduceMotion);

      if (!mounted) return;
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(I18n.t(context, 'profile_saved'))));
        HapticFeedback.mediumImpact();
      }
      setState(() => _dirty = false);
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${I18n.t(context, 'save_failed')}: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _persistString(SharedPreferences prefs, String key, dynamic value) {
    if (value == null || (value is String && value.isEmpty)) {
      prefs.remove(key);
    } else {
      prefs.setString(key, value.toString());
    }
  }

  Future<void> _saveAvatarFromXFile(XFile file) async {
    final prefs = await SharedPreferences.getInstance();
    final token = _authToken ?? prefs.getString('auth_token');

    Future<void> cacheLocally({Uint8List? bytes, String? path}) async {
      if (kIsWeb) {
        final data = bytes ?? await file.readAsBytes();
        await prefs.setString('profile_avatar_b64', base64Encode(data));
        setState(() {
          _avatarBytes = data;
          _avatarPath = null;
        });
      } else {
        final savedPath = path ?? file.path;
        await prefs.setString('profile_avatar', savedPath);
        setState(() {
          _avatarPath = savedPath;
          _avatarBytes = null;
        });
      }
    }

    if (token == null) {
      await cacheLocally();
      return;
    }

    try {
      final api = ApiService();
      String url;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        await cacheLocally(bytes: bytes);
        url = await api.uploadAvatarBytes(token, bytes, filename: file.name);
      } else {
        await cacheLocally(path: file.path);
        url = await api.uploadAvatarPath(token, file.path, filename: file.name);
      }
      await prefs.setString('profile_avatar_url', url);
      if (!mounted) return;
      setState(() => _avatarUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(I18n.t(context, 'avatar_updated'))));
      HapticFeedback.selectionClick();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${I18n.t(context, 'upload_error')}: $e')));
    }
  }

  Future<void> _saveBannerFromXFile(XFile file) async {
    final prefs = await SharedPreferences.getInstance();
    final token = _authToken ?? prefs.getString('auth_token');

    Future<void> cacheLocally({Uint8List? bytes, String? path}) async {
      if (kIsWeb) {
        final data = bytes ?? await file.readAsBytes();
        await prefs.setString('profile_banner_b64', base64Encode(data));
        setState(() {
          _bannerBytes = data;
          _bannerPath = null;
        });
      } else {
        final savedPath = path ?? file.path;
        await prefs.setString('profile_banner', savedPath);
        setState(() {
          _bannerPath = savedPath;
          _bannerBytes = null;
        });
      }
    }

    if (token == null) {
      await cacheLocally();
      return;
    }

    try {
      final api = ApiService();
      String url;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        await cacheLocally(bytes: bytes);
        url = await api.uploadBannerBytes(token, bytes, filename: file.name);
      } else {
        await cacheLocally(path: file.path);
        url = await api.uploadBannerPath(token, file.path, filename: file.name);
      }
      await prefs.setString('profile_banner_url', url);
      if (!mounted) return;
      setState(() => _bannerUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(I18n.t(context, 'banner_updated'))));
      HapticFeedback.selectionClick();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${I18n.t(context, 'upload_error')}: $e')));
    }
  }

  Future<void> _clearAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final token = _authToken ?? prefs.getString('auth_token');
    if (token != null) {
      try {
        await ApiService().deleteAvatar(token);
        await prefs.remove('profile_avatar_url');
        setState(() => _avatarUrl = null);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${I18n.t(context, 'avatar_delete_failed')}: $e')));
        }
      }
    }
    if (kIsWeb) {
      await prefs.remove('profile_avatar_b64');
      setState(() => _avatarBytes = null);
    } else {
      await prefs.remove('profile_avatar');
      setState(() => _avatarPath = null);
    }
  }

  Future<void> _clearBanner() async {
    final prefs = await SharedPreferences.getInstance();
    final token = _authToken ?? prefs.getString('auth_token');
    if (token != null) {
      try {
        await ApiService().deleteBanner(token);
        await prefs.remove('profile_banner_url');
        setState(() => _bannerUrl = null);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${I18n.t(context, 'banner_delete_failed')}: $e')));
        }
      }
    }
    if (kIsWeb) {
      await prefs.remove('profile_banner_b64');
      setState(() => _bannerBytes = null);
    } else {
      await prefs.remove('profile_banner');
      setState(() => _bannerPath = null);
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, maxWidth: 1200, maxHeight: 1200, imageQuality: 85);
      if (file != null) {
        await _saveAvatarFromXFile(file);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${I18n.t(context, 'image_load_error')}: $e')));
    }
  }

  Future<void> _pickBanner(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, maxWidth: 1920, maxHeight: 1080, imageQuality: 85);
      if (file != null) {
        await _saveBannerFromXFile(file);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Banner betöltése sikertelen: $e')));
    }
  }

  void _updateFrame(String style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_avatar_frame', style);
    setState(() => _avatarFrame = style);
    _markDirty();
  }

  void _setTempPreview(String? style) {
    setState(() => _frameTempPreview = style);
  }

  Future<void> _editStatusNote() async {
    final result = await Navigator.of(context).push(NoteEditorPage.route(
      initialText: _statusNote,
      textColor: _noteTextColor,
      backgroundColor: _noteBgColor,
      emoji: _statusEmoji,
    ));
    if (result == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (result.deleted) {
      setState(() {
        _statusNote = null;
        _statusNoteExpires = null;
        _statusEmoji = null;
      });
      await prefs.remove('profile_status_note');
      await prefs.remove('profile_status_note_expires');
      await prefs.remove('profile_status_note_emoji');
      _statusTicker?.cancel();
      _markDirty();
      return;
    }
    setState(() {
      _statusNote = result.text?.trim();
      _noteTextColor = result.textColor;
      _noteBgColor = result.backgroundColor;
      _statusEmoji = result.emoji;
      _statusNoteExpires = DateTime.now().add(const Duration(hours: 24));
    });
    await prefs.setString('profile_status_note', _statusNote ?? '');
    await prefs.setString('profile_status_note_expires', _statusNoteExpires!.toIso8601String());
    await prefs.setString('profile_status_note_color', _noteTextColor.value.toRadixString(16));
    await prefs.setString('profile_status_note_bg', _noteBgColor.value.toRadixString(16));
    if (_statusEmoji?.isNotEmpty == true) {
      await prefs.setString('profile_status_note_emoji', _statusEmoji!);
    } else {
      await prefs.remove('profile_status_note_emoji');
    }
    _startStatusTicker();
    _markDirty();
  }

  Future<void> _selectEmoji() async {
    final emoji = await NoteEditorPage.pickEmoji(context, selected: _statusEmoji);
    if (emoji == null) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() => _statusEmoji = emoji.isEmpty ? null : emoji);
    if (emoji.isEmpty) {
      await prefs.remove('profile_status_note_emoji');
    } else {
      await prefs.setString('profile_status_note_emoji', emoji);
    }
    _markDirty();
  }

  Future<void> _saveLink(String key, String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
    setState(() {
      switch (key) {
        case 'profile_facebook':
          _facebook = value;
          break;
        case 'profile_instagram':
          _instagram = value;
          break;
        case 'profile_tiktok':
          _tiktok = value;
          break;
        case 'profile_youtube':
          _youtube = value;
          break;
      }
    });
    _markDirty();
  }

  Future<void> _editLinkDialog(String title, String prefKey, String? current) async {
    final controller = TextEditingController(text: current ?? '');
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${I18n.t(context, 'edit')}: $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: I18n.t(context, 'link_hint')),
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(I18n.t(context, 'cancel'))),
          ElevatedButton(
            onPressed: () {
              final raw = controller.text.trim();
              final normalized = UiUtils.normalizeSocial(prefKey, raw);
              _saveLink(prefKey, normalized.isEmpty ? null : normalized);
              Navigator.pop(context);
              HapticFeedback.selectionClick();
            },
            child: Text(I18n.t(context, 'save')),
          ),
        ],
      ),
    );
  }

  Future<void> _openLink(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(I18n.t(context, 'missing_link'))));
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(I18n.t(context, 'invalid_url'))));
      return;
    }
    if (!await canLaunchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(I18n.t(context, 'cannot_launch'))));
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  ImageProvider? _currentAvatarImage() {
    ImageProvider? img;
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty && _avatarBytes == null && (_avatarPath == null || _avatarPath!.isEmpty)) {
      img = NetworkImage(UiUtils.normalizeUploadUrl(_avatarUrl!));
    }
    if (kIsWeb) {
      if (_avatarBytes != null && _avatarBytes!.isNotEmpty) {
        img = MemoryImage(_avatarBytes!);
      }
    } else {
      if (_avatarPath != null && _avatarPath!.isNotEmpty && File(_avatarPath!).existsSync()) {
        img = FileImage(File(_avatarPath!));
      }
    }
    return img;
  }

  ImageProvider? _currentBannerImage() {
    ImageProvider? img;
    if (_bannerUrl != null && _bannerUrl!.isNotEmpty && _bannerBytes == null && (_bannerPath == null || _bannerPath!.isEmpty)) {
      img = NetworkImage(UiUtils.normalizeUploadUrl(_bannerUrl!));
    }
    if (kIsWeb) {
      if (_bannerBytes != null && _bannerBytes!.isNotEmpty) {
        img = MemoryImage(_bannerBytes!);
      }
    } else {
      if (_bannerPath != null && _bannerPath!.isNotEmpty && File(_bannerPath!).existsSync()) {
        img = FileImage(File(_bannerPath!));
      }
    }
    return img;
  }

  double get _statusProgress {
    if (_statusNoteExpires == null) return 0;
    final end = _statusNoteExpires!;
    final start = end.subtract(const Duration(hours: 24));
    final now = DateTime.now();
    final total = end.difference(start).inMilliseconds.toDouble();
    final done = (now.isBefore(start) ? 0 : now.difference(start).inMilliseconds.toDouble()).clamp(0, total);
    return (total == 0) ? 0 : done / total;
  }

  List<Color> _colorsForFrame(String style) {
    switch (style) {
      case 'glow-emerald':
        return const [Color(0xFF00E676), Color(0xFF4CAF50)];
      case 'glow-azure':
        return const [Color(0xFF03A9F4), Color(0xFF00BCD4)];
      case 'glow-magenta':
        return const [Color(0xFFFF4081), Color(0xFFE040FB)];
      case 'neon-cyan':
        return const [Color(0xFF00E5FF), Color(0xFF18FFFF)];
      case 'neon-amber':
        return const [Color(0xFFFFEA00), Color(0xFFFFC400)];
      case 'outline-ice':
        return const [Color(0xFF90CAF9), Color(0xFFE3F2FD)];
      case 'outline-coral':
        return const [Color(0xFFFFAB91), Color(0xFFFF7043)];
      case 'ring-lime':
        return const [Color(0xFF76FF03), Color(0xFFB2FF59)];
      case 'ring-violet':
        return const [Color(0xFF7C4DFF), Color(0xFFB388FF)];
      case 'gradient-sunset':
        return const [Color(0xFFFF512F), Color(0xFFF09819)];
      case 'gradient-ocean':
        return const [Color(0xFF36D1DC), Color(0xFF5B86E5)];
      case 'gradient-aurora':
        return const [Color(0xFF00C9FF), Color(0xFF92FE9D)];
      case 'gradient-plasma':
        return const [Color(0xFF12C2E9), Color(0xFFC471ED), Color(0xFFF64F59)];
      case 'gradient-gold':
        return const [Color(0xFFFFD700), Color(0xFFFFB700)];
      case 'gradient-silver':
        return const [Color(0xFFBCC6CC), Color(0xFFE5E4E2)];
      case 'rainbow':
        return const [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.indigo, Colors.purple];
      default:
        final color = Theme.of(context).colorScheme.primary;
        return [color, color.withOpacity(0.5)];
    }
  }

  Future<void> _revertLocal() async {
    final prefs = await SharedPreferences.getInstance();
    _loadLocalSnapshot(prefs);
    setState(() => _dirty = false);
  }

  Color? _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final value = hex.replaceAll('#', '');
    if (value.length != 6 && value.length != 8) return null;
    try {
      final parsed = int.parse(value, radix: 16);
      if (value.length == 6) {
        return Color(int.parse('FF$value', radix: 16));
      }
      return Color(parsed);
    } catch (_) {
      return null;
    }
  }

  double _completeness() {
    int have = 0;
    const total = 4;
    if (_nameCtrl.text.trim().isNotEmpty) have++;
    if (_descCtrl.text.trim().isNotEmpty) have++;
    if (_currentAvatarImage() != null || (_avatarUrl ?? '').isNotEmpty) have++;
    if ((_facebook ?? '').isNotEmpty || (_instagram ?? '').isNotEmpty || (_tiktok ?? '').isNotEmpty || (_youtube ?? '').isNotEmpty) have++;
    return have / total;
  }

  Future<bool> _onBackPressed() async {
    if (!_dirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(I18n.t(context, 'unsaved_changes')),
        content: Text(I18n.t(context, 'leave_without_save')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(I18n.t(context, 'stay'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(I18n.t(context, 'leave'))),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final media = MediaQuery.of(context);
    final textScale = media.textScaleFactor.clamp(0.9, 1.2);

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: MediaQuery(
        data: media.copyWith(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          appBar: AppBar(
            title: Text(I18n.t(context, 'profile')),
          ),
          body: RefreshIndicator(
            onRefresh: _loadProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ProfileBannerCard(
                    image: _currentBannerImage(),
                    onPick: _pickBanner,
                    onDelete: _clearBanner,
                  ),
                  const SizedBox(height: 12),
                  AvatarHeader(
                    haloAnimation: _haloCtrl,
                    haloStrength: _haloStrength,
                    reduceMotion: _reduceMotion,
                    frameStyle: _frameTempPreview ?? _avatarFrame,
                    colorsForFrame: _colorsForFrame,
                    avatarRadius: media.size.width < 420 ? 48 : 64,
                    avatarImage: _currentAvatarImage(),
                    displayName: _nameCtrl.text.trim(),
                    statusNote: (_statusNoteExpires == null || DateTime.now().isBefore(_statusNoteExpires!)) ? _statusNote : null,
                    statusProgress: _statusProgress,
                    noteTextColor: _noteTextColor,
                    noteBgColor: _noteBgColor,
                    statusEmoji: _statusEmoji,
                    onAvatarTap: () => _showAvatarOptions(),
                    onEditStatus: _editStatusNote,
                    onPickEmoji: _selectEmoji,
                    onFrameSwipe: _cycleFrame,
                    onRandomizeFrame: _randomizeFrame,
                    stickerAsset: _avatarStickerAsset,
                  ),
                  const SizedBox(height: 16),
                  ProfileQuickActions(
                    onFramePicker: _openFramePicker,
                    onRandomize: _randomizeFrame,
                    onEditStatus: _editStatusNote,
                  ),
                  const SizedBox(height: 16),
                  CompletionCard(percent: _completeness()),
                  const SizedBox(height: 16),
                  _decoratedField(
                    child: TextField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: I18n.t(context, 'name'),
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _decoratedField(
                    child: TextField(
                      controller: _descCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: I18n.t(context, 'description'),
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(I18n.t(context, 'avatar_frame'), style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const SizedBox(height: 10),
                  FramePreviewStrip(
                    styles: _frameStyles,
                    selected: _avatarFrame,
                    image: _currentAvatarImage(),
                    name: _nameCtrl.text.trim(),
                    onSelected: _updateFrame,
                    colorsFor: _colorsForFrame,
                  ),
                  const SizedBox(height: 20),
                  HaloControlsCard(
                    haloStrength: _haloStrength,
                    reduceMotion: _reduceMotion,
                    onHaloChanged: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setDouble('profile_halo_strength', value);
                      setState(() => _haloStrength = value);
                      _markDirty();
                    },
                    onReduceMotionChanged: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('profile_reduce_motion', value);
                      setState(() => _reduceMotion = value);
                      if (value) {
                        _haloCtrl.stop();
                      } else if (!_haloCtrl.isAnimating) {
                        _haloCtrl.repeat();
                      }
                      _markDirty();
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildStickerPicker(),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(I18n.t(context, 'social_media'), style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const SizedBox(height: 10),
                  SocialButtonsRow(
                    facebook: _facebook,
                    instagram: _instagram,
                    tiktok: _tiktok,
                    youtube: _youtube,
                    onEdit: _editLinkDialog,
                    onOpen: _openLink,
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          bottomNavigationBar: ProfileSaveBar(
            visible: _dirty && _authToken != null,
            saving: _saving,
            onDiscard: _revertLocal,
            onSave: () => _saveProfileToServer(silent: false),
          ),
        ),
      ),
    );
  }

  Widget _decoratedField({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 12)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }

  Widget _buildStickerPicker() {
    return FutureBuilder<List<Sticker>>(
      future: StickerService().loadStickers(),
      builder: (context, snapshot) {
        _stickers = snapshot.data ?? _stickers;
        final stickers = _stickers;
        if (stickers.isEmpty) {
          return _decoratedField(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(I18n.t(context, 'no_stickers')),
            ),
          );
        }
        return _decoratedField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_emotions_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(I18n.t(context, 'sticker')),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final sticker in stickers)
                    GestureDetector(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final value = sticker.asset ?? sticker.url;
                        if (value == null) return;
                        await prefs.setString('profile_avatar_sticker_asset', value);
                        setState(() => _avatarStickerAsset = value);
                        _markDirty();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (_avatarStickerAsset == (sticker.asset ?? sticker.url))
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white24,
                            width: 1.6,
                          ),
                        ),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: sticker.asset != null
                              ? Image.asset('assets/stickers/${sticker.asset!}', fit: BoxFit.contain)
                              : Image.network(sticker.url!, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('profile_avatar_sticker_asset');
                      setState(() => _avatarStickerAsset = null);
                      _markDirty();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.close, size: 18),
                          const SizedBox(width: 6),
                          Text(I18n.t(context, 'remove')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _cycleFrame(int direction) {
    final index = _frameStyles.indexOf(_avatarFrame);
    if (index == -1) {
      _updateFrame(_frameStyles.first);
      return;
    }
    final next = (index + direction) % _frameStyles.length;
    final style = _frameStyles[(next + _frameStyles.length) % _frameStyles.length];
    _updateFrame(style);
  }

  void _randomizeFrame() {
    final frames = _frameStyles.where((element) => element != 'none').toList();
    frames.shuffle();
    if (frames.isNotEmpty) {
      _updateFrame(frames.first);
    }
  }

  Future<void> _openFramePicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FramePreviewSheet(
        categories: _frameCategories,
        current: _avatarFrame,
        styles: _frameStyles,
        colorsFor: _colorsForFrame,
        onPreviewStart: _setTempPreview,
        onPreviewEnd: () => _setTempPreview(null),
      ),
    );
    if (selected != null) {
      _updateFrame(selected);
    }
  }

  Future<void> _showAvatarOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(I18n.t(context, 'pick_from_gallery')),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(I18n.t(context, 'take_photo')),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar(ImageSource.camera);
              },
            ),
            if ((_avatarUrl ?? '').isNotEmpty || (_avatarBytes != null && _avatarBytes!.isNotEmpty) || (_avatarPath ?? '').isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(I18n.t(context, 'delete_avatar')),
                onTap: () {
                  Navigator.pop(context);
                  _clearAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class FramePreviewSheet extends StatefulWidget {
  const FramePreviewSheet({
    super.key,
    required this.styles,
    required this.current,
    required this.categories,
    required this.colorsFor,
    this.onPreviewStart,
    this.onPreviewEnd,
  });

  final List<String> styles;
  final String current;
  final Map<String, List<String>> categories;
  final List<Color> Function(String) colorsFor;
  final ValueChanged<String>? onPreviewStart;
  final VoidCallback? onPreviewEnd;

  @override
  State<FramePreviewSheet> createState() => _FramePreviewSheetState();
}

class _FramePreviewSheetState extends State<FramePreviewSheet> {
  String _category = 'All';
  String _query = '';

  List<String> get _filtered {
    Iterable<String> source = widget.styles;
    final prefixes = widget.categories[_category] ?? [];
    if (prefixes.isNotEmpty) {
      source = source.where((element) => prefixes.any((prefix) => element.startsWith(prefix)) || (prefixes.contains('rainbow') && element == 'rainbow'));
    }
    if (_query.isNotEmpty) {
      source = source.where((element) => element.toLowerCase().contains(_query.toLowerCase()));
    }
    return source.toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 30, offset: const Offset(0, -4)),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 46, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Icon(Icons.brush_outlined),
                  const SizedBox(width: 8),
                  Text(I18n.t(context, 'frame_picker'), style: theme.textTheme.titleMedium),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: I18n.t(context, 'search_frames'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final name = widget.categories.keys.elementAt(index);
                  return ChoiceChip(
                    label: Text(name),
                    selected: name == _category,
                    onSelected: (_) => setState(() => _category = name),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: widget.categories.length,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = () {
                    final width = constraints.maxWidth;
                    if (width < 360) return 3;
                    if (width < 520) return 4;
                    if (width < 760) return 5;
                    return 6;
                  }();
                  return GridView.builder(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final style = _filtered[index];
                      final selected = widget.current == style;
                      return GestureDetector(
                        onTap: () => Navigator.pop(context, style),
                        onLongPressStart: (_) => widget.onPreviewStart?.call(style),
                        onLongPressEnd: (_) => widget.onPreviewEnd?.call(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected ? theme.colorScheme.primary : Colors.white.withOpacity(0.08),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: CustomPaint(
                                  painter: _FrameSwatchPainter(colors: widget.colorsFor(style)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(style, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrameSwatchPainter extends CustomPainter {
  const _FrameSwatchPainter({required this.colors});
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final stroke = math.max(6.0, radius * 0.28);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final shader = SweepGradient(colors: [...colors, colors.first]).createShader(rect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..shader = shader
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawArc(rect, 0, math.pi * 2, false, paint);
  }

  @override
  bool shouldRepaint(covariant _FrameSwatchPainter oldDelegate) => oldDelegate.colors != colors;
}
