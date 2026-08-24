import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/ui/customer_thought_bubble_overlay.dart';

void main() {
  testWidgets('thought bubble advances one sentence per tap', (
    WidgetTester tester,
  ) async {
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: CustomerThoughtBubbleOverlay(onComplete: () => completed = true),
      ),
    );

    expect(find.byKey(const Key('guest-nameplate')), findsOneWidget);
    expect(find.text('GUEST'), findsOneWidget);
    expect(find.text('Lila'), findsOneWidget);

    const dialogue = <String>[
      "I'm ready for some glam! 💕",
      "First, let's clean my nails!",
      "Now let's smooth and shape them!",
      'Time for some beautiful color! ✨',
      "Let's make them fabulous! 💅",
    ];

    final bubble = find.byKey(const Key('customer-thought-bubble'));

    for (var i = 0; i < dialogue.length; i++) {
      expect(find.text(dialogue[i]), findsOneWidget);
      for (var hidden = 0; hidden < dialogue.length; hidden++) {
        if (hidden != i) {
          expect(find.text(dialogue[hidden]), findsNothing);
        }
      }

      await tester.tap(bubble);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 170));
    }

    expect(completed, isTrue);
  });
}
