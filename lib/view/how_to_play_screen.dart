import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'package:nail_glam/controller/game_audio.dart';
import 'package:nail_glam/model/asset_paths.dart';
import 'package:nail_glam/model/sprite_atlas.dart';
import 'cropped_asset.dart';
import 'how_to_play_demo_paint.dart';

/// Menu tutorial: wash a hand, then spray, wipe, and clip one nail.
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
    _warm();
  }

  Future<void> _warm() async {
    try {
      await Future.wait(<Future<void>>[
        for (final name in <String>[
          AssetPaths.handWash,
          AssetPaths.handSoap,
          AssetPaths.fifthNailClean,
          AssetPaths.shortNail,
          AssetPaths.nailSpray,
          AssetPaths.nailBuffer,
          AssetPaths.nailClips,
          AssetPaths.manicurePillowTop,
        ])
          AssetImageCache.load(name),
      ]);
    } catch (_) {
      // Tutorial still runs on the table; missing art stays empty.
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  void _close() {
    GameAudio.instance.tap();
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    }
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
  wash(
    start: Duration.zero,
    end: Duration(milliseconds: 4000),
    caption: 'Wash first.',
  ),
  spray(
    start: Duration(milliseconds: 4000),
    end: Duration(milliseconds: 8000),
    caption: 'Spray the nail.',
  ),
  wipe(
    start: Duration(milliseconds: 8000),
    end: Duration(milliseconds: 12000),
    caption: 'Wipe it clean.',
  ),
  clip(
    start: Duration(milliseconds: 12000),
    end: Duration(milliseconds: 16000),
    caption: 'Then clip.',
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
    return HowToPlayBeat.clip;
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

/// Tight opaque bounds so padded tool sheets fill the demo.
abstract final class _DemoCrop {
  static const Rect soap = Rect.fromLTWH(374, 59, 280, 452);
  static const Rect spray = Rect.fromLTWH(442, 66, 141, 449);
  static const Rect buffer = Rect.fromLTWH(272, 103, 479, 365);
  static const Rect clips = Rect.fromLTWH(182, 14, 1291, 889);
}

class _StageCard extends StatelessWidget {
  const _StageCard({required this.beat, required this.t});

  final HowToPlayBeat beat;
  final double t;

  @override
  Widget build(BuildContext context) {
    final local = beat.progress(t);
    return DecoratedBox(
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
            const ColoredBox(color: Color(0x22FFF3EA)),
            Align(
              alignment: const Alignment(0, -0.28),
              child: FractionallySizedBox(
                widthFactor: 0.9,
                heightFactor: 0.2,
                child: CroppedAsset(
                  asset: AssetPaths.manicurePillowTop,
                  source: const Rect.fromLTWH(2, 2, 1391, 467),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 48, 22, 36),
              child: beat == HowToPlayBeat.wash
                  ? _WashHand(t: local)
                  : _PinnedFinger(beat: beat, t: local),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              child: KeyedSubtree(
                key: ValueKey<HowToPlayBeat>(beat),
                child: SizedBox.expand(
                  child: switch (beat) {
                    HowToPlayBeat.wash => _WashTool(t: local),
                    HowToPlayBeat.spray => _SprayTool(t: local),
                    HowToPlayBeat.wipe => _WipeTool(t: local),
                    HowToPlayBeat.clip => _ClipTool(t: local),
                  },
                ),
              ),
            ),
            CustomPaint(
              key: const Key('how-to-play-stage'),
              painter: HowToPlayDemoPainter(
                scene: beat.index,
                localT: local,
              ),
              child: const SizedBox.expand(),
            ),
            const Positioned(
              top: 12,
              left: 12,
              child: _AutoBadge(),
            ),
          ],
        ),
      ),
    );
  }
}

class _WashHand extends StatelessWidget {
  const _WashHand({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final pos = Curves.easeInOut.transform(t) * 3;
    final from = pos.floor().clamp(0, 3);
    final to = math.min(from + 1, 3);
    final fade = pos - from;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _SheetCell(
          asset: AssetPaths.handWash,
          sheet: SpriteAtlas.handWash,
          frame: from,
          align: SpriteAtlas.handWashFrameAlign[from],
        ),
        if (to != from)
          Opacity(
            opacity: Curves.easeInOut.transform(fade),
            child: _SheetCell(
              asset: AssetPaths.handWash,
              sheet: SpriteAtlas.handWash,
              frame: to,
              align: SpriteAtlas.handWashFrameAlign[to],
            ),
          ),
      ],
    );
  }
}

