import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/model/salon_catalog.dart';
import 'package:nail_glam/model/player_progress.dart';

void main() {
  test('starter furniture is already owned', () {
    final progress = PlayerProgress.memory();
    expect(progress.owns(SalonCatalog.starterChair.id), isTrue);
    expect(progress.owns(SalonCatalog.pinkChair.id), isFalse);
  });

  test('buying spends coins and equips the piece', () {
    final progress = PlayerProgress.memory()..addCoins(500);
    expect(progress.buy(SalonCatalog.pinkChair), isTrue);
    expect(progress.coins, 0);
    expect(progress.owns(SalonCatalog.pinkChair.id), isTrue);
    expect(progress.equippedChairId, SalonCatalog.pinkChair.id);
  });

  test('kit colors persist after spending coins', () {
    final progress = PlayerProgress.memory()..addCoins(40);
    expect(progress.spendCoins(40), isTrue);
    progress.markOwned('polish-red');
    expect(progress.coins, 0);
    expect(progress.owns('polish-red'), isTrue);
    expect(progress.spendCoins(1), isFalse);
  });

  test('a locked piece stays locked without enough coins', () {
    final progress = PlayerProgress.memory()..addCoins(100);
    expect(progress.buy(SalonCatalog.pinkChair), isFalse);
    expect(progress.owns(SalonCatalog.pinkChair.id), isFalse);
    expect(progress.coins, 100);
  });

  test('daily login then play bonus need a finished customer', () {
    final progress = PlayerProgress.memory();
    progress.debugRollTo(DateTime(2026, 8, 23));
    expect(progress.canClaimLogin, isTrue);
    expect(progress.todayLoginReward, 100);
    expect(progress.claimDailyLogin(), 100);
    expect(progress.canClaimLogin, isFalse);
    expect(progress.canClaimPlayBonus, isFalse);

    progress.markCustomerFinished();
    expect(progress.claimPlayBonus(), SalonCatalog.dailyPlayBonus);
    expect(progress.canClaimPlayBonus, isFalse);
    expect(progress.coins, 100 + SalonCatalog.dailyPlayBonus);
  });

  test('skipping a day resets the login streak', () {
    final progress = PlayerProgress.memory();
    progress.debugRollTo(DateTime(2026, 8, 23));
    progress.claimDailyLogin();
    progress.debugRollTo(DateTime(2026, 8, 25));
    expect(progress.todayLoginDayNumber, 1);
    expect(progress.todayLoginReward, 100);
    expect(progress.canClaimLogin, isTrue);
  });

  test('the debug day-skipper walks the streak up, one tap per day', () {
    final progress = PlayerProgress.memory();
    progress.debugRollTo(DateTime(2026, 8, 23));
    expect(progress.todayLoginDayNumber, 1);
    expect(progress.todayLoginReward, 100);

    // Each hop lands on the day after the stored one, which is the only thing
    // the streak counts — so the ladder climbs instead of resetting to day 1.
    progress.claimDailyLogin();
    progress.debugAdvanceOneDay();
    expect(progress.todayLoginDayNumber, 2);
    expect(progress.todayLoginReward, 150);
    expect(progress.canClaimLogin, isTrue);

    progress.claimDailyLogin();
    progress.debugAdvanceOneDay();
    expect(progress.todayLoginDayNumber, 3);
    expect(progress.todayLoginReward, 200);

    // Unclaimed days still count as visits: the streak tracks logins.
    progress.debugAdvanceOneDay();
    expect(progress.todayLoginDayNumber, 4);
  });

  test('a sofa stays locked until the player can pay', () {
    final progress = PlayerProgress.memory()..addCoins(200);
    expect(progress.buy(SalonCatalog.blushSofa), isFalse);
    progress.addCoins(600);
    expect(progress.buy(SalonCatalog.blushSofa), isTrue);
    expect(progress.owns(SalonCatalog.blushSofa.id), isTrue);
  });

  test('a second day in a row raises the login streak', () {
    final progress = PlayerProgress.memory();
    progress.debugRollTo(DateTime(2026, 8, 23));
    progress.claimDailyLogin();
    progress.debugRollTo(DateTime(2026, 8, 24));
    expect(progress.todayLoginDayNumber, 2);
    expect(progress.todayLoginReward, 150);
    expect(progress.canClaimLogin, isTrue);
  });

  test('a clock that reads earlier than the stored day leaves the streak '
      'alone', () {
    // Regression test for the reset bug: lastLoginDay ends up ahead of
    // "today" whenever the device clock reads earlier than the last recorded
    // visit — a backward clock change, a timezone crossing, or (previously)
    // the debug day-skipper landing on a future date. _rollDay used to treat
    // that exactly like a missed day and zero the streak, so a real player's
    // progress could vanish for a reason that had nothing to do with them
    // actually skipping a day.
    final progress = PlayerProgress.memory();
    progress.debugRollTo(DateTime(2026, 8, 25));
    progress.claimDailyLogin();
    expect(progress.todayLoginDayNumber, 1);

    // The clock now reads a day *before* the stored lastLoginDay.
    progress.debugRollTo(DateTime(2026, 8, 24));

    expect(progress.todayLoginDayNumber, 1);
    expect(progress.canClaimLogin, isFalse);
  });

  test('refreshDay is a no-op on the same calendar day', () {
    final progress = PlayerProgress.memory();
    progress.debugRollTo(DateTime(2026, 8, 23));
    progress.claimDailyLogin();
    final streakBefore = progress.loginStreak;

    progress.debugRollTo(DateTime(2026, 8, 23));

    expect(progress.loginStreak, streakBefore);
    expect(progress.canClaimLogin, isFalse);
  });
}
