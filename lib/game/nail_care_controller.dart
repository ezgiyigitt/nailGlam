import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import 'audio/game_audio.dart';
import 'components/nail_workspace.dart';
import 'config/game_config.dart';
import 'config/nail_care_tools.dart';
import 'config/sprite_atlas.dart';
import 'progress/player_progress.dart';

/// Owns nail-care minigame state. UI listens; the workspace plays the art.
class NailCareController extends Component
    with HasGameReference<FlameGame>, ChangeNotifier {
  NailCareController({
    required this.workspace,
    required this.onRequestPinkyZoom,
    required this.onRequestRingZoom,
    required this.onRequestFinish,
    required this.progressOf,
  });

  final NailWorkspace workspace;
  final VoidCallback onRequestPinkyZoom;
  final VoidCallback onRequestRingZoom;
  final VoidCallback onRequestFinish;
  final PlayerProgress Function() progressOf;

  NailCareStage stage = NailCareStage.inactive;
  NailDigit digit = NailDigit.pinky;
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
  int coinBurstGeneration = 0;
  int coinBurstAmount = 0;

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
          stage == NailCareStage.nailCutting ||
          stage == NailCareStage.nailPolishing);

  bool get showsSelectedTool =>
      showsInventory && selectedItem != null && ownsKitItem(selectedItem!);

  bool get canAdvance =>
      !rewardOpen &&
      stageRewardClaimed &&
      (stage == NailCareStage.handCleaningCompleted ||
          stage == NailCareStage.nailBufferingCompleted ||
          stage == NailCareStage.nailCuttingCompleted ||
          stage == NailCareStage.nailPolishingCompleted);

  /// 0–1 across the whole manicure. Drives the face avatar.
  double get reactionProgress {
    switch (stage) {
      case NailCareStage.inactive:
        return 0;
      case NailCareStage.handCleaning:
        return actionProgress * 0.35;
      case NailCareStage.handCleaningCompleted:
      case NailCareStage.pinkyFingerFocus:
      case NailCareStage.ringFingerFocus:
        return 0.40;
      case NailCareStage.nailSpraying:
        return 0.40 + nailCleanProgress * 0.15;
      case NailCareStage.nailBuffering:
        return 0.55 + nailCleanProgress * 0.20;
      case NailCareStage.nailBufferingCompleted:
        return 0.75;
      case NailCareStage.nailCutting:
        return 0.75 + nailCleanProgress * 0.10;
      case NailCareStage.nailCuttingCompleted:
        return 0.85;
      case NailCareStage.nailPolishing:
        return 0.85 + nailCleanProgress * 0.15;
      case NailCareStage.nailPolishingCompleted:
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
    if (selected == null || !ownsKitItem(selected) || selected.toolId != id) {
      return false;
    }
    return NailCareCatalog.activeToolFor(stage)?.id == id;
  }

  List<NailCareInventoryItem> get currentKit =>
      NailCareInventory.itemsFor(stage);

  bool ownsKitItem(NailCareInventoryItem item) =>
      item.unlocked || progressOf().owns(item.id);

  void toggleInventory() {
    if (!showsInventory) {
      return;
    }
    inventoryOpen = !inventoryOpen;
    GameAudio.instance.tap();
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
    if (match == null) {
      return;
    }
    if (!ownsKitItem(match) && !_tryUnlock(match)) {
      GameAudio.instance.locked();
      return;
    }
    GameAudio.instance.tap();
    selectedItemId = match.id;
    inventoryOpen = false;
    if (match.polishColor != 0) {
      workspace.setPolishColor(match.polishColor);
    }
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
    GameAudio.instance.coin();
    adBonusApplied = false;
    stageRewardClaimed = true;
    notifyListeners();
  }

  void reset() {
    stage = NailCareStage.inactive;
    digit = NailDigit.pinky;
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
    GameAudio.instance.stopTool();
    notifyListeners();
  }

  void beginHandCleaning() {
    stage = NailCareStage.handCleaning;
    digit = NailDigit.pinky;
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
        GameAudio.instance.startSpray();
      } else if (stage == NailCareStage.nailBuffering) {
        GameAudio.instance.startBuffer();
      } else if (stage == NailCareStage.nailPolishing) {
        GameAudio.instance.startPolish();
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
    GameAudio.instance.stopTool();
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
    GameAudio.instance.tap();
    if (stage == NailCareStage.handCleaningCompleted) {
      digit = NailDigit.pinky;
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
      beginNailPolishing();
      return;
    }
    if (stage == NailCareStage.nailPolishingCompleted) {
      if (digit == NailDigit.pinky) {
        digit = NailDigit.ring;
        stage = NailCareStage.ringFingerFocus;
        toolHeldOverTarget = false;
        selectedItemId = null;
        inventoryOpen = false;
        stageRewardClaimed = false;
        nailCleanProgress = 0;
        actionProgress = 0;
        notifyListeners();
        onRequestRingZoom();
        return;
      }
      onRequestFinish();
    }
  }

  void beginNailBuffering() {
    if (stage != NailCareStage.pinkyFingerFocus &&
        stage != NailCareStage.ringFingerFocus &&
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
    if (digit == NailDigit.ring) {
      workspace.showRingNail(frame: 0);
    } else {
      workspace.showPinkyNail(frame: 0);
    }
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

  void beginNailPolishing() {
    if (stage != NailCareStage.nailCuttingCompleted) {
      return;
    }
    stage = NailCareStage.nailPolishing;
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
    workspace.showShortNail(frame: _shortSheet.frameCount - 1);
    workspace.setPolishFill(0);
    workspace.setPolishColor(NailCareInventory.polishes.first.polishColor);
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
      NailCareStage.nailPolishing => GameConfig.nailCarePolishHoldDuration,
      _ => GameConfig.nailCareBufferHoldDuration,
    };
    final previousFrame = _activeNailFrame(nailCleanProgress);
    nailCleanProgress = (nailCleanProgress + dt / duration).clamp(0.0, 1.0);
    actionProgress = _combinedNailProgress;
    if (stage == NailCareStage.nailPolishing) {
      workspace.setPolishFill(nailCleanProgress);
    } else {
      final frame = _activeNailFrame(nailCleanProgress);
      if (frame != previousFrame) {
        if (stage == NailCareStage.nailCutting) {
          workspace.setShortNailFrame(frame);
          GameAudio.instance.clip();
        } else {
          workspace.setPinkyFrame(frame);
        }
      }
    }
    notifyListeners();

    if (nailCleanProgress < 1) {
      return;
    }

    toolHeldOverTarget = false;
    workspace.hideSprayMist();
    GameAudio.instance.stopTool();
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
      workspace.setPinkyFrame(_cleanSheet.frameCount - 1);
      _openReward(GameConfig.nailCareBufferCoinReward);
      return;
    }
    if (stage == NailCareStage.nailCutting) {
      stage = NailCareStage.nailCuttingCompleted;
      workspace.setShortNailFrame(_shortSheet.frameCount - 1);
      _openReward(GameConfig.nailCareCutCoinReward);
      return;
    }

    stage = NailCareStage.nailPolishingCompleted;
    workspace.setPolishFill(1);
    _openReward(GameConfig.nailCarePolishCoinReward);
  }

  bool get _isNailHoldStage =>
      stage == NailCareStage.nailSpraying ||
      stage == NailCareStage.nailBuffering ||
      stage == NailCareStage.nailCutting ||
      stage == NailCareStage.nailPolishing;

  double get _combinedNailProgress {
    if (stage == NailCareStage.nailSpraying) {
      return nailCleanProgress * 0.5;
    }
    if (stage == NailCareStage.nailBuffering ||
        stage == NailCareStage.nailBufferingCompleted) {
      return 0.5 + nailCleanProgress * 0.5;
    }
    if (stage == NailCareStage.nailCutting ||
        stage == NailCareStage.nailCuttingCompleted ||
        stage == NailCareStage.nailPolishing ||
        stage == NailCareStage.nailPolishingCompleted) {
      return nailCleanProgress;
    }
    return nailCleanProgress;
  }

  bool _tryUnlock(NailCareInventoryItem item) {
    if (ownsKitItem(item)) {
      return true;
    }
    if (item.unlockPrice <= 0) {
      return false;
    }
    if (!_debit(item.unlockPrice)) {
      return false;
    }
    progressOf().markOwned(item.id);
    GameAudio.instance.coin();
    return true;
  }

  bool _debit(int amount) {
    if (amount <= 0) {
      return true;
    }
    if (coins + progressOf().coins < amount) {
      return false;
    }
    if (coins >= amount) {
      coins -= amount;
      return true;
    }
    final rest = amount - coins;
    coins = 0;
    return progressOf().spendCoins(rest);
  }

  void _startWashIfNeeded() {
    if (_washStarted) {
      return;
    }
    _washStarted = true;
    workspace.setWashProgress(0);
    GameAudio.instance.startSoap();
    notifyListeners();
  }

  void _openReward(int amount) {
    coins += amount;
    pendingCoins = 0;
    rewardOpen = false;
    adBonusApplied = false;
    stageRewardClaimed = true;
    coinBurstAmount = amount;
    coinBurstGeneration += 1;
    confettiGeneration += 1;
    GameAudio.instance.stopTool();
    GameAudio.instance.success();
    GameAudio.instance.coin();
    notifyListeners();
  }

  int _activeNailFrame(double progress) {
    if (stage == NailCareStage.nailPolishing ||
        stage == NailCareStage.nailPolishingCompleted) {
      return _shortSheet.frameCount - 1;
    }
    if (stage == NailCareStage.nailCutting ||
        stage == NailCareStage.nailCuttingCompleted) {
      final count = _shortSheet.frameCount;
      return (progress * (count - 1)).round().clamp(0, count - 1);
    }
    final local = (progress * 2).floor().clamp(0, 1);
    if (stage == NailCareStage.nailSpraying) {
      return local;
    }
    return 2 + local;
  }

  CharacterSheet get _cleanSheet =>
      digit == NailDigit.ring
          ? SpriteAtlas.fourthNail
          : SpriteAtlas.fifthNailClean;

  CharacterSheet get _shortSheet =>
      digit == NailDigit.ring
          ? SpriteAtlas.fourthShortNail
          : SpriteAtlas.shortNail;
}
