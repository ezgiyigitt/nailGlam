import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Menu music plus short tool / UI cues.
///
/// [start] is only called from the real app. Tests leave it off so controllers
/// can fire cues without touching the audio plugin.
class GameAudio extends ChangeNotifier {
  GameAudio._();

  static final GameAudio instance = GameAudio._();

  static const String _musicKey = 'audio.musicEnabled';
  static const String _sfxKey = 'audio.sfxEnabled';
  static const double _musicVolume = 0.38;

  bool _started = false;
  bool _userOverride = false;
  bool musicEnabled = true;
  bool sfxEnabled = true;
  int _musicEpoch = 0;

  AudioPlayer? _bgm;
  AudioPlayer? _loop;
  AudioPlayer? _shot;

  bool get isStarted => _started;

  Future<void> start() async {
    if (_started) {
      unawaited(playMusic());
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 2),
      );
      if (!_userOverride) {
        musicEnabled = prefs.getBool(_musicKey) ?? true;
        sfxEnabled = prefs.getBool(_sfxKey) ?? true;
      }
    } catch (_) {}
    try {
      _bgm = AudioPlayer(playerId: 'nailglam-bgm');
      _loop = AudioPlayer(playerId: 'nailglam-loop');
      _shot = AudioPlayer(playerId: 'nailglam-shot');
    } catch (_) {
      _bgm = null;
      _loop = null;
      _shot = null;
    }
    _started = true;
    notifyListeners();
    unawaited(playMusic());
  }

  Future<void> toggleMusic() async {
    _userOverride = true;
    musicEnabled = !musicEnabled;
    notifyListeners();
    if (musicEnabled) {
      await playMusic();
    } else {
      await stopMusic();
    }
    await _persist(_musicKey, musicEnabled);
  }

  Future<void> toggleSfx() async {
    _userOverride = true;
    sfxEnabled = !sfxEnabled;
    notifyListeners();
    if (!sfxEnabled) {
      await _silenceSfx();
    }
    await _persist(_sfxKey, sfxEnabled);
  }

  Future<void> _persist(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
  }

  Future<void> playMusic() async {
    if (!_started || !musicEnabled || _bgm == null) {
      return;
    }
    final epoch = _musicEpoch;
    bool cancelled() => !musicEnabled || epoch != _musicEpoch;
    try {
      if (cancelled()) {
        await _halt(_bgm);
        return;
      }
      await _bgm!.setReleaseMode(ReleaseMode.loop);
      if (cancelled()) {
        await _halt(_bgm);
        return;
      }
      await _bgm!.setVolume(_musicVolume);
      if (cancelled()) {
        await _halt(_bgm);
        return;
      }
      await _bgm!.play(
        AssetSource('audio/bgm_salon.wav'),
        volume: _musicVolume,
      );
    } catch (_) {}
    if (cancelled()) {
      await _halt(_bgm);
    }
  }

  Future<void> stopMusic() async {
    _musicEpoch++;
    await _halt(_bgm);
  }

  void tap() => _oneShot('sfx_tap.wav', volume: 0.55);
  void coin() => _oneShot('sfx_coin.wav', volume: 0.7);
  void success() => _oneShot('sfx_success.wav', volume: 0.7);
  void locked() => _oneShot('sfx_locked.wav', volume: 0.55);
  void arrive() => _oneShot('sfx_arrive.wav', volume: 0.6);
  void clip() => _oneShot('sfx_clip.wav', volume: 0.65);

  void startSoap() => _startLoop('sfx_soap.wav', volume: 0.45);
  void startSpray() => _startLoop('sfx_spray.wav', volume: 0.4);
  void startBuffer() => _startLoop('sfx_buffer.wav', volume: 0.4);
  void startPolish() => startBuffer();

  void stopTool() {
    unawaited(_halt(_loop));
  }

  Future<void> disposePlayers() async {
    await _silenceSfx();
    await stopMusic();
    await _bgm?.dispose();
    await _loop?.dispose();
    await _shot?.dispose();
    _bgm = null;
    _loop = null;
    _shot = null;
    _started = false;
  }

  void _startLoop(String file, {required double volume}) {
    if (!_started || !sfxEnabled) {
      return;
    }
    final player = _loop;
    if (player == null) {
      return;
    }
    unawaited(() async {
      try {
        await player.setReleaseMode(ReleaseMode.loop);
        await player.setVolume(volume);
        await player.play(AssetSource('audio/$file'), volume: volume);
      } catch (_) {}
      if (!sfxEnabled) {
        await _halt(player);
      }
    }());
  }

  void _oneShot(String file, {required double volume}) {
    if (!_started || !sfxEnabled || _shot == null) {
      return;
    }
    final player = _shot!;
    unawaited(() async {
      try {
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setVolume(volume);
        await player.play(AssetSource('audio/$file'), volume: volume);
      } catch (_) {}
      if (!sfxEnabled) {
        await _halt(player);
      }
    }());
  }

  Future<void> _silenceSfx() async {
    await _halt(_loop);
    await _halt(_shot);
  }

  Future<void> _halt(AudioPlayer? player) async {
    if (player == null) {
      return;
    }
    try {
      await player.setVolume(0);
    } catch (_) {}
    try {
      await player.setReleaseMode(ReleaseMode.stop);
    } catch (_) {}
    try {
      await player.pause();
    } catch (_) {}
    try {
      await player.stop();
    } catch (_) {}
  }
}
