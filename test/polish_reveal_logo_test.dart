import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/model/asset_paths.dart';
import 'package:nail_glam/view/polish_reveal_logo.dart';

void main() {
  Widget host({bool reduceMotion = false}) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 300,
            height: 200,
            child: PolishRevealLogo(
              asset: 'assets/images/${AssetPaths.menuLogo}',
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('the logo paints itself in and then stops animating', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(host());

    // Mid-sequence the widget is still being driven...
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.hasRunningAnimations, isTrue);

    // ...and once the stroke and the gloss are done it settles, so an idle
    // menu is not repainting every frame.
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.byType(PolishRevealLogo), findsOneWidget);
  });

  testWidgets('reduce motion shows the finished logo without animating', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(host(reduceMotion: true));

    // No frames are scheduled at all: the sequence jumps straight to the end.
    expect(tester.hasRunningAnimations, isFalse);

    await tester.tap(find.byType(PolishRevealLogo), warnIfMissed: false);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('tapping the settled logo repaints it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PolishRevealLogo), warnIfMissed: false);
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });
}
