import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/audio/game_audio.dart';
import '../game/config/asset_paths.dart';
import '../game/config/sprite_atlas.dart';
import 'cropped_asset.dart';
import 'gold_coin.dart';

/// Menu tutorial: a silent 16s loop of the real salon loop, with captions.
class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key});

  static const Duration loop = Duration(milliseconds: 16000);
  static const Color pink = Color(0xFFFF6BA8);
  static const Color pinkDeep = Color(0xFFE84F8F);
  static const Color cream = Color(0xFFFFF6F0);

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(vsync: this, duration: HowToPlayScreen.loop)
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          _clock.forward(from: 0);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  void _close() {
    GameAudio.instance.tap();
    Navigator.pop(context);
  }

  void _seek(HowToPlayBeat beat) {
    GameAudio.instance.tap();
    _clock.forward(from: beat.start.inMilliseconds / HowToPlayScreen.loop.inMilliseconds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            'assets/images/${AssetPaths.menuBackground}',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
          const ColoredBox(color: Color(0x66FFFFFF)),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: AnimatedBuilder(
              animation: _clock,
              builder: (BuildContext context, Widget? child) {
                final beat = HowToPlayBeat.at(_clock.value);
                return Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        _RoundIconButton(
                          icon: Icons.arrow_back_rounded,
                          semanticLabel: 'Back',
                          onPressed: _close,
                        ),
                        const Expanded(
                          child: Text(
                            'HOW TO PLAY',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Baloo2',
                              color: HowToPlayScreen.pinkDeep,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        _TextChip(
                          key: const Key('how-to-play-skip'),
                          label: 'Skip',
                          onPressed: _close,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 430),
                          child: _StageCard(beat: beat, t: _clock.value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Caption(text: beat.caption),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        for (final item in HowToPlayBeat.values)
                          _BeatDot(
                            active: item == beat,
                            onTap: () => _seek(item),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _GotItButton(onPressed: _close),
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

enum HowToPlayBeat {
  wish(
    start: Duration.zero,
    end: Duration(milliseconds: 3400),
    caption: 'She shows you the look.',
  ),
  wash(
    start: Duration(milliseconds: 3400),
    end: Duration(milliseconds: 7000),
    caption: 'Wash first.',
  ),
  nail(
    start: Duration(milliseconds: 7000),
    end: Duration(milliseconds: 13200),
    caption: 'One nail: spray, wipe, clip, polish.',
  ),
  gold(
    start: Duration(milliseconds: 13200),
    end: Duration(milliseconds: 16000),
    caption: 'Match her color. Earn gold.',
  );

  const HowToPlayBeat({
    required this.start,
    required this.end,
    required this.caption,
  });

  final Duration start;
  final Duration end;
  final String caption;

  static HowToPlayBeat at(double clock) {
    final ms = clock * HowToPlayScreen.loop.inMilliseconds;
    for (final beat in HowToPlayBeat.values) {
      if (ms >= beat.start.inMilliseconds && ms < beat.end.inMilliseconds) {
        return beat;
      }
    }
    return HowToPlayBeat.gold;
  }

  double progress(double clock) {
    final ms = clock * HowToPlayScreen.loop.inMilliseconds;
    final span = (end - start).inMilliseconds;
    if (span <= 0) {
      return 1;
    }
    return ((ms - start.inMilliseconds) / span).clamp(0.0, 1.0);
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({required this.beat, required this.t});

  final HowToPlayBeat beat;
  final double t;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.78,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xF7FFF8FC),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: HowToPlayScreen.cream, width: 5),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x44C2185B),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.asset(
                'assets/images/${AssetPaths.tableSurface}',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.high,
              ),
              const ColoredBox(color: Color(0x33FFF3EA)),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                child: KeyedSubtree(
                  key: ValueKey<HowToPlayBeat>(beat),
                  child: switch (beat) {
                    HowToPlayBeat.wish => _WishBeat(t: beat.progress(t)),
                    HowToPlayBeat.wash => _WashBeat(t: beat.progress(t)),
                    HowToPlayBeat.nail => _NailBeat(t: beat.progress(t)),
                    HowToPlayBeat.gold => _GoldBeat(t: beat.progress(t)),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WishBeat extends StatelessWidget {
  const _WishBeat({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final sitFrame = t < 0.38 ? (t / 0.38 * 3).floor().clamp(0, 3) : 3;
    final bubble = Curves.easeOutBack.transform(((t - 0.28) / 0.35).clamp(0.0, 1.0));

    return Stack(
      children: <Widget>[
        Align(
          alignment: const Alignment(0, 0.35),
          child: StripFrame(
            asset: AssetPaths.customerSit,
            frame: sitFrame,
            frameCount: 4,
            height: 280,
          ),
        ),
        Align(
          alignment: const Alignment(0.55, -0.55),
          child: Opacity(
            opacity: bubble.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.86 + 0.14 * bubble,
              alignment: const Alignment(0.3, 1),
              child: CustomPaint(
                painter: const _SpeechBubblePainter(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        'Lila',
                        style: TextStyle(
                          fontFamily: 'Baloo2',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFC47A96),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Image.asset(
                        'assets/images/${AssetPaths.polishBlush}',
                        height: 72,
                        filterQuality: FilterQuality.high,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WashBeat extends StatelessWidget {
  const _WashBeat({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final frame = (t * 3.99).floor().clamp(0, 3);
    final sheet = SpriteAtlas.handWash;
    final origin = sheet.framePositions[frame];
    final size = sheet.frameSize;
    final align = SpriteAtlas.handWashFrameAlign[frame];
    final soapT = Curves.easeInOut.transform(t);

    return Stack(
      children: <Widget>[
        Align(
          alignment: const Alignment(0, 0.2),
          child: Transform.translate(
            offset: Offset(align.x * 0.35, align.y * 0.35),
            child: CroppedAsset(
              asset: AssetPaths.handWash,
              source: Rect.fromLTWH(origin.x, origin.y, size.x, size.y),
              height: 300,
            ),
          ),
        ),
        Align(
          alignment: Alignment(0.55 - 0.7 * soapT, -0.55 + 0.7 * soapT),
          child: Transform.rotate(
            angle: -0.4 + soapT * 0.9,
            child: CroppedAsset(
              asset: AssetPaths.handSoap,
              source: Rect.fromLTWH(
                SpriteAtlas.handSoap.position.x,
                SpriteAtlas.handSoap.position.y,
                SpriteAtlas.handSoap.size.x,
                SpriteAtlas.handSoap.size.y,
              ),
              height: 110,
            ),
          ),
        ),
      ],
    );
  }
}

class _NailBeat extends StatelessWidget {
  const _NailBeat({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final phase = t < 0.22
        ? 0
        : t < 0.44
            ? 1
            : t < 0.72
                ? 2
                : 3;
    final clipFrame = phase < 2 ? 0 : ((t - 0.44) / 0.28 * 3.99).floor().clamp(0, 3);
    final showShort = phase >= 2;
    final toolPath = switch (phase) {
      0 => AssetPaths.nailSpray,
      1 => AssetPaths.nailBuffer,
      2 => AssetPaths.nailClips,
      _ => AssetPaths.polishBrush,
    };
    final toolRegion = switch (phase) {
      0 => SpriteAtlas.nailSpray,
      1 => SpriteAtlas.nailBuffer,
      2 => SpriteAtlas.nailClips,
      _ => SpriteAtlas.polishBrush,
    };
    final bob = math.sin(t * math.pi * 6) * 8;

    return Stack(
      children: <Widget>[
        Align(
          alignment: const Alignment(-0.15, 0.35),
          child: showShort
              ? CroppedAsset(
                  asset: AssetPaths.shortNail,
                  source: Rect.fromLTWH(
                    SpriteAtlas.shortNail.framePositions[clipFrame].x,
                    SpriteAtlas.shortNail.framePositions[clipFrame].y,
                    SpriteAtlas.shortNail.frameSize.x,
                    SpriteAtlas.shortNail.frameSize.y,
                  ),
                  height: 310,
                )
              : CroppedAsset(
                  asset: AssetPaths.fifthNailClean,
                  source: Rect.fromLTWH(
                    SpriteAtlas.fifthNailClean.framePositions[3].x,
                    SpriteAtlas.fifthNailClean.framePositions[3].y,
                    SpriteAtlas.fifthNailClean.frameSize.x,
                    SpriteAtlas.fifthNailClean.frameSize.y,
                  ),
                  height: 310,
                ),
        ),
        Align(
          alignment: Alignment(0.72, -0.05 + bob / 180),
          child: Transform.rotate(
            angle: -0.35,
            child: CroppedAsset(
              asset: toolPath,
              source: Rect.fromLTWH(
                toolRegion.position.x,
                toolRegion.position.y,
                toolRegion.size.x,
                toolRegion.size.y,
              ),
              height: phase == 2 ? 120 : 150,
            ),
          ),
        ),
        if (phase == 3)
          Align(
            alignment: const Alignment(0.78, 0.55),
            child: Image.asset(
              'assets/images/${AssetPaths.polishBlush}',
              height: 88,
              filterQuality: FilterQuality.high,
            ),
          ),
      ],
    );
  }
}

class _GoldBeat extends StatelessWidget {
  const _GoldBeat({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final coins = (t * 12).round().clamp(0, 12);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final origin = Offset(constraints.maxWidth * 0.5, constraints.maxHeight * 0.58);
        final target = Offset(constraints.maxWidth - 36, 36);
        return Stack(
          children: <Widget>[
            Positioned(
              top: 14,
              right: 14,
              child: GoldBalanceChip(coins: coins, bump: coins),
            ),
            Align(
              alignment: const Alignment(0, 0.2),
              child: CroppedAsset(
                asset: AssetPaths.shortNail,
                source: Rect.fromLTWH(
                  SpriteAtlas.shortNail.framePositions[3].x,
                  SpriteAtlas.shortNail.framePositions[3].y,
                  SpriteAtlas.shortNail.frameSize.x,
                  SpriteAtlas.shortNail.frameSize.y,
                ),
                height: 240,
              ),
            ),
            Align(
              alignment: const Alignment(0.35, 0.55),
              child: Image.asset(
                'assets/images/${AssetPaths.polishBlush}',
                height: 70,
                filterQuality: FilterQuality.high,
              ),
            ),
            for (var i = 0; i < 7; i++)
              _ArcCoin(
                t: ((t - i * 0.08) / 0.42).clamp(0.0, 1.0),
                origin: origin,
                target: target,
                sway: (i - 3) * 28,
              ),
          ],
        );
      },
    );
  }
}

class _ArcCoin extends StatelessWidget {
  const _ArcCoin({
    required this.t,
    required this.origin,
    required this.target,
    required this.sway,
  });

  final double t;
  final Offset origin;
  final Offset target;
  final double sway;

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeInOutCubic.transform(t);
    final mid = Offset(
      (origin.dx + target.dx) / 2 + sway,
      math.min(origin.dy, target.dy) - 90,
    );
    final a = Offset.lerp(origin, mid, eased)!;
    final pos = Offset.lerp(a, target, eased)!;
    return Positioned(
      left: pos.dx - 11,
      top: pos.dy - 11,
      child: Opacity(
        opacity: t <= 0 || t >= 1 ? 0 : 1,
        child: const GoldCoin(size: 22),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Text(
        text,
        key: ValueKey<String>(text),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Baloo2',
          color: Color(0xFF7A3D5C),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
    );
  }
}

class _BeatDot extends StatelessWidget {
  const _BeatDot({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: active ? 22 : 9,
          height: 9,
          decoration: BoxDecoration(
            color: active ? HowToPlayScreen.pink : const Color(0x55E84F8F),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _GotItButton extends StatelessWidget {
  const _GotItButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HowToPlayScreen.pink,
      borderRadius: BorderRadius.circular(28),
      elevation: 4,
      shadowColor: const Color(0x55C2185B),
      child: InkWell(
        key: const Key('how-to-play-got-it'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 46, vertical: 12),
          child: Text(
            'Got it',
            style: TextStyle(
              fontFamily: 'Baloo2',
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HowToPlayScreen.pink,
      shape: const CircleBorder(
        side: BorderSide(color: HowToPlayScreen.cream, width: 3),
      ),
      elevation: 5,
      shadowColor: const Color(0x55C2185B),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: Colors.white, semanticLabel: semanticLabel, size: 26),
        ),
      ),
    );
  }
}

class _TextChip extends StatelessWidget {
  const _TextChip({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF2FFF8FC),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Baloo2',
              color: HowToPlayScreen.pinkDeep,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeechBubblePainter extends CustomPainter {
  const _SpeechBubblePainter();

  static Path _shape(Size size) {
    const radius = 18.0;
    const tailWidth = 16.0;
    const tailHeight = 11.0;
    final bodyHeight = size.height - tailHeight;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, bodyHeight),
      const Radius.circular(radius),
    );
    final tipX = size.width * 0.68;
    final tail = Path()
      ..moveTo(tipX - tailWidth / 2, bodyHeight - 1)
      ..lineTo(tipX, size.height)
      ..lineTo(tipX + tailWidth / 2, bodyHeight - 1)
      ..close();
    return Path()
      ..addRRect(body)
      ..addPath(tail, Offset.zero);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final shape = _shape(size);
    canvas.drawPath(shape.shift(const Offset(0, 4)), Paint()..color = const Color(0x22000000));
    canvas.drawPath(shape, Paint()..color = const Color(0xFFFFFBFE));
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFFF4B6C8),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
