import 'package:flutter/material.dart';

import 'package:nail_glam/model/game_config.dart';
import 'package:nail_glam/model/nail_care_tools.dart';
import 'package:nail_glam/controller/nail_glam_game.dart';
import 'package:nail_glam/view/cute_hand_sim.dart';
import 'atlas_tool_image.dart';
import 'coins_sheet.dart';
import 'confetti_burst.dart';
import 'customer_emotion_avatar.dart';
import 'flying_coins.dart';
import 'gold_coin.dart';
import 'tool_purchase_button.dart';

/// Gameplay HUD for the manicure plate: kit drawer, drop target, and Next.
class NailCareOverlay extends StatelessWidget {
  const NailCareOverlay({required this.game, super.key});

  static const String id = 'nailCare';
  static const String _displayFont = 'Baloo2';
  static const String _uiFont = 'Baloo2';

  final NailGlamGame game;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game.nailCare,
      builder: (BuildContext context, Widget? child) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return _NailCareHud(
              game: game,
              size: Size(constraints.maxWidth, constraints.maxHeight),
            );
          },
        );
      },
    );
  }
}

class _NailCareHud extends StatefulWidget {
  const _NailCareHud({required this.game, required this.size});

  final NailGlamGame game;
  final Size size;

  @override
  State<_NailCareHud> createState() => _NailCareHudState();
}

class _NailCareHudState extends State<_NailCareHud> {
  /// Height held open for the "watch an ad" chip whether or not it is showing,
  /// so the bottom column never changes height mid-stage. The chip itself is
  /// 40 tall (20 icon + 2×10 padding); the rest is the gap above [_NextButton].
  static const double _adBonusSlotHeight = 50;

  /// The guest block at the top of the HUD: the 92 avatar + 6 + the ~27 name
  /// chip + 6 + the 10 patience bar, with a few pixels of slack so a font
  /// that measures a touch taller cannot overflow the column.
  ///
  /// The stage cue below is positioned off this rather than off a magic
  /// number. Growing the block to fit the patience bar is exactly what slid
  /// the cue underneath it once already.
  static const double _guestBlockHeight = 148;

  /// The stage-label line. Tall enough for the ad chip that shares it (40), so
  /// the line — and everything stacked above it — keeps its height whether the
  /// offer is showing or not.
  static const double _labelRowHeight = 40;

  /// How tall the bottom HUD column is, measured from the bottom edge of its
  /// own [SafeArea]. Fixed by construction: every optional piece in it either
  /// has a reserved height or shares a line with something permanent.
  static const double _bottomHudHeight =
      12 + // padding under the NEXT button
      50 + // NEXT button
      12 +
      22 + // gap + progress bar
      6 +
      _labelRowHeight; // gap + stage label (and the ad chip beside it)

  /// Where anything floating above the bottom HUD has to start. Derived rather
  /// than hard-coded: the HUD sits inside a [SafeArea] and a bare [Positioned]
  /// does not, so on a phone with a home-indicator inset a magic number leaves
  /// the tool cards sitting on the progress bar.
  double _bottomHudClearance(BuildContext context) =>
      MediaQuery.of(context).padding.bottom + _bottomHudHeight + 8;

  final GlobalKey _walletKey = GlobalKey();

  int _flightId = 0;
  int _flightAmount = 0;
  int _flightFrom = 0;
  Offset _flightOrigin = Offset.zero;
  bool _flying = false;
  int _shownCoins = 0;
  int _walletBump = 0;
  int _seenBurst = 0;
  NailCareInventoryItem? _previewItem;
  bool _previewUnlocking = false;
  bool _previewUnlockDone = false;

  NailGlamGame get game => widget.game;
  Size get size => widget.size;

  @override
  void initState() {
    super.initState();
    _shownCoins = game.nailCare.coins;
    _seenBurst = game.nailCare.coinBurstGeneration;
    game.nailCare.addListener(_onCareChanged);
  }

  @override
  void dispose() {
    game.nailCare.removeListener(_onCareChanged);
    super.dispose();
  }

  void _openPreview(NailCareInventoryItem item) {
    if (!mounted) {
      return;
    }
    setState(() {
      _previewItem = item;
      _previewUnlocking = false;
      _previewUnlockDone = false;
    });
  }

  void _closePreview() {
    if (!mounted) {
      return;
    }
    setState(() {
      _previewItem = null;
      _previewUnlocking = false;
      _previewUnlockDone = false;
    });
  }

