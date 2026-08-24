import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/salon_catalog.dart';

/// Coins, owned salon pieces and the daily-login streak.
///
/// Nail-care rewards used to live only on the controller and vanished on
/// reset. This is the wallet the shop and the daily chest both read.
class PlayerProgress extends ChangeNotifier {
  PlayerProgress._({
    required this.coins,
    required this.owned,
    required this.equipped,
    required this.loginStreak,
    required this.lastLoginDay,
    required this.loginClaimedToday,
    required this.customersFinishedToday,
    required this.playBonusClaimedToday,
  });

  final Set<String> owned;
  final Map<ShopSlot, String> equipped;
  SharedPreferences? store;

  int coins;
  int loginStreak;
  String lastLoginDay;
  bool loginClaimedToday;
  int customersFinishedToday;
  bool playBonusClaimedToday;

  static const String _coinsKey = 'progress.coins';
  static const String _ownedKey = 'progress.owned';
  static const String _equippedKey = 'progress.equipped';
  static const String _streakKey = 'progress.streak';
  static const String _lastDayKey = 'progress.lastDay';
  static const String _loginClaimedKey = 'progress.loginClaimed';
  static const String _customersKey = 'progress.customersToday';
  static const String _playBonusKey = 'progress.playBonus';

  /// Disk-backed wallet for the real app.
  static Future<PlayerProgress> load() async {
    final prefs = await SharedPreferences.getInstance();
    return _fromStore(prefs);
  }

  /// In-memory wallet so tests never touch the device.
  static PlayerProgress memory() => _empty();

  static PlayerProgress _empty() {
    return PlayerProgress._(
      coins: 0,
      owned: <String>{
        SalonCatalog.starterChair.id,
        SalonCatalog.starterTable.id,
      },
      equipped: <ShopSlot, String>{
        ShopSlot.chair: SalonCatalog.starterChair.id,
        ShopSlot.table: SalonCatalog.starterTable.id,
      },
      loginStreak: 0,
      lastLoginDay: '',
      loginClaimedToday: false,
      customersFinishedToday: 0,
      playBonusClaimedToday: false,
    );
  }

  static PlayerProgress _fromStore(SharedPreferences prefs) {
    final progress = _empty()..store = prefs;
    progress.coins = prefs.getInt(_coinsKey) ?? 0;
    final savedOwned = prefs.getStringList(_ownedKey);
    if (savedOwned != null) {
      progress.owned
        ..clear()
        ..addAll(savedOwned);
    }
    final savedEquipped = prefs.getStringList(_equippedKey) ?? <String>[];
    for (final entry in savedEquipped) {
      final parts = entry.split(':');
      if (parts.length != 2) {
        continue;
      }
      final slot = ShopSlot.values.asNameMap()[parts[0]];
      if (slot == null) {
        continue;
      }
      progress.equipped[slot] = parts[1];
    }
    progress.loginStreak = prefs.getInt(_streakKey) ?? 0;
    progress.lastLoginDay = prefs.getString(_lastDayKey) ?? '';
    progress.loginClaimedToday = prefs.getBool(_loginClaimedKey) ?? false;
    progress.customersFinishedToday = prefs.getInt(_customersKey) ?? 0;
    progress.playBonusClaimedToday = prefs.getBool(_playBonusKey) ?? false;
    progress._rollDay(DateTime.now());
    return progress;
  }

  String get equippedChairId =>
      equipped[ShopSlot.chair] ?? SalonCatalog.starterChair.id;

  String get equippedTableId =>
      equipped[ShopSlot.table] ?? SalonCatalog.starterTable.id;

  bool owns(String id) => owned.contains(id);

  bool get canClaimLogin => !loginClaimedToday;

  int get todayLoginReward {
    final index = (loginStreak - 1).clamp(
      0,
      SalonCatalog.dailyLoginCoins.length - 1,
    );
    return SalonCatalog.dailyLoginCoins[index];
  }

  int get todayLoginDayNumber => loginStreak.clamp(
    1,
    SalonCatalog.dailyLoginCoins.length,
  );

  bool get canClaimPlayBonus =>
      !playBonusClaimedToday && customersFinishedToday >= 1;

  void addCoins(int amount) {
    if (amount <= 0) {
      return;
    }
    coins += amount;
    _persist();
    notifyListeners();
  }

  bool spendCoins(int amount) {
    if (amount <= 0 || coins < amount) {
      return false;
    }
    coins -= amount;
    _persist();
    notifyListeners();
    return true;
  }

  void markOwned(String id) {
    if (!owned.add(id)) {
      return;
    }
    _persist();
    notifyListeners();
  }

  bool buy(ShopItem item) {
    if (item.starter || owns(item.id) || coins < item.price) {
      return false;
    }
    coins -= item.price;
    owned.add(item.id);
    equipped[item.slot] = item.id;
    _persist();
    notifyListeners();
    return true;
  }

  int claimDailyLogin() {
    if (!canClaimLogin) {
      return 0;
    }
    final reward = todayLoginReward;
    coins += reward;
    loginClaimedToday = true;
    _persist();
    notifyListeners();
    return reward;
  }

  void markCustomerFinished() {
    customersFinishedToday += 1;
    _persist();
    notifyListeners();
  }

  int claimPlayBonus() {
    if (!canClaimPlayBonus) {
      return 0;
    }
    coins += SalonCatalog.dailyPlayBonus;
    playBonusClaimedToday = true;
    _persist();
    notifyListeners();
    return SalonCatalog.dailyPlayBonus;
  }

  /// Advances the streak when a new calendar day starts.
  void _rollDay(DateTime now) {
    final today = _dayKey(now);
    if (lastLoginDay == today) {
      return;
    }
    final yesterday = _dayKey(now.subtract(const Duration(days: 1)));
    loginStreak = lastLoginDay == yesterday
        ? (loginStreak + 1).clamp(1, SalonCatalog.dailyLoginCoins.length)
        : 1;
    lastLoginDay = today;
    loginClaimedToday = false;
    customersFinishedToday = 0;
    playBonusClaimedToday = false;
    _persist();
  }

  @visibleForTesting
  void debugRollTo(DateTime day) => _rollDay(day);

  void _persist() {
    final prefs = store;
    if (prefs == null) {
      return;
    }
    prefs.setInt(_coinsKey, coins);
    prefs.setStringList(_ownedKey, owned.toList());
    prefs.setStringList(
      _equippedKey,
      equipped.entries
          .map((MapEntry<ShopSlot, String> e) => '${e.key.name}:${e.value}')
          .toList(),
    );
    prefs.setInt(_streakKey, loginStreak);
    prefs.setString(_lastDayKey, lastLoginDay);
    prefs.setBool(_loginClaimedKey, loginClaimedToday);
    prefs.setInt(_customersKey, customersFinishedToday);
    prefs.setBool(_playBonusKey, playBonusClaimedToday);
  }

  static String _dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}
