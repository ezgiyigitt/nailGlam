import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/game/audio/game_audio.dart';

void main() {
  test('cues are silent no-ops until the real app starts audio', () {
    final audio = GameAudio.instance;
    expect(audio.isStarted, isFalse);
    expect(() => audio.tap(), returnsNormally);
    expect(() => audio.coin(), returnsNormally);
    expect(() => audio.success(), returnsNormally);
    expect(() => audio.locked(), returnsNormally);
    expect(() => audio.arrive(), returnsNormally);
    expect(() => audio.clip(), returnsNormally);
    expect(() => audio.startSoap(), returnsNormally);
    expect(() => audio.startSpray(), returnsNormally);
    expect(() => audio.startBuffer(), returnsNormally);
    expect(() => audio.startPolish(), returnsNormally);
    expect(() => audio.stopTool(), returnsNormally);
  });

  test('music and sound toggle independently', () async {
    final audio = GameAudio.instance;
    final music = audio.musicEnabled;
    final sfx = audio.sfxEnabled;

    await audio.toggleMusic();
    expect(audio.musicEnabled, isNot(music));
    expect(audio.sfxEnabled, sfx);

    await audio.toggleSfx();
    expect(audio.sfxEnabled, isNot(sfx));
    expect(audio.musicEnabled, isNot(music));

    await audio.toggleMusic();
    await audio.toggleSfx();
    expect(audio.musicEnabled, music);
    expect(audio.sfxEnabled, sfx);
  });

  test('playMusic is a no-op while music is off', () async {
    final audio = GameAudio.instance;
    final previous = audio.musicEnabled;
    audio.musicEnabled = false;
    await audio.playMusic();
    expect(audio.musicEnabled, isFalse);
    await audio.stopMusic();
    audio.musicEnabled = previous;
  });
}
