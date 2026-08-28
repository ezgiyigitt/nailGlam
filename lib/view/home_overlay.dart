import 'package:flutter/material.dart';

import 'package:nail_glam/controller/game_audio.dart';
import 'package:nail_glam/controller/home_controller.dart';
import 'package:nail_glam/model/asset_paths.dart';
import 'package:nail_glam/model/customer_roster.dart';
import 'cropped_asset.dart';
import 'daily_reward_sheet.dart';
import 'gold_coin.dart';
import 'how_to_play_screen.dart';
import 'settings_sheet.dart';
import 'shop_screen.dart';

/// Independent first screen. Gameplay stays hidden until Start is pressed.
class HomeOverlay extends StatefulWidget {
  const HomeOverlay({required this.controller, super.key});

  static const String id = 'home';

  final HomeController controller;

  @override
  State<HomeOverlay> createState() => _HomeOverlayState();
}

class _HomeOverlayState extends State<HomeOverlay> {
  bool _settingsOpen = false;
  bool _guestsOpen = false;

  HomeController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      GameAudio.instance.playMusic();
      if (_controller.shouldPromptDailyLogin) {
        showDailyRewardSheet(
          context: context,
          progressController: _controller.progress,
        );
      }
    });
  }

  void _selectGuest(CustomerProfile guest) {
    setState(() => _controller.selectGuest(guest));
  }

  void _openSettings() {
    GameAudio.instance.tap();
    setState(() {
      _guestsOpen = false;
      _settingsOpen = true;
    });
  }

  void _closeSettings() {
    setState(() => _settingsOpen = false);
  }

  void _openGuests() {
    GameAudio.instance.tap();
    setState(() {
      _settingsOpen = false;
      _guestsOpen = true;
    });
  }

  void _closeGuests() {
    setState(() => _guestsOpen = false);
  }

  void _openShop() {
    GameAudio.instance.tap();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShopScreen(progressController: _controller.progress),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4C8),
      body: GestureDetector(
        onHorizontalDragEnd: (DragEndDetails details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! < -240) {
            _openShop();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.asset(
              'assets/images/${AssetPaths.menuBackground}',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0x14FFFFFF),
                    Color(0x00000000),
                    Color(0x66C47A6A),
                  ],
                  stops: <double>[0, 0.45, 1],
                ),
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 12, 20, 22),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final compact = constraints.maxHeight < 700;
                  final startWidth =
                      (constraints.maxWidth * (compact ? 0.76 : 0.80))
                          .clamp(220.0, 360.0);
                  final howWidth = startWidth * 0.88;

                  return Column(
                    children: <Widget>[
                      Align(
                        alignment: Alignment.topRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            AnimatedBuilder(
                              animation: _controller.progress,
                              builder: (BuildContext context, _) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: GoldBalanceChip(
                                    coins: _controller.progress.coins,
                                  ),
                                );
                              },
                            ),
                            AnimatedBuilder(
                              animation: _controller.progress,
                              builder: (BuildContext context, _) {
                                if (!_controller.progress.canClaimLogin) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: _MenuIconButton(
                                    tooltip: 'Daily coins',
                                    icon: Icons.card_giftcard_rounded,
                                    onPressed: () {
                                      GameAudio.instance.tap();
                                      showDailyRewardSheet(
                                        context: context,
                                        progressController: _controller.progress,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                            _MenuIconButton(
                              tooltip: 'Salon shop',
                              icon: Icons.storefront_rounded,
                              onPressed: _openShop,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                _MenuIconButton(
                                  tooltip: 'Settings',
                                  icon: Icons.settings_rounded,
                                  onPressed: _openSettings,
                                ),
                                const SizedBox(height: 10),
                                _MenuIconButton(
                                  tooltip: 'Guests',
                                  icon: Icons.people_alt_rounded,
                                  onPressed: _openGuests,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (BuildContext context, BoxConstraints logo) {
                            final maxWidth = logo.maxWidth * 0.94;
                            final maxHeight = logo.maxHeight * 0.74;
                            return Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: maxWidth,
                                  maxHeight: maxHeight,
                                ),
                                child: Image.asset(
                                  'assets/images/${AssetPaths.menuLogo}',
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                  gaplessPlayback: true,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 16),
                      _MenuArtButton(
                        asset: AssetPaths.menuStart,
                        semanticLabel: 'Start',
                        width: startWidth,
                        onPressed: () {
                          GameAudio.instance.tap();
                          _controller.onStart();
                        },
                      ),
                      SizedBox(height: compact ? 8 : 10),
                      _MenuArtButton(
                        asset: AssetPaths.menuHowToPlay,
                        semanticLabel: 'How to play',
                        width: howWidth,
                        onPressed: () {
                          GameAudio.instance.tap();
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const HowToPlayScreen(),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: compact ? 10 : 18),
                    ],
                  );
                },
              ),
            ),
            if (_settingsOpen) ...<Widget>[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeSettings,
                  child: const ColoredBox(color: Color(0xCC3A1C28)),
                ),
              ),
              Center(
                child: SettingsDialog(onDone: _closeSettings),
              ),
            ],
            if (_guestsOpen) ...<Widget>[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeGuests,
                  child: const ColoredBox(color: Color(0xCC3A1C28)),
                ),
              ),
              Center(
                child: _GuestsDialog(
                  selected: _controller.selectedGuest,
                  onSelect: _selectGuest,
                  onDone: _closeGuests,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuestsDialog extends StatelessWidget {
  const _GuestsDialog({
    required this.selected,
    required this.onSelect,
    required this.onDone,
  });

  final CustomerProfile selected;
  final ValueChanged<CustomerProfile> onSelect;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF8FC),
      borderRadius: BorderRadius.circular(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 22),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF4B6C8), width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Guests',
                style: TextStyle(
                  fontFamily: 'Baloo2',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE84F8F),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tap a guest, then Start to do their nails.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Baloo2',
                  fontSize: 15,
                  color: Color(0xFF8A4B63),
                ),
              ),
              const SizedBox(height: 18),
              for (var i = 0; i < CustomerRoster.all.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: 10),
                _GuestCard(
                  guest: CustomerRoster.all[i],
                  order: i + 1,
                  selected: selected.id == CustomerRoster.all[i].id,
                  onTap: () {
                    GameAudio.instance.tap();
                    onSelect(CustomerRoster.all[i]);
                  },
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6BA8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: onDone,
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
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

class _GuestCard extends StatelessWidget {
  const _GuestCard({
    required this.guest,
    required this.order,
    required this.selected,
    required this.onTap,
  });

  final CustomerProfile guest;
  final int order;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFE0EF) : const Color(0xFFFFF6EE),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        key: Key('guest-card-${guest.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? const Color(0xFFE56B97) : Colors.white,
              width: 2.5,
            ),
          ),
          child: Row(
            children: <Widget>[
              _GuestFaceAvatar(emotionAsset: guest.emotionAsset),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      guest.name,
                      style: const TextStyle(
                        fontFamily: 'Baloo2',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF5B3742),
                      ),
                    ),
                    Text(
                      'Guest #$order',
                      style: const TextStyle(
                        fontFamily: 'Baloo2',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9A6A7A),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: selected
                    ? const Color(0xFFE56B97)
                    : const Color(0xFFC98AA3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tight circular crop of one emotion-strip face (happy frame).
class _GuestFaceAvatar extends StatefulWidget {
  const _GuestFaceAvatar({required this.emotionAsset});

  final String emotionAsset;

  static const double _size = 72;
  static const int _frameCount = 5;
  static const int _happyFrame = 3;

  @override
  State<_GuestFaceAvatar> createState() => _GuestFaceAvatarState();
}

class _GuestFaceAvatarState extends State<_GuestFaceAvatar> {
  Rect? _source;

  @override
  void initState() {
    super.initState();
    _resolveSource();
  }

  @override
  void didUpdateWidget(covariant _GuestFaceAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emotionAsset != widget.emotionAsset) {
      _source = null;
      _resolveSource();
    }
  }

  Future<void> _resolveSource() async {
    final path = widget.emotionAsset;
    try {
      final image = await AssetImageCache.load(path);
      if (!mounted || path != widget.emotionAsset) {
        return;
      }
      final cellW = image.width / _GuestFaceAvatar._frameCount;
      final cellH = image.height.toDouble();
      final face = cellW < cellH ? cellW * 0.86 : cellH * 0.72;
      setState(() {
        _source = Rect.fromLTWH(
          _GuestFaceAvatar._happyFrame * cellW + (cellW - face) / 2,
          cellH * 0.06,
          face,
          face,
        );
      });
    } catch (_) {
      // Placeholder circle stays visible.
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = _source;
    return Container(
      width: _GuestFaceAvatar._size,
      height: _GuestFaceAvatar._size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFE4F0),
        border: Border.all(color: const Color(0xFFF4B6C8), width: 3),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: source == null
          ? const Center(
              child: Icon(Icons.face_rounded, color: Color(0xFFE56B97)),
            )
          : CroppedAsset(
              asset: widget.emotionAsset,
              source: source,
              width: _GuestFaceAvatar._size,
              height: _GuestFaceAvatar._size,
              fit: BoxFit.cover,
            ),
    );
  }
}

class _MenuArtButton extends StatefulWidget {
  const _MenuArtButton({
    required this.asset,
    required this.semanticLabel,
    required this.width,
    required this.onPressed,
  });

  final String asset;
  final String semanticLabel;
  final double width;
  final VoidCallback onPressed;

  @override
  State<_MenuArtButton> createState() => _MenuArtButtonState();
}

class _MenuArtButtonState extends State<_MenuArtButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutCubic,
          child: Image.asset(
            'assets/images/${widget.asset}',
            width: widget.width,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

abstract final class _MenuColors {
  static const Color pink = Color(0xFFFF6BA8);
  static const Color cream = Color(0xFFFFF6F0);
}

class _MenuIconButton extends StatelessWidget {
  const _MenuIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: _MenuColors.pink,
        elevation: 4,
        shadowColor: const Color(0x55964172),
        shape: const CircleBorder(
          side: BorderSide(color: _MenuColors.cream, width: 3),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
