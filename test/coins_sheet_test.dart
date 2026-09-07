import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/model/player_progress.dart';
import 'package:nail_glam/model/salon_catalog.dart';
import 'package:nail_glam/view/coins_sheet.dart';
import 'package:nail_glam/view/gold_coin.dart';

void main() {
  testWidgets('the chip is only a button when it has somewhere to go', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: GoldBalanceChip(coins: 120))),
      ),
    );
    expect(find.byKey(const Key('gold-balance-chip')), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: GoldBalanceChip(coins: 120, onTap: () {})),
        ),
      ),
    );
    expect(find.byKey(const Key('gold-balance-chip')), findsOneWidget);
  });

  testWidgets('the sheet shows the balance and claims the daily login', (
    WidgetTester tester,
  ) async {
    final PlayerProgress wallet = PlayerProgress.memory();
    wallet.debugRollTo(DateTime(2026, 8, 23));
    wallet.addCoins(120);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: CoinsDialog(wallet: wallet))),
    );

    expect(find.byKey(const Key('coins-sheet')), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('Ways to earn'), findsOneWidget);

    // Day one is unclaimed, so the collect button is offered...
    final int reward = SalonCatalog.dailyLoginCoins.first;
    expect(find.text('Collect +$reward'), findsOneWidget);

    await tester.tap(find.byKey(const Key('coins-sheet-claim')));
    await tester.pump();

    // ...and once taken it pays out and stops offering itself.
    expect(wallet.coins, 120 + reward);
    expect(find.text('${120 + reward}'), findsOneWidget);
    expect(find.byKey(const Key('coins-sheet-claim')), findsNothing);
  });

  testWidgets('the shop shortcut only appears when the caller can open it', (
    WidgetTester tester,
  ) async {
    final PlayerProgress wallet = PlayerProgress.memory();

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: CoinsDialog(wallet: wallet))),
    );
    expect(find.byKey(const Key('coins-sheet-shop')), findsNothing);

    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CoinsDialog(wallet: wallet, onOpenShop: () => opened += 1),
        ),
      ),
    );
    expect(find.byKey(const Key('coins-sheet-shop')), findsOneWidget);
    expect(opened, 0);
  });

  testWidgets('coins earned in the current manicure are called out', (
    WidgetTester tester,
  ) async {
    final PlayerProgress wallet = PlayerProgress.memory()..addCoins(40);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CoinsDialog(wallet: wallet, sessionCoins: 85)),
      ),
    );

    expect(find.text('+85 earned in this manicure'), findsOneWidget);
  });
}
