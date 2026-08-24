import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/game/config/asset_paths.dart';
import 'package:nail_glam/ui/cropped_asset.dart';
import 'package:nail_glam/ui/how_to_play_screen.dart';

Future<void> _readyDemo(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const MaterialApp(home: HowToPlayScreen()));
  await tester.pump();
  await tester.runAsync(() async {
    await Future.wait(<Future<void>>[
      AssetImageCache.load(AssetPaths.customerSit),
      AssetImageCache.load(AssetPaths.customerEmotion),
      AssetImageCache.load(AssetPaths.handWash),
      AssetImageCache.load(AssetPaths.handSoap),
      AssetImageCache.load(AssetPaths.fifthNailClean),
      AssetImageCache.load(AssetPaths.shortNail),
      AssetImageCache.load(AssetPaths.nailSpray),
      AssetImageCache.load(AssetPaths.nailBuffer),
      AssetImageCache.load(AssetPaths.nailClips),
      AssetImageCache.load(AssetPaths.polishBrush),
      AssetImageCache.load(AssetPaths.polishBlush),
      AssetImageCache.load(AssetPaths.manicurePillowTop),
    ]);
  });
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('how to play autoplays captions with painted sprites', (
    WidgetTester tester,
  ) async {
    await _readyDemo(tester);

    expect(find.text('HOW TO PLAY'), findsOneWidget);
    expect(find.text('She shows you the look.'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);

    final paints = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
    expect(
      paints.any(
        (CustomPaint paint) =>
            paint.size.width > 80 && paint.size.height > 80,
      ),
      isTrue,
    );

    await tester.pump(const Duration(milliseconds: 3600));
    expect(find.text('Wash first.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 3600));
    expect(find.text('One nail: spray, wipe, clip, polish.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 6400));
    expect(find.text('Match her color. Earn gold.'), findsOneWidget);
  });
}
