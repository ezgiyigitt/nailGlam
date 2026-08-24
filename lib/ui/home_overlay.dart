import 'package:flutter/material.dart';

import '../game/audio/game_audio.dart';
import '../game/config/asset_paths.dart';
import '../game/progress/player_progress.dart';
import 'daily_reward_sheet.dart';
import 'gold_coin.dart';
import 'how_to_play_screen.dart';
import 'settings_sheet.dart';
import 'shop_screen.dart';

/// Independent first screen. Gameplay stays hidden until Start is pressed.
class HomeOverlay extends StatefulWidget {
  const HomeOverlay({
    required this.onPlay,
    this.progress,
    super.key,
  });

  static const String id = 'home';

  final VoidCallback onPlay;
  final PlayerProgress? progress;

  @override
  State<HomeOverlay> createState() => _HomeOverlayState();
}

class _HomeOverlayState extends State<HomeOverlay> {
  late final PlayerProgress _progress =
      widget.progress ?? PlayerProgress.memory();
  bool _settingsOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      GameAudio.instance.playMusic();
      if (_progress.store != null && _progress.canClaimLogin) {
        showDailyRewardSheet(context: context, progress: _progress);
      }
    });
  }

  void _openSettings() {
    GameAudio.instance.tap();
    setState(() => _settingsOpen = true);
  }

  void _closeSettings() {
    setState(() => _settingsOpen = false);
  }

  void _openShop() {
    GameAudio.instance.tap();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShopScreen(progress: _progress),
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
          // Soft wash so logo and buttons stay readable on any wallpaper.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0x14FFFFFF),
                  Color(0x00000000),
                  Color(0x550F3D38),
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
                final startWidth = (constraints.maxWidth * (compact ? 0.76 : 0.80))
                    .clamp(220.0, 360.0);
                final howWidth = startWidth * 0.88;

                return Column(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          AnimatedBuilder(
                            animation: _progress,
                            builder: (BuildContext context, _) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: GoldBalanceChip(coins: _progress.coins),
                              );
                            },
                          ),
                          AnimatedBuilder(
                            animation: _progress,
                            builder: (BuildContext context, _) {
                              if (!_progress.canClaimLogin) {
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
                                      progress: _progress,
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
                          _MenuIconButton(
                            tooltip: 'Settings',
                            icon: Icons.settings_rounded,
                            onPressed: _openSettings,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Image.asset(
                          'assets/images/${AssetPaths.menuLogo}',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 16),
                    _MenuArtButton(
                      asset: AssetPaths.menuStart,
                      semanticLabel: 'Start',
                      width: startWidth,
                      onPressed: () {
                        GameAudio.instance.tap();
                        widget.onPlay();
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
        ],
      ),
      ),
    );
  }
}

/// Gold-rim pink menu buttons. The label is painted into the PNG.
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
