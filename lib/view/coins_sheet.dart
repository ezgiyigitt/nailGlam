import 'package:flutter/material.dart';

import 'package:nail_glam/controller/ads_service.dart';
import 'package:nail_glam/controller/game_audio.dart';
import 'package:nail_glam/model/game_config.dart';
import 'package:nail_glam/model/player_progress.dart';
import 'package:nail_glam/model/salon_catalog.dart';
import 'gold_coin.dart';

/// What the wallet chip opens: the balance, and every way to grow it.
///
/// Built on [PlayerProgress] rather than the controller so both call sites can
/// use it — the menu holds a controller, the manicure page only ever gets the
/// wallet model.
///
/// [sessionCoins] is the amount earned in the manicure currently in progress,
/// which the gameplay HUD counts separately from the saved wallet. Pass 0 (the
/// default) anywhere that number would be meaningless.
Future<void> showCoinsSheet({
  required BuildContext context,
  required PlayerProgress wallet,
  int sessionCoins = 0,
  VoidCallback? onOpenShop,
}) {
  GameAudio.instance.tap();
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: const Color(0xCC3A1C28),
    builder: (BuildContext context) => CoinsDialog(
      wallet: wallet,
      sessionCoins: sessionCoins,
      onOpenShop: onOpenShop,
    ),
  );
}

class CoinsDialog extends StatelessWidget {
  const CoinsDialog({
    required this.wallet,
    this.sessionCoins = 0,
    this.onOpenShop,
    super.key,
  });

  final PlayerProgress wallet;
  final int sessionCoins;

  /// Shown as a shortcut button when the caller can actually open the shop.
  final VoidCallback? onOpenShop;

  static const Color _pink = Color(0xFFE84F8F);
  static const Color _ink = Color(0xFF8A4B63);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Container(
              key: const Key('coins-sheet'),
              margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8FC),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFF4B6C8), width: 3),
              ),
              child: ListenableBuilder(
                listenable: wallet,
                builder: (BuildContext context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        'Coins',
                        style: TextStyle(
                          fontFamily: 'Baloo2',
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: _pink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const GoldCoin(size: 34),
                          const SizedBox(width: 10),
                          Text(
                            '${wallet.coins}',
                            style: const TextStyle(
                              fontFamily: 'Baloo2',
                              fontSize: 40,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5B3742),
                            ),
                          ),
                        ],
                      ),
                      if (sessionCoins > 0) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          '+$sessionCoins earned in this manicure',
                          style: const TextStyle(
                            fontFamily: 'Baloo2',
                            fontSize: 14,
                            color: _ink,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _StreakStrip(wallet: wallet),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Ways to earn',
                          style: TextStyle(
                            fontFamily: 'Baloo2',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _EarnRow(
                        icon: Icons.card_giftcard_rounded,
                        title: 'Daily login',
                        detail: wallet.canClaimLogin
                            ? 'Day ${wallet.todayLoginDayNumber} is ready'
                            : 'Collected — come back tomorrow for more',
                        amount: '+${wallet.todayLoginReward}',
                      ),
                      _EarnRow(
                        icon: Icons.favorite_rounded,
                        title: 'First customer of the day',
                        detail: wallet.playBonusClaimedToday
                            ? 'Collected today'
                            : 'Finish one manicure to collect',
                        amount: '+${SalonCatalog.dailyPlayBonus}',
                      ),
                      _EarnRow(
                        icon: Icons.auto_awesome_rounded,
                        title: 'Every manicure step',
                        detail: 'Wash, wipe, clips and polish each pay out',
                        amount:
                            '+${GameConfig.nailCareWashCoinReward}'
                            '–${GameConfig.nailCarePolishCoinReward}',
                      ),
                      if (AdsService.instance.isRewardedReady(
                        AdPlacement.stageBonus,
                      ))
                        _EarnRow(
                          icon: Icons.play_circle_fill_rounded,
                          title: 'Watch a short video',
                          detail: 'Doubles the coins from a finished step',
                          amount: '×${GameConfig.nailCareAdMultiplier}',
                        ),
                      const SizedBox(height: 16),
                      if (wallet.canClaimLogin)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            key: const Key('coins-sheet-claim'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6BA8),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              wallet.claimDailyLogin();
                              GameAudio.instance.coin();
                              GameAudio.instance.success();
                            },
                            child: Text(
                              'Collect +${wallet.todayLoginReward}',
                              style: const TextStyle(
                                fontFamily: 'Baloo2',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      if (onOpenShop != null) ...<Widget>[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            key: const Key('coins-sheet-shop'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _pink, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              onOpenShop!();
                            },
                            child: const Text(
                              'Spend in the shop',
                              style: TextStyle(
                                fontFamily: 'Baloo2',
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: _pink,
                              ),
                            ),
                          ),
                        ),
                      ],
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontFamily: 'Baloo2',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _pink,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The seven-day ladder, with today marked. Same shape as the daily sheet's
/// row so the two screens read as one system.
class _StreakStrip extends StatelessWidget {
  const _StreakStrip({required this.wallet});

  final PlayerProgress wallet;

  @override
  Widget build(BuildContext context) {
    final int today = wallet.todayLoginDayNumber;
    return Row(
      children: <Widget>[
        for (int i = 0; i < SalonCatalog.dailyLoginCoins.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                children: <Widget>[
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: i + 1 == today
                          ? const Color(0xFFFF6BA8)
                          : i + 1 < today
                          ? const Color(0xFFFFE4F0)
                          : const Color(0xFFF3E6EA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: i + 1 < today
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Color(0xFFE84F8F),
                            )
                          : Text(
                              '${SalonCatalog.dailyLoginCoins[i]}',
                              style: TextStyle(
                                fontFamily: 'Baloo2',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: i + 1 == today
                                    ? Colors.white
                                    : const Color(0xFFC98AA3),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${i + 1}',
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 11,
                      color: Color(0xFF8A4B63),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _EarnRow extends StatelessWidget {
  const _EarnRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.amount,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 22, color: CoinsDialog._pink),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5B3742),
                    ),
                  ),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 12,
                      color: CoinsDialog._ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amount,
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF5B3742),
              ),
            ),
            const SizedBox(width: 4),
            const GoldCoin(size: 15),
          ],
        ),
      ),
    );
  }
}
