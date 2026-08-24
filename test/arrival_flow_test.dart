import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/game/components/customer_component.dart';
import 'package:nail_glam/game/config/asset_paths.dart';
import 'package:nail_glam/game/config/game_config.dart';
import 'package:nail_glam/game/nail_glam_game.dart';
import 'package:nail_glam/game/placeholder_art.dart';
import 'package:nail_glam/ui/arrival_complete_overlay.dart';
import 'package:nail_glam/ui/arrival_controls_overlay.dart';
import 'package:nail_glam/ui/customer_thought_bubble_overlay.dart';
import 'package:nail_glam/ui/home_overlay.dart';
import 'package:nail_glam/ui/nail_care_overlay.dart';

/// Drives the real arrival sequence frame by frame and measures the things
/// that are easy to get wrong and hard to spot by eye: the customer skating
/// above or below the floor, and her feet jumping when one animation hands
/// over to the next.
void main() {
  testWidgets(
    'customer walks in, sits, and the camera moves to the workspace',
    (WidgetTester tester) async {
      final game = NailGlamGame();

      // Decoding PNGs needs real async I/O, which cannot happen while the test
      // is pumping frames. Warming the cache first means the game's onLoad
      // resolves straight from memory once the widget is mounted.
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
      expect(game.isLoaded, isTrue, reason: 'game never finished loading');

      game.startArrival();

      const frame = Duration(milliseconds: 16);
      const band = GameConfig.customerBobAmplitude + 1;

      double? previousBase;
      double largestBaseStep = 0;
      var sawWalking = false;
      var sawTurning = false;
      var sawSitting = false;
      var sawSeatedIdle = false;
      var sittingEntries = 0;
      CustomerPhase? previousPhase;
      double? lockedSeatX;
      double? lockedSeatY;
      var completedDialogue = false;

      for (var i = 0; i < 1200; i++) {
        await tester.pump(frame);

        final customer = game.scene.customer;
        if (customer.phase == CustomerPhase.offstage) {
          continue;
        }

        sawWalking |= customer.phase == CustomerPhase.walking;
        sawTurning |= customer.phase == CustomerPhase.turning;
        sawSitting |= customer.phase == CustomerPhase.sitting;
        sawSeatedIdle |= customer.phase == CustomerPhase.seatedIdle;

        if (customer.phase == CustomerPhase.sitting &&
            previousPhase != CustomerPhase.sitting) {
          sittingEntries++;
        }
        previousPhase = customer.phase;

        if (customer.phase == CustomerPhase.turning ||
            customer.phase == CustomerPhase.sitting ||
            customer.phase == CustomerPhase.seatedIdle ||
            customer.phase == CustomerPhase.handsToTable) {
          lockedSeatX ??= customer.position.x;
          expect(
            customer.position.x,
            closeTo(lockedSeatX, 0.001),
            reason: 'world x moved after the sit transition on frame $i',
          );
        }
        if (customer.phase == CustomerPhase.sitting ||
            customer.phase == CustomerPhase.seatedIdle ||
            customer.phase == CustomerPhase.handsToTable) {
          lockedSeatY ??= customer.position.y;
          expect(
            customer.position.y,
            closeTo(lockedSeatY, 0.001),
            reason: 'world y moved after the sit transition on frame $i',
          );
        }

        if (customer.phase == CustomerPhase.seatedIdle && !completedDialogue) {
          expect(find.byKey(const Key('guest-nameplate')), findsOneWidget);
          expect(find.text('Lila'), findsOneWidget);
          completedDialogue = true;
          game.completeCustomerDialogue();
        }

        final base = customer.baseY;

        expect(
          base,
          inInclusiveRange(
            GameConfig.customerBottomY - band,
            GameConfig.customerBottomY + GameConfig.customerSitDrop + band,
          ),
          reason: 'she left the walk line on frame $i',
        );

        if (previousBase != null &&
            customer.phase == CustomerPhase.walking) {
          final step = (base - previousBase).abs();
          if (step > largestBaseStep) {
            largestBaseStep = step;
          }
        }
        previousBase = base;

        if (game.phase == GamePhase.workspace) {
          break;
        }
      }

      // Workspace is a hard page cut; wait until the manicure HUD is up.
      for (var i = 0; i < 800; i++) {
        await tester.pump(frame);
        expect(
          game.scene.customer.position.x,
          closeTo(GameConfig.customerSeatX, 0.001),
          reason: 'seated idle changed world x',
        );
        expect(
          game.scene.customer.position.y,
          closeTo(
            GameConfig.customerTopY + GameConfig.customerSitDrop,
            0.001,
          ),
          reason: 'seated idle changed world y',
        );
        if (game.overlays.isActive(NailCareOverlay.id) &&
            game.scene.workspace.isRevealed) {
          break;
        }
      }

      expect(sawWalking, isTrue, reason: 'she never started walking in');
      expect(sawTurning, isTrue, reason: 'she never turned towards the desk');
      expect(sawSitting, isTrue, reason: 'the sit beat never played');
      expect(sawSeatedIdle, isTrue, reason: 'seated idle never started');
      expect(sittingEntries, 1, reason: 'sit beat started more than once');
      expect(game.phase, GamePhase.workspace);
      expect(game.scene.customer.phase, CustomerPhase.handsToTable);
      expect(
        game.scene.customer.priority,
        GameConfig.priorityCustomer,
        reason: 'body must stay behind the manicure table',
      );
      expect(
        game.scene.customer.position.x,
        closeTo(GameConfig.customerSeatX, 0.5),
        reason: 'seat must stay on the table knee well',
      );

      // Only the walk bob moves her vertically; a much larger step means a
      // sprite swap teleported her.
      expect(
        largestBaseStep,
        lessThan(6.0),
        reason: 'she jumped between frames',
      );

      expect(
        game.scene.workspace.isRevealed,
        isTrue,
        reason: 'nail-care page never opened',
      );
      expect(
        game.camera.viewfinder.position.x,
        closeTo(GameConfig.cameraNailcareFocus.x, 8),
        reason: 'camera never finished the forward dolly',
      );
      expect(
        game.camera.viewfinder.zoom,
        closeTo(GameConfig.cameraNailcareZoom, 0.02),
        reason: 'camera never settled on the nail-care framing',
      );
      expect(
        game.overlays.isActive(NailCareOverlay.id),
        isTrue,
        reason: 'nail-care page never opened after the hand close-up',
      );
    },
  );

  testWidgets(
    'replaying arrival resumes the walk animation loop',
    (WidgetTester tester) async {
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

      // First arrival through seated idle (hands finish and stop playing).
      game.startArrival();
      const frame = Duration(milliseconds: 16);
      for (var i = 0; i < 1200; i++) {
        await tester.pump(frame);
        if (game.scene.customer.phase == CustomerPhase.seatedIdle) {
          break;
        }
      }
      expect(game.scene.customer.phase, CustomerPhase.seatedIdle);
      expect(
        game.scene.customer.position.x,
        closeTo(GameConfig.customerSeatX, 0.001),
      );

      // Second arrival must restart from off-screen and walk in again.
      game.startArrival();
      expect(game.scene.customer.phase, CustomerPhase.walking);
      expect(
        game.scene.customer.position.x,
        closeTo(GameConfig.customerEntryX, 0.001),
        reason: 'replay did not send her back to the start',
      );

      var sawForwardTravel = false;
      var previousX = game.scene.customer.position.x;
      for (var i = 0; i < 200; i++) {
        await tester.pump(frame);
        final customer = game.scene.customer;
        if (customer.phase != CustomerPhase.walking) {
          continue;
        }
        if (customer.position.x > previousX + 0.01) {
          sawForwardTravel = true;
          break;
        }
        previousX = customer.position.x;
      }
      expect(
        sawForwardTravel,
        isTrue,
        reason: 'second arrival never moved towards the desk',
      );
    },
  );
}
