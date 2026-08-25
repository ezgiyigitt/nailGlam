import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/view/how_to_play_screen.dart';

void main() {
  testWidgets('how to play autoplays wash, spray, wipe, then clip', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: HowToPlayScreen()));
    await tester.pump();

    expect(find.text('HOW TO PLAY'), findsOneWidget);
    expect(find.text('Wash first.'), findsOneWidget);
    expect(find.byKey(const Key('how-to-play-stage')), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 4100));
    expect(find.text('Spray the nail.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 4000));
    expect(find.text('Wipe it clean.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 4000));
    expect(find.text('Then clip.'), findsOneWidget);
  });
}
