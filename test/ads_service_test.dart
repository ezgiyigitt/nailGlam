import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/controller/ads_service.dart';
import 'package:nail_glam/model/game_config.dart';

void main() {
  test('fake service reports ready and earns the reward', () async {
    final fake = FakeAdsService(delay: Duration.zero);

    expect(fake.isRewardedReady(AdPlacement.stageBonus), isTrue);
    expect(await fake.showRewarded(AdPlacement.stageBonus), isTrue);
    expect(fake.shownCount, 1);
  });

  test('disabled service never offers and never earns', () async {
    const disabled = DisabledAdsService();

    expect(disabled.isRewardedReady(AdPlacement.stageBonus), isFalse);
    expect(await disabled.showRewarded(AdPlacement.stageBonus), isFalse);
  });

  test('the default instance is swappable, and restores cleanly', () async {
    final original = AdsService.instance;
    addTearDown(() => AdsService.instance = original);

    AdsService.instance = const DisabledAdsService();
    expect(AdsService.instance.isRewardedReady(AdPlacement.stageBonus), isFalse);
  });

  test('the ad multiplier pays a bonus, not a replacement', () {
    // watchAdForBonus adds (multiplier - 1) x the base reward on top of coins
    // that were already paid, so a multiplier of 1 would make the offer a lie.
    expect(GameConfig.nailCareAdMultiplier, greaterThan(1));
  });
}
