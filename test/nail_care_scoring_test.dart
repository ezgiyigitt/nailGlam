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
  /// the soap is picked up, which is how an operation is pushed past its own
  /// bar without changing how the wash itself is played.
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
    testWidgets('drains during an operation and stops at the reveal', (
      WidgetTester tester,
    ) async {
      final game = await loadGame(tester);
      game.debugOpenNailCare();
      expect(game.nailCare.patience, 1);

      game.nailCare.update(6);
      expect(
        game.nailCare.patience,
        closeTo(1 - 6 / GameConfig.nailCareStagePatienceSeconds, 1e-9),
      );

      // Nothing is owed once the work is done and on show.
      game.nailCare.beginHandReveal();
      final atReveal = game.nailCare.patience;
      game.nailCare.update(30);
      expect(game.nailCare.patience, atReveal);
    });

    testWidgets('every operation gets its own full bar', (
      WidgetTester tester,
    ) async {
      final game = await loadGame(tester);
      game.debugOpenNailCare();

      // Burn most of the wash's bar, then finish it.
      game.nailCare.update(12);
      expect(game.nailCare.patience, lessThan(0.5));
      washHand(game);
      expect(game.nailCare.stage, NailCareStage.handCleaningCompleted);

      // Between operations the bar holds its value rather than refilling
      // early, so the last one's result stays readable.
      final betweenOperations = game.nailCare.patience;
      game.nailCare.update(5);
      expect(game.nailCare.patience, betweenOperations);
      expect(game.nailCare.showsPatienceBar, isFalse);

      // Moving into the next real operation refills it.
      game.nailCare.advanceFromNext();
      game.nailCare.stage = NailCareStage.nailSpraying;
      game.nailCare.update(0.016);
      expect(game.nailCare.patience, 1);
      expect(game.nailCare.showsPatienceBar, isTrue);
    });

    testWidgets('the guest sours per missed operation, not per bar', (
      WidgetTester tester,
    ) async {
      final game = await loadGame(tester);
      game.debugOpenNailCare();
      // At the reveal the manicure itself reads as finished, so the only
      // thing left moving the face is how the visit went.
      game.nailCare.stage = NailCareStage.handReveal;

      game.nailCare.stagesPaid = 6;
      game.nailCare.stagesInTime = 6;
      expect(game.nailCare.emotionFrame, 4);

      game.nailCare.stagesInTime = 5;
      expect(game.nailCare.emotionFrame, 3);

      game.nailCare.stagesInTime = 4;
      expect(game.nailCare.emotionFrame, 2);

      game.nailCare.stagesInTime = 2;
      expect(game.nailCare.emotionFrame, 1);
    });

    testWidgets('the tip is the share of operations that beat their bar', (
      WidgetTester tester,
    ) async {
      final game = await loadGame(tester);
      game.debugOpenNailCare();
      final before = game.nailCare.coins;

      game.nailCare.stagesPaid = 8;
      game.nailCare.stagesInTime = 4;
      game.nailCare.beginHandReveal();

      expect(game.nailCare.tipPaid, GameConfig.nailCareMaxTipCoins ~/ 2);
      expect(game.nailCare.coins, before + game.nailCare.tipPaid);
    });

    testWidgets('missing every operation pays no tip', (
      WidgetTester tester,
    ) async {
      final game = await loadGame(tester);
      game.debugOpenNailCare();
      final before = game.nailCare.coins;

      game.nailCare.stagesPaid = 6;
      game.nailCare.stagesInTime = 0;
      game.nailCare.beginHandReveal();

      expect(game.nailCare.tipPaid, 0);
      expect(game.nailCare.coins, before);
    });
  });

  group('tip card', () {
    testWidgets('the reveal names the tip and why it was that much', (
      WidgetTester tester,
    ) async {
      final game = await loadGame(tester);
      game.debugOpenNailCare();

      // Nothing to show mid-manicure: the tip is not settled yet.
      await tester.pump();
      expect(find.byKey(const Key('nail-care-tip')), findsNothing);

      game.nailCare.stagesPaid = 8;
      game.nailCare.stagesInTime = 6;
      game.nailCare.beginHandReveal();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('nail-care-tip')), findsOneWidget);
      expect(find.text('TIP'), findsOneWidget);
      expect(find.text('+${game.nailCare.tipPaid}'), findsOneWidget);
      // The reason matters as much as the number — it is what tells the
      // player the bars were being scored at all.
      expect(find.text('6 of 8 steps finished in time'), findsOneWidget);
    });

    testWidgets('a visit that beat nothing says so instead of showing +0', (
      WidgetTester tester,
    ) async {
      final game = await loadGame(tester);
      game.debugOpenNailCare();

      game.nailCare.stagesPaid = 5;
      game.nailCare.stagesInTime = 0;
      game.nailCare.beginHandReveal();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('NO TIP'), findsOneWidget);
      expect(find.text('+0'), findsNothing);
    });
  });

  group('patience bar', () {
    testWidgets('the fill is actually drawn, and shrinks as patience drains', (
      WidgetTester tester,
    ) async {
      final game = await loadGame(tester);
      game.debugOpenNailCare();
      await tester.pump();

      final bar = find.byKey(const Key('nail-care-patience'));
      expect(bar, findsOneWidget);

      // The fill is the FractionallySizedBox inside the bar. It shipped once
      // with no heightFactor, which left it zero-tall — present in the tree,
      // correct width, and completely invisible. Size is the assertion.
      final fill = find.descendant(
        of: bar,
        matching: find.byType(FractionallySizedBox),
      );
      expect(fill, findsOneWidget);

      final fullSize = tester.getSize(fill);
      expect(fullSize.height, greaterThan(0));
      expect(fullSize.width, greaterThan(0));

      game.nailCare.patience = 0.25;
      await tester.pump();
      // Let the fill's tween settle on the new value.
      await tester.pump(const Duration(milliseconds: 400));

      final drainedSize = tester.getSize(fill);
      expect(drainedSize.height, fullSize.height);
      expect(drainedSize.width, lessThan(fullSize.width));
    });
  });

  group('combo', () {
    test('multiplier steps at the configured tiers', () {
      // Pure lookup, so it needs no game: tier boundaries are the part worth
      // pinning, since the payout of every operation hangs off them.
      expect(GameConfig.nailCareComboTier1, lessThan(GameConfig.nailCareComboTier2));
      expect(GameConfig.nailCareComboMultiplier1, greaterThan(1));
      expect(
        GameConfig.nailCareComboMultiplier2,
        greaterThan(GameConfig.nailCareComboMultiplier1),
      );
    });

    testWidgets('an operation that beats its bar extends the combo', (
      WidgetTester tester,
    ) async {
      final game = await loadGame(tester);
      game.debugOpenNailCare();
      expect(game.nailCare.combo, 0);

      washHand(game);

      expect(game.nailCare.stage, NailCareStage.handCleaningCompleted);
      expect(game.nailCare.combo, 1);
      expect(game.nailCare.stagesInTime, 1);
      expect(game.nailCare.stagesPaid, 1);
      // Below the first tier, so the reward is untouched — a player who is
      // not on a run never earns less than the base economy.
      expect(game.nailCare.comboMultiplier, 1);
      expect(game.nailCare.coins, GameConfig.nailCareWashCoinReward);
    });

    testWidgets('letting the bar run out breaks the combo', (
      WidgetTester tester,
    ) async {
      final game = await loadGame(tester);
      game.debugOpenNailCare();
      game.nailCare.combo = GameConfig.nailCareComboTier2;

      washHand(game, leadIn: GameConfig.nailCareStagePatienceSeconds + 1);

      expect(game.nailCare.patience, 0);
      expect(game.nailCare.combo, 0);
      expect(game.nailCare.comboMultiplier, 1);
      // The work still pays, and still counts — only the bonus was lost.
      expect(game.nailCare.stagesPaid, 1);
      expect(game.nailCare.stagesInTime, 0);
      expect(game.nailCare.coins, GameConfig.nailCareWashCoinReward);
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