  Future<void> _unlockPreview() async {
    final item = _previewItem;
    if (item == null || _previewUnlocking) {
      return;
    }
    setState(() {
      _previewUnlocking = true;
      _previewUnlockDone = false;
    });
    final unlocked = game.nailCare.unlockItem(item.id);
    if (!mounted) {
      return;
    }
    if (!unlocked) {
      setState(() => _previewUnlocking = false);
      return;
    }
    setState(() {
      _previewUnlockDone = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted) {
      return;
    }
    setState(() {
      _previewItem = null;
      _previewUnlocking = false;
      _previewUnlockDone = false;
    });
  }

  /// Borrows the previewed tool for this visit in exchange for an ad.
  ///
  /// On success the sheet closes straight away rather than showing a
  /// "purchased" beat: the tool is already selected by the controller, so
  /// getting out of the way puts it in the player's hand immediately.
  Future<void> _trialPreview() async {
    final item = _previewItem;
    if (item == null) {
      return;
    }
    final started = await game.nailCare.watchAdForTrial(item);
    if (!mounted || !started) {
      return;
    }
    _closePreview();
  }

  void _onCareChanged() {
    if (!mounted) {
      return;
    }
    final care = game.nailCare;
    if (care.coinBurstGeneration == _seenBurst || care.coinBurstAmount <= 0) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || care.coinBurstGeneration == _seenBurst) {
        return;
      }
      _seenBurst = care.coinBurstGeneration;
      setState(() {
        _flying = true;
        _flightAmount = care.coinBurstAmount;
        _flightFrom = (care.coins - care.coinBurstAmount).clamp(0, care.coins);
        _flightOrigin = Offset(size.width / 2, size.height * 0.48);
        _flightId = care.coinBurstGeneration;
        _shownCoins = _flightFrom;
      });
    });
  }

  Offset _localCenter(GlobalKey key, Offset fallback) {
    if (!mounted || !context.mounted) {
      return fallback;
    }
    final targetContext = key.currentContext;
    if (targetContext == null || !targetContext.mounted) {
      return fallback;
    }
    try {
      final box = targetContext.findRenderObject();
      final parentBox = context.findRenderObject();
      if (box is! RenderBox ||
          parentBox is! RenderBox ||
          !box.attached ||
          !parentBox.attached ||
          !box.hasSize ||
          !parentBox.hasSize) {
        return fallback;
      }
      return parentBox.globalToLocal(
        box.localToGlobal(box.size.center(Offset.zero)),
      );
    } catch (_) {
      return fallback;
    }
  }

  void _onCoinArrived(int index) {
    if (!_flying) {
      return;
    }
    final count = _spriteCount(_flightAmount);
    final gained = ((index + 1) * _flightAmount / count).round();
    setState(() {
      _shownCoins = (_flightFrom + gained).clamp(
        _flightFrom,
        _flightFrom + _flightAmount,
      );
      _walletBump += 1;
    });
  }

  void _onFlightDone() {
    if (!mounted) {
      return;
    }
    setState(() {
      _flying = false;
      _shownCoins = game.nailCare.coins;
    });
  }

  static int _spriteCount(int amount) {
    return (amount / 5).round().clamp(8, 14);
  }

  @override
  Widget build(BuildContext context) {
    final care = game.nailCare;
    final stage = care.stage;
    final target = care.usesNailDropTarget
        ? _targetRect(
            size,
            GameConfig.nailCareNailTargetLeft,
            GameConfig.nailCareNailTargetTop,
            GameConfig.nailCareNailTargetWidth,
            GameConfig.nailCareNailTargetHeight,
          )
        : _targetRect(
            size,
            GameConfig.nailCareHandTargetLeft,
            GameConfig.nailCareHandTargetTop,
            GameConfig.nailCareHandTargetWidth,
            GameConfig.nailCareHandTargetHeight,
          );
    final selected = care.selectedItem;
    final kit = care.currentKit;

    return Stack(
      children: <Widget>[
        Positioned.fromRect(
          rect: target,
          child: DragTarget<NailCareToolId>(
            key: Key(
              care.usesNailDropTarget
                  ? 'nail-care-drop-nail'
                  : 'nail-care-drop-hand',
            ),
            onWillAcceptWithDetails:
                (DragTargetDetails<NailCareToolId> details) =>
                    care.canUse(details.data),
            onMove: (DragTargetDetails<NailCareToolId> details) {
              care.onToolHeldOverTarget(details.data);
            },
            onLeave: (NailCareToolId? data) => care.onToolLeftTarget(),
            onAcceptWithDetails: (DragTargetDetails<NailCareToolId> details) {
              care.onToolDroppedOnTarget(details.data);
            },
            builder:
                (
                  BuildContext context,
                  List<NailCareToolId?> candidate,
                  List<dynamic> rejected,
                ) {
                  return const SizedBox.expand();
                },
          ),
        ),
        if (care.showsProgressBar)
          Positioned(
            left: GameConfig.hudPad,
            right: GameConfig.hudPad,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: GameConfig.hudPad),
                child: SizedBox(
                  height: _guestBlockHeight,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: <Widget>[
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          CustomerEmotionAvatar(
                            key: const Key('nail-care-emotion'),
                            game: game,
                            frame: care.emotionFrame,
                            emotionAsset: game.guest.emotionAsset,
                          ),
                          const SizedBox(height: 6),
                          _GuestNameChip(name: game.guest.name),
                          const SizedBox(height: 6),
                          // Reserved whether or not the bar is showing, so
                          // the guest block keeps its height between
                          // operations and nothing below it shifts.
                          SizedBox(
                            height: _PatienceBar.height,
                            child: care.showsPatienceBar
                                ? _PatienceBar(
                                    key: const Key('nail-care-patience'),
                                    patience: care.patience,
                                  )
                                : null,
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GoldBalanceChip(
                          key: _walletKey,
                          coins: _flying ? _shownCoins : care.coins,
                          bump: _walletBump,
                          // No shop shortcut mid-manicure: the sheet is here to
                          // explain where coins come from, not to send the
                          // player shopping in the middle of a customer.
                          onTap: () => showCoinsSheet(
                            context: context,
                            wallet: care.progressOf(),
                            sessionCoins: care.coins,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Rides just under the patience bar so the reward and the thing that
        // earned it are the same piece of screen. Kept outside the guest block
        // on purpose: that block is a fixed-height Stack and clips, which would
        // eat the flash exactly as it rose.
        if (care.tipFlashGeneration > 0)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: GameConfig.hudPad + _guestBlockHeight - 30,
                ),
                child: IgnorePointer(
                  child: Center(
                    child: _TipFlash(
                      key: const Key('nail-care-tip-flash'),
                      generation: care.tipFlashGeneration,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (care.showsStageCue)
          Positioned(
            left: 28,
            right: 28,
            top: 0,
            // Inside the same SafeArea and padding as the guest block, then
            // pushed past its full height. The old fixed 148 was measured on
            // a phone with no notch, so it already crept under the guest's
            // name on a taller device before the patience bar existed.
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: GameConfig.hudPad + _guestBlockHeight + 10,
                ),
                child: IgnorePointer(
                  child: _StageCue(text: care.stageCue!),
                ),
              ),
            ),
          ),
        if (care.showsSelectedTool && selected != null)
          Positioned(
            right: 14,
            bottom: _bottomHudClearance(context) + 124,
            child: _SelectedToolChip(game: game, item: selected),
          ),
        Positioned(
          left: GameConfig.hudPad,
          right: GameConfig.hudPad,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (care.showsNailHud) ...<Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CuteHandSimCard(
                        // Progress is tracked on the seated guest's own hand,
                        // not one shared light-skinned still.
                        art: care.careKit.hudHand,
                        done: care.nailsDone,
                        total: care.nailsTotal,
                        snapshots: <NailDigit, DigitSimSnapshot>{
                          for (final NailDigit digit in NailDigit.values)
                            digit: care.simSnapshotFor(digit),
                        },
                        activeDigit: care.simActiveDigit,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (care.showsProgressBar) ...<Widget>[
                    // The stage label and the ad chip share one fixed-height
                    // line. The chip appears the instant a stage completes, so
                    // a line of its own would both grow this bottom-anchored
                    // column and push the hand card up into the guest's hand —
                    // and the space beside a one-word label was empty anyway.
                    SizedBox(
                      height: _labelRowHeight,
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              care.progressLabel,
                              style: const TextStyle(
                                fontFamily: NailCareOverlay._displayFont,
                                fontSize: 18,
                                height: 1,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF8A4B63),
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                          if (care.showsComboChip) ...<Widget>[
                            _ComboChip(
                              key: const Key('nail-care-combo'),
                              multiplier: care.comboMultiplier,
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (care.showsAdBonusOffer || care.adBonusPending)
                            _AdBonusChip(
                              bonus: care.adBonusCoins,
                              busy: care.adBonusPending,
                              onPressed: care.watchAdForBonus,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    _ProgressBar(progress: care.actionProgress),
                    const SizedBox(height: 12),
                  ],
                  if (stage == NailCareStage.handReveal) ...<Widget>[
                    _FinishedPolishRow(colors: care.polishByDigit),
                    const SizedBox(height: 12),
                  ],
                  // The tip lands on both reveals — the pedicure never showed
                  // a finished-polish row, but it is paid a tip just the same.
                  if (stage == NailCareStage.handReveal ||
                      stage == NailCareStage.footReveal) ...<Widget>[
                    _TipCard(
                      key: const Key('nail-care-tip'),
                      tip: care.tipPaid,
                      inTime: care.stagesInTime,
                      total: care.stagesPaid,
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Fallback slot for the stages that have no progress bar to
                  // hang the chip beside. Still a reserved height, so nothing
                  // above it moves when the offer arrives.
                  if (!care.showsProgressBar)
                    SizedBox(
                      height: _adBonusSlotHeight,
                      child: care.showsAdBonusOffer || care.adBonusPending
                          ? Center(
                              child: _AdBonusChip(
                                bonus: care.adBonusCoins,
                                busy: care.adBonusPending,
                                onPressed: care.watchAdForBonus,
                              ),
                            )
                          : null,
                    ),
                  _NextButton(
                    enabled: care.canAdvance,
                    label: stage == NailCareStage.handReveal ||
                            stage == NailCareStage.footReveal
                        ? 'Next customer'
                        : 'NEXT',
                    onPressed: game.advanceNailCare,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: ConfettiBurst(generation: care.confettiGeneration),
        ),
        Positioned.fill(
          child: FlyingCoins(
            key: const Key('nail-care-flying-coins'),
            generation: _flightId,
            origin: _flightOrigin,
            count: _spriteCount(_flightAmount),
            targetOf: () => _localCenter(
              _walletKey,
              Offset(size.width - 52, 52),
            ),
            onCoinArrived: _onCoinArrived,
            onComplete: _onFlightDone,
          ),
        ),
        if (care.nailShapeChoiceOpen)
          Positioned.fill(
            child: Stack(
              children: <Widget>[
                const ModalBarrier(
                  dismissible: false,
                  color: Color(0x99000000),
                ),
                Center(
                  child: _NailShapePicker(
                    selected: care.nailShape,
                    onSelected: care.selectNailShape,
                  ),
                ),
              ],
            ),
          ),
        if (care.inventoryOpen)
          Positioned.fill(
            child: GestureDetector(
              key: const Key('nail-care-inventory-scrim'),
              behavior: HitTestBehavior.opaque,
              onTap: care.closeInventory,
              child: const ColoredBox(color: Color(0x66000000)),
            ),
          ),
        if (care.inventoryOpen)
          Center(
            child: _InventoryPanel(
              game: game,
              title: care.panelTitle,
              items: care.panelItems,
              selectedId: care.selectedItemId,
              onSelect: _openPreview,
            ),
          ),
        // Painted after the scrim so the drawer buttons stay tappable while
        // a panel is open — otherwise the scrim (which dismisses on any tap
        // outside the panel) swallows taps meant to switch straight from one
        // drawer's panel to the other's.
        if (care.showsInventory)
          Positioned(
            right: 14,
            bottom: _bottomHudClearance(context),
            child: care.usesPolishPanel
                ? _KitDrawer(
                    game: game,
                    label: NailCareInventory.kitLabelFor(stage),
                    preview: kit.isEmpty ? null : kit.first,
                    onTap: care.toggleInventory,
                  )
                : care.showsSplitToolBoxes
                // Stacked, not side by side: two 86-wide cards in a row reach
                // ~180px in from the right edge, which on a narrow phone lands
                // on top of the zoomed nail. One column keeps the drawers in
                // the same right-hand lane every other stage uses.
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      _ToolDrawer(
                        game: game,
                        drawerKey: const Key('nail-care-inventory-drawer-spray'),
                        item: care.sprayDrawerPreview,
                        active: care.canUse(NailCareToolId.nailSpray),
                      ),
                      const SizedBox(height: 8),
                      _ToolDrawer(
                        game: game,
                        drawerKey: const Key('nail-care-inventory-drawer-wipe'),
                        item: care.wipeDrawerPreview,
                        active: care.canUse(NailCareToolId.nailBuffer),
                      ),
                    ],
                  )
                : _ToolDrawer(
                    game: game,
                    drawerKey: const Key('nail-care-inventory-drawer'),
                    item: care.activeTool == null
                        ? null
                        : care.equippedItemFor(care.activeTool!.id),
                    active: true,
                  ),
          ),
        if (_previewItem != null)
          Positioned.fill(
            child: Stack(
              children: <Widget>[
                GestureDetector(
                  key: const Key('nail-care-preview-scrim'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _previewUnlocking ? null : _closePreview,
                  child: const ModalBarrier(
                    dismissible: false,
                    color: Color(0xB8000000),
                  ),
                ),
                Center(
                  child: _InventoryPreviewSheet(
                    game: game,
                    item: _previewItem!,
                    owned: care.ownsKitItem(_previewItem!),
                    selected: care.selectedItemId == _previewItem!.id,
                    unlocking: _previewUnlocking,
                    unlockDone: _previewUnlockDone,
                    canTrial: care.canTrialItem(_previewItem!),
                    trialPending: care.trialPending,
                    onTrial: _trialPreview,
                    onClose: _closePreview,
                    onUnlock: _unlockPreview,
                    onEquip: () {
                      game.nailCare.selectItem(_previewItem!.id);
                      _closePreview();
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static Rect _targetRect(
    Size size,
    double left,
    double top,
    double width,
    double height,
  ) {
    return Rect.fromLTWH(
      size.width * left,
      size.height * top,
      size.width * width,
      size.height * height,
    );
  }
}

class _StageCue extends StatelessWidget {
  const _StageCue({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('nail-care-stage-cue'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xE6FFF6EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: NailCareOverlay._uiFont,
          fontSize: 16,
          height: 1.2,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B524C),
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class _NailShapePicker extends StatelessWidget {
  const _NailShapePicker({required this.selected, required this.onSelected});

  final NailShape selected;
  final ValueChanged<NailShape> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('nail-shape-picker'),
      color: const Color(0xF7FFF8FC),
      elevation: 18,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Choose nail shape',
              style: TextStyle(
                fontFamily: NailCareOverlay._displayFont,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF8A4B63),
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _ShapeCard(
                  label: 'Square',
                  previewAsset: 'assets/images/nail_preview_square.png',
                  selected: selected == NailShape.square,
                  onTap: () => onSelected(NailShape.square),
                ),
                const SizedBox(width: 14),
                _ShapeCard(
                  label: 'Stiletto',
                  previewAsset: 'assets/images/nail_preview_stiletto.png',
                  selected: selected == NailShape.stiletto,
                  onTap: () => onSelected(NailShape.stiletto),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShapeCard extends StatelessWidget {
  const _ShapeCard({
    required this.label,
    required this.previewAsset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String previewAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFE4F0) : const Color(0xFFFFF0F6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFFD6618A) : const Color(0xFFEEC4D8),
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: selected
              ? <BoxShadow>[
                  const BoxShadow(
                    color: Color(0x22D6618A),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? const Color(0xFFD6618A) : const Color(0xFFEEC4D8),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  previewAsset,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: NailCareOverlay._uiFont,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? const Color(0xFFD6618A) : const Color(0xFF8A6070),
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('nail-care-progress'),
      label: 'Cleaning progress',
      value: '${(progress * 100).round()} percent',
      child: Container(
        height: 22,
        decoration: BoxDecoration(
          color: const Color(0xCCFFF6EE),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const ColoredBox(color: Color(0x33E56B97)),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[Color(0xFFFF8FBF), Color(0xFFFFD36A)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestNameChip extends StatelessWidget {
  const _GuestNameChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('nail-care-guest-name'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xF2FFF6EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        name,
        style: const TextStyle(
          fontFamily: NailCareOverlay._displayFont,
          fontSize: 14,
          height: 1.1,
          fontWeight: FontWeight.w800,
          color: Color(0xFF7A3D5C),
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

/// The tool card itself. It shows the skin equipped in the shop and is the
/// drag handle: press it and pull straight onto the hand — no picker in
/// between. Tapping does nothing on purpose.
class _ToolDrawer extends StatelessWidget {
  const _ToolDrawer({
    required this.game,
    required this.item,
    required this.active,
    this.drawerKey,
  });

  final NailGlamGame game;
  final NailCareInventoryItem? item;
  final bool active;
  final Key? drawerKey;

  @override
  Widget build(BuildContext context) {
    final tool = item;
    final card = _card(
      tool == null
          ? const Icon(Icons.inventory_2_rounded, color: Color(0xFF8A4B63))
          : FittedBox(
              child: AtlasToolImage(
                game: game,
                toolId: tool.toolId,
                iconPath: tool.iconPath,
                width: 46,
              ),
            ),
      tool == null ? '' : NailCareInventory.toolLabel(tool.toolId),
    );

    if (tool == null) {
      return KeyedSubtree(key: drawerKey, child: card);
    }

    return KeyedSubtree(
      key: drawerKey,
      child: Draggable<NailCareToolId>(
        key: Key('nail-care-tool-${tool.toolId.name}'),
        data: tool.toolId,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Material(
          color: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          child: AtlasToolImage(
            game: game,
            toolId: tool.toolId,
            iconPath: tool.iconPath,
            width: 84,
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.28, child: card),
        child: Opacity(opacity: active ? 1 : 0.55, child: card),
      ),
    );
  }

  Widget _card(Widget art, String label) {
    return Material(
      color: const Color(0xF2FFF6EE),
      elevation: 8,
      shadowColor: const Color(0x55402832),
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: 86,
        height: 108,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Column(
            children: <Widget>[
              Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: NailCareOverlay._uiFont,
                  fontSize: 13,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF8A4B63),
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(child: art),
            ],
          ),
        ),
      ),
    );
  }
}

class _KitDrawer extends StatelessWidget {
  const _KitDrawer({
    required this.game,
    required this.label,
    required this.preview,
    required this.onTap,
    this.drawerKey,
  });

  final NailGlamGame game;
  final String label;
  final NailCareInventoryItem? preview;
  final VoidCallback onTap;
  final Key? drawerKey;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF2FFF6EE),
      elevation: 8,
      shadowColor: const Color(0x55402832),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        key: drawerKey ?? const Key('nail-care-inventory-drawer'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          width: 86,
          height: 108,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: Column(
              children: <Widget>[
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: NailCareOverlay._uiFont,
                    fontSize: 13,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8A4B63),
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: preview == null
                      ? const Icon(Icons.inventory_2_rounded, color: Color(0xFF8A4B63))
                      : FittedBox(
                          child: AtlasToolImage(
                            game: game,
                            toolId: preview!.toolId,
                            iconPath: preview!.iconPath,
                            width: 44,
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

class _InventoryPanel extends StatelessWidget {
  const _InventoryPanel({
    required this.game,
    required this.title,
    required this.items,
    required this.selectedId,
    required this.onSelect,
  });

  final NailGlamGame game;
  final String title;
  final List<NailCareInventoryItem> items;
  final String? selectedId;
  final ValueChanged<NailCareInventoryItem> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF7FFF8FC),
      elevation: 18,
      shadowColor: const Color(0x66000000),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        key: const Key('nail-care-inventory-panel'),
        width: 320,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(
                fontFamily: NailCareOverlay._displayFont,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9B4C91),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              items.any((NailCareInventoryItem item) => item.unlockPrice > 0)
                  ? 'Tap a color. Locked shades cost coins.'
                  : items.any(
                      (NailCareInventoryItem item) => item.polishColor != 0,
                    )
                  ? 'Pick a polish color'
                  : 'Pick the one you own',
              style: const TextStyle(
                fontFamily: NailCareOverlay._uiFont,
                fontSize: 13,
                color: Color(0xFF6E5360),
              ),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (BuildContext context, int index) {
                final item = items[index];
                return _InventorySlot(
                  game: game,
                  item: item,
                  selected: selectedId == item.id,
                  owned: game.nailCare.ownsKitItem(item),
                  onTap: () => onSelect(item),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InventorySlot extends StatelessWidget {
  const _InventorySlot({
    required this.game,
    required this.item,
    required this.selected,
    required this.owned,
    required this.onTap,
  });

  final NailGlamGame game;
  final NailCareInventoryItem item;
  final bool selected;
  final bool owned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = !owned;
    return Material(
      color: selected ? const Color(0xFFFFE0EF) : const Color(0xFFFFF6EE),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: Key('nail-care-slot-${item.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? const Color(0xFFE56B97) : Colors.white,
              width: 2,
            ),
          ),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Color(0x00FFFFFF),
                        Color(0x18F48FB2),
                      ],
                    ),
                  ),
                ),
              ),
              if (locked)
                Positioned(
                  left: -14,
                  right: -14,
                  top: 1,
                  bottom: 6,
                  child: IgnorePointer(
                    child: Icon(
                      Icons.lock_rounded,
                      size: 84,
                      color: const Color(0xFF6E5360).withOpacity(0.14),
                    ),
                  ),
                ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: FittedBox(
                    child: ColorFiltered(
                      colorFilter: locked
                          ? const ColorFilter.matrix(<double>[
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0, 0, 0, 1, 0,
                            ])
                          : const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.srcATop,
                            ),
                      child: AtlasToolImage(
                        game: game,
                        toolId: item.toolId,
                        iconPath: item.iconPath,
                        width: 42,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: _SlotPriceChip(
                  locked: locked,
                  price: item.unlockPrice,
                  ownedLabel: selected ? 'Selected' : 'Owned',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotPriceChip extends StatelessWidget {
  const _SlotPriceChip({
    required this.locked,
    required this.price,
    required this.ownedLabel,
  });

  final bool locked;
  final int price;
  final String ownedLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: locked ? const Color(0xE6FFF0B8) : const Color(0xE6E7F5D8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: locked
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const GoldCoin(size: 15),
                const SizedBox(width: 4),
                Text(
                  '$price',
                  style: const TextStyle(
                    fontFamily: NailCareOverlay._uiFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6B524C),
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            )
          : Text(
              ownedLabel,
              style: const TextStyle(
                fontFamily: NailCareOverlay._uiFont,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF52714A),
                decoration: TextDecoration.none,
              ),
            ),
    );
  }
}

class _InventoryPreviewSheet extends StatelessWidget {
  const _InventoryPreviewSheet({
    required this.game,
    required this.item,
    required this.owned,
    required this.selected,
    required this.unlocking,
    required this.unlockDone,
    required this.onClose,
    required this.onUnlock,
    required this.onEquip,
    required this.canTrial,
    required this.trialPending,
    required this.onTrial,
  });

  final NailGlamGame game;
  final NailCareInventoryItem item;
  final bool owned;
  final bool selected;
  final bool unlocking;
  final bool unlockDone;
  final VoidCallback onClose;
  final VoidCallback onUnlock;
  final VoidCallback onEquip;

  /// Whether this item can be borrowed for the visit by watching an ad.
  final bool canTrial;

  /// True while the trial ad is on screen.
  final bool trialPending;
  final VoidCallback onTrial;

  @override
  Widget build(BuildContext context) {
    final buttonLabel = unlockDone
      ? 'Purchased'
      : owned
        ? (selected ? 'Selected' : 'Use')
        : 'Unlock for';
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Material(
        color: const Color(0xFFFDF8F4),
        elevation: 36,
        shadowColor: const Color(0x88000000),
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  key: const Key('nail-care-preview-close'),
                  onPressed: unlocking ? null : onClose,
                  icon: const Icon(Icons.close_rounded),
                  color: const Color(0xFF8A4B63),
                  tooltip: 'Close preview',
                ),
              ),
              PreviewArtPopIn(
                child: AtlasToolImage(
                  game: game,
                  toolId: item.toolId,
                  iconPath: item.iconPath,
                  width: 138,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: NailCareOverlay._displayFont,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF8A4B63),
                  decoration: TextDecoration.none,
                ),
              ),
              // The sheet is where the coins are actually spent, so it has to
              // say what they buy. Without this the player is asked to commit
              // 800 coins on the strength of a nicer bottle.
              if (item.speedLabel.isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  item.speedLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: NailCareOverlay._displayFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4E9C7E),
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              if (!owned || unlocking || unlockDone) ...<Widget>[
                ToolPurchaseButton(
                  price: item.unlockPrice,
                  label: buttonLabel,
                  unlocking: unlocking,
                  unlockDone: unlockDone,
                  onPressed: onUnlock,
                ),
                // Second door out of this sheet: borrow the tool for this
                // visit instead of buying it. Sits under the price so it
                // reads as the cheaper option rather than competing with it —
                // the point is to let the tool sell itself, not to replace
                // the purchase.
                if (canTrial || trialPending) ...<Widget>[
                  const SizedBox(height: 8),
                  _TrialButton(busy: trialPending, onPressed: onTrial),
                ],
              ] else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('nail-care-equip'),
                    onPressed: selected ? null : onEquip,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE56B97),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(buttonLabel),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
// ToolPurchaseButton and UnlockLockVisual moved to tool_purchase_button.dart
// so the Salon Shop's Tools tab can share this exact purchase moment instead
// of carrying its own copy.

/// "Try it this visit" — the rewarded-ad alternative to paying for a tool.
///
/// Deliberately quieter than the purchase button above it: outlined rather
/// than filled, so the sheet still leads with the sale.
class _TrialButton extends StatelessWidget {
  const _TrialButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        key: const Key('nail-care-tool-trial'),
        onPressed: busy ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF8A4B63),
          side: const BorderSide(color: Color(0xFFE0B6C6), width: 2),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (busy)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8A4B63)),
                ),
              )
            else
              const Icon(Icons.play_circle_outline_rounded, size: 19),
            const SizedBox(width: 8),
            Text(
              busy ? 'Playing ad...' : 'Try it this visit',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedToolChip extends StatelessWidget {
  const _SelectedToolChip({required this.game, required this.item});

  final NailGlamGame game;
  final NailCareInventoryItem item;

  @override
  Widget build(BuildContext context) {
    final tool = NailCareCatalog.toolById(item.toolId);
    final compact = item.toolId == NailCareToolId.nailPolish;
    final icon = AtlasToolImage(
      game: game,
      toolId: item.toolId,
      iconPath: item.iconPath,
      width: compact ? 36 : 72,
    );
    final ghost = AtlasToolImage(
      game: game,
      toolId: item.toolId,
      iconPath: item.iconPath,
      width: compact ? 42 : 84,
    );

    return Material(
      color: const Color(0xF2FFF6EE),
      elevation: 10,
      shadowColor: const Color(0x55402832),
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              item.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: NailCareOverlay._displayFont,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8A4B63),
              ),
            ),
            const SizedBox(height: 8),
            Draggable<NailCareToolId>(
              key: Key('nail-care-tool-${item.toolId.name}'),
              data: item.toolId,
              dragAnchorStrategy: pointerDragAnchorStrategy,
              feedback: Material(
                color: Colors.transparent,
                elevation: 0,
                shadowColor: Colors.transparent,
                child: ghost,
              ),
              childWhenDragging: Opacity(opacity: 0.28, child: icon),
              child: icon,
            ),
            const SizedBox(height: 8),
            Text(
              tool.hint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: NailCareOverlay._uiFont,
                fontSize: 11,
                height: 1.25,
                color: Color(0xFF6E5360),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinishedPolishRow extends StatelessWidget {
  const _FinishedPolishRow({required this.colors});

  final Map<NailDigit, int> colors;

  static const List<NailDigit> _order = <NailDigit>[
    NailDigit.pinky,
    NailDigit.ring,
    NailDigit.middle,
    NailDigit.pointer,
    NailDigit.thumb,
  ];

  static const Map<NailDigit, String> _shortLabel = <NailDigit, String>{
    NailDigit.pinky: 'S',
    NailDigit.ring: 'Y',
    NailDigit.middle: 'O',
    NailDigit.pointer: 'İ',
    NailDigit.thumb: 'B',
  };

  @override
  Widget build(BuildContext context) {
    final painted = _order
        .where((NailDigit d) => (colors[d] ?? 0) != 0)
        .toList(growable: false);
    if (painted.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: <Widget>[
        const Text(
          'Finished colors',
          style: TextStyle(
            fontFamily: NailCareOverlay._displayFont,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF8A4B63),
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox.shrink(),
      ],
    );
  }
}

/// "Watch an ad, double this reward" offered right after a stage's coin
/// burst, sitting just above NEXT so it reads as an optional extra rather
/// than something standing between the player and the next stage.
///
/// The chip only exists while `NailCareController.showsAdBonusOffer` is true —
/// i.e. a reward was just paid, the offer has not been taken, and the ad is
/// actually loaded — so it can never be tapped into a dead end.
/// How much of the guest's goodwill is left, as a plain fill bar.
///
/// Colour carries the warning, not an icon: mint while there is plenty of
/// time, amber as it gets tight, rose once the tip is nearly gone. The whole
/// thing is drawn from rounded rectangles, so it needs no art.
class _PatienceBar extends StatelessWidget {
  const _PatienceBar({required this.patience, super.key});

  /// 1 = freshly seated, 0 = out of patience.
  final double patience;

  static const double _width = 96;

  /// Tall enough to actually read as a bar against the guest's hand. At 7 the
  /// fill was a hairline even once it was drawn at all.
  static const double height = 10;
  static const double _height = height;

  /// Thresholds match the mood bands in `_patienceMoodPenalty`, so the bar
  /// changing colour and the guest's face dropping are the same event twice
  /// rather than two unrelated warnings.
  Color get _fillColor {
    if (patience >= 0.5) {
      return const Color(0xFF5FC79B);
    }
    if (patience >= 0.3) {
      return const Color(0xFFF2B740);
    }
    return const Color(0xFFE8657F);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _width,
      height: _height,
      // A dark groove rather than a pale one: this sits on the guest's hand,
      // and a white-on-skin track was invisible even when full.
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0x3D000000),
        borderRadius: BorderRadius.circular(_height / 2),
        border: Border.all(color: const Color(0x59FFFFFF), width: 1),
      ),
      // The controller only notifies every ~0.004 of the bar, so the tween is
      // what turns those steps back into a smooth creep.
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: patience, end: patience.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        builder: (BuildContext context, double value, Widget? child) {
          // heightFactor is the whole trick: with only a widthFactor the
          // fill's height constraints stay loose, and a childless DecoratedBox
          // then takes the smallest height it is allowed — zero — so the bar
          // read as permanently empty however full it actually was.
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0.0, 1.0),
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _fillColor,
                borderRadius: BorderRadius.circular(_height / 2),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The "+TIP" that lifts off the patience bar when an operation beats it.
///
/// Deliberately carries no coin number. The tip is one per-visit payment
/// worked out at the reveal, so any figure here would either be a guess or a
/// promise the reveal might not keep — and a wrong number teaches the mechanic
/// backwards. What the player needs in the moment is only the yes/no: that
/// one counted.
///
/// Driven off a generation counter rather than a flag the controller has to
/// clear: the key replays the tween on each bump, and the animation ending on
/// zero opacity is what makes it go away. Nothing to reset, nothing to leak.
class _TipFlash extends StatelessWidget {
  const _TipFlash({required this.generation, super.key});

  final int generation;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(generation),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (BuildContext context, double t, Widget? child) {
        // Rises from just below the bar to just above it, popping to full size
        // over the first fifth and holding until it fades out over the last
        // third — so it reads at a glance instead of only in a screenshot.
        final double pop = (t / 0.2).clamp(0.0, 1.0);
        final double fade = ((1 - t) / 0.35).clamp(0.0, 1.0);
        return Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: Offset(0, 16 - 34 * t),
            child: Transform.scale(scale: 0.7 + 0.3 * pop, child: child),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xF2FFF6EE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const GoldCoin(size: 16),
            const SizedBox(width: 6),
            const Text(
              '+TIP',
              style: TextStyle(
                fontFamily: NailCareOverlay._displayFont,
                fontSize: 14,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: Color(0xFF8A4B63),
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The guest's tip, shown on the reveal where it is actually paid.
///
/// The tip used to arrive as coins alone, which made the whole per-operation
/// bar pointless: the player was being scored all visit and never told the
/// result. So the card names the number *and* the reason for it — how many
/// operations beat their bar — because that is the sentence that teaches the
/// mechanic.
class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.tip,
    required this.inTime,
    required this.total,
    super.key,
  });

  final int tip;

  /// Operations finished before their bar ran out, out of [total] paid.
  final int inTime;
  final int total;

  @override
  Widget build(BuildContext context) {
    final earned = tip > 0;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (BuildContext context, double t, Widget? child) {
        return Transform.scale(
          scale: 0.86 + 0.14 * t,
          child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xF2FFF6EE),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  earned ? 'TIP' : 'NO TIP',
                  style: TextStyle(
                    fontFamily: NailCareOverlay._displayFont,
                    fontSize: 16,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: earned
                        ? const Color(0xFF8A4B63)
                        : const Color(0xFFB993A0),
                    decoration: TextDecoration.none,
                  ),
                ),
                if (earned) ...<Widget>[
                  const SizedBox(width: 10),
                  const GoldCoin(size: 22),
                  const SizedBox(width: 6),
                  Text(
                    '+$tip',
                    style: const TextStyle(
                      fontFamily: NailCareOverlay._displayFont,
                      fontSize: 26,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8A4B63),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 5),
            Text(
              total == 0
                  ? 'No steps scored this visit'
                  : '$inTime of $total steps finished in time',
              style: const TextStyle(
                fontFamily: NailCareOverlay._uiFont,
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9A7080),
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The live payout multiplier, shown only while it is above face value.
///
/// Scales up each time the multiplier steps, so the reward for a clean run
/// registers as a moment rather than a number that quietly changed.
class _ComboChip extends StatelessWidget {
  const _ComboChip({required this.multiplier, super.key});

  final double multiplier;

  @override
  Widget build(BuildContext context) {
    // 1.5 needs its decimal, 2 does not.
    final label = multiplier == multiplier.roundToDouble()
        ? multiplier.toStringAsFixed(0)
        : multiplier.toStringAsFixed(1);
    return TweenAnimationBuilder<double>(
      // Keyed on the multiplier so the pop replays on each step up, not on
      // every rebuild while the combo holds.
      key: ValueKey<double>(multiplier),
      tween: Tween<double>(begin: 0.7, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (BuildContext context, double scale, Widget? child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFB74E78),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.local_fire_department_rounded,
                size: 16,
                color: Color(0xFFFFD9E6),
              ),
              const SizedBox(width: 4),
              Text(
                '×$label',
                style: const TextStyle(
                  fontFamily: NailCareOverlay._displayFont,
                  fontSize: 15,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdBonusChip extends StatelessWidget {
  const _AdBonusChip({
    required this.bonus,
    required this.busy,
    required this.onPressed,
  });

  /// Extra coins the player gets for watching, on top of what was just paid.
  final int bonus;

  /// True while the ad is on screen: the chip greys out and shows a spinner
  /// so a second tap cannot start a second ad.
  final bool busy;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: busy ? 0.6 : 1,
      child: Material(
        color: const Color(0xFFFFC24D),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          key: const Key('nail-care-ad-bonus'),
          onTap: busy ? null : onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (busy)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF7A4A12),
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.play_circle_fill_rounded,
                    size: 20,
                    color: Color(0xFF7A4A12),
                  ),
                const SizedBox(width: 8),
                Text(
                  busy ? 'Playing ad...' : 'Watch for +$bonus',
                  style: const TextStyle(
                    fontFamily: NailCareOverlay._uiFont,
                    fontSize: 15,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF7A4A12),
                    decoration: TextDecoration.none,
                  ),
                ),
                if (!busy) ...<Widget>[
                  const SizedBox(width: 6),
                  const GoldCoin(size: 15),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({
    required this.enabled,
    required this.onPressed,
    this.label = 'NEXT',
  });

  final bool enabled;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? const Color(0xFFE56B97) : const Color(0x66C4A4B0);
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          key: const Key('nail-care-next'),
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: NailCareOverlay._displayFont,
                fontSize: 18,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
