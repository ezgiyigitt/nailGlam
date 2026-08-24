import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../game/config/asset_paths.dart';
import '../game/nail_glam_game.dart';

/// Circular HUD crop of the current customer's face.
///
/// [frame] is one cell of the 5×1 emotion strip: 0 sad … 4 delighted.
class CustomerEmotionAvatar extends StatefulWidget {
  const CustomerEmotionAvatar({
    required this.game,
    required this.frame,
    super.key,
  });

  final NailGlamGame game;
  final int frame;

  static const double _diameter = 92;
  static const int _frameCount = 5;

  @override
  State<CustomerEmotionAvatar> createState() => _CustomerEmotionAvatarState();
}

class _CustomerEmotionAvatarState extends State<CustomerEmotionAvatar> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final image = await widget.game.images.load(AssetPaths.customerEmotion);
    if (!mounted) {
      return;
    }
    setState(() => _image = image);
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.frame.clamp(0, CustomerEmotionAvatar._frameCount - 1);
    final image = _image;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Container(
        key: ValueKey<int>(index),
        width: CustomerEmotionAvatar._diameter,
        height: CustomerEmotionAvatar._diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF2B1D22),
          border: Border.all(color: const Color(0xFFF4B6C8), width: 3),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: image == null
            ? const SizedBox.expand()
            : CustomPaint(
                painter: _EmotionFramePainter(image: image, frame: index),
              ),
      ),
    );
  }
}

class _EmotionFramePainter extends CustomPainter {
  const _EmotionFramePainter({required this.image, required this.frame});

  final ui.Image image;
  final int frame;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = image.width / CustomerEmotionAvatar._frameCount;
    final cellH = image.height.toDouble();
    // Tight face window: skip blouse / extra hair so the circle is just her.
    final face = cellW < cellH ? cellW * 0.86 : cellH * 0.72;
    final src = Rect.fromLTWH(
      frame * cellW + (cellW - face) / 2,
      cellH * 0.06,
      face,
      face,
    );
    canvas.drawImageRect(
      image,
      src,
      Offset.zero & size,
      Paint()
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_EmotionFramePainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.frame != frame;
}
