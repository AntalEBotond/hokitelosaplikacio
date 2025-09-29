import 'package:flutter/material.dart';

class NoteEditorResult {
  const NoteEditorResult({
    required this.text,
    required this.textColor,
    required this.backgroundColor,
    required this.emoji,
    this.deleted = false,
  });

  final String? text;
  final Color textColor;
  final Color backgroundColor;
  final String? emoji;
  final bool deleted;
}

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({
    super.key,
    this.initialText,
    required this.textColor,
    required this.backgroundColor,
    this.emoji,
  });

  final String? initialText;
  final Color textColor;
  final Color backgroundColor;
  final String? emoji;

  static Route<NoteEditorResult?> route({
    String? initialText,
    required Color textColor,
    required Color backgroundColor,
    String? emoji,
  }) {
    return MaterialPageRoute<NoteEditorResult?>(
      fullscreenDialog: true,
      builder: (_) => NoteEditorPage(
        initialText: initialText,
        textColor: textColor,
        backgroundColor: backgroundColor,
        emoji: emoji,
      ),
    );
  }

  static Future<String?> pickEmoji(BuildContext context, {String? selected}) async {
    const options = ['😀', '😎', '🔥', '🌈', '💡', '💜', '🚀', '💬', ''];
    return showModalBottomSheet<String?>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            for (final emoji in options)
              ListTile(
                leading: Text(emoji.isEmpty ? '🚫' : emoji, style: const TextStyle(fontSize: 22)),
                title: Text(emoji.isEmpty ? 'Eltávolítás' : 'Válaszd: $emoji'),
                trailing: emoji == selected ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, emoji),
              ),
          ],
        ),
      ),
    );
  }

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late TextEditingController _controller;
  late Color _textColor;
  late Color _backgroundColor;
  String? _emoji;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _textColor = widget.textColor;
    _backgroundColor = widget.backgroundColor;
    _emoji = widget.emoji;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Státusz jegyzet'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              NoteEditorResult(
                text: null,
                textColor: _textColor,
                backgroundColor: _backgroundColor,
                emoji: _emoji,
                deleted: true,
              ),
            ),
            child: const Text('Törlés'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              NoteEditorResult(
                text: _controller.text,
                textColor: _textColor,
                backgroundColor: _backgroundColor,
                emoji: _emoji,
              ),
            ),
            child: const Text('Mentés'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              maxLength: 120,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Mit mondjunk?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text('Színek', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _colorButton(
                    context: context,
                    color: _textColor,
                    label: 'Szöveg',
                    onTap: () => _pickColor(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _colorButton(
                    context: context,
                    color: _backgroundColor,
                    label: 'Háttér',
                    onTap: () => _pickColor(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: () async {
                final emoji = await NoteEditorPage.pickEmoji(context, selected: _emoji);
                if (!mounted) return;
                setState(() => _emoji = emoji);
              },
              icon: const Icon(Icons.emoji_emotions_outlined),
              label: Text(_emoji?.isNotEmpty == true ? 'Emoji: $_emoji' : 'Emoji választása'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorButton({required BuildContext context, required Color color, required String label, required VoidCallback onTap}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 22, height: 22, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white24))),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _pickColor(bool text) async {
    final color = await showDialog<Color?>(
      context: context,
      builder: (context) => _ColorPickerDialog(initial: text ? _textColor : _backgroundColor),
    );
    if (color == null) return;
    setState(() {
      if (text) {
        _textColor = color;
      } else {
        _backgroundColor = color;
      }
    });
  }
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initial});
  final Color initial;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Szín választása'),
      content: SizedBox(
        width: 260,
        height: 220,
        child: Column(
          children: [
            Expanded(
              child: ColorPickerSlider(
                value: _hsv,
                onChanged: (value) => setState(() => _hsv = value),
              ),
            ),
            const SizedBox(height: 16),
            Text('HEX: #${_hsv.toColor().value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
        FilledButton(onPressed: () => Navigator.pop(context, _hsv.toColor()), child: const Text('OK')),
      ],
    );
  }
}

class ColorPickerSlider extends StatelessWidget {
  const ColorPickerSlider({super.key, required this.value, required this.onChanged});

  final HSVColor value;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(colors: [Colors.red, Colors.yellow, Colors.green, Colors.cyan, Colors.blue, Colors.purple, Colors.red]).createShader(rect),
            child: Slider(
              value: value.hue,
              min: 0,
              max: 360,
              onChanged: (hue) => onChanged(value.withHue(hue)),
            ),
          ),
        ),
        Slider(
          value: value.saturation,
          onChanged: (s) => onChanged(value.withSaturation(s)),
        ),
        Slider(
          value: value.value,
          onChanged: (v) => onChanged(value.withValue(v)),
        ),
      ],
    );
  }
}
