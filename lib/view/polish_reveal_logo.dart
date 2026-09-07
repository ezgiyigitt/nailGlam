import 'package:flutter/material.dart';

/// The menu logo painting itself on, the way a nail gets lacquered.
///
/// Three beats, all driven by one [AnimationController] so the timing stays in
/// one place and there is exactly one repaint per frame:
///
///  1. **Bare** — the logo sits desaturated and pale, like an unpainted nail.
///  2. **Stroke** — colour sweeps up across it behind a soft, slightly tilted
///     edge: the brush pass. The tilt is what stops it reading as a loading bar.
///  3. **Gloss** — a narrow highlight slides across the finished logo, clipped
///     to the logo's own pixels so it looks wet rather than like a flare
///     floating over the screen.
///
/// The controller stops when the sequence ends, so an idle menu costs nothing.
/// If the player has "reduce motion" on, the whole thing snaps to the finished
/// state instead of animating.
class PolishRevealLogo extends StatefulWidget {
  const PolishRevealLogo({
    required this.asset,
    this.replayOnTap = true,
    super.key,
  });

  /// Full asset path, e.g. `assets/images/nail_glam_logo.png`.
  final String asset;

  /// Tapping the logo paints it again. Cheap delight, and it makes the effect
  /// demonstrable on request instead of only in the first second.
  final bool replayOnTap;

  @override
  State<PolishRevealLogo> createState() => _PolishRevealLogoState();
}

class _PolishRevealLogoState extends State<PolishRevealLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );

  /// Colour climbing the logo. Starts after a beat so the bare state registers.
  late final Animation<double> _stroke = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.12, 0.62, curve: Curves.easeInOutCubic),
  );

  /// Highlight sweep, starting just as the stroke finishes.
  late final Animation<double> _gloss = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.60, 1, curve: Curves.easeInOut),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    // Accessibility: with "reduce motion" on, show the painted logo outright.
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _replay() {
    if (!widget.replayOnTap || _controller.isAnimating) {
      return;
    }
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      return;
    }
    _controller.forward(from: 0);
  }

  /// Greyed, lightened copy of the art: the "no polish yet" state. Built as a
  /// colour matrix so it works for any logo without a second asset to keep in
  /// sync with the first.
  static const ColorFilter _bare = ColorFilter.matrix(<double>[
    0.30, 0.42, 0.14, 0, 46, //
    0.26, 0.46, 0.14, 0, 46, //
    0.26, 0.42, 0.18, 0, 46, //
    0, 0, 0, 0.55, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final Widget logo = Image.asset(
      widget.asset,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: _replay,
      child: AnimatedBuilder(
        animation: _controller,
        child: logo,
        builder: (BuildContext context, Widget? child) {
          final double stroke = _stroke.value;
          final double gloss = _gloss.value;
          return Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              // 1. Unpainted logo underneath, fading out as colour covers it.
              Opacity(
                opacity: 1 - stroke * 0.9,
                child: ColorFiltered(colorFilter: _bare, child: child),
              ),
              // 2. The painted logo, revealed behind a soft tilted brush edge.
              ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (Rect bounds) => _strokeShader(bounds, stroke),
                child: child,
              ),
              // 3. Wet gloss travelling across the finished letters.
              if (gloss > 0 && gloss < 1)
                IgnorePointer(
                  child: Opacity(
                    opacity: _glossFade(gloss),
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (Rect bounds) =>
                          _glossShader(bounds, gloss),
                      // White silhouette of the logo: tinting through srcATop
                      // keeps the art's own alpha, so the shine can never spill
                      // outside the letters.
                      child: Image.asset(
                        widget.asset,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        gaplessPlayback: true,
                        color: Colors.white,
                        colorBlendMode: BlendMode.srcATop,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Bottom-to-top wipe with a feathered edge, tilted a few degrees so it
  /// reads as a brush pass rather than a progress bar.
  ///
  /// The gradient's *endpoints* move rather than its stops: with the default
  /// clamp tiling everything below `begin` stays opaque and everything above
  /// `end` stays clear, so the edge can travel cleanly off both ends of the
  /// logo without any stop arithmetic that could fall out of order.
  static Shader _strokeShader(Rect bounds, double t) {
    const double feather = 0.22;
    // Alignment space: -1 is the top edge, +1 the bottom. Start fully below
    // the logo and finish fully above it, feather included.
    final double edge = (1 + feather) - t * (2 + feather * 2);
    return LinearGradient(
      begin: Alignment(-0.45, edge + feather),
      end: Alignment(0.45, edge - feather),
      colors: const <Color>[Colors.white, Color(0x00FFFFFF)],
    ).createShader(bounds);
  }

  /// Narrow diagonal highlight band sliding left to right across the letters.
  static Shader _glossShader(Rect bounds, double t) {
    const double band = 0.5;
    final double centre = -1 - band + t * (2 + band * 2);
    return LinearGradient(
      begin: Alignment(centre - band, -0.6),
      end: Alignment(centre + band, 0.6),
      colors: const <Color>[
        Color(0x00FFFFFF),
        Colors.white,
        Color(0x00FFFFFF),
      ],
      stops: const <double>[0, 0.5, 1],
    ).createShader(bounds);
  }

  /// Fade the shine in and back out so it never pops on or off.
  static double _glossFade(double t) {
    final double edge = t < 0.5 ? t / 0.5 : (1 - t) / 0.5;
    return (edge * 0.55).clamp(0.0, 0.55);
  }
}
