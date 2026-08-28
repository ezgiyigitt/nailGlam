import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nail_glam/model/asset_paths.dart';
import 'package:nail_glam/model/nail_care_tools.dart';

/// Shared manicure HUD hand — one art set for every guest.
///
/// Base dorsal hand plus per-digit lacquer masks that tint as work progresses
/// and lock to polish color when painted. Counter shows done/total.
class CuteHandSimCard extends StatelessWidget {
  const CuteHandSimCard({
    required this.done,
    required this.total,
    required this.snapshots,
    required this.activeDigit,
    this.onDigitTap,
    super.key,
  });

  final int done;
  final int total;
  final Map<NailDigit, DigitSimSnapshot> snapshots;
  final NailDigit? activeDigit;
  final ValueChanged<NailDigit>? onDigitTap;

  static const List<NailDigit> _order = <NailDigit>[
    NailDigit.pinky,
    NailDigit.ring,
    NailDigit.middle,
    NailDigit.pointer,
    NailDigit.thumb,
  ];

  static const Map<NailDigit, String> _maskAssets = <NailDigit, String>{
    NailDigit.pinky: AssetPaths.finalHandLightNailPinky,
    NailDigit.ring: AssetPaths.finalHandLightNailRing,
    NailDigit.middle: AssetPaths.finalHandLightNailMiddle,
    NailDigit.pointer: AssetPaths.finalHandLightNailPointer,
    NailDigit.thumb: AssetPaths.finalHandLightNailThumb,
  };

  /// Approximate nail centers in hand image space (for tap targets only).
  static const Map<NailDigit, Offset> _hitCenters = <NailDigit, Offset>{
    NailDigit.pinky: Offset(0.062, 0.801),
    NailDigit.ring: Offset(0.254, 0.914),
    NailDigit.middle: Offset(0.498, 0.956),
    NailDigit.pointer: Offset(0.759, 0.920),
    NailDigit.thumb: Offset(0.939, 0.707),
  };

  static const double _padL = 4;
  static const double _padT = 8;
  static const double _padR = 4;
  static const double _padB = 26;
  static const double _cardW = 132;
  static const double _cardH = 156;

  static Rect _paintBox() => Rect.fromLTRB(
        _padL,
        _padT,
        _cardW - _padR,
        _cardH - _padB,
      );

  static Rect _handDestInPaint(Size paint) {
    const imageAspect = 833 / 1446;
    final boxAspect = paint.width / math.max(paint.height, 1e-6);
    late final double drawW;
    late final double drawH;
    if (boxAspect > imageAspect) {
      drawH = paint.height;
      drawW = drawH * imageAspect;
    } else {
      drawW = paint.width;
      drawH = drawW / imageAspect;
    }
    return Rect.fromLTWH(
      (paint.width - drawW) / 2,
      paint.height - drawH,
      drawW,
      drawH,
    );
  }

  /// Test helper: destination rect for [BoxFit.contain] + bottomCenter.
  @visibleForTesting
  static Rect handDestForTest(Size paint) => _handDestInPaint(paint);

  static Rect _digitHit(NailDigit digit) {
    final paint = _paintBox();
    final dest = _handDestInPaint(paint.size);
    final center = _hitCenters[digit]!;
    final cx = paint.left + dest.left + center.dx * dest.width;
    final cy = paint.top + dest.top + center.dy * dest.height;
    return Rect.fromCenter(center: Offset(cx, cy), width: 34, height: 40);
  }

  static Color? _tintFor(DigitSimSnapshot snap) {
    final polish = snap.polishColor;
    if (polish != null && polish != 0) {
      return Color(polish);
    }
    if (snap.cleanProgress <= 0 && snap.cutFrame <= 0) {
      return null;
    }
    final t = snap.cleanProgress.clamp(0.0, 1.0);
    final cut = snap.cutFrame.clamp(0, 3) / 3.0;
    final blend = math.max(t, cut * 0.35);
    return Color.lerp(
      const Color(0xFFC4A05A),
      const Color(0xFFF6D7C8),
      blend,
    );
  }

  static double _tintOpacity(DigitSimSnapshot snap) {
    final polish = snap.polishColor;
    if (polish != null && polish != 0) {
      return 0.94;
    }
    final work = snap.cleanProgress.clamp(0.0, 1.0) +
        snap.cutFrame.clamp(0, 3) / 3.0;
    return (0.28 + work.clamp(0.0, 1.0) * 0.55).clamp(0.0, 0.85);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('nail-care-finger-sim'),
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.selectionClick();
          if (activeDigit != null) {
            onDigitTap?.call(activeDigit!);
          }
        },
        child: Ink(
          width: _cardW,
          height: _cardH,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFFFFF8FB), Color(0xFFFFEEF4)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8A0B8), width: 2.2),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x28000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _padL,
                    _padT,
                    _padR,
                    _padB,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Image.asset(
                        'assets/images/${AssetPaths.finalHandLight}',
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        filterQuality: FilterQuality.medium,
                      ),
                      for (final NailDigit digit in _order)
                        _DigitLacquerLayer(
                          asset: _maskAssets[digit]!,
                          tint: _tintFor(
                            snapshots[digit] ?? const DigitSimSnapshot(),
                          ),
                          opacity: _tintOpacity(
                            snapshots[digit] ?? const DigitSimSnapshot(),
                          ),
                          active: activeDigit == digit,
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 10,
                bottom: 8,
                child: _ProgressBadge(done: done, total: total),
              ),
              for (final NailDigit digit in _order)
                Builder(
                  builder: (BuildContext context) {
                    final hit = _digitHit(digit);
                    return Positioned(
                      left: hit.left,
                      top: hit.top,
                      width: hit.width,
                      height: hit.height,
                      child: GestureDetector(
                        key: Key('nail-care-finger-sim-${digit.name}'),
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onDigitTap?.call(digit);
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DigitLacquerLayer extends StatelessWidget {
  const _DigitLacquerLayer({
    required this.asset,
    required this.tint,
    required this.opacity,
    required this.active,
  });

  final String asset;
  final Color? tint;
  final double opacity;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final showActive = active && (tint == null);
    if (tint == null && !showActive) {
      return const SizedBox.shrink();
    }
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (tint != null)
          Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(tint!, BlendMode.srcIn),
              child: Image.asset(
                'assets/images/$asset',
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        if (showActive)
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Color(0xAAE8A0B8),
              BlendMode.srcIn,
            ),
            child: Image.asset(
              'assets/images/$asset',
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              filterQuality: FilterQuality.medium,
            ),
          ),
      ],
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('nail-care-remaining-box'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8A0B8)),
      ),
      child: Text(
        '$done / $total',
        style: const TextStyle(
          fontFamily: 'Baloo2',
          fontSize: 11,
          height: 1,
          fontWeight: FontWeight.w800,
          color: Color(0xFF8A4B63),
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
