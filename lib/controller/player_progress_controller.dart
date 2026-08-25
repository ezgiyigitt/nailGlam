import 'package:flutter/foundation.dart';

import 'package:nail_glam/model/player_progress.dart';
import 'package:nail_glam/model/salon_catalog.dart';

/// MVC controller for wallet, shop and daily-login actions.
///
/// Views read state through this class and call its methods instead of
/// mutating [PlayerProgress] directly.
class PlayerProgressController extends ChangeNotifier {
  PlayerProgressController(PlayerProgress model) : _model = model {
    _model.addListener(_forwardModelChanges);
  }

  factory PlayerProgressController.memory() =>
      PlayerProgressController(PlayerProgress.memory());

  PlayerProgress _model;

  /// Wallet model for salon / nail-care systems that still read equipped ids.
  PlayerProgress get wallet => _model;

  /// Underlying model — for tests that seed state.
  @visibleForTesting
  PlayerProgress get model => _model;

  void attachModel(PlayerProgress model) {
    _model.removeListener(_forwardModelChanges);
    _model = model;
    _model.addListener(_forwardModelChanges);
    notifyListeners();
  }

  @override
  void dispose() {
    _model.removeListener(_forwardModelChanges);
    super.dispose();
  }

  void _forwardModelChanges() => notifyListeners();

  // --- Read state (views) ---

  int get coins => _model.coins;

  bool owns(String id) => _model.owns(id);

  bool isEquipped(ShopSlot slot, String itemId) =>
      _model.equipped[slot] == itemId;

  bool get canClaimLogin => _model.canClaimLogin;

  bool get hasPersistentStore => _model.store != null;

  bool get shouldPromptDailyLogin =>
      hasPersistentStore && canClaimLogin;

  int get todayLoginReward => _model.todayLoginReward;

  int get todayLoginDayNumber => _model.todayLoginDayNumber;

  bool canBuy(ShopItem item) =>
      !item.starter && !owns(item.id) && coins >= item.price;

  // --- Actions (views) ---

  bool buyShopItem(ShopItem item) => _model.buy(item);

  int claimDailyLogin() => _model.claimDailyLogin();

  // --- Actions (gameplay controller) ---

  void rewardFinishedCustomer(int coins) {
    _model.addCoins(coins);
    _model.markCustomerFinished();
    _model.claimPlayBonus();
  }
}
