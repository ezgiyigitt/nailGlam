import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/controller/home_controller.dart';
import 'package:nail_glam/controller/nail_glam_game.dart';
import 'package:nail_glam/model/asset_paths.dart';
import 'package:nail_glam/model/customer_roster.dart';
import 'package:nail_glam/model/placeholder_art.dart';
import 'package:nail_glam/view/arrival_complete_overlay.dart';
import 'package:nail_glam/view/arrival_controls_overlay.dart';
import 'package:nail_glam/view/components/customer_component.dart';
import 'package:nail_glam/view/customer_thought_bubble_overlay.dart';
import 'package:nail_glam/view/home_overlay.dart';
import 'package:nail_glam/view/nail_care_overlay.dart';

void main() {
  test('Asta walk strip is a transparent 4-cell cycle', () async {
    final bytes = File(
      'assets/images/${AssetPaths.customer3Walk}',
    ).readAsBytesSync();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    expect(image.width, 1728);
    expect(image.height, 433);

    final data = await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    expect(data, isNotNull);
    final pixels = data!.buffer.asUint8List();
    expect(pixels[3], 0, reason: 'top-left must be transparent');
    expect(pixels[0], 0);
    expect(pixels[1], 0);
    expect(pixels[2], 0);
  });

  testWidgets('Asta walk visits every cell then sits without base jump', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final game = NailGlamGame();
    await tester.runAsync(() async {
      await game.images.loadAll(AssetPaths.all);
      await PlaceholderArt.primeCache(game.images);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: GameWidget<NailGlamGame>(
          game: game,
          overlayBuilderMap:
              <String, Widget Function(BuildContext, NailGlamGame)>{
                HomeOverlay.id: (BuildContext context, NailGlamGame game) =>
                    HomeOverlay(controller: HomeController.fromGame(game)),
                ArrivalCompleteOverlay.id:
                    (BuildContext context, NailGlamGame game) =>
                        ArrivalCompleteOverlay(onReplay: game.startArrival),
                ArrivalControlsOverlay.id:
                    (BuildContext context, NailGlamGame game) =>
                        ArrivalControlsOverlay(
                          onTogglePause: game.togglePause,
                          onHome: game.returnToHome,
                        ),
                CustomerThoughtBubbleOverlay.id:
                    (BuildContext context, NailGlamGame game) =>
                        CustomerThoughtBubbleOverlay(
                          onComplete: game.completeCustomerDialogue,
                          guest: game.guest,
                        ),
                NailCareOverlay.id: (BuildContext context, NailGlamGame game) =>
                    NailCareOverlay(game: game),
              },
        ),
      ),
    );
    for (var i = 0; i < 5 && !game.isLoaded; i++) {
      await tester.pump();
    }
    expect(game.isLoaded, isTrue);

    game.selectPreferredGuest(CustomerRoster.asta);
    game.startArrival();
    expect(game.guest.id, 'customer3');
    expect(game.guest.name, 'Asta');

    const frame = Duration(milliseconds: 16);
    for (var i = 0; i < 40; i++) {
      await tester.pump(frame);
    }
    expect(game.scene.customer.phase, CustomerPhase.walking);

    final outputDir = Directory('build/screens')..createSync(recursive: true);
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        game.render(canvas);
        final picture = recorder.endRecording();
        final image = await picture.toImage(1080, 1920);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('${outputDir.path}/$name.png').writeAsBytesSync(
          bytes!.buffer.asUint8List(),
        );
      });
    }

    final seen = <int>{};
    for (var i = 0; i < 4; i++) {
      final index = game.scene.customer.animationTicker?.currentIndex ?? -1;
      seen.add(index);
      await capture('asta_walk_$i');
      await tester.pump(const Duration(milliseconds: 150));
    }

    var sawSeated = false;
    double? prevSitY;
    double maxSitStep = 0;
    var sitTicks = 0;
    final sitIndices = <int>{};
    for (var i = 0; i < 500; i++) {
      await tester.pump(frame);
      final customer = game.scene.customer;
      final index = customer.animationTicker?.currentIndex;
      if (customer.phase == CustomerPhase.walking && index != null) {
        seen.add(index);
      }
      if (customer.phase == CustomerPhase.sitting) {
        sitTicks++;
        if (index != null) {
          sitIndices.add(index);
        }
        final y = customer.position.y;
        if (prevSitY != null) {
          final step = (y - prevSitY!).abs();
          if (step > maxSitStep) {
            maxSitStep = step;
          }
          expect(
            y + 1.0,
            greaterThanOrEqualTo(prevSitY!),
            reason: 'sit drop should ease downward, not jump up',
          );
          expect(
            step,
            lessThan(4.0),
            reason: 'sit must ease; no hard snap per tick',
          );
        }
        prevSitY = y;
      }
      sawSeated |= customer.isSeated;
      if (sawSeated &&
          seen.containsAll(<int>[0, 1, 2, 3]) &&
          sitIndices.length >= 3) {
        break;
      }
    }
    if (sawSeated) {
      await capture('asta_sit');
    }

    expect(seen, containsAll(<int>[0, 1, 2, 3]));
    expect(sawSeated, isTrue);
    expect(
      sitIndices.length,
      greaterThanOrEqualTo(3),
      reason: 'sit strip must advance through multiple settle poses',
    );
    expect(
      sitTicks,
      greaterThanOrEqualTo(60),
      reason: 'sit phase should last ~1s+ at 16ms ticks (slow settle)',
    );
    expect(maxSitStep, lessThan(4.0));
  });
}
