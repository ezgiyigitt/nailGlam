import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/controller/ads_service.dart';
import 'package:nail_glam/controller/nail_glam_game.dart';
import 'package:nail_glam/model/asset_paths.dart';
import 'package:nail_glam/model/game_config.dart';
import 'package:nail_glam/model/nail_care_tools.dart';
import 'package:nail_glam/model/placeholder_art.dart';
import 'package:nail_glam/view/arrival_controls_overlay.dart';
import 'package:nail_glam/view/nail_care_overlay.dart';

/// Only the overlays `debugOpenNailCare` actually raises. Flame throws on an
/// overlay with no registered builder, so this has to cover them.
final Map<String, Widget Function(BuildContext, NailGlamGame)> _overlays =
    <String, Widget Function(BuildContext, NailGlamGame)>{
      ArrivalControlsOverlay.id: (BuildContext context, NailGlamGame game) =>
          ArrivalControlsOverlay(
            onTogglePause: game.togglePause,
            onHome: game.returnToHome,
          ),
      NailCareOverlay.id: (BuildContext context, NailGlamGame game) =>
          NailCareOverlay(game: game),
    };

/// Covers the three scoring systems layered on top of the manicure flow:
/// guest patience (and the tip it pays), the combo multiplier, and the
/// ad-funded tool trial.
///
/// The flow itself is exercised in nail_care_flow_test.dart, which pins
/// `comboEnabled = false` so it can keep asserting face-value rewards. This
/// file is where the multiplier is allowed to move.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Boots a real game far enough that `nailCare` is mounted and its
  /// `update` can be driven by hand.
  Future<NailGlamGame> loadGame(WidgetTester tester) async {
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
        home: GameWidget<NailGlamGame>(game: game, overlayBuilderMap: _overlays),
      ),
    );
    for (var i = 0; i < 60 && !game.isLoaded; i++) {
      await tester.pump();
    }
    expect(game.isLoaded, isTrue);
    return game;
  }

  /// Runs the hand wash to completion. [leadIn] is dead time burned before
  /// the soap is picked up, which is what pushes a stage outside the combo
  /// window without changing how the wash itself is played.
  void washHand(NailGlamGame game, {double leadIn = 0}) {
    if (leadIn > 0) {
      game.nailCare.update(leadIn);
    }
    game.nailCare.onToolHeldOverTarget(NailCareToolId.handSoap);
    // One long tick: the wash advances by dt / nailCareWashDuration and
    // clamps, so anything past the full duration finishes it outright.
    game.nailCare.update(GameConfig.nailCareWashDuration + 0.1);
  }

  group('patience', () {
    testWidgets('drains while the guest waits and stops at the reveal', (
      WidgetTester tester,
    ) async {
      final game = await loadGame(tester);
      game.debugOpenNailCare();
      expect(game.nailCare.patience, 1);

      game.nailCare.update(15);
      expect(
        game.nailCare.patience,
        closeTo(1 - 15 / game.nailCare.patienceBudgetSeconds, 1e-9),
      );

      // Nothing is owed once the work is done and on show.
      game.nailCare.beginHandReveal();
      final atReveal = game.nailCare.patience;
      game.nailCare.update(30);
      expect(game.nailCare.patience, atReveal);
    });

    testWidgets('sours the guest without ever going below the sheet', (
      WidgetTester tester,
    ) async {
      final game = await loadGame(tester);
      game.debugOpenNailCare();
      // At the reveal the manicure itself reads as finished, so the only
      // thing left moving the face is how long the guest was kept waiting.
      game.nailCare.stage = NailCareStage.handReveal;

      // A briskly played visit ends above half, and keeps a delighted guest.
      game.nailCare.patience = 1;
      expect(game.nailCare.emotionFrame, 4);
      game.nailCare.patience = 0.55;
      expect(game.nailCare.emotionFrame, 4);
      // Below half the guest starts to show it.
      game.nailCare.patience = 0.4;
      expect(game.nailCare.emotionFrame, 3);
      game.nailCare.patience = 0.2;
      expect(game.nailCare.emotionFrame, 2);
      game.nailCare.patience = 0;
      expect(game.nailCare.emotionFrame, 1);
    });

    testWidgets('pays a tip scaled by whatever patience is left', (
      WidgetTester tester,
    ) async {
      final game = await loadGame(tester);
      game.debugOpenNailCare();
      final before = game.nailCare.coins;

      game.nailCare.patience = 0.5;
      game.nailCare.beginHandReveal();

      expect(game.nailCare.tipPaid, GameConfig.nailCareMaxTipCoins ~/ 2);
      expect(game.nailCare.coins, before + game.nailCare.tipPaid);
    });

    testWidgets('pays nothing once patience is gone', (
      WidgetTester tester,
    ) async {
      final game = await loadGame(tester);
      game.debugOpenNailCare();
      final before = game.nailCare.coins;

      game.nailCare.patience = 0;
      game.nailCare.beginHandReveal();

      expect(game.nailCare.tipPaid, 0);
      expect(game.nailCare.coins, before);
    });
  });

  group('patience budget', () {
    testWidgets('a pedicure gets far less patience than a manicure', (
      WidgetTester tester,
    ) async {
      final game = await loadGame(tester);

      game.nailCare.beginHandCleaning();
      final handBudget = game.nailCare.patienceBudgetSeconds;

      game.nailCare.beginFootCleaning();
      final footBudget = game.nailCare.patienceBudgetSeconds;

      // The whole point of budgeting by flow: a four-stage pedicure must not
      // be handed the same clock as a sixteen-stage manicure, or it finishes
      // on a full bar every time and the tip stops meaning anything.
      expect(footBudget, lessThan(handBudget));
      expect(
        footBudget,
        GameConfig.nailCarePatienceBaseSeconds +
            GameConfig.nailCarePatiencePerStageSeconds * 4,
      );
    });

    testWidgets('a manicure after a pedicure is re-sized for the hand', (
      WidgetTester tester,
    ) async {
      final game = await loadGame(tester);

      game.nailCare.beginFootCleaning();
      final footBudget = game.nailCare.patienceBudgetSeconds;
      // careTarget used to be left on foot here, which handed the following
      // manicure the pedicure's much smaller budget.
      game.nailCare.beginHandCleaning();

      expect(game.nailCare.patienceBudgetSeconds, greaterThan(footBudget));
    });
  });

  group('combo', () {
    test('multiplier steps at the configured tiers', () {
      // Pure lookup, so it needs no game: tier boundaries are the part worth
      // pinning, since the payout of every stage hangs off them.
      expect(GameConfig.nailCareComboTier1, lessThan(GameConfig.nailCareComboTier2));
      expect(GameConfig.nailCareComboMultiplier1, greaterThan(1));
      expect(
        GameConfig.nailCareComboMultiplier2,
        greaterThan(GameConfig.nailCareComboMultiplier1),
      );
    });

    testWidgets('a prompt stage extends the combo and pays face value first', (
      WidgetTester tester,
    ) async {
      final game = await loadGame(tester);
      game.debugOpenNailCare();
      expect(game.nailCare.combo, 0);

      washHand(game);

      expect(game.nailCare.stage, NailCareStage.handCleaningCompleted);
      expect(game.nailCare.combo, 1);
      // Below the first tier, so the reward is untouched — a player who is
      // not on a run never earns less than the base economy.
      expect(game.nailCare.comboMultiplier, 1);
      expect(game.nailCare.coins, GameConfig.nailCareWashCoinReward);
    });

    testWidgets('dawdling past the window breaks the combo', (
      WidgetTester tester,
    ) async {
      final game = await loadGame(tester);
      game.debugOpenNailCare();
      game.nailCare.combo = GameConfig.nailCareComboTier2;

      washHand(game, leadIn: GameConfig.nailCareComboWindow + 1);

      expect(game.nailCare.combo, 0);
      expect(game.nailCare.comboMultiplier, 1);
    });

    testWidgets('a stage already on a run pays the multiplied reward', (
      WidgetTester tester,
    ) async {
      final game = await loadGame(tester);
      game.debugOpenNailCare();
      // One clean stage short of the top tier, so finishing this wash
      // promptly lands exactly on it.
      game.nailCare.combo = GameConfig.nailCareComboTier2 - 1;

      washHand(game);

      expect(game.nailCare.combo, GameConfig.nailCareComboTier2);
      expect(
        game.nailCare.comboMultiplier,
        GameConfig.nailCareComboMultiplier2,
      );
      expect(
        game.nailCare.coins,
        (GameConfig.nailCareWashCoinReward *
                GameConfig.nailCareComboMultiplier2)
            .round(),
      );
    });

    testWidgets('comboEnabled=false pins every payout to face value', (
      WidgetTester tester,
    ) async {
      final game = await loadGame(tester);
      game.nailCare.comboEnabled = false;
      game.debugOpenNailCare();
      game.nailCare.combo = GameConfig.nailCareComboTier2;

      washHand(game);

      expect(game.nailCare.comboMultiplier, 1);
      expect(game.nailCare.coins, GameConfig.nailCareWashCoinReward);
    });
  });

  group('tool trial', () {
    /// A locked spray: priced, and with no polish colour, so lending it
    /// touches nothing in the workspace.
    final locked = NailCareInventory.sprays.firstWhere(
      (NailCareInventoryItem item) => !item.unlocked && item.unlockPrice > 0,
    );

    testWidgets('an ad lends the tool for this visit only', (
      WidgetTester tester,
    ) async {
      AdsService.instance = FakeAdsService(delay: Duration.zero);
      addTearDown(() => AdsService.instance = FakeAdsService());

      final game = await loadGame(tester);
      game.debugOpenNailCare();
      expect(game.nailCare.ownsKitItem(locked), isFalse);
      expect(game.nailCare.canTrialItem(locked), isTrue);

      late bool started;
      await tester.runAsync(() async {
        started = await game.nailCare.watchAdForTrial(locked);
      });

      expect(started, isTrue);
      expect(game.nailCare.ownsKitItem(locked), isTrue);
      expect(game.nailCare.isTrialUnlocked(locked.id), isTrue);
      // Borrowed, never bought: nothing may reach the saved wallet.
      expect(game.progress.owns(locked.id), isFalse);
      // A tool already on loan is not offered again.
      expect(game.nailCare.canTrialItem(locked), isFalse);

      // The next guest starts from scratch.
      game.nailCare.beginHandCleaning();
      expect(game.nailCare.ownsKitItem(locked), isFalse);
      expect(game.nailCare.isTrialUnlocked(locked.id), isFalse);
    });

    testWidgets('no offer when the ad network has nothing to show', (
      WidgetTester tester,
    ) async {
      AdsService.instance = const DisabledAdsService();
      addTearDown(() => AdsService.instance = FakeAdsService());

      final game = await loadGame(tester);
      game.debugOpenNailCare();

      expect(game.nailCare.canTrialItem(locked), isFalse);

      late bool started;
      await tester.runAsync(() async {
        started = await game.nailCare.watchAdForTrial(locked);
      });
      expect(started, isFalse);
      expect(game.nailCare.ownsKitItem(locked), isFalse);
    });

    testWidgets('an owned item is never offered a trial', (
      WidgetTester tester,
    ) async {
      final game = await loadGame(tester);
      game.debugOpenNailCare();

      final free = NailCareInventory.sprays.firstWhere(
        (NailCareInventoryItem item) => item.unlocked,
      );
      expect(game.nailCare.canTrialItem(free), isFalse);
    });
  });
}
