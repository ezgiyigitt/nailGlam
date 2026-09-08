import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:nail_glam/controller/game_audio.dart';
import 'package:nail_glam/controller/player_progress_controller.dart';
import 'package:nail_glam/model/nail_care_tools.dart';
import 'package:nail_glam/model/salon_catalog.dart';
import 'gold_coin.dart';
import 'tool_purchase_button.dart';

/// Swipeable furniture showroom. One piece per page; locked items need coins.
class ShopScreen extends StatefulWidget {
  const ShopScreen({required this.progressController, super.key});

  final PlayerProgressController progressController;

  static const List<ShopItem> showroom = <ShopItem>[
    SalonCatalog.starterChair,
    SalonCatalog.pinkChair,
    SalonCatalog.goldChair,
    SalonCatalog.starterTable,
    SalonCatalog.marbleTable,
    SalonCatalog.premiumTable,
  ];

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final PageController _pages = PageController(viewportFraction: 0.86);
  int _index = 0;
  int _tab = 0;

  /// Tools sold here. Polish keeps its own in-game picker, so it is not listed.
  static const List<NailCareToolId> _toolTabs = <NailCareToolId>[
    NailCareToolId.handSoap,
    NailCareToolId.nailSpray,
    NailCareToolId.nailBuffer,
    NailCareToolId.nailClips,
  ];

  // The locked-tool preview: pop-in art, "Unlock for <price>", the lock
  // sprite, and the short hold on "Purchased" before it closes on its own.
  // Mirrors the manicure HUD's tool-drawer preview state machine exactly (see
  // NailCareOverlay's _openPreview / _unlockPreview) so a locked skin behaves
  // the same whether it is opened from a manicure or from this menu.
  NailCareInventoryItem? _previewItem;
  bool _previewUnlocking = false;
  bool _previewUnlockDone = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _openToolPreview(NailCareInventoryItem item) {
    setState(() {
      _previewItem = item;
      _previewUnlocking = false;
      _previewUnlockDone = false;
    });
  }

  void _closeToolPreview() {
    setState(() {
      _previewItem = null;
      _previewUnlocking = false;
      _previewUnlockDone = false;
    });
  }

