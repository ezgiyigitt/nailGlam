import 'dart:io';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/view/components/customer_component.dart';
import 'package:nail_glam/model/asset_paths.dart';
import 'package:nail_glam/controller/home_controller.dart';
import 'package:nail_glam/controller/nail_glam_game.dart';
import 'package:nail_glam/model/placeholder_art.dart';
import 'package:nail_glam/view/arrival_complete_overlay.dart';
import 'package:nail_glam/view/arrival_controls_overlay.dart';
import 'package:nail_glam/view/care_target_choice_overlay.dart';
import 'package:nail_glam/view/customer_thought_bubble_overlay.dart';
import 'package:nail_glam/view/home_overlay.dart';
import 'package:nail_glam/view/nail_care_overlay.dart';

/// Development helper: renders key beats of the arrival to PNGs so the scene
/// composition can be eyeballed without launching a device.
void main() {
  testWidgets('capture home menu', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const boundaryKey = Key('home-capture');
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: boundaryKey,
          child: HomeOverlay(controller: HomeController.testing(onStart: () {})),
        ),
      ),
    );
    await tester.runAsync(() async {
      final context = tester.element(find.byKey(boundaryKey));
      await precacheImage(
        AssetImage('assets/images/${AssetPaths.menuBackground}'),
        context,
      );
      await precacheImage(
        AssetImage('assets/images/${AssetPaths.menuLogo}'),
        context,
      );
      await precacheImage(
        AssetImage('assets/images/${AssetPaths.menuStart}'),
        context,
      );
      await precacheImage(
        AssetImage('assets/images/${AssetPaths.menuHowToPlay}'),
        context,
      );
    });
    await tester.pumpAndSettle();

    final boundary =
        tester.renderObject(find.byKey(boundaryKey)) as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ImageByteFormat.png);
      Directory('build/screens').createSync(recursive: true);
      File('build/screens/00_home.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });

  testWidgets('capture arrival beats', (WidgetTester tester) async {
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
                          guest: game.guest,
                        ),
                NailCareOverlay.id: (BuildContext context, NailGlamGame game) =>
                    NailCareOverlay(game: game),
                CareTargetChoiceOverlay.id:
                    (BuildContext context, NailGlamGame game) =>
                        CareTargetChoiceOverlay(
                          onChooseHand: game.chooseHandCare,
                          onChooseFoot: game.chooseFootCare,
                        ),
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

    // Fading in at the back of the room.
    for (var i = 0; i < 30; i++) {
      await tester.pump(frame);
    }
    await capture('01_entering');

    // Mid approach: bigger, closer, still short of the desk.
    for (var i = 0; i < 60; i++) {
      await tester.pump(frame);
    }
    await capture('02_approaching');

    // Pivoting from profile towards the desk.
    while (game.scene.customer.phase == CustomerPhase.walking) {
      await tester.pump(frame);
    }
    await capture('03_turning');

    // Seated idle before the camera moves.
    while (game.scene.customer.phase != CustomerPhase.seatedIdle) {
      await tester.pump(frame);
    }
    await capture('04_seated');

    // Second arrival must replay the approach from the back of the room.
    game.startArrival();
    for (var i = 0; i < 40; i++) {
      await tester.pump(frame);
    }
    expect(game.scene.customer.phase, CustomerPhase.walking);
    await capture('06_replay_walking');

    // Resume the seating path for the remaining captures.
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

  testWidgets('capture nail-care hud', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final game = NailGlamGame();
    await tester.runAsync(() async {
      await game.images.loadAll(AssetPaths.all);
      await PlaceholderArt.primeCache(game.images);
    });

    const boundaryKey = Key('workspace-hud-capture');
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: boundaryKey,
          child: GameWidget<NailGlamGame>(
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
                  NailCareOverlay.id:
                      (BuildContext context, NailGlamGame game) =>
                          NailCareOverlay(game: game),
                  CareTargetChoiceOverlay.id:
                      (BuildContext context, NailGlamGame game) =>
                          CareTargetChoiceOverlay(
                            onChooseHand: game.chooseHandCare,
                            onChooseFoot: game.chooseFootCare,
                          ),
                },
          ),
        ),
      ),
    );
    for (var i = 0; i < 5 && !game.isLoaded; i++) {
      await tester.pump();
    }

    game.debugOpenNailCare();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    Future<void> saveHud(String name) async {
      final boundary =
          tester.renderObject(find.byKey(boundaryKey)) as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ImageByteFormat.png);
        Directory('build/screens').createSync(recursive: true);
        File('build/screens/$name.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }

    await saveHud('07_nail_care_hud');

    game.scene.workspace.showPinkyNail();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await saveHud('08_pinky_closeup');
  });
}
