import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/game/config/asset_paths.dart';
import 'package:nail_glam/game/nail_glam_game.dart';

void main() {
  testWidgets('Pixel 8 portrait fills the canvas without letterboxing', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final game = NailGlamGame();
    await tester.runAsync(() async {
      await game.images.loadAll(AssetPaths.all);
    });

    await tester.pumpWidget(
      MaterialApp(home: GameWidget<NailGlamGame>(game: game)),
    );
    for (var i = 0; i < 5 && !game.isLoaded; i++) {
      await tester.pump();
    }

    expect(game.isLoaded, isTrue);
    expect(game.camera.viewport.size.x, closeTo(1080, 0.1));
    expect(game.camera.viewport.size.y, closeTo(2400, 0.1));
    expect(game.camera.viewport.virtualSize.x, closeTo(1080, 0.1));
    expect(game.camera.viewport.virtualSize.y, closeTo(2400, 0.1));
  });
}