  Future<void> _unlockToolPreview() async {
    final item = _previewItem;
    if (item == null || _previewUnlocking) {
      return;
    }
    setState(() {
      _previewUnlocking = true;
      _previewUnlockDone = false;
    });
    final bought = widget.progressController.buySkin(item);
    if (!mounted) {
      return;
    }
    if (!bought) {
      // Not enough coins: drop back to the plain "Unlock for" state instead
      // of hanging on the spinner-less unlocking state forever.
      setState(() => _previewUnlocking = false);
      return;
    }
    GameAudio.instance.coin();
    setState(() => _previewUnlockDone = true);
    // Hold on the "Purchased" state long enough to read, same pause the
    // manicure drawer uses, then dismiss on its own — no extra tap needed.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D2),
      body: AnimatedBuilder(
        animation: widget.progressController,
        builder: (BuildContext context, _) {
          final progress = widget.progressController;
          final item = ShopScreen.showroom[_index];
          final preview = _previewItem;
          return Stack(
            children: <Widget>[
              SafeArea(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                      child: Row(
                        children: <Widget>[
                          IconButton(
                            onPressed: () {
                              GameAudio.instance.tap();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const Expanded(
                            child: Text(
                              'Salon Shop',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Baloo2',
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFE84F8F),
                              ),
                            ),
                          ),
                          GoldBalanceChip(coins: progress.coins),
                        ],
                      ),
                    ),
                    _TabBar(
                      index: _tab,
                      onChanged: (int value) {
                        GameAudio.instance.tap();
                        setState(() => _tab = value);
                      },
                    ),
                    Text(
                      _tab == 0
                          ? 'Swipe to browse. Locked pieces cost coins.'
                          : 'Tap a tool to equip it. It goes straight on your HUD card.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Baloo2',
                        fontSize: 14,
                        color: Color(0xFF8A4B63),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_tab == 1)
                      Expanded(
                        child: ListView(
                          key: const Key('shop-tools'),
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                          children: <Widget>[
                            for (final NailCareToolId tool in _toolTabs)
                              _ToolShelf(
                                tool: tool,
                                progressController: progress,
                                onPreview: _openToolPreview,
                              ),
                          ],
                        ),
                      )
                    else ...<Widget>[
                    Expanded(
                      child: PageView.builder(
                        key: const Key('shop-showroom'),
                        controller: _pages,
                        scrollBehavior: const MaterialScrollBehavior().copyWith(
                          dragDevices: const {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.trackpad,
                            PointerDeviceKind.stylus,
                          },
                        ),
                        itemCount: ShopScreen.showroom.length,
                        onPageChanged: (int value) =>
                            setState(() => _index = value),
                        itemBuilder: (BuildContext context, int index) {
                          return _FurnitureCard(
                            item: ShopScreen.showroom[index],
                            progressController: progress,
                            focused: index == _index,
                          );
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        for (var i = 0; i < ShopScreen.showroom.length; i++)
                          Container(
                            width: i == _index ? 16 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 3,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: i == _index
                                  ? const Color(0xFFE84F8F)
                                  : const Color(0x66E84F8F),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                      child: _BuyBar(item: item, progressController: progress),
                    ),
                    ],
                  ],
                ),
              ),
              if (preview != null) ...<Widget>[
                Positioned.fill(
                  child: GestureDetector(
                    key: const Key('shop-tool-preview-scrim'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _previewUnlocking ? null : _closeToolPreview,
                    child: const ColoredBox(color: Color(0xB8000000)),
                  ),
                ),
                Center(
                  child: _ToolUnlockSheet(
                    item: preview,
                    unlocking: _previewUnlocking,
                    unlockDone: _previewUnlockDone,
                    onClose: _closeToolPreview,
                    onUnlock: _unlockToolPreview,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _pill('Salon', 0),
          const SizedBox(width: 8),
          _pill('Tools', 1),
        ],
      ),
    );
  }

  Widget _pill(String label, int value) {
    final on = index == value;
    return GestureDetector(
      key: Key('shop-tab-${label.toLowerCase()}'),
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: on ? const Color(0xFFFF6BA8) : const Color(0x22E84F8F),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Baloo2',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: on ? Colors.white : const Color(0xFF8A4B63),
          ),
        ),
      ),
    );
  }
}

/// One tool's shelf: every skin it has, with buy / equip in a single tap.
class _ToolShelf extends StatelessWidget {
  const _ToolShelf({
    required this.tool,
    required this.progressController,
    required this.onPreview,
  });

  final NailCareToolId tool;
  final PlayerProgressController progressController;
  final ValueChanged<NailCareInventoryItem> onPreview;

  @override
  Widget build(BuildContext context) {
    final skins = NailCareInventory.skinsFor(tool);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              NailCareInventory.toolLabel(tool).toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF8A4B63),
              ),
            ),
          ),
          SizedBox(
            // 132 before the speed line was added under the name; grown by
            // exactly that line so the bottle art keeps the room it had.
            height: 147,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: skins.length,
              separatorBuilder: (BuildContext _, int __) =>
                  const SizedBox(width: 10),
              itemBuilder: (BuildContext context, int i) => _SkinCard(
                item: skins[i],
                progressController: progressController,
                onPreview: onPreview,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkinCard extends StatelessWidget {
  const _SkinCard({
    required this.item,
    required this.progressController,
    required this.onPreview,
  });

  final NailCareInventoryItem item;
  final PlayerProgressController progressController;
  final ValueChanged<NailCareInventoryItem> onPreview;

  @override
  Widget build(BuildContext context) {
    final owned = progressController.ownsSkin(item);
    final equipped =
        owned && progressController.isToolEquipped(item.toolId, item.id);
    final canBuy = progressController.canBuySkin(item);

    return GestureDetector(
      key: Key('shop-skin-${item.id}'),
      onTap: () {
        if (owned) {
          GameAudio.instance.tap();
          progressController.equipSkin(item);
          return;
        }
        // Locked: open the same preview/unlock sheet the manicure HUD uses,
        // instead of spending coins on a bare tap with no confirmation.
        GameAudio.instance.tap();
        onPreview(item);
      },
      child: Container(
        width: 104,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8FC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: equipped ? const Color(0xFFFF6BA8) : const Color(0xFFF4B6C8),
            width: equipped ? 3 : 2,
          ),
        ),
        // The lock now sits over the padding too, in a Stack one level up
        // from before: centering it inside just the bottle's Expanded put it
        // in the upper two-thirds of the card, never the middle of the whole
        // card the way a real watermark should read.
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Opacity(
                      opacity: owned ? 1 : 0.45,
                      child: Image.asset(
                        'assets/images/${item.iconPath}',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5B3742),
                    ),
                  ),
                  // What the coins actually buy. Reserved at a fixed height
                  // rather than shown only when there is a bonus: the free
                  // starter has no label, and letting the row collapse made
                  // its bottle taller than every other card on the shelf.
                  SizedBox(
                    height: 13,
                    child: item.speedLabel.isEmpty
                        ? null
                        : Text(
                            item.speedLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Baloo2',
                              fontSize: 11,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5FA98A),
                            ),
                          ),
                  ),
                  const SizedBox(height: 2),
                  if (equipped)
                    const Text(
                      'Equipped',
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE84F8F),
                      ),
                    )
                  else if (owned)
                    const Text(
                      'Tap to use',
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontSize: 12,
                        color: Color(0xFF9A6A7A),
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const GoldCoin(size: 13),
                        const SizedBox(width: 4),
                        Text(
                          '${item.unlockPrice}',
                          style: TextStyle(
                            fontFamily: 'Baloo2',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: canBuy
                                ? const Color(0xFF5B3742)
                                : const Color(0xFFB993A0),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // The lock now fills the whole card — not an icon sitting on the
            // card, but the card's entire face read as one big translucent
            // lock — clipped to the same rounded rect so it never pokes past
            // the border.
            if (!owned)
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: Icon(
                        Icons.lock_rounded,
                        color: const Color(0xFF5B3742).withOpacity(0.14),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FurnitureCard extends StatelessWidget {
  const _FurnitureCard({
    required this.item,
    required this.progressController,
    required this.focused,
  });

  final ShopItem item;
  final PlayerProgressController progressController;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final owned = progressController.owns(item.id);
    return AnimatedScale(
      scale: focused ? 1 : 0.92,
      duration: const Duration(milliseconds: 180),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8FC),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF4B6C8), width: 3),
          ),
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  const SizedBox(height: 16),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF5B3742),
                    ),
                  ),
                  Text(
                    _slotLabel(item.slot),
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 14,
                      color: Color(0xFF9A6A7A),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _preview(owned),
                    ),
                  ),
                ],
              ),
              if (!owned)
                const Positioned(
                  top: 16,
                  right: 16,
                  child: Icon(
                    Icons.lock_rounded,
                    color: Color(0xFFE84F8F),
                    size: 32,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _preview(bool owned) {
    final asset = item.previewAsset;
    final image = asset == null
        ? _Silhouette(slot: item.slot)
        : Image.asset(
            'assets/images/$asset',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          );
    if (owned) {
      return image;
    }
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Color(0xAA5B3742), BlendMode.modulate),
      child: image,
    );
  }

  static String _slotLabel(ShopSlot slot) {
    switch (slot) {
      case ShopSlot.sofa:
        return 'Sofa';
      case ShopSlot.chair:
        return 'Chair';
      case ShopSlot.table:
        return 'Table';
      case ShopSlot.plant:
        return 'Plant';
      case ShopSlot.lamp:
        return 'Lamp';
    }
  }
}

