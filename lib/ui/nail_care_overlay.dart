import 'package:flutter/material.dart';

import '../game/config/game_config.dart';
import '../game/config/nail_care_tools.dart';
import '../game/nail_care_controller.dart';
import '../game/nail_glam_game.dart';
import 'atlas_tool_image.dart';
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
  final GlobalKey _walletKey = GlobalKey();

  int _flightId = 0;
  int _flightAmount = 0;
  int _flightFrom = 0;
  Offset _flightOrigin = Offset.zero;
  bool _flying = false;
  int _shownCoins = 0;
  int _walletBump = 0;
  int _seenBurst = 0;

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
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    final parent = context.findRenderObject() as RenderBox?;
    if (box == null || parent == null || !box.hasSize || !parent.hasSize) {
      return fallback;
    }
    return parent.globalToLocal(
      box.localToGlobal(box.size.center(Offset.zero)),
    );
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
    final usingNail =
        stage == NailCareStage.pinkyFingerFocus ||
        stage == NailCareStage.ringFingerFocus ||
        stage == NailCareStage.nailSpraying ||
        stage == NailCareStage.nailBuffering ||
        stage == NailCareStage.nailBufferingCompleted ||
        stage == NailCareStage.nailCutting ||
        stage == NailCareStage.nailCuttingCompleted ||
        stage == NailCareStage.nailPolishing ||
        stage == NailCareStage.nailPolishingCompleted;
    final target = usingNail
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
            key: Key(usingNail ? 'nail-care-drop-nail' : 'nail-care-drop-hand'),
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
        if (_showsProgress(stage))
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (care.showsInventory)
          Positioned(
            right: 14,
            bottom: 156,
            child: _KitDrawer(
              game: game,
              label: NailCareInventory.kitLabelFor(stage),
              preview: kit.isEmpty ? null : kit.first,
              stackPreview: _stackedNailTools(stage, kit),
              onTap: care.toggleInventory,
            ),
          ),
        if (_cueFor(care) != null && care.actionProgress <= 0)
          Positioned(
            left: 28,
            right: 28,
            top: 148,
            child: IgnorePointer(
              child: _StageCue(text: _cueFor(care)!),
            ),
          ),
        if (care.showsSelectedTool && selected != null)
          Positioned(
            right: 14,
            bottom: 280,
            child: _SelectedToolChip(game: game, item: selected),
          ),
        if (care.inventoryOpen) ...<Widget>[
          Positioned.fill(
            child: GestureDetector(
              key: const Key('nail-care-inventory-scrim'),
              behavior: HitTestBehavior.opaque,
              onTap: care.closeInventory,
              child: const ColoredBox(color: Color(0x66000000)),
            ),
          ),
          Center(
            child: _InventoryPanel(
              game: game,
              title: NailCareInventory.kitLabelFor(stage),
              items: kit,
              selectedId: care.selectedItemId,
              onSelect: care.selectItem,
            ),
          ),
        ],
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
                  if (_showsProgress(stage)) ...<Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _progressLabel(stage),
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
                  _NextButton(
                    enabled: care.canAdvance,
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
      ],
    );
  }

  static bool _showsProgress(NailCareStage stage) {
    return stage == NailCareStage.handCleaning ||
        stage == NailCareStage.handCleaningCompleted ||
        stage == NailCareStage.pinkyFingerFocus ||
        stage == NailCareStage.ringFingerFocus ||
        stage == NailCareStage.nailSpraying ||
        stage == NailCareStage.nailBuffering ||
        stage == NailCareStage.nailBufferingCompleted ||
        stage == NailCareStage.nailCutting ||
        stage == NailCareStage.nailCuttingCompleted ||
        stage == NailCareStage.nailPolishing ||
        stage == NailCareStage.nailPolishingCompleted;
  }

  static String _progressLabel(NailCareStage stage) {
    if (stage == NailCareStage.nailPolishing ||
        stage == NailCareStage.nailPolishingCompleted) {
      return 'Polish';
    }
    return 'Clean';
  }

  static String? _cueFor(NailCareController care) {
    final ring = care.digit == NailDigit.ring;
    switch (care.stage) {
      case NailCareStage.handCleaning:
        return 'Open SOAPS and drag soap onto the hand';
      case NailCareStage.ringFingerFocus:
        return 'Now the RING FINGER';
      case NailCareStage.nailSpraying:
        return ring
            ? 'Spray the ring finger to loosen grime'
            : 'Spray the pinky nail to loosen grime';
      case NailCareStage.nailBuffering:
        return ring
            ? 'Wipe the ring finger until it shines'
            : 'Wipe the pinky until it shines';
      case NailCareStage.nailCutting:
        return ring
            ? 'Open CLIPS and clip the ring finger'
            : 'Open CLIPS and clip the pinky nail';
      case NailCareStage.nailPolishing:
        return ring
            ? 'Open BRUSHES and paint the ring finger'
            : 'Open BRUSHES and paint the nail';
      case NailCareStage.handCleaningCompleted:
      case NailCareStage.nailBufferingCompleted:
      case NailCareStage.nailCuttingCompleted:
        return 'Nice! Tap NEXT to keep going';
      case NailCareStage.nailPolishingCompleted:
        return ring
            ? 'Nice! Tap NEXT to finish'
            : 'Nice! Next up: the ring finger';
      case NailCareStage.inactive:
      case NailCareStage.pinkyFingerFocus:
        return null;
    }
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

  static List<NailCareInventoryItem>? _stackedNailTools(
    NailCareStage stage,
    List<NailCareInventoryItem> kit,
  ) {
    final nailPage =
        stage == NailCareStage.nailSpraying ||
        stage == NailCareStage.nailBuffering ||
        stage == NailCareStage.nailBufferingCompleted;
    if (!nailPage) {
      return null;
    }
    NailCareInventoryItem? spray;
    NailCareInventoryItem? buffer;
    for (final item in kit) {
      if (item.toolId == NailCareToolId.nailSpray && item.unlocked) {
        spray = item;
      }
      if (item.toolId == NailCareToolId.nailBuffer && item.unlocked) {
        buffer ??= item;
      }
    }
    if (spray == null || buffer == null) {
      return null;
    }
    return <NailCareInventoryItem>[spray, buffer];
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

class _KitDrawer extends StatelessWidget {
  const _KitDrawer({
    required this.game,
    required this.label,
    required this.preview,
    required this.onTap,
    this.stackPreview,
  });

  final NailGlamGame game;
  final String label;
  final NailCareInventoryItem? preview;
  final List<NailCareInventoryItem>? stackPreview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF2FFF6EE),
      elevation: 8,
      shadowColor: const Color(0x55402832),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        key: const Key('nail-care-inventory-drawer'),
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
                          child: stackPreview == null
                              ? AtlasToolImage(
                                  game: game,
                                  toolId: preview!.toolId,
                                  iconPath: preview!.iconPath,
                                  width: 44,
                                )
                              : _StackedToolIcons(
                                  game: game,
                                  items: stackPreview!,
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

class _StackedToolIcons extends StatelessWidget {
  const _StackedToolIcons({required this.game, required this.items});

  final NailGlamGame game;
  final List<NailCareInventoryItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            left: 10,
            bottom: 0,
            child: AtlasToolImage(
              game: game,
              toolId: items.last.toolId,
              iconPath: items.last.iconPath,
              width: 36,
            ),
          ),
          Positioned(
            right: 8,
            top: 0,
            child: AtlasToolImage(
              game: game,
              toolId: items.first.toolId,
              iconPath: items.first.iconPath,
              width: 34,
            ),
          ),
        ],
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
  final ValueChanged<String> onSelect;

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
                crossAxisCount: items.length <= 5 ? 3 : 4,
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
                  onTap: () => onSelect(item.id),
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
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: FittedBox(
                    child: owned
                        ? AtlasToolImage(
                            game: game,
                            toolId: item.toolId,
                            iconPath: item.iconPath,
                            width: 42,
                          )
                        : ColorFiltered(
                            colorFilter: const ColorFilter.matrix(<double>[
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0, 0, 0, 1, 0,
                            ]),
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
              if (!owned)
                Positioned.fill(
                  child: ColoredBox(
                    color: const Color(0x66FFFFFF),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(
                          Icons.lock_rounded,
                          color: Color(0xFF6E5360),
                          size: 22,
                        ),
                        if (item.unlockPrice > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const GoldCoin(size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${item.unlockPrice}',
                                style: const TextStyle(
                                  fontFamily: NailCareOverlay._uiFont,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF6E5360),
                                ),
                              ),
                            ],
                          ),
                      ],
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

class _NextButton extends StatelessWidget {
  const _NextButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

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
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 36, vertical: 14),
            child: Text(
              'NEXT',
              style: TextStyle(
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
