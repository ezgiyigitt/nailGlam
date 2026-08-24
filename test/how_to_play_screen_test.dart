import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/ui/how_to_play_screen.dart';

void main() {
  testWidgets('how to play autoplays captions then skip closes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: HowToPlayScreen()),
    );
    await tester.pump();

    expect(find.text('HOW TO PLAY'), findsOneWidget);
    expect(find.text('She shows you the look.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 3600));
    expect(find.text('Wash first.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 3600));
    expect(find.text('One nail: spray, wipe, clip, polish.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 6400));
    expect(find.text('Match her color. Earn gold.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('how-to-play-skip')));
    await tester.pumpAndSettle();
    expect(find.byType(HowToPlayScreen), findsNothing);
  });

  testWidgets('got it closes how to play', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HowToPlayScreen()),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('how-to-play-got-it')));
    await tester.pumpAndSettle();
    expect(find.byType(HowToPlayScreen), findsNothing);
  });
}
