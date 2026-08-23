import 'package:flutter/material.dart';

import '../game/config/asset_paths.dart';
import 'how_to_play_screen.dart';

/// Independent first screen. Gameplay stays hidden until Start is pressed.
class HomeOverlay extends StatefulWidget {
  const HomeOverlay({required this.onPlay, super.key});

  static const String id = 'home';

  final VoidCallback onPlay;

  @override
  State<HomeOverlay> createState() => _HomeOverlayState();
}

class _HomeOverlayState extends State<HomeOverlay> {
  bool _musicEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFD6E8),
      body: Stack(
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
                  Color(0x22FFFFFF),
                  Color(0x00FFFFFF),
                  Color(0x33FFB7D5),
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
                final logoHeight =
                    (constraints.maxHeight * (compact ? 0.42 : 0.46)).clamp(
                      220.0,
                      420.0,
                    );
                final startWidth = (constraints.maxWidth * 0.72).clamp(
                  220.0,
                  320.0,
                );
                final howWidth = (constraints.maxWidth * 0.66).clamp(
                  200.0,
                  290.0,
                );

                return Column(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _MenuIconButton(
                            tooltip: _musicEnabled ? 'Music on' : 'Music off',
                            icon: _musicEnabled
                                ? Icons.music_note_rounded
                                : Icons.music_off_rounded,
                            onPressed: () =>
                                setState(() => _musicEnabled = !_musicEnabled),
                          ),
                          const SizedBox(width: 10),
                          _MenuIconButton(
                            tooltip: 'Settings',
                            icon: Icons.settings_rounded,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Image.asset(
                          'assets/images/${AssetPaths.menuLogo}',
                          height: logoHeight,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 16),
                    _GlossyMenuButton(
                      label: 'START',
                      width: startWidth,
                      height: compact ? 64 : 72,
                      primary: true,
                      onPressed: widget.onPlay,
                    ),
                    SizedBox(height: compact ? 12 : 16),
                    _GlossyMenuButton(
                      label: 'HOW TO PLAY',
                      width: howWidth,
                      height: compact ? 56 : 62,
                      primary: false,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const HowToPlayScreen(),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 18),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Bubble-gloss pink CTA that matches the NAIL GLAM logo sticker look.
class _GlossyMenuButton extends StatefulWidget {
  const _GlossyMenuButton({
    required this.label,
    required this.width,
    required this.height,
    required this.primary,
    required this.onPressed,
  });

  final String label;
  final double width;
  final double height;
  final bool primary;
  final VoidCallback onPressed;

  @override
  State<_GlossyMenuButton> createState() => _GlossyMenuButtonState();
}

class _GlossyMenuButtonState extends State<_GlossyMenuButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.height * 0.48;
    final cream = _MenuColors.cream;
    final pink = widget.primary ? _MenuColors.pink : _MenuColors.pinkSoft;
    final pinkDeep = widget.primary
        ? _MenuColors.pinkDeep
        : const Color(0xFFF06A9F);

    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
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
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0x55C2185B),
                  blurRadius: _pressed ? 8 : 16,
                  offset: Offset(0, _pressed ? 4 : 8),
                ),
              ],
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: cream, width: 5),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color.lerp(pink, Colors.white, 0.22)!,
                    pink,
                    pinkDeep,
                  ],
                  stops: const <double>[0, 0.45, 1],
                ),
              ),
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 18,
                    right: 18,
                    top: 7,
                    height: widget.height * 0.34,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Colors.white.withValues(alpha: 0.55),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontSize: widget.primary ? 30 : 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        height: 1,
                        color: Colors.white,
                        shadows: const <Shadow>[
                          Shadow(
                            color: Color(0x66B0004F),
                            blurRadius: 0,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

abstract final class _MenuColors {
  static const Color pink = Color(0xFFFF6BA8);
  static const Color pinkSoft = Color(0xFFFF85B8);
  static const Color pinkDeep = Color(0xFFE84F8F);
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