class _Silhouette extends StatelessWidget {
  const _Silhouette({required this.slot});

  final ShopSlot slot;

  @override
  Widget build(BuildContext context) {
    final icon = switch (slot) {
      ShopSlot.sofa => Icons.weekend_rounded,
      ShopSlot.chair => Icons.chair_rounded,
      ShopSlot.table => Icons.table_restaurant_rounded,
      ShopSlot.plant => Icons.local_florist_rounded,
      ShopSlot.lamp => Icons.light_rounded,
    };
    return Center(
      child: Icon(icon, size: 140, color: const Color(0xFFC98AA3)),
    );
  }
}

class _BuyBar extends StatelessWidget {
  const _BuyBar({required this.item, required this.progressController});

  final ShopItem item;
  final PlayerProgressController progressController;

  @override
  Widget build(BuildContext context) {
    final owned = progressController.owns(item.id);
    final equipped = progressController.isEquipped(item.slot, item.id);
    final canBuy = progressController.canBuy(item);
    // Owned but parked (e.g. the starter piece after buying a premium one,
    // or a premium piece after switching back to the starter) can be
    // re-equipped instead of sitting there with no action at all.
    final canEquip = owned && !equipped;

    late final Widget child;
    if (equipped) {
      child = const Text(
        'Placed in salon',
        style: TextStyle(
          fontFamily: 'Baloo2',
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      );
    } else if (owned) {
      child = const Text(
        'Use in salon',
        style: TextStyle(
          fontFamily: 'Baloo2',
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      );
    } else {
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            canBuy ? 'Buy  ' : 'Locked  ',
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const GoldCoin(size: 18),
          const SizedBox(width: 6),
          Text(
            '${item.price}',
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        key: Key('shop-buy-${item.id}'),
        style: FilledButton.styleFrom(
          backgroundColor: canBuy || canEquip
              ? const Color(0xFFFF6BA8)
              : const Color(0xFFD7B4C0),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: canBuy
            ? () {
                if (progressController.buyShopItem(item)) {
                  GameAudio.instance.coin();
                }
              }
            : canEquip
            ? () {
                if (progressController.equipShopItem(item)) {
                  GameAudio.instance.tap();
                }
              }
            : null,
        child: child,
      ),
    );
  }
}

/// The locked-tool confirmation card: art pops in, then a single
/// [ToolPurchaseButton] carries the price, the lock sprite, and the
/// "Purchased" hold-then-close. Deliberately the plain-card half of
/// NailCareOverlay's `_InventoryPreviewSheet` — this screen only ever opens
/// it for a locked item, never for an owned one to re-equip, so there is no
/// "Use / Selected" branch to carry over.
class _ToolUnlockSheet extends StatelessWidget {
  const _ToolUnlockSheet({
    required this.item,
    required this.unlocking,
    required this.unlockDone,
    required this.onClose,
    required this.onUnlock,
  });

  final NailCareInventoryItem item;
  final bool unlocking;
  final bool unlockDone;
  final VoidCallback onClose;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
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
                  key: const Key('shop-tool-preview-close'),
                  onPressed: unlocking ? null : onClose,
                  icon: const Icon(Icons.close_rounded),
                  color: const Color(0xFF8A4B63),
                  tooltip: 'Close preview',
                ),
              ),
              PreviewArtPopIn(
                child: Image.asset(
                  'assets/images/${item.iconPath}',
                  width: 138,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF8A4B63),
                ),
              ),
              const SizedBox(height: 6),
              ToolPurchaseButton(
                price: item.unlockPrice,
                label: unlockDone ? 'Purchased' : 'Unlock for',
                unlocking: unlocking,
                unlockDone: unlockDone,
                onPressed: onUnlock,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
