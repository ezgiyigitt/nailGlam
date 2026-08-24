import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'gold_coin.dart';

/// Staggered coins that arc from [origin] into the wallet.
class FlyingCoins extends StatefulWidget {
  const FlyingCoins({
    required this.generation,
    required this.origin,
    required this.targetOf,
    required this.count,
    this.onCoinArrived,
    this.onComplete,
    super.key,
  });

  final int generation;
  final Offset origin;
  final Offset Function() targetOf;
  final int count;
  final ValueChanged<int>? onCoinArrived;
  final VoidCallback? onComplete;

  @override
  State<FlyingCoins> createState() => _FlyingCoinsState();
}

class _FlyingCoinsState extends State<FlyingCoins>
    with SingleTickerProviderStateMixin {
  static const int _flightMs = 720;
  static const int _staggerMs = 68;

  late final AnimationController _controller;
  final List<bool> _landed = <bool>[];

  int get _count => math.max(0, widget.count);

  Duration get _total {
    final n = math.max(1, _count);
    return Duration(milliseconds: _flightMs + (n - 1) * _staggerMs);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addListener(_onTick);
    _controller.addStatusListener(_onStatus);
    if (widget.generation > 0 && _count > 0) {
      _launch();
    }
  }

  @override
  void didUpdateWidget(FlyingCoins oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.generation != widget.generation &&
        widget.generation > 0 &&
        _count > 0) {
      _launch();
    }
  }

  void _launch() {
    _landed
      ..clear()
      ..addAll(List<bool>.filled(_count, false));
    _controller.duration = _total;
    _controller.forward(from: 0);
  }

  void _onTick() {
    if (_landed.isEmpty) {
      return;
    }
    final totalMs = _total.inMilliseconds.toDouble();
    for (var i = 0; i < _landed.length; i++) {
      if (_landed[i]) {
        continue;
      }
      final start = i * _staggerMs / totalMs;
      final end = start + _flightMs / totalMs;
      final local = (( _controller.value - start) / (end - start)).clamp(0.0, 1.0);
      if (local >= 1) {
        _landed[i] = true;
        final index = i;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          widget.onCoinArrived?.call(index);
        });
      }
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        widget.onComplete?.call();
      });
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTick)
      ..removeStatusListener(_onStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.generation <= 0 || _count <= 0) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final target = widget.targetOf();
          final totalMs = _total.inMilliseconds.toDouble();
          return Stack(
            children: <Widget>[
              for (var i = 0; i < _count; i++)
                _coinAt(i, target, totalMs),
            ],
          );
        },
      ),
    );
  }

  Widget _coinAt(int i, Offset target, double totalMs) {
    final startT = i * _staggerMs / totalMs;
    final endT = startT + _flightMs / totalMs;
    final local =
        ((_controller.value - startT) / (endT - startT)).clamp(0.0, 1.0);
    if (local <= 0 || local >= 1) {
      return const SizedBox.shrink();
    }
    final t = Curves.easeInOutCubic.transform(local);
    final fan = (i - (_count - 1) / 2) * 16;
    final origin = widget.origin + Offset(fan, i * 5.0);
    final lift = 70.0 + (i % 4) * 18;
    final control = Offset(
      (origin.dx + target.dx) / 2 + fan * 0.35,
      math.min(origin.dy, target.dy) - lift,
    );
    final pos = _quad(origin, control, target, t);
    final scale = 1.18 - 0.48 * t;
    final fade = local > 0.88 ? (1 - (local - 0.88) / 0.12) : 1.0;
    return Positioned(
      left: pos.dx - 15,
      top: pos.dy - 15,
      child: Opacity(
        opacity: fade,
        child: Transform.rotate(
          angle: (i.isEven ? 1 : -1) * 0.55 * t,
          child: Transform.scale(
            scale: scale,
            child: const GoldCoin(size: 30),
          ),
        ),
      ),
    );
  }

  static Offset _quad(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    return Offset(
      u * u * a.dx + 2 * u * t * b.dx + t * t * c.dx,
      u * u * a.dy + 2 * u * t * b.dy + t * t * c.dy,
    );
  }
}
