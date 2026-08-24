import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/game/config/salon_catalog.dart';
import 'package:nail_glam/game/progress/player_progress.dart';

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
}
