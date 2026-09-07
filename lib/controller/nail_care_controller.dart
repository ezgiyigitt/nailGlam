import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import 'package:nail_glam/controller/ads_service.dart';
import 'package:nail_glam/controller/game_audio.dart';
import 'package:nail_glam/view/components/nail_workspace.dart';
import 'package:nail_glam/model/game_config.dart';
import 'package:nail_glam/model/guest_care_kit.dart';
import 'package:nail_glam/model/nail_finger_treatment.dart';
import 'package:nail_glam/model/nail_care_tools.dart';
import 'package:nail_glam/model/sprite_atlas.dart';
import 'package:nail_glam/model/player_progress.dart';

/// Owns nail-care minigame state. UI listens; the workspace plays the art.
class NailCareController extends Component
    with HasGameReference<FlameGame>, ChangeNotifier {
  NailCareController({
    required this.workspace,
    required this.onRequestFingerZoom,
    required this.onRequestHandReveal,
    required this.onRequestFinish,
    required this.progressOf,
  });

  final NailWorkspace workspace;
  final VoidCallback onRequestFingerZoom;
  final VoidCallback onRequestHandReveal;
  final VoidCallback onRequestFinish;
  final PlayerProgress Function() progressOf;

  String guestId = 'customer1';
  GuestCareKit get careKit => GuestCareCatalog.forId(guestId);

  NailCareStage stage = NailCareStage.inactive;
  CareTarget careTarget = CareTarget.hand;
  NailDigit digit = NailDigit.pinky;
  NailShape nailShape = NailShape.square;
  bool nailShapeChoiceOpen = false;

  /// True once the guest has picked a shape for this manicure — later
  /// fingers reuse it instead of asking again on every cutting page.
  bool _nailShapeLockedIn = false;
  bool toolHeldOverTarget = false;
  double nailCleanProgress = 0;
  double actionProgress = 0;

  /// Clip stage: each snip needs a fresh touch (leave + re-enter).
  bool _clipSnipReady = true;

  bool inventoryOpen = false;
  String? selectedItemId;

  int coins = 0;
  int pendingCoins = 0;
  bool rewardOpen = false;
  bool adBonusApplied = false;

  /// Coins the last stage reward paid out. While this is non-zero the HUD may
  /// offer "watch an ad to double it"; [_clearAdBonusOffer] takes the offer
  /// away the moment the player moves on to the next stage.
  int adBonusOfferAmount = 0;

  /// True while a rewarded ad is on screen, so the chip can show a spinner and
  /// a second tap cannot start a second ad.
  bool adBonusPending = false;
  bool stageRewardClaimed = false;
  int confettiGeneration = 0;
  int coinBurstGeneration = 0;
  int coinBurstAmount = 0;

  bool _washStarted = false;
  int _activePolishColor = NailCareInventory.polishes.first.polishColor;
  final Map<NailDigit, int> polishByDigit = <NailDigit, int>{};
  final Map<NailDigit, DigitSimSnapshot> _digitSim =
      <NailDigit, DigitSimSnapshot>{};

  /// Highlighted slot on the HUD strip; none during hand wash or reveal.
  NailDigit? get simActiveDigit {
    switch (stage) {
      case NailCareStage.inactive:
      case NailCareStage.handCleaning:
      case NailCareStage.handCleaningCompleted:
      case NailCareStage.handReveal:
      case NailCareStage.footCleaning:
      case NailCareStage.footCleaningCompleted:
      case NailCareStage.footNailSpraying:
      case NailCareStage.footNailBuffering:
      case NailCareStage.footNailBufferingCompleted:
      case NailCareStage.footNailCutting:
      case NailCareStage.footNailCuttingCompleted:
      case NailCareStage.footNailPolishing:
      case NailCareStage.footNailPolishingCompleted:
      case NailCareStage.footReveal:
        return null;
      case NailCareStage.pinkyFingerFocus:
      case NailCareStage.ringFingerFocus:
      case NailCareStage.middleFingerFocus:
      case NailCareStage.indexFingerFocus:
      case NailCareStage.thumbFingerFocus:
      case NailCareStage.nailSpraying:
      case NailCareStage.nailBuffering:
      case NailCareStage.nailBufferingCompleted:
      case NailCareStage.nailCutting:
      case NailCareStage.nailCuttingCompleted:
      case NailCareStage.nailPolishing:
      case NailCareStage.nailPolishingCompleted:
        return digit;
    }
  }

  /// Overlay-only read of one finger: locked work plus live progress.
  DigitSimSnapshot simSnapshotFor(NailDigit d) {
    final stored = _digitSim[d] ?? const DigitSimSnapshot();
    if (stage == NailCareStage.handReveal) {
      return stored.copyWith(
        cleanProgress: stored.cleanProgress > 0 ? stored.cleanProgress : 1,
        cutFrame: stored.cutFrame,
        polishColor: polishByDigit[d] ?? stored.polishColor,
      );
    }
    if (d != digit) {
      return stored.copyWith(
        polishColor: polishByDigit[d] ?? stored.polishColor,
      );
    }
    switch (stage) {
      case NailCareStage.nailSpraying:
        return stored.copyWith(cleanProgress: nailCleanProgress * 0.5);
      case NailCareStage.nailBuffering:
        return stored.copyWith(
          cleanProgress: 0.5 + nailCleanProgress * 0.5,
        );
      case NailCareStage.nailBufferingCompleted:
        return stored.copyWith(cleanProgress: 1);
      case NailCareStage.nailCutting:
        return stored.copyWith(
          cleanProgress: 1,
          cutFrame: (nailCleanProgress * 3).round().clamp(0, 3),
        );
      case NailCareStage.nailCuttingCompleted:
        return stored.copyWith(cleanProgress: 1, cutFrame: 3);
      case NailCareStage.nailPolishing:
        return stored.copyWith(
          cleanProgress: 1,
          cutFrame: careKit.allowsCutAndPolish(d) ? 3 : stored.cutFrame,
          polishColor: nailCleanProgress > 0.05
              ? _activePolishColor
              : stored.polishColor,
        );
      case NailCareStage.nailPolishingCompleted:
        return stored.copyWith(
          cleanProgress: 1,
          cutFrame: careKit.allowsCutAndPolish(d) ? 3 : stored.cutFrame,
          polishColor: polishByDigit[d] ?? stored.polishColor,
        );
      case NailCareStage.inactive:
      case NailCareStage.handCleaning:
      case NailCareStage.handCleaningCompleted:
      case NailCareStage.pinkyFingerFocus:
      case NailCareStage.ringFingerFocus:
      case NailCareStage.middleFingerFocus:
      case NailCareStage.indexFingerFocus:
      case NailCareStage.thumbFingerFocus:
      case NailCareStage.handReveal:
      case NailCareStage.footCleaning:
      case NailCareStage.footCleaningCompleted:
      case NailCareStage.footNailSpraying:
      case NailCareStage.footNailBuffering:
      case NailCareStage.footNailBufferingCompleted:
      case NailCareStage.footNailCutting:
      case NailCareStage.footNailCuttingCompleted:
      case NailCareStage.footNailPolishing:
      case NailCareStage.footNailPolishingCompleted:
      case NailCareStage.footReveal:
        return stored;
    }
  }

  void _lockDigitSim(
    NailDigit d, {
    double? cleanProgress,
    int? cutFrame,
    int? polishColor,
    NailShape? shape,
  }) {
    final prev = _digitSim[d] ?? const DigitSimSnapshot();
    _digitSim[d] = DigitSimSnapshot(
      cleanProgress: cleanProgress ?? prev.cleanProgress,
      cutFrame: cutFrame ?? prev.cutFrame,
      polishColor: polishColor ?? prev.polishColor,
      shape: shape ?? prev.shape,
    );
  }

  /// Fingers that still need polish before the manicure is complete.
  int get nailsRemaining {
    final targets =
        careKit.cutPolishDigits ?? NailDigit.values.toSet();
    return targets.where((NailDigit d) => (polishByDigit[d] ?? 0) == 0).length;
  }

  int get nailsTotal {
    final targets = careKit.cutPolishDigits;
    return targets?.length ?? NailDigit.values.length;
  }

  /// Painted nails so far (for the shared HUD hand counter).
  int get nailsDone => (nailsTotal - nailsRemaining).clamp(0, nailsTotal);

  /// Mini hand tracker during nail work only — hidden on reveal so it does
  /// not cover the finished full-hand art.
  bool get showsNailHud => showsProgressBar && careTarget == CareTarget.hand;

  NailCareTool? get activeTool => NailCareCatalog.activeToolFor(stage);

  NailCareInventoryItem? get selectedItem {
    final id = selectedItemId;
    if (id == null) {
      return null;
    }
    for (final list in <List<NailCareInventoryItem>>[
      NailCareInventory.soaps,
      NailCareInventory.sprays,
      NailCareInventory.buffers,
      NailCareInventory.clips,
      NailCareInventory.polishes,
      NailCareInventory.brushes,
    ]) {
      for (final item in list) {
        if (item.id == id) {
          return item;
        }
      }
    }
    return null;
  }

  /// The skin the player equipped in the shop for [tool], falling back to the
  /// free starter. This is what the HUD card shows and what gets dragged, so
  /// there is no picker to open mid-manicure any more.
  NailCareInventoryItem? equippedItemFor(NailCareToolId tool) {
    final skins = NailCareInventory.skinsFor(tool);
    if (skins.isEmpty) {
      return null;
    }
    final equippedId = progressOf().equippedToolId(tool.name);
    if (equippedId != null) {
      for (final item in skins) {
        if (item.id == equippedId && ownsKitItem(item)) {
          return item;
        }
      }
    }
    for (final item in skins) {
      if (ownsKitItem(item)) {
        return item;
      }
    }
    return null;
  }

  /// Polish keeps its picker: colours are chosen per nail, not equipped once.
  bool get usesPolishPanel =>
      stage == NailCareStage.nailPolishing ||
      stage == NailCareStage.nailPolishingCompleted ||
      stage == NailCareStage.footNailPolishing ||
      stage == NailCareStage.footNailPolishingCompleted;

  /// Spray drawer thumbnail: equipped skin, or the free starter.
  NailCareInventoryItem get sprayDrawerPreview =>
      equippedItemFor(NailCareToolId.nailSpray) ?? NailCareInventory.spray;

  /// Wipe drawer thumbnail: equipped skin, or the free starter.
  NailCareInventoryItem get wipeDrawerPreview =>
      equippedItemFor(NailCareToolId.nailBuffer) ??
      NailCareInventory.buffers.first;

  bool get showsInventory =>
      !rewardOpen &&
      (stage == NailCareStage.handCleaning ||
          stage == NailCareStage.nailSpraying ||
          stage == NailCareStage.nailBuffering ||
          stage == NailCareStage.nailCutting ||
          stage == NailCareStage.nailPolishing ||
          stage == NailCareStage.footCleaning ||
          stage == NailCareStage.footNailSpraying ||
          stage == NailCareStage.footNailBuffering ||
          stage == NailCareStage.footNailCutting ||
          stage == NailCareStage.footNailPolishing);

  /// Only polish still parks a separate chip on screen; every other tool is
  /// dragged straight off its HUD card.
  bool get showsSelectedTool =>
      showsInventory &&
      usesPolishPanel &&
      selectedItem != null &&
      ownsKitItem(selectedItem!);

  bool get canAdvance =>
      !rewardOpen &&
      stageRewardClaimed &&
      (stage == NailCareStage.handCleaningCompleted ||
          stage == NailCareStage.nailBufferingCompleted ||
          stage == NailCareStage.nailCuttingCompleted ||
          stage == NailCareStage.nailPolishingCompleted ||
          stage == NailCareStage.handReveal ||
          stage == NailCareStage.footCleaningCompleted ||
          stage == NailCareStage.footNailBufferingCompleted ||
          stage == NailCareStage.footNailCuttingCompleted ||
          stage == NailCareStage.footNailPolishingCompleted ||
          stage == NailCareStage.footReveal);

  /// Whether the HUD shows the bottom progress bar and wallet header.
  bool get showsProgressBar {
    switch (stage) {
      case NailCareStage.inactive:
      case NailCareStage.pinkyFingerFocus:
        return false;
      case NailCareStage.handCleaning:
      case NailCareStage.handCleaningCompleted:
      case NailCareStage.ringFingerFocus:
      case NailCareStage.middleFingerFocus:
      case NailCareStage.indexFingerFocus:
      case NailCareStage.thumbFingerFocus:
      case NailCareStage.nailSpraying:
      case NailCareStage.nailBuffering:
      case NailCareStage.nailBufferingCompleted:
      case NailCareStage.nailCutting:
      case NailCareStage.nailCuttingCompleted:
      case NailCareStage.nailPolishing:
      case NailCareStage.nailPolishingCompleted:
      case NailCareStage.footCleaning:
      case NailCareStage.footCleaningCompleted:
      case NailCareStage.footNailSpraying:
      case NailCareStage.footNailBuffering:
      case NailCareStage.footNailBufferingCompleted:
      case NailCareStage.footNailCutting:
      case NailCareStage.footNailCuttingCompleted:
      case NailCareStage.footNailPolishing:
      case NailCareStage.footNailPolishingCompleted:
        return true;
      case NailCareStage.handReveal:
      case NailCareStage.footReveal:
        return false;
    }
  }

  /// Hand vs nail drop target for the current stage.
  bool get usesNailDropTarget {
    switch (stage) {
      case NailCareStage.pinkyFingerFocus:
      case NailCareStage.ringFingerFocus:
      case NailCareStage.middleFingerFocus:
      case NailCareStage.indexFingerFocus:
      case NailCareStage.thumbFingerFocus:
      case NailCareStage.nailSpraying:
      case NailCareStage.nailBuffering:
      case NailCareStage.nailBufferingCompleted:
      case NailCareStage.nailCutting:
      case NailCareStage.nailCuttingCompleted:
      case NailCareStage.nailPolishing:
      case NailCareStage.nailPolishingCompleted:
        return true;
      case NailCareStage.inactive:
      case NailCareStage.handCleaning:
      case NailCareStage.handCleaningCompleted:
      case NailCareStage.handReveal:
      case NailCareStage.footCleaning:
      case NailCareStage.footCleaningCompleted:
      case NailCareStage.footNailSpraying:
      case NailCareStage.footNailBuffering:
      case NailCareStage.footNailBufferingCompleted:
      case NailCareStage.footNailCutting:
      case NailCareStage.footNailCuttingCompleted:
      case NailCareStage.footNailPolishing:
      case NailCareStage.footNailPolishingCompleted:
      case NailCareStage.footReveal:
        return false;
    }
  }

  String get progressLabel {
    if (stage == NailCareStage.nailPolishing ||
        stage == NailCareStage.nailPolishingCompleted ||
        stage == NailCareStage.footNailPolishing ||
        stage == NailCareStage.footNailPolishingCompleted) {
      return 'Polish';
    }
    return 'Clean';
  }

  String? get stageCue {
    final name = digit.label;
    switch (stage) {
      case NailCareStage.handCleaning:
        return 'Open SOAPS and drag soap onto the hand';
      case NailCareStage.footCleaning:
        return 'Open SOAPS and drag soap onto the foot';
      case NailCareStage.ringFingerFocus:
      case NailCareStage.middleFingerFocus:
      case NailCareStage.indexFingerFocus:
      case NailCareStage.thumbFingerFocus:
        return 'Now the ${name.toUpperCase()}';
      case NailCareStage.nailSpraying:
        return 'Spray the $name to loosen grime';
      case NailCareStage.nailBuffering:
        return 'Wipe the $name until it shines';
      case NailCareStage.footNailSpraying:
        return 'Spray the toes to loosen grime';
      case NailCareStage.footNailBuffering:
        return 'Wipe the toes until they shine';
      case NailCareStage.nailCutting:
        return 'Open CLIPS — touch the nail once per snip';
      case NailCareStage.footNailCutting:
        return 'Open CLIPS — touch the toes once per snip';
      case NailCareStage.nailPolishing:
        return 'Open POLISHES and paint the $name';
      case NailCareStage.handCleaningCompleted:
      case NailCareStage.nailCuttingCompleted:
      case NailCareStage.footCleaningCompleted:
        return 'Nice! Tap NEXT to keep going';
      case NailCareStage.nailBufferingCompleted:
        if (!careKit.allowsCutAndPolish(digit) && digit.next == null) {
          return 'Nice! Tap NEXT to see your work';
        }
        return 'Nice! Tap NEXT to keep going';
      case NailCareStage.footNailBufferingCompleted:
        return 'Nice! Tap NEXT to keep going';
      case NailCareStage.footNailCuttingCompleted:
        return 'Nice! Tap NEXT to keep going';
      case NailCareStage.footNailPolishing:
        return 'Open POLISHES and paint the toes';
      case NailCareStage.footNailPolishingCompleted:
        return 'Nice! Tap NEXT to see your work';
      case NailCareStage.nailPolishingCompleted:
        final next = digit.next;
        return next == null
            ? 'Nice! Tap NEXT to see your work'
            : 'Nice! Next up: the ${next.label}';
      case NailCareStage.handReveal:
      case NailCareStage.footReveal:
        return null;
      case NailCareStage.inactive:
      case NailCareStage.pinkyFingerFocus:
        return null;
    }
  }

  bool get showsStageCue {
    final cue = stageCue;
    return cue != null && (actionProgress <= 0 || canAdvance);
  }

  bool get showsSplitToolBoxes =>
      showsInventory && NailCareInventory.splitSprayAndWipe(stage);

  List<NailCareInventoryItem> get panelItems => _openKit ?? currentKit;

  String get panelTitle {
    if (identical(_openKit, NailCareInventory.sprays)) {
      return 'Spray';
    }
    if (identical(_openKit, NailCareInventory.buffers)) {
      return 'Wipe';
    }
    return NailCareInventory.kitLabelFor(stage);
  }

  List<NailCareInventoryItem>? _openKit;

  /// 0–1 across the whole manicure. Drives the face avatar.
  double get reactionProgress {
    switch (stage) {
      case NailCareStage.inactive:
        return 0;
      case NailCareStage.handCleaning:
      case NailCareStage.footCleaning:
        return actionProgress * 0.35;
      case NailCareStage.handCleaningCompleted:
      case NailCareStage.pinkyFingerFocus:
      case NailCareStage.ringFingerFocus:
      case NailCareStage.middleFingerFocus:
      case NailCareStage.indexFingerFocus:
      case NailCareStage.thumbFingerFocus:
      case NailCareStage.footCleaningCompleted:
        return 0.40;
      case NailCareStage.nailSpraying:
      case NailCareStage.footNailSpraying:
        return 0.40 + nailCleanProgress * 0.15;
      case NailCareStage.nailBuffering:
      case NailCareStage.footNailBuffering:
        return 0.55 + nailCleanProgress * 0.20;
      case NailCareStage.nailBufferingCompleted:
      case NailCareStage.footNailBufferingCompleted:
        return 0.75;
      case NailCareStage.nailCutting:
      case NailCareStage.footNailCutting:
        return 0.75 + nailCleanProgress * 0.10;
      case NailCareStage.nailCuttingCompleted:
      case NailCareStage.footNailCuttingCompleted:
        return 0.85;
      case NailCareStage.nailPolishing:
      case NailCareStage.footNailPolishing:
        return 0.85 + nailCleanProgress * 0.15;
      case NailCareStage.nailPolishingCompleted:
      case NailCareStage.footNailPolishingCompleted:
      case NailCareStage.handReveal:
      case NailCareStage.footReveal:
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
    if (NailCareCatalog.activeToolFor(stage)?.id != id) {
      return false;
    }
    if (usesPolishPanel) {
      final selected = selectedItem;
      return selected != null &&
          ownsKitItem(selected) &&
          selected.toolId == id;
    }
    // Soap / spray / wipe / clips: whatever is equipped in the shop is what
    // the card carries, so owning it is the only gate.
    return equippedItemFor(id) != null;
  }

  List<NailCareInventoryItem> get currentKit =>
      NailCareInventory.itemsFor(stage);

  bool ownsKitItem(NailCareInventoryItem item) =>
      item.unlocked || progressOf().owns(item.id);

  void toggleInventory([List<NailCareInventoryItem>? kit]) {
    // Only the polish stage still has a picker; every other kit is equipped in
    // the shop and dragged straight from the HUD card.
    if (!showsInventory || !usesPolishPanel) {
      return;
    }
    final target = kit ?? currentKit;
    if (inventoryOpen && identical(_openKit ?? currentKit, target)) {
      closeInventory();
      return;
    }
    GameAudio.instance.tap();
    _openKit = kit;
    inventoryOpen = true;
    notifyListeners();
  }

  void closeInventory() {
    if (!inventoryOpen && _openKit == null) {
      return;
    }
    inventoryOpen = false;
    _openKit = null;
    notifyListeners();
  }

  void selectItem(String id) {
    final match = itemById(id);
    if (match == null || !ownsKitItem(match)) {
      return;
    }
    GameAudio.instance.tap();
    selectedItemId = match.id;
    inventoryOpen = false;
    _openKit = null;
    if (match.polishColor != 0) {
      _activePolishColor = match.polishColor;
      workspace.setPolishColor(match.polishColor);
      if (stage == NailCareStage.footNailPolishing ||
          stage == NailCareStage.footNailPolishingCompleted) {
        // The foot takes its colour by argument, so repaint now instead of
        // leaving the swatch disagreeing with the toes until the next hold.
        workspace.showFootPolish(
          color: match.polishColor,
          fill: nailCleanProgress,
        );
      }
    }
    notifyListeners();
  }

  NailCareInventoryItem? itemById(String id) {
    for (final item in panelItems) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  bool unlockItem(String id) {
    final match = itemById(id);
    if (match == null) {
      return false;
    }
    final unlocked = _tryUnlock(match);
    if (!unlocked) {
      GameAudio.instance.locked();
    }
    return unlocked;
  }

  bool ownsOrUnlocked(String id) {
    final match = itemById(id);
    if (match == null) {
      return false;
    }
    return ownsKitItem(match);
  }

  void equipItem(String id) {
    if (!showsInventory) {
      return;
    }
    final match = itemById(id);
    if (match == null || !ownsKitItem(match)) {
      return;
    }
    GameAudio.instance.tap();
    selectedItemId = match.id;
    inventoryOpen = false;
    _openKit = null;
    if (match.polishColor != 0) {
      _activePolishColor = match.polishColor;
      workspace.setPolishColor(match.polishColor);
      if (stage == NailCareStage.footNailPolishing ||
          stage == NailCareStage.footNailPolishingCompleted) {
        // The foot takes its colour by argument, so repaint now instead of
        // leaving the swatch disagreeing with the toes until the next hold.
        workspace.showFootPolish(
          color: match.polishColor,
          fill: nailCleanProgress,
        );
      }
    }
    notifyListeners();
  }

  /// Whether the HUD should offer "watch an ad, double this reward".
  ///
  /// Gated on the ad actually being loaded so the chip never appears for a
  /// tap that would fail, and on the offer not having been taken already.
  bool get showsAdBonusOffer =>
      adBonusOfferAmount > 0 &&
      !adBonusApplied &&
      !adBonusPending &&
      AdsService.instance.isRewardedReady(AdPlacement.stageBonus);

  /// Extra coins the offer is worth, on top of the reward already paid.
  int get adBonusCoins =>
      adBonusOfferAmount * (GameConfig.nailCareAdMultiplier - 1);

  /// Plays the rewarded ad and, only if the network says the reward was
  /// earned, pays the difference between the base reward and the multiplied
  /// one. A dismissed or failed ad simply leaves the base reward alone.
  Future<void> watchAdForBonus() async {
    if (!showsAdBonusOffer) {
      return;
    }
    final int bonus = adBonusCoins;
    adBonusPending = true;
    notifyListeners();
    bool earned = false;
    try {
      earned = await AdsService.instance.showRewarded(AdPlacement.stageBonus);
    } finally {
      adBonusPending = false;
    }
    if (!earned || bonus <= 0) {
      notifyListeners();
      return;
    }
    adBonusApplied = true;
    adBonusOfferAmount = 0;
    coins += bonus;
    coinBurstAmount = bonus;
    coinBurstGeneration += 1;
    GameAudio.instance.coin();
    notifyListeners();
  }

  /// Takes the doubling offer off the HUD. Called wherever a stage ends or the
  /// flow resets, so an offer can never carry over into the next stage.
  void _clearAdBonusOffer() {
    adBonusApplied = false;
    adBonusOfferAmount = 0;
    adBonusPending = false;
  }

  void collectReward() {
    if (!rewardOpen) {
      return;
    }
    coins += pendingCoins;
    pendingCoins = 0;
    rewardOpen = false;
    GameAudio.instance.coin();
    _clearAdBonusOffer();
    stageRewardClaimed = true;
    notifyListeners();
  }

  void reset() {
    stage = NailCareStage.inactive;
    careTarget = CareTarget.hand;
    digit = NailDigit.pinky;
    nailShape = NailShape.square;
    nailShapeChoiceOpen = false;
    _nailShapeLockedIn = false;
    toolHeldOverTarget = false;
    _clipSnipReady = true;
    nailCleanProgress = 0;
    actionProgress = 0;
    inventoryOpen = false;
    _openKit = null;
    selectedItemId = null;
    pendingCoins = 0;
    rewardOpen = false;
    _clearAdBonusOffer();
    stageRewardClaimed = false;
    _washStarted = false;
    polishByDigit.clear();
    _digitSim.clear();
    _activePolishColor = NailCareInventory.polishes.first.polishColor;
    workspace.hideSprayMist();
    workspace.resetCare();
    GameAudio.instance.stopTool();
    notifyListeners();
  }

  void beginHandCleaning() {
    stage = NailCareStage.handCleaning;
    digit = NailDigit.pinky;
    nailShape = NailShape.square;
    _nailShapeLockedIn = false;
    toolHeldOverTarget = false;
    _clipSnipReady = true;
    nailCleanProgress = 0;
    actionProgress = 0;
    inventoryOpen = false;
    _openKit = null;
    selectedItemId = null;
    pendingCoins = 0;
    rewardOpen = false;
    _clearAdBonusOffer();
    stageRewardClaimed = false;
    _washStarted = false;
    polishByDigit.clear();
    _digitSim.clear();
    _activePolishColor = NailCareInventory.polishes.first.polishColor;
    workspace.resetCare();
    notifyListeners();
  }

  /// Foot flow entry point, mirrors [beginHandCleaning] but on foot art.
  void beginFootCleaning() {
    careTarget = CareTarget.foot;
    stage = NailCareStage.footCleaning;
    digit = NailDigit.pinky;
    toolHeldOverTarget = false;
    _clipSnipReady = true;
    nailCleanProgress = 0;
    actionProgress = 0;
    inventoryOpen = false;
    _openKit = null;
    selectedItemId = null;
    pendingCoins = 0;
    rewardOpen = false;
    _clearAdBonusOffer();
    stageRewardClaimed = false;
    _washStarted = false;
    polishByDigit.clear();
    _digitSim.clear();
    _activePolishColor = NailCareInventory.polishes.first.polishColor;
    workspace.showFootWashHand(cleanliness: 0);
    notifyListeners();
  }

  void onToolHeldOverTarget(NailCareToolId id) {
    if (!canUse(id)) {
      return;
    }
    if (stage == NailCareStage.handCleaning || stage == NailCareStage.footCleaning) {
      _startWashIfNeeded();
      return;
    }
    if (stage == NailCareStage.nailCutting || stage == NailCareStage.footNailCutting) {
      if (!_clipSnipReady) {
        return;
      }
      _clipSnipReady = false;
      toolHeldOverTarget = true;
      if (stage == NailCareStage.footNailCutting) {
        _applyFootClipSnip();
      } else {
        _applyClipSnip();
      }
      return;
    }
    if (_isContinuousNailHoldStage && !toolHeldOverTarget) {
      toolHeldOverTarget = true;
      if (stage == NailCareStage.nailSpraying) {
        workspace.showSprayMist();
        GameAudio.instance.startSpray();
      } else if (stage == NailCareStage.nailBuffering) {
        GameAudio.instance.startBuffer();
      } else if (stage == NailCareStage.footNailSpraying) {
        workspace.showSprayMist();
        GameAudio.instance.startSpray();
      } else if (stage == NailCareStage.footNailBuffering) {
        GameAudio.instance.startBuffer();
      } else if (stage == NailCareStage.nailPolishing ||
          stage == NailCareStage.footNailPolishing) {
        GameAudio.instance.startPolish();
      }
      notifyListeners();
    }
  }

  void onToolLeftTarget() {
    if (stage == NailCareStage.nailCutting || stage == NailCareStage.footNailCutting) {
      _clipSnipReady = true;
      if (!toolHeldOverTarget) {
        return;
      }
      toolHeldOverTarget = false;
      notifyListeners();
      return;
    }
    if (!toolHeldOverTarget) {
      return;
    }
    toolHeldOverTarget = false;
    workspace.hideSprayMist();
    GameAudio.instance.stopTool();
    notifyListeners();
  }

  void onToolDroppedOnTarget(NailCareToolId id) {
    if (stage == NailCareStage.handCleaning || stage == NailCareStage.footCleaning) {
      onToolHeldOverTarget(id);
      return;
    }
    if (stage == NailCareStage.nailCutting ||
        stage == NailCareStage.footNailCutting ||
        _isContinuousNailHoldStage) {
      onToolLeftTarget();
    }
  }

  /// One snip per touch. Holding still does nothing until the tool leaves.
  void _applyClipSnip() {
    final last = (_shortSheet.frameCount - 1).clamp(1, 99);
    final current = _activeNailFrame(nailCleanProgress);
    final next = (current + 1).clamp(0, last);
    nailCleanProgress = next / last;
    actionProgress = nailCleanProgress;
    workspace.setShortNailFrame(next);
    GameAudio.instance.clip();
    if (next >= last) {
      toolHeldOverTarget = false;
      _clipSnipReady = false;
      _lockDigitSim(
        digit,
        cleanProgress: 1,
        cutFrame: 3,
        shape: nailShape,
      );
      stage = NailCareStage.nailCuttingCompleted;
      workspace.setShortNailFrame(_shortSheet.frameCount - 1);
      _releaseTool();
      _openReward(GameConfig.nailCareCutCoinReward);
      return;
    }
    notifyListeners();
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
    _openKit = null;
      stageRewardClaimed = false;
      notifyListeners();
      onRequestFingerZoom();
      return;
    }
    if (stage == NailCareStage.nailBufferingCompleted) {
      if (!careKit.allowsCutAndPolish(digit)) {
        _advanceToNextFingerOrReveal();
        return;
      }
      beginNailCutting();
      return;
    }
    if (stage == NailCareStage.nailCuttingCompleted) {
      beginNailPolishing();
      return;
    }
    if (stage == NailCareStage.nailPolishingCompleted) {
      _advanceToNextFingerOrReveal();
      return;
    }
    if (stage == NailCareStage.handReveal) {
      onRequestFinish();
      return;
    }
    if (stage == NailCareStage.footCleaningCompleted) {
      stage = NailCareStage.footNailSpraying;
      toolHeldOverTarget = false;
      selectedItemId = null;
      inventoryOpen = false;
      _openKit = null;
      stageRewardClaimed = false;
      nailCleanProgress = 0;
      actionProgress = 0;
      workspace.setFootNailCleanProgress(0);
      notifyListeners();
      return;
    }
    if (stage == NailCareStage.footNailBufferingCompleted) {
      beginFootNailCutting();
      return;
    }
    if (stage == NailCareStage.footNailCuttingCompleted) {
      beginFootNailPolishing();
      return;
    }
    if (stage == NailCareStage.footNailPolishingCompleted) {
      beginFootReveal();
      return;
    }
    if (stage == NailCareStage.footReveal) {
      onRequestFinish();
    }
  }

  /// Whole-foot toenail cutting — every toe shortens together, one snip per
  /// touch, no shape choice (mirrors [beginNailCutting] minus the picker).
  void beginFootNailCutting() {
    if (stage != NailCareStage.footNailBufferingCompleted) {
      return;
    }
    stage = NailCareStage.footNailCutting;
    toolHeldOverTarget = false;
    _clipSnipReady = true;
    nailCleanProgress = 0;
    actionProgress = 0;
    inventoryOpen = false;
    _openKit = null;
    selectedItemId = null;
    pendingCoins = 0;
    rewardOpen = false;
    _clearAdBonusOffer();
    stageRewardClaimed = false;
    workspace.hideSprayMist();
    workspace.showFootNailCutFrame(0);
    notifyListeners();
  }

  void _applyFootClipSnip() {
    final last = (careKit.footNailCutSheet.frameCount - 1).clamp(1, 99);
    final current = (nailCleanProgress * last).round().clamp(0, last);
    final next = (current + 1).clamp(0, last);
    nailCleanProgress = next / last;
    actionProgress = nailCleanProgress;
    workspace.showFootNailCutFrame(next);
    GameAudio.instance.clip();
    if (next >= last) {
      toolHeldOverTarget = false;
      _clipSnipReady = false;
      stage = NailCareStage.footNailCuttingCompleted;
      workspace.showFootNailCutFrame(last);
      _releaseTool();
      _openReward(GameConfig.nailCareCutCoinReward);
      return;
    }
    notifyListeners();
  }

  /// Lacquer every toenail in one sweep — the pedicure has no per-toe loop,
  /// so this mirrors [beginNailPolishing] without the digit bookkeeping.
  void beginFootNailPolishing() {
    if (stage != NailCareStage.footNailCuttingCompleted) {
      return;
    }
    stage = NailCareStage.footNailPolishing;
    toolHeldOverTarget = false;
    nailCleanProgress = 0;
    actionProgress = 0;
    inventoryOpen = false;
    _openKit = null;
    selectedItemId = null;
    pendingCoins = 0;
    rewardOpen = false;
    _clearAdBonusOffer();
    stageRewardClaimed = false;
    workspace.hideSprayMist();
    workspace.showFootPolish(color: _activePolishColor, fill: 0);
    notifyListeners();
  }

  void beginFootReveal() {
    stage = NailCareStage.footReveal;
    toolHeldOverTarget = false;
    nailCleanProgress = 1;
    actionProgress = 1;
    inventoryOpen = false;
    _openKit = null;
    selectedItemId = null;
    rewardOpen = false;
    stageRewardClaimed = true;
    workspace.hideSprayMist();
    // Hold the painted toes — re-running the clean strip here would wipe the
    // lacquer the guest just watched go on.
    workspace.showFootPolish(color: _activePolishColor, fill: 1);
    onRequestHandReveal();
    notifyListeners();
  }

  void _advanceToNextFingerOrReveal() {
    final next = digit.next;
    if (next != null) {
      digit = next;
      stage = next.focusStage;
      toolHeldOverTarget = false;
      selectedItemId = null;
      inventoryOpen = false;
      _openKit = null;
      stageRewardClaimed = false;
      nailCleanProgress = 0;
      actionProgress = 0;
      notifyListeners();
      onRequestFingerZoom();
      return;
    }
    beginHandReveal();
  }

  void beginHandReveal() {
    stage = NailCareStage.handReveal;
    toolHeldOverTarget = false;
    nailCleanProgress = 1;
    actionProgress = 1;
    inventoryOpen = false;
    _openKit = null;
    selectedItemId = null;
    rewardOpen = false;
    stageRewardClaimed = true;
    workspace.hideSprayMist();
    workspace.showFinishedHand(polishByDigit, _allCutDigitsAreStiletto);
    onRequestHandReveal();
    notifyListeners();
  }

  /// True once every nail that got cut+polished this visit was stiletto
  /// shaped — the trigger for the dedicated stiletto reveal art.
  bool get _allCutDigitsAreStiletto {
    final targets = careKit.cutPolishDigits ?? NailDigit.values.toSet();
    if (targets.isEmpty) {
      return false;
    }
    return targets.every(
      (NailDigit d) => _digitSim[d]?.shape == NailShape.stiletto,
    );
  }

  void beginNailBuffering() {
    if (stage != NailCareStage.pinkyFingerFocus &&
        stage != NailCareStage.ringFingerFocus &&
        stage != NailCareStage.middleFingerFocus &&
        stage != NailCareStage.indexFingerFocus &&
        stage != NailCareStage.thumbFingerFocus &&
        stage != NailCareStage.handCleaningCompleted) {
      return;
    }
    stage = NailCareStage.nailSpraying;
    toolHeldOverTarget = false;
    nailCleanProgress = 0;
    actionProgress = 0;
    inventoryOpen = false;
    _openKit = null;
    selectedItemId = null;
    pendingCoins = 0;
    rewardOpen = false;
    _clearAdBonusOffer();
    stageRewardClaimed = false;
    workspace.hideSprayMist();
    workspace.beginSprayTreatment(digit);
    notifyListeners();
  }

  void beginNailCutting() {
    if (stage != NailCareStage.nailBufferingCompleted) {
      return;
    }
    stage = NailCareStage.nailCutting;
    toolHeldOverTarget = false;
    _clipSnipReady = true;
    nailCleanProgress = 0;
    actionProgress = 0;
    inventoryOpen = false;
    _openKit = null;
    selectedItemId = null;
    pendingCoins = 0;
    rewardOpen = false;
    _clearAdBonusOffer();
    stageRewardClaimed = false;
    workspace.hideSprayMist();
    if (_nailShapeLockedIn) {
      // Shape was already chosen for an earlier finger this visit — reuse it
      // silently instead of asking again.
      workspace.setNailShape(nailShape, digit: digit);
      workspace.showShortNail(frame: 0);
      nailShapeChoiceOpen = false;
    } else {
      workspace.setNailShape(NailShape.square, digit: digit);
      workspace.showShortNail(frame: 0);
      nailShapeChoiceOpen = true;
    }
    notifyListeners();
  }

  void selectNailShape(NailShape shape) {
    if (stage != NailCareStage.nailCutting ||
        nailCleanProgress > 0 ||
        !nailShapeChoiceOpen) {
      return;
    }
    nailShape = shape;
    _nailShapeLockedIn = true;
    nailShapeChoiceOpen = false;
    workspace.setNailShape(shape, digit: digit);
    GameAudio.instance.tap();
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
    _openKit = null;
    selectedItemId = null;
    pendingCoins = 0;
    rewardOpen = false;
    _clearAdBonusOffer();
    stageRewardClaimed = false;
    workspace.hideSprayMist();
    workspace.showShortNail(frame: _shortSheet.frameCount - 1);
    workspace.setPolishFill(0);
    workspace.setPolishColor(_activePolishColor);
    notifyListeners();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.paused || rewardOpen) {
      return;
    }

    if ((stage == NailCareStage.handCleaning ||
            stage == NailCareStage.footCleaning) &&
        _washStarted) {
      if (actionProgress >= 1) {
        return;
      }
      final next = (actionProgress + dt / GameConfig.nailCareWashDuration)
          .clamp(0.0, 1.0);
      if (stage == NailCareStage.footCleaning) {
        workspace.setFootWashProgress(next);
      } else {
        workspace.setWashProgress(next);
      }
      actionProgress = next;
      if (next >= 1) {
        stage = stage == NailCareStage.footCleaning
            ? NailCareStage.footCleaningCompleted
            : NailCareStage.handCleaningCompleted;
        _releaseTool();
        _openReward(GameConfig.nailCareWashCoinReward);
      } else {
        notifyListeners();
      }
      return;
    }

    if (!_isContinuousNailHoldStage || !toolHeldOverTarget) {
      return;
    }

    final isFootNail = stage == NailCareStage.footNailSpraying ||
        stage == NailCareStage.footNailBuffering;

    final duration = switch (stage) {
      NailCareStage.nailSpraying => GameConfig.nailCareSprayHoldDuration,
      NailCareStage.nailBuffering => GameConfig.nailCareBufferHoldDuration,
      NailCareStage.nailPolishing => GameConfig.nailCarePolishHoldDuration,
      NailCareStage.footNailSpraying => GameConfig.nailCareSprayHoldDuration,
      NailCareStage.footNailBuffering => GameConfig.nailCareBufferHoldDuration,
      NailCareStage.footNailPolishing => GameConfig.nailCarePolishHoldDuration,
      _ => GameConfig.nailCareBufferHoldDuration,
    };
    final previousFrame = isFootNail ? 0 : _activeNailFrame(nailCleanProgress);
    nailCleanProgress = (nailCleanProgress + dt / duration).clamp(0.0, 1.0);
    // Last wipe/spray cell shows before the timer hits 1. Treat that as
    // done so Next is not locked behind a second hold.
    if (isFootNail) {
      if (nailCleanProgress >= 0.999) {
        nailCleanProgress = 1;
      }
    } else if (_holdShowsFinalArt) {
      nailCleanProgress = 1;
    }
    actionProgress = _combinedNailProgress;
    if (stage == NailCareStage.nailPolishing) {
      workspace.setPolishFill(nailCleanProgress);
    } else if (stage == NailCareStage.footNailPolishing) {
      workspace.showFootPolish(
        color: _activePolishColor,
        fill: nailCleanProgress,
      );
    } else if (isFootNail) {
      workspace.setFootNailCleanProgress(actionProgress);
    } else {
      final frame = _activeNailFrame(nailCleanProgress);
      if (frame != previousFrame) {
        workspace.setPinkyFrame(frame);
      }
    }
    notifyListeners();

    if (nailCleanProgress < 1) {
      return;
    }

    toolHeldOverTarget = false;
    workspace.hideSprayMist();
    GameAudio.instance.stopTool();
    _releaseTool();
    if (stage == NailCareStage.nailSpraying) {
      stage = NailCareStage.nailBuffering;
      nailCleanProgress = 0;
      if (_splitNailSheets) {
        workspace.beginWipeTreatment(digit);
      } else {
        workspace.setPinkyFrame(1);
      }
      notifyListeners();
      return;
    }
    if (stage == NailCareStage.nailBuffering) {
      _lockDigitSim(digit, cleanProgress: 1);
      stage = NailCareStage.nailBufferingCompleted;
      workspace.setPinkyFrame(_cleanSheet.frameCount - 1);
      _openReward(GameConfig.nailCareBufferCoinReward);
      return;
    }
    if (stage == NailCareStage.footNailSpraying) {
      stage = NailCareStage.footNailBuffering;
      nailCleanProgress = 0;
      workspace.setFootNailCleanProgress(0.5);
      notifyListeners();
      return;
    }
    if (stage == NailCareStage.footNailBuffering) {
      stage = NailCareStage.footNailBufferingCompleted;
      workspace.setFootNailCleanProgress(1);
      _openReward(GameConfig.nailCareBufferCoinReward);
      return;
    }

    if (stage == NailCareStage.footNailPolishing) {
      stage = NailCareStage.footNailPolishingCompleted;
      workspace.showFootPolish(color: _activePolishColor, fill: 1);
      _openReward(GameConfig.nailCarePolishCoinReward);
      return;
    }

    stage = NailCareStage.nailPolishingCompleted;
    polishByDigit[digit] = _activePolishColor;
    _lockDigitSim(
      digit,
      cleanProgress: 1,
      cutFrame: 3,
      polishColor: _activePolishColor,
    );
    workspace.setPolishFill(1);
    _openReward(GameConfig.nailCarePolishCoinReward);
  }

  void _releaseTool() {
    selectedItemId = null;
    inventoryOpen = false;
    _openKit = null;
  }

  /// True once the sprite already shows the finished cell for this hold.
  bool get _holdShowsFinalArt {
    if (stage == NailCareStage.nailPolishing) {
      return false;
    }
    if (stage == NailCareStage.nailSpraying) {
      return _activeNailFrame(nailCleanProgress) >= _spraySheet.frameCount - 1;
    }
    if (stage == NailCareStage.nailBuffering) {
      if (_splitNailSheets) {
        return _activeNailFrame(nailCleanProgress) >= _wipeSheet.frameCount - 1;
      }
      return _activeNailFrame(nailCleanProgress) >= _cleanSheet.frameCount - 1;
    }
    return false;
  }

  bool get _isContinuousNailHoldStage =>
      stage == NailCareStage.nailSpraying ||
      stage == NailCareStage.nailBuffering ||
      stage == NailCareStage.nailPolishing ||
      stage == NailCareStage.footNailSpraying ||
      stage == NailCareStage.footNailBuffering ||
      stage == NailCareStage.footNailPolishing;

  double get _combinedNailProgress {
    if (stage == NailCareStage.nailSpraying ||
        stage == NailCareStage.footNailSpraying) {
      return nailCleanProgress * 0.5;
    }
    if (stage == NailCareStage.nailBuffering ||
        stage == NailCareStage.nailBufferingCompleted ||
        stage == NailCareStage.footNailBuffering ||
        stage == NailCareStage.footNailBufferingCompleted) {
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
    if (stage == NailCareStage.footCleaning) {
      workspace.setFootWashProgress(0);
    } else {
      workspace.setWashProgress(0);
    }
    GameAudio.instance.startSoap();
    notifyListeners();
  }

  void _openReward(int amount) {
    coins += amount;
    pendingCoins = 0;
    rewardOpen = false;
    _clearAdBonusOffer();
    adBonusOfferAmount = amount;
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
    if (_splitNailSheets) {
      final count = stage == NailCareStage.nailSpraying
          ? _spraySheet.frameCount
          : _wipeSheet.frameCount;
      return (progress * (count - 1)).round().clamp(0, count - 1);
    }
    final local = (progress * 2).floor().clamp(0, 1);
    if (stage == NailCareStage.nailSpraying) {
      return local;
    }
    return 2 + local;
  }

  bool get _splitNailSheets =>
      !careKit.unifiedNailClean &&
      NailFingerTreatmentCatalog.hasSplitSheets(digit);

  CharacterSheet get _spraySheet {
    final art = careKit.artFor(digit);
    if (art != null) {
      return art.cleanSheet;
    }
    return careKit.unifiedNailClean
        ? careKit.nailCleanSheet
        : NailFingerTreatmentCatalog.artFor(digit).spraySheet;
  }

  CharacterSheet get _wipeSheet {
    final art = careKit.artFor(digit);
    if (art != null) {
      return art.cleanSheet;
    }
    return careKit.unifiedNailClean
        ? careKit.nailCleanSheet
        : NailFingerTreatmentCatalog.artFor(digit).wipeSheet;
  }

  CharacterSheet get _cleanSheet {
    final art = careKit.artFor(digit);
    if (art != null) {
      return art.cleanSheet;
    }
    return careKit.unifiedNailClean
        ? careKit.nailCleanSheet
        : switch (digit) {
            NailDigit.pinky => SpriteAtlas.fifthNailClean,
            NailDigit.ring => SpriteAtlas.fourthNail,
            NailDigit.middle => SpriteAtlas.thirdNailClean,
            NailDigit.pointer => SpriteAtlas.secondNailClean,
            NailDigit.thumb => SpriteAtlas.firstNailClean,
          };
  }

  CharacterSheet get _shortSheet {
    if (nailShape == NailShape.stiletto) {
      // Ring, middle and pointer all reuse the pinky's stiletto sheet — see
      // GuestCareCatalog.light.stilettoArt.
      return switch (digit) {
        NailDigit.thumb => SpriteAtlas.thumbStilettoLight,
        _ => SpriteAtlas.pinkyStilettoLight,
      };
    }
    final art = careKit.artFor(digit);
    if (art != null && careKit.allowsCutAndPolish(digit)) {
      return art.shortSheet;
    }
    final guestShort = careKit.shortNailSheet;
    if (guestShort != null && careKit.allowsCutAndPolish(digit)) {
      return guestShort;
    }
    return switch (digit) {
      NailDigit.pinky   => SpriteAtlas.shortNail,
      NailDigit.ring    => SpriteAtlas.fourthShortNail,
      NailDigit.middle  => SpriteAtlas.thirdNailShort,
      NailDigit.pointer => SpriteAtlas.secondNailShort,
      NailDigit.thumb   => SpriteAtlas.firstNailShort,
    };
  }
}
