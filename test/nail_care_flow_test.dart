import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/model/asset_paths.dart';
import 'package:nail_glam/model/customer_roster.dart';
import 'package:nail_glam/model/game_config.dart';
import 'package:nail_glam/model/nail_care_tools.dart';
import 'package:nail_glam/controller/home_controller.dart';
import 'package:nail_glam/controller/nail_glam_game.dart';
import 'package:nail_glam/model/placeholder_art.dart';
import 'package:nail_glam/view/arrival_complete_overlay.dart';
import 'package:nail_glam/view/arrival_controls_overlay.dart';
import 'package:nail_glam/view/cute_hand_sim.dart';
import 'package:nail_glam/view/customer_thought_bubble_overlay.dart';
import 'package:nail_glam/view/home_overlay.dart';
import 'package:nail_glam/view/nail_care_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('finished hand art is a required gameplay asset', () {
    expect(AssetPaths.finalHand, 'final_hand_01.png');
    expect(AssetPaths.all, contains(AssetPaths.finalHand));
  });

  test('catalog only enables the tool that matches the current stage', () {
    expect(
      NailCareCatalog.activeToolFor(NailCareStage.handCleaning)?.id,
      NailCareToolId.handSoap,
    );
    expect(
      NailCareCatalog.activeToolFor(NailCareStage.nailSpraying)?.id,
      NailCareToolId.nailSpray,
    );
    expect(
      NailCareCatalog.activeToolFor(NailCareStage.nailBuffering)?.id,
      NailCareToolId.nailBuffer,
    );
    expect(
      NailCareCatalog.activeToolFor(NailCareStage.nailCutting)?.id,
      NailCareToolId.nailClips,
    );
    expect(
      NailCareCatalog.activeToolFor(NailCareStage.nailPolishing)?.id,
      NailCareToolId.nailPolish,
    );
    expect(
      NailCareCatalog.toolById(NailCareToolId.nailSpray).iconPath,
      AssetPaths.nailSpray,
    );
    expect(
      NailCareCatalog.activeToolFor(NailCareStage.handCleaningCompleted),
      isNull,
    );
    expect(
      NailCareCatalog.toolById(NailCareToolId.handSoap).iconPath,
      AssetPaths.handSoap,
    );
    expect(
      NailCareCatalog.toolById(NailCareToolId.nailBuffer).iconPath,
      AssetPaths.nailBuffer,
    );
    expect(
      NailCareCatalog.toolById(NailCareToolId.nailBuffer).name,
      'Nail Wipe',
    );
    expect(
      NailCareCatalog.toolById(NailCareToolId.nailClips).iconPath,
      AssetPaths.nailClips,
    );
    expect(
      NailCareCatalog.toolById(NailCareToolId.nailPolish).iconPath,
      AssetPaths.polishBrush,
    );
    expect(
      NailCareCatalog.toolById(NailCareToolId.nailPolish).name,
      'Nail Brush',
    );
  });

  test('kits have eight slots with only the first item owned', () {
    expect(NailCareInventory.soaps, hasLength(GameConfig.nailCareInventorySlotCount));
    expect(NailCareInventory.buffers, hasLength(GameConfig.nailCareInventorySlotCount));
    expect(NailCareInventory.clips, hasLength(GameConfig.nailCareInventorySlotCount));
    expect(NailCareInventory.brushes, hasLength(GameConfig.nailCareInventorySlotCount));
    expect(NailCareInventory.polishes, hasLength(5));
    expect(
      NailCareInventory.polishes.every((item) => item.unlocked),
      isTrue,
    );
    expect(NailCareInventory.polishes.first.id, 'polish-blush');
    expect(NailCareInventory.soaps.first.unlocked, isTrue);
    expect(NailCareInventory.buffers.first.unlocked, isTrue);
    expect(NailCareInventory.clips.first.unlocked, isTrue);
    expect(NailCareInventory.brushes.first.unlocked, isTrue);
    expect(NailCareInventory.brushes.first.id, 'brush-0');
    expect(
      NailCareInventory.soaps.skip(1).every((item) => !item.unlocked),
      isTrue,
    );
    expect(
      NailCareInventory.buffers.skip(1).every((item) => !item.unlocked),
      isTrue,
    );
    expect(
      NailCareInventory.clips.skip(1).every((item) => !item.unlocked),
      isTrue,
    );
    expect(
      NailCareInventory.brushes.skip(1).every((item) => !item.unlocked),
      isTrue,
    );
    expect(NailCareInventory.soaps.first.iconPath, AssetPaths.handSoap);
    expect(NailCareInventory.soaps[1].iconPath, AssetPaths.toolSoap1);
    expect(NailCareInventory.soaps[1].unlockPrice, greaterThan(0));
    expect(
      NailCareInventory.buffers.first.iconPath,
      AssetPaths.nailBuffer,
    );
    expect(NailCareInventory.buffers[1].iconPath, AssetPaths.toolWipe1);
    expect(NailCareInventory.buffers[1].unlockPrice, greaterThan(0));
    expect(
      NailCareInventory.clips.every(
        (item) =>
            item.iconPath == AssetPaths.nailClips ||
            item.iconPath.startsWith('tool_clips_'),
      ),
      isTrue,
    );
    expect(
      NailCareInventory.brushes.every(
        (item) => item.iconPath == AssetPaths.polishBrush,
      ),
      isTrue,
    );
    expect(NailCareInventory.sprays, hasLength(5));
    expect(NailCareInventory.sprays.first.iconPath, AssetPaths.nailSpray);
    expect(NailCareInventory.sprays[1].iconPath, AssetPaths.toolSpray1);
    expect(NailCareInventory.sprays[1].unlockPrice, greaterThan(0));
    expect(NailCareInventory.clips[1].iconPath, AssetPaths.toolClips1);
    expect(NailCareInventory.clips[1].unlockPrice, greaterThan(0));
    expect(NailCareInventory.sprays.first.id, 'spray-0');
    expect(
      NailCareInventory.splitSprayAndWipe(NailCareStage.nailSpraying),
      isTrue,
    );
    expect(
      NailCareInventory.splitSprayAndWipe(NailCareStage.nailBuffering),
      isTrue,
    );
    expect(
      NailCareInventory.splitSprayAndWipe(NailCareStage.handCleaning),
      isFalse,
    );
  });

  testWidgets('soap wash then buffer then cut completes the nail-care page', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
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
          overlayBuilderMap: _overlays,
        ),
      ),
    );
    for (var i = 0; i < 60 && !game.isLoaded; i++) {
      await tester.pump();
    }
    expect(game.isLoaded, isTrue);

    game.debugOpenNailCare();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 32));

    expect(game.overlays.isActive(NailCareOverlay.id), isTrue);
    expect(find.byKey(const Key('nail-care-emotion')), findsOneWidget);
    expect(game.nailCare.emotionFrame, 0);
    expect(game.nailCare.stage, NailCareStage.handCleaning);
    expect(game.nailCare.canUse(NailCareToolId.handSoap), isFalse);
    expect(game.nailCare.canAdvance, isFalse);
    expect(find.byKey(const Key('nail-care-tool-handSoap')), findsNothing);
    expect(find.byKey(const Key('nail-care-inventory-drawer')), findsOneWidget);
    expect(find.byKey(const Key('nail-care-drop-hand')), findsOneWidget);
    expect(find.byKey(const Key('nail-care-progress')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nail-care-inventory-drawer')));
    await tester.pump();
    expect(find.byKey(const Key('nail-care-inventory-panel')), findsOneWidget);
    expect(find.byKey(const Key('nail-care-slot-soap-0')), findsOneWidget);
    expect(find.byKey(const Key('nail-care-slot-soap-7')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nail-care-slot-soap-1')));
    await tester.pump();
    expect(game.nailCare.selectedItemId, isNull);
    expect(find.byKey(const Key('nail-care-inventory-panel')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nail-care-slot-soap-0')));
    await tester.pump();
    expect(game.nailCare.selectedItemId, 'soap-0');
    expect(find.byKey(const Key('nail-care-inventory-panel')), findsNothing);
    expect(find.text('Drag onto hand'), findsOneWidget);
    expect(find.byKey(const Key('nail-care-tool-handSoap')), findsOneWidget);

    game.nailCare.onToolHeldOverTarget(NailCareToolId.nailBuffer);
    expect(game.nailCare.stage, NailCareStage.handCleaning);

    game.nailCare.onToolHeldOverTarget(NailCareToolId.handSoap);
    expect(game.nailCare.stage, NailCareStage.handCleaning);

    for (var i = 0;
        i < 400 && game.nailCare.stage != NailCareStage.handCleaningCompleted;
        i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(game.nailCare.stage, NailCareStage.handCleaningCompleted);
    expect(game.nailCare.emotionFrame, 2);
    expect(game.nailCare.rewardOpen, isFalse);
    expect(game.nailCare.canAdvance, isTrue);
    expect(find.byKey(const Key('nail-care-reward')), findsNothing);
    expect(
      game.nailCare.coins,
      GameConfig.nailCareWashCoinReward,
    );

    await tester.tap(find.byKey(const Key('nail-care-next')));
    await tester.pump();
    expect(
      game.nailCare.stage,
      anyOf(
        NailCareStage.pinkyFingerFocus,
        NailCareStage.nailSpraying,
        NailCareStage.nailBuffering,
      ),
    );

    for (var i = 0;
        i < 400 && game.nailCare.stage != NailCareStage.nailSpraying;
        i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(game.nailCare.stage, NailCareStage.nailSpraying);
    expect(game.nailCare.canUse(NailCareToolId.nailSpray), isFalse);
    expect(find.byKey(const Key('nail-care-tool-nailSpray')), findsNothing);
    expect(
      find.byKey(const Key('nail-care-inventory-drawer-spray')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('nail-care-inventory-drawer-wipe')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('nail-care-inventory-drawer')), findsNothing);

    await tester.tap(find.byKey(const Key('nail-care-inventory-drawer-spray')));
    await tester.pump();
    expect(find.byKey(const Key('nail-care-slot-spray-0')), findsOneWidget);
    expect(find.byKey(const Key('nail-care-slot-buffer-0')), findsNothing);

    await tester.tap(find.byKey(const Key('nail-care-inventory-drawer-wipe')));
    await tester.pump();
    expect(find.byKey(const Key('nail-care-slot-buffer-0')), findsOneWidget);
    expect(find.byKey(const Key('nail-care-slot-spray-0')), findsNothing);
    await tester.tap(find.byKey(const Key('nail-care-slot-buffer-0')));
    await tester.pump();
    expect(game.nailCare.canUse(NailCareToolId.nailBuffer), isFalse);

    await tester.tap(find.byKey(const Key('nail-care-inventory-drawer-spray')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('nail-care-slot-spray-0')));
    await tester.pump();
    expect(find.text('Spray onto nail'), findsOneWidget);
    expect(game.nailCare.canUse(NailCareToolId.nailSpray), isTrue);

    game.nailCare.onToolHeldOverTarget(NailCareToolId.nailSpray);
    expect(game.nailCare.toolHeldOverTarget, isTrue);
    for (var i = 0;
        i < 200 && game.nailCare.stage != NailCareStage.nailBuffering;
        i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(game.nailCare.stage, NailCareStage.nailBuffering);
    expect(game.nailCare.canUse(NailCareToolId.nailBuffer), isFalse);
    expect(find.byKey(const Key('nail-care-tool-nailBuffer')), findsNothing);

    await tester.tap(find.byKey(const Key('nail-care-inventory-drawer-wipe')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('nail-care-slot-buffer-0')));
    await tester.pump();
    expect(find.text('Drag onto nail'), findsOneWidget);
    expect(game.nailCare.canUse(NailCareToolId.nailBuffer), isTrue);

    game.nailCare.onToolHeldOverTarget(NailCareToolId.nailBuffer);
    expect(game.nailCare.toolHeldOverTarget, isTrue);

    game.nailCare.onToolLeftTarget();
    expect(game.nailCare.toolHeldOverTarget, isFalse);
    final pausedProgress = game.nailCare.nailCleanProgress;
    await tester.pump(const Duration(milliseconds: 400));
    expect(game.nailCare.nailCleanProgress, pausedProgress);

    game.nailCare.onToolHeldOverTarget(NailCareToolId.nailBuffer);
    for (var i = 0;
        i < 200 && game.nailCare.stage != NailCareStage.nailBufferingCompleted;
        i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(game.nailCare.stage, NailCareStage.nailBufferingCompleted);
    expect(game.nailCare.emotionFrame, 3);
    expect(game.nailCare.rewardOpen, isFalse);
    expect(game.nailCare.canAdvance, isTrue);
    expect(
      game.nailCare.coins,
      GameConfig.nailCareWashCoinReward + GameConfig.nailCareBufferCoinReward,
    );

    await tester.tap(find.byKey(const Key('nail-care-next')));
    await tester.pump();
    expect(game.nailCare.stage, NailCareStage.nailCutting);
    expect(find.byKey(const Key('nail-care-drop-nail')), findsOneWidget);
    expect(game.nailCare.canUse(NailCareToolId.nailClips), isFalse);

    await tester.tap(find.byKey(const Key('nail-care-inventory-drawer')));
    await tester.pump();
    expect(find.byKey(const Key('nail-care-slot-clips-0')), findsOneWidget);
    expect(find.byKey(const Key('nail-care-slot-clips-7')), findsOneWidget);
    await tester.tap(find.byKey(const Key('nail-care-slot-clips-0')));
    await tester.pump();
    expect(find.text('Clip the nail'), findsOneWidget);
    expect(game.nailCare.canUse(NailCareToolId.nailClips), isTrue);

    game.nailCare.onToolHeldOverTarget(NailCareToolId.nailClips);
    expect(game.nailCare.toolHeldOverTarget, isTrue);
    expect(game.nailCare.stage, NailCareStage.nailCutting);
    // Holding still must not finish the cut — leave and re-touch each snip.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(game.nailCare.stage, NailCareStage.nailCutting);

    for (var snip = 0;
        snip < 8 && game.nailCare.stage != NailCareStage.nailCuttingCompleted;
        snip++) {
      game.nailCare.onToolLeftTarget();
      game.nailCare.onToolHeldOverTarget(NailCareToolId.nailClips);
      await tester.pump();
    }

    expect(game.nailCare.stage, NailCareStage.nailCuttingCompleted);
    expect(game.nailCare.emotionFrame, 3);
    expect(game.nailCare.rewardOpen, isFalse);
    expect(game.nailCare.canAdvance, isTrue);
    expect(
      game.nailCare.coins,
      GameConfig.nailCareWashCoinReward +
          GameConfig.nailCareBufferCoinReward +
          GameConfig.nailCareCutCoinReward,
    );

    await tester.tap(find.byKey(const Key('nail-care-next')));
    await tester.pump();
    expect(game.nailCare.stage, NailCareStage.nailPolishing);
    expect(find.byKey(const Key('nail-care-drop-nail')), findsOneWidget);
    expect(game.nailCare.canUse(NailCareToolId.nailPolish), isFalse);

    await tester.tap(find.byKey(const Key('nail-care-inventory-drawer')));
    await tester.pump();
    expect(find.byKey(const Key('nail-care-slot-polish-blush')), findsOneWidget);
    expect(find.byKey(const Key('nail-care-slot-polish-gold')), findsOneWidget);
    await tester.tap(find.byKey(const Key('nail-care-slot-polish-red')));
    await tester.pump();
    expect(game.nailCare.selectedItemId, 'polish-red');
    expect(find.byKey(const Key('nail-care-inventory-panel')), findsNothing);
    expect(find.text('Paint the nail'), findsOneWidget);
    expect(game.nailCare.canUse(NailCareToolId.nailPolish), isTrue);

    game.nailCare.onToolHeldOverTarget(NailCareToolId.nailPolish);
    expect(game.nailCare.toolHeldOverTarget, isTrue);
    for (var i = 0;
        i < 200 && game.nailCare.stage != NailCareStage.nailPolishingCompleted;
        i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(game.nailCare.stage, NailCareStage.nailPolishingCompleted);
    expect(game.nailCare.emotionFrame, 4);
    expect(game.nailCare.rewardOpen, isFalse);
    expect(game.nailCare.canAdvance, isTrue);
    expect(
      game.nailCare.coins,
      GameConfig.nailCareWashCoinReward +
          GameConfig.nailCareBufferCoinReward +
          GameConfig.nailCareCutCoinReward +
          GameConfig.nailCarePolishCoinReward,
    );

    await tester.tap(find.byKey(const Key('nail-care-next')));
    await tester.pump();
    expect(game.nailCare.digit, NailDigit.ring);
    expect(
      game.nailCare.stage,
      anyOf(
        NailCareStage.ringFingerFocus,
        NailCareStage.nailSpraying,
        NailCareStage.nailBuffering,
      ),
    );

    for (var i = 0;
        i < 400 && game.nailCare.stage != NailCareStage.nailSpraying;
        i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(game.nailCare.stage, NailCareStage.nailSpraying);
    expect(find.text('Spray the ring finger to loosen grime'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nail-care-inventory-drawer-spray')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('nail-care-slot-spray-0')));
    await tester.pump();
    game.nailCare.onToolHeldOverTarget(NailCareToolId.nailSpray);
    for (var i = 0;
        i < 200 && game.nailCare.stage != NailCareStage.nailBuffering;
        i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(game.nailCare.stage, NailCareStage.nailBuffering);

    await tester.tap(find.byKey(const Key('nail-care-inventory-drawer-wipe')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('nail-care-slot-buffer-0')));
    await tester.pump();
    game.nailCare.onToolHeldOverTarget(NailCareToolId.nailBuffer);
    for (var i = 0;
        i < 200 && game.nailCare.stage != NailCareStage.nailBufferingCompleted;
        i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(game.nailCare.stage, NailCareStage.nailBufferingCompleted);
    await tester.tap(find.byKey(const Key('nail-care-next')));
    await tester.pump();
    expect(game.nailCare.stage, NailCareStage.nailCutting);

    await tester.tap(find.byKey(const Key('nail-care-inventory-drawer')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('nail-care-slot-clips-0')));
    await tester.pump();
    game.nailCare.onToolHeldOverTarget(NailCareToolId.nailClips);
    for (var snip = 0;
        snip < 8 && game.nailCare.stage != NailCareStage.nailCuttingCompleted;
        snip++) {
      game.nailCare.onToolLeftTarget();
      game.nailCare.onToolHeldOverTarget(NailCareToolId.nailClips);
      await tester.pump();
    }
    expect(game.nailCare.stage, NailCareStage.nailCuttingCompleted);
    await tester.tap(find.byKey(const Key('nail-care-next')));
    await tester.pump();
    expect(game.nailCare.stage, NailCareStage.nailPolishing);

    await tester.tap(find.byKey(const Key('nail-care-inventory-drawer')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('nail-care-slot-polish-blush')));
    await tester.pump();
    game.nailCare.onToolHeldOverTarget(NailCareToolId.nailPolish);
    for (var i = 0;
        i < 200 && game.nailCare.stage != NailCareStage.nailPolishingCompleted;
        i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(game.nailCare.stage, NailCareStage.nailPolishingCompleted);
    await tester.tap(find.byKey(const Key('nail-care-next')));
    await tester.pump();
    expect(game.nailCare.digit, NailDigit.middle);

    await _finishCurrentNail(tester, game);
    expect(game.nailCare.digit, NailDigit.pointer);

    await _finishCurrentNail(tester, game);
    expect(game.nailCare.digit, NailDigit.thumb);

    await _finishCurrentNail(tester, game);
    expect(game.nailCare.stage, NailCareStage.handReveal);
    expect(game.scene.workspace.showingFinishedHand, isTrue);
    expect(find.text('All done — look at that manicure!'), findsNothing);
    expect(find.text('Finished colors'), findsOneWidget);
    expect(find.text('Next customer'), findsOneWidget);
    expect(find.byType(CuteHandSimCard), findsNothing);
    final finishedGuest = game.guest.id;
    await tester.tap(find.byKey(const Key('nail-care-next')));
    await tester.pump();
    expect(game.overlays.isActive(ArrivalCompleteOverlay.id), isTrue);
    expect(game.overlays.isActive(NailCareOverlay.id), isFalse);
    expect(game.preferredGuest.id, isNot(finishedGuest));
  });

  testWidgets(
    'clip advances one frame per touch; holding still does not finish',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1;
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
            overlayBuilderMap: _overlays,
          ),
        ),
      );
      for (var i = 0; i < 60 && !game.isLoaded; i++) {
        await tester.pump();
      }
      expect(game.isLoaded, isTrue);

      game.debugOpenNailCare();
      await tester.pump();

      game.nailCare.stage = NailCareStage.nailBufferingCompleted;
      game.nailCare.beginNailCutting();
      game.nailCare.selectedItemId = 'clips-0';
      await tester.pump();

      game.nailCare.onToolHeldOverTarget(NailCareToolId.nailClips);
      expect(game.nailCare.stage, NailCareStage.nailCutting);
      expect(game.nailCare.nailCleanProgress, greaterThan(0));

      // Stay on the nail without leaving — no further snips.
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(game.nailCare.stage, NailCareStage.nailCutting);

      for (var snip = 0;
          snip < 8 &&
              game.nailCare.stage != NailCareStage.nailCuttingCompleted;
          snip++) {
        game.nailCare.onToolLeftTarget();
        game.nailCare.onToolHeldOverTarget(NailCareToolId.nailClips);
        await tester.pump();
      }

      expect(game.nailCare.stage, NailCareStage.nailCuttingCompleted);
      expect(game.nailCare.canAdvance, isTrue);
      expect(game.nailCare.selectedItemId, isNull);
      expect(find.text('Nice! Tap NEXT to keep going'), findsOneWidget);

      await tester.tap(find.byKey(const Key('nail-care-next')));
      await tester.pump();
      expect(game.nailCare.stage, NailCareStage.nailPolishing);
    },
  );

  testWidgets('Asta clips and polishes every digit', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
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
          overlayBuilderMap: _overlays,
        ),
      ),
    );
    for (var i = 0; i < 60 && !game.isLoaded; i++) {
      await tester.pump();
    }
    expect(game.isLoaded, isTrue);

    game.selectPreferredGuest(CustomerRoster.customer3);
    game.debugOpenNailCare();
    await tester.pump();

    expect(game.guest.name, 'Asta');
    expect(game.nailCare.guestId, 'customer3');
    expect(game.nailCare.careKit.allowsCutAndPolish(NailDigit.pinky), isTrue);
    expect(game.nailCare.careKit.allowsCutAndPolish(NailDigit.ring), isTrue);
    expect(game.nailCare.careKit.allowsCutAndPolish(NailDigit.middle), isTrue);
    expect(game.nailCare.careKit.allowsCutAndPolish(NailDigit.pointer), isTrue);
    expect(game.nailCare.careKit.allowsCutAndPolish(NailDigit.thumb), isTrue);
    expect(game.nailCare.careKit.finalHandAsset, AssetPaths.finalHandDark);

    game.nailCare.stage = NailCareStage.nailBufferingCompleted;
    game.nailCare.digit = NailDigit.pinky;
    game.nailCare.stageRewardClaimed = true;
    game.nailCare.advanceFromNext();
    expect(game.nailCare.digit, NailDigit.pinky);
    expect(game.nailCare.stage, NailCareStage.nailCutting);

    game.nailCare.stage = NailCareStage.nailBufferingCompleted;
    game.nailCare.digit = NailDigit.ring;
    game.nailCare.stageRewardClaimed = true;
    game.nailCare.advanceFromNext();
    expect(game.nailCare.digit, NailDigit.ring);
    expect(game.nailCare.stage, NailCareStage.nailCutting);

    game.nailCare.stage = NailCareStage.nailBufferingCompleted;
    game.nailCare.digit = NailDigit.middle;
    game.nailCare.stageRewardClaimed = true;
    game.nailCare.advanceFromNext();
    expect(game.nailCare.digit, NailDigit.middle);
    expect(game.nailCare.stage, NailCareStage.nailCutting);

    game.nailCare.stage = NailCareStage.nailBufferingCompleted;
    game.nailCare.digit = NailDigit.pointer;
    game.nailCare.stageRewardClaimed = true;
    game.nailCare.advanceFromNext();
    expect(game.nailCare.digit, NailDigit.pointer);
    expect(game.nailCare.stage, NailCareStage.nailCutting);

    game.nailCare.stage = NailCareStage.nailBufferingCompleted;
    game.nailCare.digit = NailDigit.thumb;
    game.nailCare.stageRewardClaimed = true;
    game.nailCare.advanceFromNext();
    expect(game.nailCare.digit, NailDigit.thumb);
    expect(game.nailCare.stage, NailCareStage.nailCutting);

    game.nailCare.polishByDigit[NailDigit.pinky] = 0xFFFF6BA8;
    game.nailCare.polishByDigit[NailDigit.ring] = 0xFFD0123A;
    game.nailCare.beginHandReveal();
    expect(game.nailCare.stage, NailCareStage.handReveal);
    expect(game.nailCare.polishByDigit[NailDigit.pinky], 0xFFFF6BA8);
    expect(game.nailCare.polishByDigit[NailDigit.ring], 0xFFD0123A);
  });

  testWidgets('finger sim keeps completed pinky when ring becomes active', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
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
          overlayBuilderMap: _overlays,
        ),
      ),
    );
    for (var i = 0; i < 60 && !game.isLoaded; i++) {
      await tester.pump();
    }
    expect(game.isLoaded, isTrue);

    game.selectPreferredGuest(CustomerRoster.customer3);
    game.debugOpenNailCare();
    await tester.pump();

    expect(find.byKey(const Key('nail-care-finger-sim')), findsOneWidget);
    expect(game.nailCare.simActiveDigit, isNull);
    expect(game.nailCare.simSnapshotFor(NailDigit.pinky).isClean, isFalse);

    game.nailCare.digit = NailDigit.pinky;
    game.nailCare.stage = NailCareStage.pinkyFingerFocus;
    game.nailCare.beginNailBuffering();
    await tester.pump();

    expect(game.nailCare.stage, NailCareStage.nailSpraying);
    expect(game.nailCare.simActiveDigit, NailDigit.pinky);
    expect(find.byKey(const Key('nail-care-finger-sim-pinky')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nail-care-inventory-drawer-spray')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('nail-care-slot-spray-0')));
    await tester.pump();
    game.nailCare.onToolHeldOverTarget(NailCareToolId.nailSpray);
    for (var i = 0;
        i < 200 && game.nailCare.stage != NailCareStage.nailBuffering;
        i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(game.nailCare.stage, NailCareStage.nailBuffering);

    await tester.tap(find.byKey(const Key('nail-care-inventory-drawer-wipe')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('nail-care-slot-buffer-0')));
    await tester.pump();
    game.nailCare.onToolHeldOverTarget(NailCareToolId.nailBuffer);
    for (var i = 0;
        i < 200 && game.nailCare.stage != NailCareStage.nailBufferingCompleted;
        i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(game.nailCare.stage, NailCareStage.nailBufferingCompleted);
    expect(game.nailCare.simSnapshotFor(NailDigit.pinky).isClean, isTrue);
    expect(game.nailCare.simSnapshotFor(NailDigit.pinky).isShort, isFalse);

    await tester.tap(find.byKey(const Key('nail-care-next')));
    await tester.pump();
    expect(game.nailCare.stage, NailCareStage.nailCutting);

    await tester.tap(find.byKey(const Key('nail-care-inventory-drawer')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('nail-care-slot-clips-0')));
    await tester.pump();
    game.nailCare.onToolHeldOverTarget(NailCareToolId.nailClips);
    for (var snip = 0;
        snip < 8 && game.nailCare.stage != NailCareStage.nailCuttingCompleted;
        snip++) {
      game.nailCare.onToolLeftTarget();
      game.nailCare.onToolHeldOverTarget(NailCareToolId.nailClips);
      await tester.pump();
    }
    expect(game.nailCare.stage, NailCareStage.nailCuttingCompleted);
    expect(game.nailCare.simSnapshotFor(NailDigit.pinky).isShort, isTrue);
    expect(game.nailCare.simSnapshotFor(NailDigit.pinky).isPolished, isFalse);

    await tester.tap(find.byKey(const Key('nail-care-next')));
    await tester.pump();
    expect(game.nailCare.stage, NailCareStage.nailPolishing);

    await tester.tap(find.byKey(const Key('nail-care-inventory-drawer')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('nail-care-slot-polish-blush')));
    await tester.pump();
    game.nailCare.onToolHeldOverTarget(NailCareToolId.nailPolish);
    for (var i = 0;
        i < 200 && game.nailCare.stage != NailCareStage.nailPolishingCompleted;
        i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(game.nailCare.stage, NailCareStage.nailPolishingCompleted);
    final pinkyDone = game.nailCare.simSnapshotFor(NailDigit.pinky);
    expect(pinkyDone.isClean, isTrue);
    expect(pinkyDone.isShort, isTrue);
    expect(pinkyDone.polishColor, 0xFFFF6BA8);

    await tester.tap(find.byKey(const Key('nail-care-next')));
    await tester.pump();
    expect(game.nailCare.digit, NailDigit.ring);
    expect(game.nailCare.simActiveDigit, NailDigit.ring);
    expect(game.nailCare.simSnapshotFor(NailDigit.pinky).isClean, isTrue);
    expect(game.nailCare.simSnapshotFor(NailDigit.pinky).isShort, isTrue);
    expect(game.nailCare.simSnapshotFor(NailDigit.pinky).polishColor, 0xFFFF6BA8);
    expect(game.nailCare.simSnapshotFor(NailDigit.ring).isClean, isFalse);
    expect(game.nailCare.simSnapshotFor(NailDigit.ring).isPolished, isFalse);
    expect(find.byKey(const Key('nail-care-finger-sim')), findsOneWidget);
    expect(find.byKey(const Key('nail-care-finger-sim-ring')), findsOneWidget);
  });
}

Future<void> _finishCurrentNail(
  WidgetTester tester,
  NailGlamGame game,
) async {
  for (var i = 0;
      i < 400 && game.nailCare.stage != NailCareStage.nailSpraying;
      i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(game.nailCare.stage, NailCareStage.nailSpraying);

  await tester.tap(find.byKey(const Key('nail-care-inventory-drawer-spray')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('nail-care-slot-spray-0')));
  await tester.pump();
  game.nailCare.onToolHeldOverTarget(NailCareToolId.nailSpray);
  for (var i = 0;
      i < 200 && game.nailCare.stage != NailCareStage.nailBuffering;
      i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }

  await tester.tap(find.byKey(const Key('nail-care-inventory-drawer-wipe')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('nail-care-slot-buffer-0')));
  await tester.pump();
  game.nailCare.onToolHeldOverTarget(NailCareToolId.nailBuffer);
  for (var i = 0;
      i < 200 && game.nailCare.stage != NailCareStage.nailBufferingCompleted;
      i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  await tester.tap(find.byKey(const Key('nail-care-next')));
  await tester.pump();

  await tester.tap(find.byKey(const Key('nail-care-inventory-drawer')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('nail-care-slot-clips-0')));
  await tester.pump();
  game.nailCare.onToolHeldOverTarget(NailCareToolId.nailClips);
  for (var snip = 0;
      snip < 8 && game.nailCare.stage != NailCareStage.nailCuttingCompleted;
      snip++) {
    game.nailCare.onToolLeftTarget();
    game.nailCare.onToolHeldOverTarget(NailCareToolId.nailClips);
    await tester.pump();
  }
  await tester.tap(find.byKey(const Key('nail-care-next')));
  await tester.pump();

  await tester.tap(find.byKey(const Key('nail-care-inventory-drawer')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('nail-care-slot-polish-blush')));
  await tester.pump();
  game.nailCare.onToolHeldOverTarget(NailCareToolId.nailPolish);
  for (var i = 0;
      i < 200 && game.nailCare.stage != NailCareStage.nailPolishingCompleted;
      i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  await tester.tap(find.byKey(const Key('nail-care-next')));
  await tester.pump();
}

final Map<String, Widget Function(BuildContext, NailGlamGame)> _overlays =
    <String, Widget Function(BuildContext, NailGlamGame)>{
      HomeOverlay.id: (BuildContext context, NailGlamGame game) =>
          HomeOverlay(controller: HomeController.fromGame(game)),
      ArrivalCompleteOverlay.id: (BuildContext context, NailGlamGame game) =>
          ArrivalCompleteOverlay(onReplay: game.startArrival),
      ArrivalControlsOverlay.id: (BuildContext context, NailGlamGame game) =>
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
    };
