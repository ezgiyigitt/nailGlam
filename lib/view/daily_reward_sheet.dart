import 'package:flutter/material.dart';

import 'package:nail_glam/controller/game_audio.dart';
import 'package:nail_glam/controller/player_progress_controller.dart';
import 'package:nail_glam/model/salon_catalog.dart';

/// First visit of the day. The player must collect; the sheet cannot be
/// dismissed. The play bonus still waits until a customer is finished.
Future<void> showDailyRewardSheet({
  required BuildContext context,
  required PlayerProgressController progressController,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xCC3A1C28),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return DailyRewardDialog(progressController: progressController);
        },
  );
}

class DailyRewardDialog extends StatelessWidget {
  const DailyRewardDialog({required this.progressController, super.key});

  final PlayerProgressController progressController;

  @override
  Widget build(BuildContext context) {
    final progress = progressController;
    final today = progress.todayLoginDayNumber;
    return PopScope(
      canPop: false,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 22),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8FC),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFF4B6C8), width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Daily coins',
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE84F8F),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Come back every day. Miss a day and the streak restarts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 15,
                    color: Color(0xFF8A4B63),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    for (var i = 0; i < SalonCatalog.dailyLoginCoins.length; i++)
                      Expanded(
                        child: _DayCell(
                          day: i + 1,
                          coins: SalonCatalog.dailyLoginCoins[i],
                          state: i + 1 < today
                              ? _DayState.done
                              : i + 1 == today
                              ? _DayState.today
                              : _DayState.locked,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  '+${progress.todayLoginReward} coins today',
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5B3742),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Finish one customer for +${SalonCatalog.dailyPlayBonus} more.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 14,
                    color: Color(0xFF8A4B63),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6BA8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      progressController.claimDailyLogin();
                      GameAudio.instance.coin();
                      GameAudio.instance.success();
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Collect',
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _DayState { done, today, locked }

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.coins,
    required this.state,
  });

  final int day;
  final int coins;
  final _DayState state;

  @override
  Widget build(BuildContext context) {
    final today = state == _DayState.today;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: <Widget>[
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: today
                  ? const Color(0xFFFF6BA8)
                  : state == _DayState.done
                  ? const Color(0xFFFFE4F0)
                  : const Color(0xFFF3E6EA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: today
                    ? const Color(0xFFE84F8F)
                    : const Color(0x00FFFFFF),
                width: 2,
              ),
            ),
            child: Center(
              child: state == _DayState.locked
                  ? const Icon(
                      Icons.lock_rounded,
                      size: 16,
                      color: Color(0xFFC98AA3),
                    )
                  : state == _DayState.done
                  ? const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Color(0xFFE84F8F),
                    )
                  : Text(
                      '$coins',
                      style: const TextStyle(
                        fontFamily: 'Baloo2',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'D$day',
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: today
                  ? const Color(0xFFE84F8F)
                  : const Color(0xFF9A6A7A),
            ),
          ),
        ],
      ),
    );
  }
}
