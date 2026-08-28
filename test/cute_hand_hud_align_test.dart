import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/model/nail_care_tools.dart';
import 'package:nail_glam/view/cute_hand_sim.dart';

void main() {
  test('contain dest letterboxes the tall light hand horizontally', () {
    const paint = Size(124, 122);
    final dest = CuteHandSimCard.handDestForTest(paint);

    expect(dest.height, closeTo(122, 0.01));
    expect(dest.width, lessThan(80));
    expect(dest.left, greaterThan(20));
    expect(dest.right, lessThan(104));
  });

  test('pinky hit center maps onto the drawn hand, not the gutter', () {
    const paint = Size(124, 122);
    final dest = CuteHandSimCard.handDestForTest(paint);
    // Same normalized pinky center used by the HUD hit map.
    const pinky = Offset(0.062, 0.801);

    final buggyX = pinky.dx * paint.width;
    expect(buggyX, lessThan(dest.left));

    final fixedX = dest.left + pinky.dx * dest.width;
    final fixedY = dest.top + pinky.dy * dest.height;
    expect(fixedX, inInclusiveRange(dest.left + 2, dest.right - 2));
    expect(fixedY, inInclusiveRange(dest.top + 2, dest.bottom - 2));
  });

  testWidgets('badge shows done / total for shared hand HUD', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CuteHandSimCard(
            done: 2,
            total: 5,
            snapshots: const <NailDigit, DigitSimSnapshot>{
              NailDigit.pinky: DigitSimSnapshot(
                cleanProgress: 1,
                cutFrame: 3,
                polishColor: 0xFFD0123A,
              ),
              NailDigit.ring: DigitSimSnapshot(
                cleanProgress: 1,
                cutFrame: 3,
                polishColor: 0xFFE8A0B8,
              ),
            },
            activeDigit: NailDigit.middle,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('2 / 5'), findsOneWidget);
    expect(find.byKey(const Key('nail-care-finger-sim')), findsOneWidget);
  });
}
