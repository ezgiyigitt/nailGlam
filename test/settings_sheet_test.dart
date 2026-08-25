import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/controller/game_audio.dart';
import 'package:nail_glam/view/settings_sheet.dart';

void main() {
  testWidgets('settings keeps music and sound on separate switches', (
    WidgetTester tester,
  ) async {
    final audio = GameAudio.instance;
    audio.musicEnabled = true;
    audio.sfxEnabled = true;

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SettingsDialog())),
    );

    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Sound'), findsOneWidget);
    expect(find.byKey(const Key('settings-music')), findsOneWidget);
    expect(find.byKey(const Key('settings-sfx')), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-music')));
    await tester.pump();
    expect(audio.musicEnabled, isFalse);
    expect(audio.sfxEnabled, isTrue);

    await tester.tap(find.byKey(const Key('settings-sfx')));
    await tester.pump();
    expect(audio.musicEnabled, isFalse);
    expect(audio.sfxEnabled, isFalse);

    audio.musicEnabled = true;
    audio.sfxEnabled = true;
  });
}
