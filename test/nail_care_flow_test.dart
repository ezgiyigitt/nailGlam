import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/game/config/asset_paths.dart';
import 'package:nail_glam/game/config/game_config.dart';
import 'package:nail_glam/game/config/nail_care_tools.dart';
import 'package:nail_glam/game/nail_glam_game.dart';
import 'package:nail_glam/game/placeholder_art.dart';
import 'package:nail_glam/ui/arrival_complete_overlay.dart';
import 'package:nail_glam/ui/arrival_controls_overlay.dart';
import 'package:nail_glam/ui/customer_thought_bubble_overlay.dart';
import 'package:nail_glam/ui/home_overlay.dart';
import 'package:nail_glam/ui/nail_care_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    expect(
      NailCareInventory.soaps.every((item) => item.iconPath == AssetPaths.handSoap),
      isTrue,
    );
    expect(
      NailCareInventory.buffers.every(
        (item) => item.iconPath == AssetPaths.nailBuffer,
      ),
      isTrue,
    );
    expect(
      NailCareInventory.clips.every(
        (item) => item.iconPath == AssetPaths.nailClips,
      ),
      isTrue,
    );
    expect(
      NailCareInventory.brushes.every(
        (item) => item.iconPath == AssetPaths.polishBrush,
      ),
      isTrue,
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

    await tester.tap(find.byKey(const Key('nail-care-inventory-drawer')));
    await tester.pump();
    expect(find.byKey(const Key('nail-care-slot-spray-0')), findsOneWidget);
    expect(find.byKey(const Key('nail-care-slot-buffer-0')), findsOneWidget);
    await tester.tap(find.byKey(const Key('nail-care-slot-buffer-0')));
    await tester.pump();
    expect(game.nailCare.canUse(NailCareToolId.nailBuffer), isFalse);

    await tester.tap(find.byKey(const Key('nail-care-inventory-drawer')));
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

    await tester.tap(find.byKey(const Key('nail-care-inventory-drawer')));
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
    for (var i = 0;
        i < 200 && game.nailCare.stage != NailCareStage.nailCuttingCompleted;
        i++) {
      await tester.pump(const Duration(milliseconds: 16));
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
    expect(find.byKey(const Key('nail-care-slot-brush-0')), findsOneWidget);
    expect(find.byKey(const Key('nail-care-slot-brush-7')), findsOneWidget);
    await tester.tap(find.byKey(const Key('nail-care-slot-brush-1')));
    await tester.pump();
    expect(game.nailCare.selectedItemId, isNull);
    expect(find.byKey(const Key('nail-care-inventory-panel')), findsOneWidget);
    await tester.tap(find.byKey(const Key('nail-care-slot-brush-0')));
    await tester.pump();
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

    await tester.tap(find.byKey(const Key('nail-care-inventory-drawer')));
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

    await tester.tap(find.byKey(const Key('nail-care-inventory-drawer')));
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
    for (var i = 0;
        i < 200 && game.nailCare.stage != NailCareStage.nailCuttingCompleted;
        i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(game.nailCare.stage, NailCareStage.nailCuttingCompleted);
    await tester.tap(find.byKey(const Key('nail-care-next')));
    await tester.pump();
    expect(game.nailCare.stage, NailCareStage.nailPolishing);

    await tester.tap(find.byKey(const Key('nail-care-inventory-drawer')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('nail-care-slot-brush-0')));
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
    expect(game.overlays.isActive(ArrivalCompleteOverlay.id), isTrue);
    expect(game.overlays.isActive(NailCareOverlay.id), isFalse);
  });
}

final Map<String, Widget Function(BuildContext, NailGlamGame)> _overlays =
    <String, Widget Function(BuildContext, NailGlamGame)>{
      HomeOverlay.id: (BuildContext context, NailGlamGame game) =>
          HomeOverlay(onPlay: game.startArrival),
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
