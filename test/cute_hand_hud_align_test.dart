import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/model/guest_care_kit.dart';
import 'package:nail_glam/model/nail_care_tools.dart';
import 'package:nail_glam/view/cute_hand_sim.dart';

void main() {
  CuteHandSimCard card(GuestHudHandArt art) => CuteHandSimCard(
    art: art,
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
  );

  test('contain dest letterboxes each hand by its own aspect', () {
    const paint = Size(124, 122);

    final light = card(GuestHudHandArt.light).handDestForTest(paint);
    final dark = card(GuestHudHandArt.dark).handDestForTest(paint);

    // Both hands are taller than the box, so height fills and width insets.
    expect(light.height, closeTo(122, 0.01));
    expect(dark.height, closeTo(122, 0.01));
    expect(light.width, closeTo(122 * GuestHudHandArt.light.aspect, 0.01));
    expect(dark.width, closeTo(122 * GuestHudHandArt.dark.aspect, 0.01));

    // The dark crop is the wider canvas, so it letterboxes less.
    expect(dark.width, greaterThan(light.width));
    expect(light.left, greaterThan(0));
    expect(dark.left, greaterThan(0));
  });

  test('every nail centre lands on the drawn hand, for both tones', () {
    const paint = Size(124, 122);

    for (final GuestHudHandArt art in <GuestHudHandArt>[
      GuestHudHandArt.light,
      GuestHudHandArt.dark,
    ]) {
      final dest = card(art).handDestForTest(paint);
      expect(art.nailCenters.length, 5);
      expect(art.nailMasks.length, 5);
      for (final MapEntry<NailDigit, Offset> entry
          in art.nailCenters.entries) {
        final double x = dest.left + entry.value.dx * dest.width;
        final double y = dest.top + entry.value.dy * dest.height;
        expect(
          x,
          inInclusiveRange(dest.left, dest.right),
          reason: '${entry.key} sits outside the drawn hand horizontally',
        );
        expect(
          y,
          inInclusiveRange(dest.top, dest.bottom),
          reason: '${entry.key} sits outside the drawn hand vertically',
        );
      }
    }
  });

  test('the two tones do not share a still or a pose', () {
    expect(
      GuestHudHandArt.dark.handAsset,
      isNot(GuestHudHandArt.light.handAsset),
    );
    // Light points its fingers up with the thumb left; dark is the mirror.
    expect(GuestHudHandArt.light.nailCenters[NailDigit.pinky]!.dx, greaterThan(0.5));
    expect(GuestHudHandArt.dark.nailCenters[NailDigit.pinky]!.dx, lessThan(0.5));
  });

  testWidgets('the card draws the art it was handed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: card(GuestHudHandArt.dark))),
    );
    await tester.pump();

    expect(find.text('2 / 5'), findsOneWidget);
    expect(find.byKey(const Key('nail-care-finger-sim')), findsOneWidget);

    final Iterable<String> assets = tester
        .widgetList<Image>(find.byType(Image))
        .map((Image image) => (image.image as AssetImage).assetName);
    expect(
      assets.any(
        (String name) => name.endsWith(GuestHudHandArt.dark.handAsset),
      ),
      isTrue,
      reason: 'the dark guest must be tracked on the dark hand',
    );
    expect(
      assets.any(
        (String name) => name.endsWith(GuestHudHandArt.light.handAsset),
      ),
      isFalse,
      reason: 'the light hand must not leak into a dark guest\'s HUD',
    );
  });
}
