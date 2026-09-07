import 'package:flutter/foundation.dart';

/// Every spot in the game that may show an ad.
///
/// Keep the list small and named after the *game moment*, not the ad format:
/// swapping a placement's format later (rewarded → offerwall, say) should not
/// ripple through gameplay code.
enum AdPlacement {
  /// "Watch to double this stage's coins", offered right after a wash / cut /
  /// buffer / polish reward burst. See `NailCareController.watchAdForBonus`.
  stageBonus,

  /// "Watch to use this locked tool for the rest of this visit", offered from
  /// a locked item's preview sheet. See `NailCareController.watchAdForTrial`.
  ///
  /// The point of this placement is conversion, not ad revenue: letting
  /// someone actually feel a tool they have not bought is what makes its
  /// price tag legible. Keep it scoped to a single visit so it stays a taste
  /// of the thing rather than a substitute for buying it.
  toolTrial,
}

/// The seam between the game and whatever ad SDK ships with it.
///
/// Gameplay code never talks to an SDK directly — it talks to
/// [AdsService.instance]. The default is [FakeAdsService], so the whole
/// flow (offer chip → watch → bonus coins) is playable and testable with no
/// ad network wired up at all.
///
/// To go live: add the SDK to `pubspec.yaml`, write a `GoogleAdsService`
/// (or whichever network) that implements this interface, and set
/// `AdsService.instance = GoogleAdsService()` in `main()` before `runApp`.
/// Nothing else in the game needs to change.
///
/// Notes for that implementation:
///  * [showRewarded] must resolve `true` **only** when the network reports the
///    reward as earned — a dismissed or failed ad returns `false` and the
///    player keeps their base reward.
///  * Pause the game loop and duck `GameAudio` around a full-screen ad, and
///    restore both in a `finally` so a crashed ad never leaves the game muted.
///  * Ask for consent (UMP) and, on iOS, ATT before the first request.
///  * If the app ships to a kids/family audience, only certified SDKs and
///    non-personalised requests are allowed — decide that before wiring one up.
abstract class AdsService {
  /// The service the whole game reads. Swap it in `main()` for the real one,
  /// or in a test for a stub.
  static AdsService instance = FakeAdsService();

  /// Called once at startup. Safe to call again; implementations should
  /// no-op on a second call rather than re-initialising the SDK.
  Future<void> initialize();

  /// Whether a rewarded ad for [placement] is loaded and can be shown *now*.
  /// The HUD hides its offer when this is false, so the player is never shown
  /// a button that fails on tap.
  bool isRewardedReady(AdPlacement placement);

  /// Shows the rewarded ad and completes with `true` only if the player
  /// watched far enough to earn the reward.
  Future<bool> showRewarded(AdPlacement placement);

  /// Drop cached ads (called on app teardown).
  void dispose() {}
}

/// Pretends every rewarded ad is loaded and instantly earned.
///
/// This is the default so the bonus flow can be built and played before any
/// SDK exists. It costs nothing and shows nothing.
class FakeAdsService implements AdsService {
  FakeAdsService({this.delay = const Duration(milliseconds: 600)});

  /// Stands in for the time a real ad holds the screen, so the HUD's
  /// "watching…" state is exercised instead of flashing past.
  final Duration delay;

  int shownCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  bool isRewardedReady(AdPlacement placement) => true;

  @override
  Future<bool> showRewarded(AdPlacement placement) async {
    shownCount += 1;
    debugPrint('[ads] fake rewarded shown for $placement');
    await Future<void>.delayed(delay);
    return true;
  }

  @override
  void dispose() {}
}

/// No ads at all: nothing is ever ready, so every offer stays hidden.
///
/// Use this for tests that must not wait on a fake ad, and as the
/// belt-and-braces default if an SDK fails to initialise.
class DisabledAdsService implements AdsService {
  const DisabledAdsService();

  @override
  Future<void> initialize() async {}

  @override
  bool isRewardedReady(AdPlacement placement) => false;

  @override
  Future<bool> showRewarded(AdPlacement placement) async => false;

  @override
  void dispose() {}
}
