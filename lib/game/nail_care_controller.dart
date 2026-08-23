import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import 'components/nail_workspace.dart';
import 'config/game_config.dart';
import 'config/nail_care_tools.dart';
import 'config/sprite_atlas.dart';

/// Owns nail-care minigame state. UI listens; the workspace plays the art.
class NailCareController extends Component
    with HasGameReference<FlameGame>, ChangeNotifier {
  NailCareController({
    required this.workspace,
    required this.onRequestPinkyZoom,
    required this.onRequestFinish,
  });

  final NailWorkspace workspace;
  final VoidCallback onRequestPinkyZoom;
  final VoidCallback onRequestFinish;

  NailCareStage stage = NailCareStage.inactive;
  bool toolHeldOverTarget = false;
  double nailCleanProgress = 0;
  double actionProgress = 0;

  bool inventoryOpen = false;
  String? selectedItemId;

  int coins = 0;
  int pendingCoins = 0;
  bool rewardOpen = false;
  bool adBonusApplied = false;
  bool stageRewardClaimed = false;
  int confettiGeneration = 0;

  bool _washStarted = false;

  NailCareTool? get activeTool => NailCareCatalog.activeToolFor(stage);

  NailCareInventoryItem? get selectedItem {
    final id = selectedItemId;
    if (id == null) {
      return null;
    }
    for (final item in NailCareInventory.itemsFor(stage)) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  bool get showsInventory =>
      !rewardOpen &&
      (stage == NailCareStage.handCleaning ||
          stage == NailCareStage.nailSpraying ||
          stage == NailCareStage.nailBuffering ||
          stage == NailCareStage.nailCutting);

  bool get showsSelectedTool =>
      showsInventory && selectedItem != null && selectedItem!.unlocked;

  bool get canAdvance =>
      !rewardOpen &&
      stageRewardClaimed &&
      (stage == NailCareStage.handCleaningCompleted ||
          stage == NailCareStage.nailBufferingCompleted ||
          stage == NailCareStage.nailCuttingCompleted);

  /// 0–1 across the whole manicure. Drives the face avatar.
  double get reactionProgress {
    switch (stage) {
      case NailCareStage.inactive:
        return 0;
      case NailCareStage.handCleaning:
        return actionProgress * 0.35;
      case NailCareStage.handCleaningCompleted:
      case NailCareStage.pinkyFingerFocus:
        return 0.40;
      case NailCareStage.nailSpraying:
        return 0.40 + nailCleanProgress * 0.15;
      case NailCareStage.nailBuffering:
        return 0.55 + nailCleanProgress * 0.20;
      case NailCareStage.nailBufferingCompleted:
        return 0.75;
      case NailCareStage.nailCutting:
        return 0.75 + nailCleanProgress * 0.25;
      case NailCareStage.nailCuttingCompleted:
        return 1;
    }
  }

  /// 0 = unhappy … 4 = delighted. One emotion sheet frame.
  int get emotionFrame {
    final progress = reactionProgress;
    if (progress >= 0.999) {
      return 4;
    }
    if (progress >= 0.60) {
      return 3;
    }
    if (progress >= 0.40) {
      return 2;
    }
    if (progress > 0.04) {
      return 1;
    }
    return 0;
  }

  bool canUse(NailCareToolId id) {
    final selected = selectedItem;
    if (selected == null || !selected.unlocked || selected.toolId != id) {
      return false;
    }
    return NailCareCatalog.activeToolFor(stage)?.id == id;
  }

  List<NailCareInventoryItem> get currentKit =>
      NailCareInventory.itemsFor(stage);

  void toggleInventory() {
    if (!showsInventory) {
      return;
    }
    inventoryOpen = !inventoryOpen;
    notifyListeners();
  }

  void closeInventory() {
    if (!inventoryOpen) {
      return;
    }
    inventoryOpen = false;
    notifyListeners();
  }

  void selectItem(String id) {
    if (!showsInventory) {
      return;
    }
    NailCareInventoryItem? match;
    for (final item in currentKit) {
      if (item.id == id) {
        match = item;
        break;
      }
    }
    if (match == null || !match.unlocked) {
      return;
    }
    selectedItemId = match.id;
    inventoryOpen = false;
    notifyListeners();
  }

  void watchAd() {
    if (!rewardOpen || adBonusApplied) {
      return;
    }
    pendingCoins *= GameConfig.nailCareAdMultiplier;
    adBonusApplied = true;
    notifyListeners();
  }

  void collectReward() {
    if (!rewardOpen) {
      return;
    }
    coins += pendingCoins;
    pendingCoins = 0;
    rewardOpen = false;
    adBonusApplied = false;
    stageRewardClaimed = true;
    notifyListeners();
  }

  void reset() {
    stage = NailCareStage.inactive;
    toolHeldOverTarget = false;
    nailCleanProgress = 0;
    actionProgress = 0;
    inventoryOpen = false;
    selectedItemId = null;
    pendingCoins = 0;
    rewardOpen = false;
    adBonusApplied = false;
    stageRewardClaimed = false;
    _washStarted = false;
    workspace.hideSprayMist();
    workspace.resetCare();
    notifyListeners();
  }

  void beginHandCleaning() {
    stage = NailCareStage.handCleaning;
    toolHeldOverTarget = false;
    nailCleanProgress = 0;
    actionProgress = 0;
    inventoryOpen = false;
    selectedItemId = null;
    pendingCoins = 0;
    rewardOpen = false;
    adBonusApplied = false;
    stageRewardClaimed = false;
    _washStarted = false;
    workspace.resetCare();
    notifyListeners();
  }

  void onToolHeldOverTarget(NailCareToolId id) {
    if (!canUse(id)) {
      return;
    }
    if (stage == NailCareStage.handCleaning) {
      _startWashIfNeeded();
      return;
    }
    if (_isNailHoldStage && !toolHeldOverTarget) {
      toolHeldOverTarget = true;
      if (stage == NailCareStage.nailSpraying) {
        workspace.showSprayMist();
      }
      notifyListeners();
    }
  }

  void onToolLeftTarget() {
    if (!toolHeldOverTarget) {
      return;
    }
    toolHeldOverTarget = false;
    workspace.hideSprayMist();
    notifyListeners();
  }

  void onToolDroppedOnTarget(NailCareToolId id) {
    if (stage == NailCareStage.handCleaning) {
      onToolHeldOverTarget(id);
      return;
    }
    if (_isNailHoldStage) {
      onToolLeftTarget();
    }
  }

  void advanceFromNext() {
    if (!canAdvance) {
      return;
    }
    if (stage == NailCareStage.handCleaningCompleted) {
      stage = NailCareStage.pinkyFingerFocus;
      toolHeldOverTarget = false;
      selectedItemId = null;
      inventoryOpen = false;
      stageRewardClaimed = false;
      notifyListeners();
      onRequestPinkyZoom();
      return;
    }
    if (stage == NailCareStage.nailBufferingCompleted) {
      beginNailCutting();
      return;
    }
    if (stage == NailCareStage.nailCuttingCompleted) {
      onRequestFinish();
    }
  }

  void beginNailBuffering() {
    if (stage != NailCareStage.pinkyFingerFocus &&
        stage != NailCareStage.handCleaningCompleted) {
      return;
    }
    stage = NailCareStage.nailSpraying;
    toolHeldOverTarget = false;
    nailCleanProgress = 0;
    actionProgress = 0;
    inventoryOpen = false;
    selectedItemId = null;
    pendingCoins = 0;
    rewardOpen = false;
    adBonusApplied = false;
    stageRewardClaimed = false;
    workspace.hideSprayMist();
    workspace.showPinkyNail(frame: 0);
    notifyListeners();
  }

  void beginNailCutting() {
    if (stage != NailCareStage.nailBufferingCompleted) {
      return;
    }
    stage = NailCareStage.nailCutting;
    toolHeldOverTarget = false;
    nailCleanProgress = 0;
    actionProgress = 0;
    inventoryOpen = false;
    selectedItemId = null;
    pendingCoins = 0;
    rewardOpen = false;
    adBonusApplied = false;
    stageRewardClaimed = false;
    workspace.hideSprayMist();
    workspace.showShortNail(frame: 0);
    notifyListeners();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.paused || rewardOpen) {
      return;
    }

    if (stage == NailCareStage.handCleaning && _washStarted) {
      if (actionProgress >= 1) {
        return;
      }
      final next = (actionProgress + dt / GameConfig.nailCareWashDuration)
          .clamp(0.0, 1.0);
      workspace.setWashProgress(next);
      actionProgress = next;
      if (next >= 1) {
        stage = NailCareStage.handCleaningCompleted;
        _openReward(GameConfig.nailCareWashCoinReward);
      } else {
        notifyListeners();
      }
      return;
    }

    if (!_isNailHoldStage || !toolHeldOverTarget) {
      return;
    }

    final duration = switch (stage) {
      NailCareStage.nailSpraying => GameConfig.nailCareSprayHoldDuration,
      NailCareStage.nailBuffering => GameConfig.nailCareBufferHoldDuration,
      NailCareStage.nailCutting => GameConfig.nailCareCutHoldDuration,
      _ => GameConfig.nailCareBufferHoldDuration,
    };
    final previousFrame = _activeNailFrame(nailCleanProgress);
    nailCleanProgress = (nailCleanProgress + dt / duration).clamp(0.0, 1.0);
    actionProgress = _combinedNailProgress;
    final frame = _activeNailFrame(nailCleanProgress);
    if (frame != previousFrame) {
      if (stage == NailCareStage.nailCutting) {
        workspace.setShortNailFrame(frame);
      } else {
        workspace.setPinkyFrame(frame);
      }
    }
    notifyListeners();

    if (nailCleanProgress < 1) {
      return;
    }

    toolHeldOverTarget = false;
    workspace.hideSprayMist();
    if (stage == NailCareStage.nailSpraying) {
      stage = NailCareStage.nailBuffering;
      nailCleanProgress = 0;
      selectedItemId = null;
      workspace.setPinkyFrame(1);
      notifyListeners();
      return;
    }
    if (stage == NailCareStage.nailBuffering) {
      stage = NailCareStage.nailBufferingCompleted;
      workspace.setPinkyFrame(SpriteAtlas.fifthNailClean.frameCount - 1);
      _openReward(GameConfig.nailCareBufferCoinReward);
      return;
    }

    stage = NailCareStage.nailCuttingCompleted;
    workspace.setShortNailFrame(SpriteAtlas.shortNail.frameCount - 1);
    _openReward(GameConfig.nailCareCutCoinReward);
  }

  bool get _isNailHoldStage =>
      stage == NailCareStage.nailSpraying ||
      stage == NailCareStage.nailBuffering ||
      stage == NailCareStage.nailCutting;

  double get _combinedNailProgress {
    if (stage == NailCareStage.nailSpraying) {
      return nailCleanProgress * 0.5;
    }
    if (stage == NailCareStage.nailBuffering ||
        stage == NailCareStage.nailBufferingCompleted) {
      return 0.5 + nailCleanProgress * 0.5;
    }
    if (stage == NailCareStage.nailCutting ||
        stage == NailCareStage.nailCuttingCompleted) {
      return nailCleanProgress;
    }
    return nailCleanProgress;
  }

  void _startWashIfNeeded() {
    if (_washStarted) {
      return;
    }
    _washStarted = true;
    workspace.setWashProgress(0);
    notifyListeners();
  }

  void _openReward(int amount) {
    pendingCoins = amount;
    adBonusApplied = false;
    rewardOpen = true;
    stageRewardClaimed = false;
    confettiGeneration += 1;
    notifyListeners();
  }

  int _activeNailFrame(double progress) {
    if (stage == NailCareStage.nailCutting ||
        stage == NailCareStage.nailCuttingCompleted) {
      final count = SpriteAtlas.shortNail.frameCount;
      return (progress * (count - 1)).round().clamp(0, count - 1);
    }
    final local = (progress * 2).floor().clamp(0, 1);
    if (stage == NailCareStage.nailSpraying) {
      return local;
    }
    return 2 + local;
  }
}
