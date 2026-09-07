import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

/// The one place the app's timings, curves and springs are defined.
///
/// The point of a motion system is that nothing is hand-tuned per widget. A
/// button, a sheet and a number all borrow from the same short vocabulary, so
/// the interface feels like one object rather than a pile of parts.
abstract final class AppMotion {
  /// State changes the eye should barely register: a press, a highlight.
  static const Duration fast = Duration(milliseconds: 140);

  /// The default. Most things that appear, move or swap use this.
  static const Duration standard = Duration(milliseconds: 260);

  /// Large surfaces travelling a long way — a sheet, a page.
  static const Duration slow = Duration(milliseconds: 420);

  /// Decelerating ease for anything arriving. Nothing in a polished interface
  /// arrives at constant speed; it enters fast and settles.
  static const Curve enter = Cubic(0.22, 1, 0.36, 1);

  /// Accelerating ease for anything leaving. Exits are quicker than entrances —
  /// the user has already decided, so waiting for the old thing is dead time.
  static const Curve exit = Cubic(0.4, 0, 1, 1);

  /// Symmetric ease for a value moving between two states in place.
  static const Curve move = Cubic(0.4, 0, 0.2, 1);

  /// The press spring. Firm and barely bouncy: one small overshoot, no wobble.
  /// Wobble reads as toy; a single settle reads as physical.
  static const SpringDescription pressSpring = SpringDescription(
    mass: 1,
    stiffness: 460,
    damping: 26,
  );

  /// Softer spring for things that pop into existence rather than react.
  static const SpringDescription entranceSpring = SpringDescription(
    mass: 1,
    stiffness: 260,
    damping: 24,
  );
}

/// Wraps any widget in the press behaviour used across the app.
///
/// Down is immediate and linear-feeling so the surface tracks the finger;
/// release is a spring that overshoots once. The overshoot is what separates a
/// button that feels alive from one that merely changes size — and it is why
/// this cannot be an [AnimatedScale], whose reverse is just the forward curve
/// played backwards.
///
/// Also owns the haptic, so every tappable thing in the app taps back the same
/// way instead of each call site remembering.
class PressableScale extends StatefulWidget {
  const PressableScale({
    required this.child,
    required this.onPressed,
    this.pressedScale = 0.94,
    this.haptic = true,
    this.semanticLabel,
    super.key,
  });

  final Widget child;

  /// Null disables the press entirely and dims the child, so a disabled
  /// control cannot animate as though it did something.
  final VoidCallback? onPressed;

  /// How far down the press goes. Small targets need less: at 46px a 6% dip is
  /// already clearly visible, while a wide button needs the same 6% to read at
  /// all. Percentages, not pixels, keep the feel constant across sizes.
  final double pressedScale;

  final bool haptic;
  final String? semanticLabel;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  /// 0 = at rest, 1 = fully pressed. The lower bound goes negative so the
  /// release spring has room to overshoot past rest instead of being clamped
  /// flat at the exact moment the bounce should happen.
  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
    value: 0,
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null;

  void _down() {
    if (!_enabled) {
      return;
    }
    _press.animateTo(1, duration: AppMotion.fast, curve: AppMotion.move);
  }

  void _up() {
    _press.animateWith(
      SpringSimulation(AppMotion.pressSpring, _press.value, 0, 0),
    );
  }

  void _tap() {
    if (!_enabled) {
      return;
    }
    if (widget.haptic) {
      // Fires on the up, not the down: the tap is only real once the finger
      // lifts inside the target, and a haptic on down lies about cancelled taps.
      unawaited(HapticFeedback.lightImpact());
    }
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _down(),
        onTapCancel: _up,
        onTapUp: (_) {
          _up();
          _tap();
        },
        child: AnimatedBuilder(
          animation: _press,
          builder: (BuildContext context, Widget? child) {
            final double t = _press.value;
            return Transform.scale(
              // Overshoot is bounded so a fast double-tap cannot stack springs
              // into something cartoonish.
              scale: (1 - t * (1 - widget.pressedScale)).clamp(0.85, 1.06),
              child: child,
            );
          },
          child: Opacity(
            opacity: _enabled ? 1 : 0.45,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// A number that changes by rolling the new value in rather than snapping.
///
/// Snapping a balance from 100 to 250 gives the player nothing to follow; the
/// eye cannot tell whether it went up or down. Direction-aware motion answers
/// that without a label: gains rise into place, spends drop.
class RollingCount extends StatelessWidget {
  const RollingCount({
    required this.value,
    required this.style,
    super.key,
  });

  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.standard,
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      layoutBuilder: (Widget? current, List<Widget> previous) {
        // Right-aligned so the digits grow leftward and the coin beside them
        // never shuffles sideways mid-count.
        return Stack(
          alignment: Alignment.centerRight,
          children: <Widget>[...previous, if (current != null) current],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        final bool incoming = child.key == ValueKey<int>(value);
        final double from = incoming ? 0.6 : -0.6;
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, from),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Text(
        '$value',
        key: ValueKey<int>(value),
        style: style,
      ),
    );
  }
}

/// Fades and lifts a widget into place once, [delay] after it is first built.
///
/// Used to stagger a row or column so the screen assembles instead of blinking
/// on. The offsets are deliberately tiny — a few pixels reads as depth, a big
/// slide reads as a transition the user has to wait through.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, -10),
    super.key,
  });

  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) {
          _c.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> eased = CurvedAnimation(
      parent: _c,
      curve: AppMotion.enter,
    );
    return FadeTransition(
      opacity: eased,
      child: AnimatedBuilder(
        animation: eased,
        builder: (BuildContext context, Widget? child) {
          return Transform.translate(
            offset: widget.offset * (1 - eased.value),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Scrim + scaled sheet entrance, shared by the menu's inline dialogs.
///
/// The sheet starts slightly small and settles with the entrance spring, which
/// is the difference between a panel that appears and one that is placed.
class SheetEntrance extends StatefulWidget {
  const SheetEntrance({required this.child, super.key});

  final Widget child;

  @override
  State<SheetEntrance> createState() => _SheetEntranceState();
}

class _SheetEntranceState extends State<SheetEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(
    vsync: this,
    value: 0,
  );

  @override
  void initState() {
    super.initState();
    _c.animateWith(
      SpringSimulation(AppMotion.entranceSpring, 0, 1, 6),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? child) {
        final double t = _c.value.clamp(0.0, 1.08);
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.92 + 0.08 * t,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
