import 'package:flutter/material.dart';

import 'package:nail_glam/model/asset_paths.dart';
import 'gold_coin.dart';

/// The "Unlock for <price>" / "Purchased" button, with the little lock sprite
/// that pops up over its top-left corner and springs open on purchase.
///
/// Pulled out of the manicure HUD's tool drawer so the Salon Shop's Tools tab
/// can show the exact same purchase moment — same button, same lock, same
/// timing — instead of a second hand-built copy that would drift from this
/// one the next time either screen changes.
class ToolPurchaseButton extends StatelessWidget {
  const ToolPurchaseButton({
    required this.price,
    required this.label,
    required this.unlocking,
    required this.unlockDone,
    required this.onPressed,
    super.key,
  });

  final int price;
  final String label;
  final bool unlocking;
  final bool unlockDone;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(
          top: 7,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: unlockDone
                  ? const Color(0xFF4F8D5A)
                  : const Color(0xFFB74E78),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            // Kept as 'nail-care-unlock' rather than renamed: the widget
            // moved here from the manicure HUD, and nail_care_flow_test.dart
            // still finds it by this key. The Salon Shop's copy of this
            // button reuses the same key value harmlessly — the two never
            // render in the same tree.
            key: const Key('nail-care-unlock'),
            onPressed: unlocking || unlockDone ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: unlockDone
                  ? const Color(0xFF73B87D)
                  : const Color(0xFFE56B97),
              foregroundColor: Colors.white,
              disabledBackgroundColor: unlockDone
                  ? const Color(0xFF8BC49A)
                  : const Color(0xFFE56B97),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                if (!unlockDone) ...<Widget>[
                  const SizedBox(width: 6),
                  const GoldCoin(size: 18),
                  const SizedBox(width: 4),
                  Text('$price'),
                ] else
                  const Icon(Icons.check_rounded, size: 20),
              ],
            ),
          ),
        ),
        Positioned(
          top: -27,
          left: -8,
          child: UnlockLockVisual(opening: unlocking, open: unlockDone),
        ),
      ],
    );
  }
}

/// Three-frame lock sprite: shut, mid-open, sprung open. [opening] plays the
/// strip once; [open] holds the last frame for an already-purchased item that
/// gets rebuilt (e.g. the sheet reopened) without replaying the animation.
class UnlockLockVisual extends StatefulWidget {
  const UnlockLockVisual({required this.opening, required this.open, super.key});

  final bool opening;
  final bool open;

  @override
  State<UnlockLockVisual> createState() => _UnlockLockVisualState();
}

class _UnlockLockVisualState extends State<UnlockLockVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      value: widget.open ? 1 : 0,
    );
    if (widget.opening) {
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant UnlockLockVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.opening && !oldWidget.opening) {
      _controller.forward(from: 0);
    } else if (widget.open && !oldWidget.open) {
      _controller.value = 1;
    } else if (!widget.opening && !widget.open) {
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final frame = (_controller.value * 2).round().clamp(0, 2);
        const frameSize = 64.0;
        return SizedBox(
          width: frameSize,
          height: frameSize,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: frameSize * 3,
              maxWidth: frameSize * 3,
              minHeight: frameSize,
              maxHeight: frameSize,
              child: Transform.translate(
                offset: Offset(-frame * frameSize, 0),
                child: Image.asset(
                  'assets/images/${AssetPaths.lock}',
                  width: frameSize * 3,
                  height: frameSize,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The pop-in an item's art plays when a preview sheet opens: a touch small,
/// tilted, and springing up to full size. Shared so a tool previewed from the
/// manicure drawer and one previewed from the Salon Shop arrive on screen the
/// same way.
class PreviewArtPopIn extends StatelessWidget {
  const PreviewArtPopIn({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.72, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutBack,
      builder: (BuildContext context, double scale, Widget? child) {
        return Transform.rotate(
          angle: (1 - scale) * 0.18,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: child,
    );
  }
}
