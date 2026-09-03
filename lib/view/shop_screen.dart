import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:nail_glam/controller/game_audio.dart';
import 'package:nail_glam/controller/player_progress_controller.dart';
import 'package:nail_glam/model/nail_care_tools.dart';
import 'package:nail_glam/model/salon_catalog.dart';
import 'gold_coin.dart';

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

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
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
          return SafeArea(
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
                          _ToolShelf(tool: tool, progressController: progress),
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
                    onPageChanged: (int value) => setState(() => _index = value),
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
  const _ToolShelf({required this.tool, required this.progressController});

  final NailCareToolId tool;
  final PlayerProgressController progressController;

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
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: skins.length,
              separatorBuilder: (BuildContext _, int __) =>
                  const SizedBox(width: 10),
              itemBuilder: (BuildContext context, int i) => _SkinCard(
                item: skins[i],
                progressController: progressController,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkinCard extends StatelessWidget {
  const _SkinCard({required this.item, required this.progressController});

  final NailCareInventoryItem item;
  final PlayerProgressController progressController;

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
        if (progressController.buySkin(item)) {
          GameAudio.instance.coin();
        }
      },
      child: Container(
        width: 104,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8FC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: equipped ? const Color(0xFFFF6BA8) : const Color(0xFFF4B6C8),
            width: equipped ? 3 : 2,
          ),
        ),
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
