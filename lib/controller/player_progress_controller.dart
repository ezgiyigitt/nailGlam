import 'package:flutter/foundation.dart';

import 'package:nail_glam/model/nail_care_tools.dart';
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

  // --- Manicure tool skins (shop Tools tab) ---

  bool ownsSkin(NailCareInventoryItem item) =>
      item.unlocked || owns(item.id);

  bool canBuySkin(NailCareInventoryItem item) =>
      !ownsSkin(item) && coins >= item.unlockPrice;

  bool isToolEquipped(NailCareToolId tool, String itemId) {
    if (_model.isToolEquipped(tool.name, itemId)) {
      return true;
    }
    // Nothing picked yet: the free starter is what the HUD shows.
    return _model.equippedToolId(tool.name) == null &&
        _defaultSkinFor(tool)?.id == itemId;
  }

  NailCareInventoryItem? _defaultSkinFor(NailCareToolId tool) {
    for (final item in NailCareInventory.skinsFor(tool)) {
      if (ownsSkin(item)) {
        return item;
      }
    }
    return null;
  }

  // --- Actions (views) ---

  bool buyShopItem(ShopItem item) => _model.buy(item);

  bool buySkin(NailCareInventoryItem item) => _model.buyTool(
    toolKey: item.toolId.name,
    itemId: item.id,
    price: item.unlockPrice,
  );

  void equipSkin(NailCareInventoryItem item) {
    if (!ownsSkin(item)) {
      return;
    }
    _model.equipTool(item.toolId.name, item.id);
  }

  /// Re-equips an already-owned piece (e.g. switching back to the starter
  /// chair/table after buying a premium one).
  bool equipShopItem(ShopItem item) => _model.equip(item);

  int claimDailyLogin() => _model.claimDailyLogin();

  /// Current login streak, for the debug day-skipper's readout.
  int get loginStreak => _model.loginStreak;

  /// Debug-only: jump to tomorrow so the daily-login streak can be stepped
  /// through by hand. Guard call sites with [kDebugMode]; there is no UI for
  /// this in a release build.
  void debugAdvanceOneDay() => _model.debugAdvanceOneDay();

  // --- Actions (gameplay controller) ---

  void rewardFinishedCustomer(int coins) {
    _model.addCoins(coins);
    _model.markCustomerFinished();
    _model.claimPlayBonus();
  }
}
