import 'package:flutter/material.dart';

import 'package:nail_glam/model/game_config.dart';
import 'package:nail_glam/model/asset_paths.dart';
import 'package:nail_glam/model/nail_care_tools.dart';
import 'package:nail_glam/controller/nail_glam_game.dart';
import 'package:nail_glam/view/cute_hand_sim.dart';
import 'atlas_tool_image.dart';
import 'coins_sheet.dart';
import 'confetti_burst.dart';
import 'customer_emotion_avatar.dart';
import 'flying_coins.dart';
import 'gold_coin.dart';

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
                  height: 124,
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
        if (care.showsStageCue)
          Positioned(
            left: 28,
            right: 28,
            top: 148,
            child: IgnorePointer(
              child: _StageCue(text: care.stageCue!),
            ),
          ),
        if (care.showsSelectedTool && selected != null)
          Positioned(
            right: 14,
            bottom: 280,
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
                    Align(
                      alignment: Alignment.centerLeft,
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
                    const SizedBox(height: 6),
                    _ProgressBar(progress: care.actionProgress),
                    const SizedBox(height: 12),
                  ],
                  if (stage == NailCareStage.handReveal) ...<Widget>[
                    _FinishedPolishRow(colors: care.polishByDigit),
                    const SizedBox(height: 12),
                  ],
                  // A reserved slot, not a conditional row: this column is
                  // anchored to the bottom and grows upward, so a chip that
                  // pops in the moment a stage completes would shove the hand
                  // card up over the nail. Keeping the height constant means
                  // nothing above it ever moves.
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
            bottom: 156,
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
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.72, end: 1),
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutBack,
                builder: (BuildContext context, double scale, Widget? child) {
                  return Transform.rotate(
                    angle: (1 - scale) * 0.18,
                    child: Transform.scale(scale: scale, child: child),
                  );
                },
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
              const SizedBox(height: 6),
              if (!owned || unlocking || unlockDone)
                _PurchaseButton(
                  price: item.unlockPrice,
                  label: buttonLabel,
                  unlocking: unlocking,
                  unlockDone: unlockDone,
                  onPressed: onUnlock,
                )
              else
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
class _PurchaseButton extends StatelessWidget {
  const _PurchaseButton({
    required this.price,
    required this.label,
    required this.unlocking,
    required this.unlockDone,
    required this.onPressed,
  });

  final int price;
  final String label;
  final bool unlocking;
  final bool unlockDone;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(
          top: 7,
          child: DecoratedBox(
            decoration: BoxDecoration(
                color: unlockDone
                  ? const Color(0xFF4F8D5A)
                  : const Color(0xFFB74E78),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const Key('nail-care-unlock'),
            onPressed: unlocking || unlockDone ? null : onPressed,
            style: ElevatedButton.styleFrom(
                backgroundColor: unlockDone
                  ? const Color(0xFF73B87D)
                  : const Color(0xFFE56B97),
              foregroundColor: Colors.white,
              disabledBackgroundColor: unlockDone
                  ? const Color(0xFF8BC49A)
                  : const Color(0xFFE56B97),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                if (!unlockDone) ...<Widget>[
                  const SizedBox(width: 6),
                  const GoldCoin(size: 18),
                  const SizedBox(width: 4),
                  Text('$price'),
                ] else
                  const Icon(Icons.check_rounded, size: 20),
              ],
            ),
          ),
        ),
        Positioned(
          top: -27,
          left: -8,
          child: _UnlockLockVisual(
            opening: unlocking,
            open: unlockDone,
          ),
        ),
      ],
    );
  }
}
class _UnlockLockVisual extends StatefulWidget {
  const _UnlockLockVisual({required this.opening, required this.open});

  final bool opening;
  final bool open;

  @override
  State<_UnlockLockVisual> createState() => _UnlockLockVisualState();
}

class _UnlockLockVisualState extends State<_UnlockLockVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      value: widget.open ? 1 : 0,
    );
    if (widget.opening) {
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant _UnlockLockVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.opening && !oldWidget.opening) {
      _controller.forward(from: 0);
    } else if (widget.open && !oldWidget.open) {
      _controller.value = 1;
    } else if (!widget.opening && !widget.open) {
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final frame = (_controller.value * 2).round().clamp(0, 2);
        const frameSize = 64.0;
        return SizedBox(
          width: frameSize,
          height: frameSize,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: frameSize * 3,
              maxWidth: frameSize * 3,
              minHeight: frameSize,
              maxHeight: frameSize,
              child: Transform.translate(
                offset: Offset(-frame * frameSize, 0),
                child: Image.asset(
                  'assets/images/${AssetPaths.lock}',
                  width: frameSize * 3,
                  height: frameSize,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        );
      },
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
