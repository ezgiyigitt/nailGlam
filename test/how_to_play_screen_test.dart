import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/view/how_to_play_screen.dart';

void main() {
  testWidgets('how to play shows short skippable pages', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: HowToPlayScreen()));
    await tester.pumpAndSettle();

    expect(find.text('HOW TO PLAY'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Wash'), findsOneWidget);
    expect(find.text('Wash the hand first.'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.byKey(const Key('how-to-play-pager')), findsOneWidget);

    await tester.tap(find.byKey(const Key('how-to-play-next')));
    await tester.pumpAndSettle();
    expect(find.text('Clean'), findsOneWidget);
    expect(find.text('Spray, then wipe each nail.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('how-to-play-next')));
    await tester.pumpAndSettle();
    expect(find.text('Clip'), findsOneWidget);

    await tester.tap(find.byKey(const Key('how-to-play-next')));
    await tester.pumpAndSettle();
    expect(find.text('Polish'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
    expect(find.byKey(const Key('how-to-play-got-it')), findsOneWidget);
  });
}