class _WashTool extends StatelessWidget {
  const _WashTool({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final soap = Curves.easeInOut.transform(t);
    final swirl = soap * math.pi * 4;
    return Align(
      alignment: Alignment(
        0.22 + math.cos(swirl) * 0.22,
        -0.18 + math.sin(swirl) * 0.16 + soap * 0.08,
      ),
      child: Transform.rotate(
        angle: -0.45 + soap * 0.9,
        child: const _Tool(asset: AssetPaths.handSoap, source: _DemoCrop.soap, height: 150),
      ),
    );
  }
}

class _SprayTool extends StatelessWidget {
  const _SprayTool({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final enter = Curves.easeOutBack.transform((t / 0.22).clamp(0.0, 1.0));
    final pump = math.sin(t * math.pi * 6) * 6;
    return Align(
      alignment: Alignment(0.72, -0.08 + pump / 240),
      child: Opacity(
        opacity: enter.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset((1 - enter.clamp(0.0, 1.0)) * 72, 0),
          child: Transform.rotate(
            angle: -0.38,
            child: const _Tool(asset: AssetPaths.nailSpray, source: _DemoCrop.spray, height: 158),
          ),
        ),
      ),
    );
  }
}

class _WipeTool extends StatelessWidget {
  const _WipeTool({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final sweep = math.sin(t * math.pi * 3);
    return Align(
      alignment: Alignment(0.12 + sweep * 0.36, 0.04),
      child: Transform.rotate(
        angle: -0.16 + sweep * 0.1,
        child: const _Tool(asset: AssetPaths.nailBuffer, source: _DemoCrop.buffer, height: 108),
      ),
    );
  }
}

class _ClipTool extends StatelessWidget {
  const _ClipTool({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final swing = math.sin(t * math.pi * 2 - math.pi / 2);
    return Align(
      alignment: Alignment(swing * 0.52, 0.22),
      child: Transform.rotate(
        angle: swing * 0.62,
        alignment: Alignment.topCenter,
        child: const _Tool(
          asset: AssetPaths.nailClips,
          source: _DemoCrop.clips,
          height: 150,
        ),
      ),
    );
  }
}

class _PinnedFinger extends StatelessWidget {
  const _PinnedFinger({required this.beat, required this.t});

  final HowToPlayBeat beat;
  final double t;

  @override
  Widget build(BuildContext context) {
    final clip = beat == HowToPlayBeat.clip;
    final progress = clip || beat == HowToPlayBeat.wipe
        ? Curves.easeInOut.transform(t) * 3
        : 0.0;
    final from = progress.floor().clamp(0, 3);
    final to = math.min(from + 1, 3);
    final fade = progress - from;
    final asset = clip ? AssetPaths.shortNail : AssetPaths.fifthNailClean;
    final sheet = clip ? SpriteAtlas.shortNail : SpriteAtlas.fifthNailClean;
    final image = AssetImageCache.decoded[asset];
    if (image == null) {
      return const SizedBox.expand();
    }
    return CustomPaint(
      painter: HowToPlayFingerPainter(
        image: image,
        sheet: sheet,
        frame: from,
        nextFrame: to == from ? null : to,
        fade: to == from ? 0 : Curves.easeInOut.transform(fade),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SheetCell extends StatelessWidget {
  const _SheetCell({
    required this.asset,
    required this.sheet,
    required this.frame,
    required this.align,
  });

  final String asset;
  final CharacterSheet sheet;
  final int frame;
  final Vector2 align;

  @override
  Widget build(BuildContext context) {
    final index = frame.clamp(0, sheet.frameCount - 1);
    final origin = sheet.framePositions[index];
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final scaleX = constraints.maxWidth / sheet.frameSize.x;
        final scaleY = constraints.maxHeight / sheet.frameSize.y;
        return Transform.translate(
          offset: Offset(align.x * scaleX, align.y * scaleY),
          child: CroppedAsset(
            asset: asset,
            source: Rect.fromLTWH(
              origin.x,
              origin.y,
              sheet.frameSize.x,
              sheet.frameSize.y,
            ),
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            fit: BoxFit.contain,
            topFade: 0.08,
          ),
        );
      },
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({
    required this.asset,
    required this.source,
    required this.height,
  });

  final String asset;
  final Rect source;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CroppedAsset(
      asset: asset,
      source: source,
      height: height,
      fit: BoxFit.contain,
    );
  }
}

class _AutoBadge extends StatelessWidget {
  const _AutoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xDDFF6BA8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'AUTO',
        style: TextStyle(
          fontFamily: 'Baloo2',
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
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
