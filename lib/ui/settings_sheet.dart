import 'package:flutter/material.dart';

import '../game/audio/game_audio.dart';

/// Music and sound as two independent toggles.
Future<void> showSettingsSheet({required BuildContext context}) {
  GameAudio.instance.tap();
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: const Color(0xCC3A1C28),
    builder: (BuildContext context) => SettingsDialog(
      onDone: () => Navigator.of(context).pop(),
    ),
  );
}

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({this.onDone, super.key});

  final VoidCallback? onDone;

  static const Color _pink = Color(0xFFE84F8F);
  static const Color _ink = Color(0xFF8A4B63);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF8FC),
      borderRadius: BorderRadius.circular(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 22),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF4B6C8), width: 3),
        ),
        child: ListenableBuilder(
          listenable: GameAudio.instance,
          builder: (BuildContext context, _) {
            final audio = GameAudio.instance;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _pink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Music and sound are separate.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 15,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 14),
                _AudioToggle(
                  key: const Key('settings-music'),
                  icon: audio.musicEnabled
                      ? Icons.music_note_rounded
                      : Icons.music_off_rounded,
                  label: 'Music',
                  value: audio.musicEnabled,
                  onPressed: audio.toggleMusic,
                ),
                const SizedBox(height: 8),
                _AudioToggle(
                  key: const Key('settings-sfx'),
                  icon: audio.sfxEnabled
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  label: 'Sound',
                  value: audio.sfxEnabled,
                  onPressed: audio.toggleSfx,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    final close = onDone;
                    if (close != null) {
                      close();
                      return;
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _pink,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      ),
    );
  }
}

class _AudioToggle extends StatelessWidget {
  const _AudioToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool value;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF0F5),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: <Widget>[
              Icon(icon, color: SettingsDialog._pink, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: SettingsDialog._ink,
                  ),
                ),
              ),
              Container(
                width: 64,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value
                      ? SettingsDialog._pink
                      : const Color(0xFFD7B4C2),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Text(
                  value ? 'ON' : 'OFF',
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
