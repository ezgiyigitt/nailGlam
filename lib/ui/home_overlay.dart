import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/config/asset_paths.dart';
import 'how_to_play_screen.dart';

/// Independent first screen. Gameplay remains hidden until Play is pressed.
class HomeOverlay extends StatefulWidget {
  const HomeOverlay({required this.onPlay, super.key});

  static const String id = 'home';

  final VoidCallback onPlay;

  @override
  State<HomeOverlay> createState() => _HomeOverlayState();
}

class _HomeOverlayState extends State<HomeOverlay> {
  late final Future<ui.Image> _buttonSheet = _loadButtonSheet();
  bool _musicEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8CF),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            'assets/images/${AssetPaths.menuBackground}',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final compact = constraints.maxHeight < 700;
                final logoHeight =
                    (constraints.maxHeight * (compact ? 0.48 : 0.53)).clamp(
                      280.0,
                      540.0,
                    );
                final playWidth = (constraints.maxWidth * 0.56).clamp(
                  190.0,
                  270.0,
                );
                final howWidth = (constraints.maxWidth * 0.5).clamp(
                  180.0,
                  235.0,
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
                            color: const Color(0xFFFF78B6),
                            onPressed: () =>
                                setState(() => _musicEnabled = !_musicEnabled),
                          ),
                          const SizedBox(width: 10),
                          _MenuIconButton(
                            tooltip: 'Settings',
                            icon: Icons.settings_rounded,
                            color: const Color(0xFF9D69E7),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Image.asset(
                        'assets/images/${AssetPaths.menuLogo}',
                        height: logoHeight,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    SizedBox(height: compact ? 6 : 14),
                    FutureBuilder<ui.Image>(
                      future: _buttonSheet,
                      builder:
                          (
                            BuildContext context,
                            AsyncSnapshot<ui.Image> snapshot,
                          ) {
                            if (!snapshot.hasData) {
                              return SizedBox(height: compact ? 190 : 230);
                            }
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                _SpritePressButton(
                                  image: snapshot.data!,
                                  source: const Rect.fromLTWH(
                                    18,
                                    283,
                                    988,
                                    500,
                                  ),
                                  width: playWidth,
                                  semanticLabel: 'Play',
                                  onPressed: widget.onPlay,
                                ),
                                SizedBox(height: compact ? 8 : 14),
                                _SpritePressButton(
                                  image: snapshot.data!,
                                  source: const Rect.fromLTWH(
                                    48,
                                    881,
                                    929,
                                    356,
                                  ),
                                  width: howWidth,
                                  semanticLabel: 'How to play',
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const HowToPlayScreen(),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                    ),
                    SizedBox(height: compact ? 8 : 18),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<ui.Image> _loadButtonSheet() async {
    final data = await rootBundle.load(
      'assets/images/${AssetPaths.menuButtons}',
    );
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }
}

class _SpritePressButton extends StatefulWidget {
  const _SpritePressButton({
    required this.image,
    required this.source,
    required this.width,
    required this.semanticLabel,
    required this.onPressed,
  });

  final ui.Image image;
  final Rect source;
  final double width;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  State<_SpritePressButton> createState() => _SpritePressButtonState();
}

class _SpritePressButtonState extends State<_SpritePressButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final visualHeight =
        widget.width * widget.source.height / widget.source.width;
    final hitPadding = (visualHeight * 0.08).clamp(6.0, 12.0);

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onPressed();
        },
        child: Padding(
          padding: EdgeInsets.all(hitPadding),
          child: AnimatedScale(
            scale: _pressed ? 0.95 : 1,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOutCubic,
            child: SizedBox(
              width: widget.width,
              height: visualHeight,
              child: CustomPaint(
                painter: _SpriteCropPainter(
                  image: widget.image,
                  source: widget.source,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpriteCropPainter extends CustomPainter {
  const _SpriteCropPainter({required this.image, required this.source});

  final ui.Image image;
  final Rect source;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      source,
      Offset.zero & size,
      Paint()
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_SpriteCropPainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.source != source;
}

class _MenuIconButton extends StatelessWidget {
  const _MenuIconButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color,
        elevation: 5,
        shadowColor: const Color(0x55964172),
        shape: const CircleBorder(
          side: BorderSide(color: Colors.white, width: 2.5),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}
