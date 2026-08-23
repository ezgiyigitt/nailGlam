import 'dart:io';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/game/components/customer_component.dart';
import 'package:nail_glam/game/config/asset_paths.dart';
import 'package:nail_glam/game/nail_glam_game.dart';
import 'package:nail_glam/ui/arrival_complete_overlay.dart';
import 'package:nail_glam/ui/arrival_controls_overlay.dart';
import 'package:nail_glam/ui/customer_thought_bubble_overlay.dart';
import 'package:nail_glam/ui/home_overlay.dart';
import 'package:nail_glam/ui/nail_care_overlay.dart';

/// Development helper: renders key beats of the arrival to PNGs so the scene
/// composition can be eyeballed without launching a device.
void main() {
  testWidgets('capture arrival beats', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final game = NailGlamGame();
    await tester.runAsync(() async {
      await game.images.loadAll(AssetPaths.all);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: GameWidget<NailGlamGame>(
          game: game,
          overlayBuilderMap:
              <String, Widget Function(BuildContext, NailGlamGame)>{
                HomeOverlay.id: (BuildContext context, NailGlamGame game) =>
                    HomeOverlay(onPlay: game.startArrival),
                ArrivalCompleteOverlay.id: (
                  BuildContext context,
                  NailGlamGame game,
                ) => ArrivalCompleteOverlay(onReplay: game.startArrival),
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

    final outputDir = Directory('build/screens')..createSync(recursive: true);
    const frame = Duration(milliseconds: 16);

    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        game.render(canvas);
        final picture = recorder.endRecording();
        final image = await picture.toImage(1080, 1920);
        final bytes = await image.toByteData(format: ImageByteFormat.png);
        File('${outputDir.path}/$name.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }

    game.startArrival();

    // Door swinging open with the customer fading in behind it.
    for (var i = 0; i < 30; i++) {
      await tester.pump(frame);
    }
    await capture('01_door_open');

    // Mid walk, door closing behind her, foreground plant should overlap.
    for (var i = 0; i < 70; i++) {
      await tester.pump(frame);
    }
    await capture('02_walking');

    // Extra walk samples so gait (contact/pass/contact/pass) can be eyeballed.
    for (var sample = 0; sample < 4; sample++) {
      for (var i = 0; i < 8; i++) {
        await tester.pump(frame);
      }
      if (game.scene.customer.phase != CustomerPhase.walking) {
        break;
      }
      await capture('02b_walk_$sample');
    }

    // Approaching the chair at full perspective scale.
    while (game.scene.customer.phase == CustomerPhase.walking) {
      await tester.pump(frame);
    }
    await capture('03_reaching_chair');

    // Seated idle before the camera moves.
    while (game.scene.customer.phase != CustomerPhase.seatedIdle) {
      await tester.pump(frame);
    }
    await capture('04_seated');

    // Second arrival must walk again (regression for playing=false bug).
    game.startArrival();
    for (var i = 0; i < 80; i++) {
      await tester.pump(frame);
    }
    expect(game.scene.customer.phase, CustomerPhase.walking);
    expect(game.scene.customer.playing, isTrue);
    await capture('06_replay_walking');

    // Resume first-run seating path for the remaining captures.
    while (game.scene.customer.phase == CustomerPhase.walking) {
      await tester.pump(frame);
    }
    while (game.scene.customer.phase != CustomerPhase.seatedIdle) {
      await tester.pump(frame);
    }

    // Camera settled on the workspace.
    game.completeCustomerDialogue();
    while (game.phase != GamePhase.workspace) {
      await tester.pump(frame);
    }
    for (var i = 0; i < 200; i++) {
      await tester.pump(frame);
    }
    await capture('05_workspace');
  });
}
