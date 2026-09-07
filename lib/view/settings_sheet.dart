import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import 'package:nail_glam/controller/game_audio.dart';
import 'package:nail_glam/controller/player_progress_controller.dart';

/// Music and sound as two independent toggles.
///
/// [progress] is only used by the debug day-skipper, so it stays optional:
/// call sites that have no wallet to hand still work.
Future<void> showSettingsSheet({
  required BuildContext context,
  PlayerProgressController? progress,
}) {
  GameAudio.instance.tap();
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: const Color(0xCC3A1C28),
    builder: (BuildContext context) => SettingsDialog(
      progress: progress,
      onDone: () => Navigator.of(context).pop(),
    ),
  );
}

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({this.onDone, this.progress, super.key});

  final VoidCallback? onDone;

  /// Wallet behind the debug day-skipper. Null hides that row entirely.
  final PlayerProgressController? progress;

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
                if (kDebugMode && progress != null) ...<Widget>[
                  const SizedBox(height: 14),
                  _DebugDaySkipper(progress: progress!),
                ],
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

/// Debug-only: walk the daily-login streak forward a day at a time.
///
/// The streak only grows when the previous login was literally yesterday, so
/// without this the seven-day ladder takes seven real days to see — and on a
/// build whose stored prefs do not survive a restart it never leaves day 1.
/// Compiled out of release builds by the [kDebugMode] guard at the call site.
class _DebugDaySkipper extends StatelessWidget {
  const _DebugDaySkipper({required this.progress});

  final PlayerProgressController progress;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: progress,
      builder: (BuildContext context, _) {
        return Material(
          color: const Color(0xFFF3ECFF),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            key: const Key('settings-debug-next-day'),
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              progress.debugAdvanceOneDay();
              GameAudio.instance.tap();
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.fast_forward_rounded,
                    color: Color(0xFF6B4EA8),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Skip to tomorrow',
                          style: TextStyle(
                            fontFamily: 'Baloo2',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B4EA8),
                          ),
                        ),
                        Text(
                          'debug only  ·  streak day ${progress.loginStreak}'
                          '  ·  next ${progress.todayLoginReward} coins',
                          style: const TextStyle(
                            fontFamily: 'Baloo2',
                            fontSize: 12,
                            color: Color(0xFF8A7BB0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
