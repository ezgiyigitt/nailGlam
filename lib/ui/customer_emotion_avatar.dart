import 'package:flutter/material.dart';

import '../game/config/asset_paths.dart';
import '../game/config/sprite_atlas.dart';

/// Fixed HUD face. Shows exactly one emotion cell inside a circle.
class CustomerEmotionAvatar extends StatelessWidget {
  const CustomerEmotionAvatar({required this.frame, super.key});

  final int frame;

  static const double _diameter = 92;

  @override
  Widget build(BuildContext context) {
    final sheet = SpriteAtlas.customerEmotion;
    final index = frame.clamp(0, sheet.frameCount - 1);
    final frameW = sheet.frameSize.x;
    final frameH = sheet.frameSize.y;
    final count = sheet.frameCount;
    // Cover the circle from a single cell, bias toward the face.
    final scale = (_diameter / frameW > _diameter / frameH
            ? _diameter / frameW
            : _diameter / frameH) *
        1.2;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Container(
        key: ValueKey<int>(index),
        width: _diameter,
        height: _diameter,
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
        child: ClipOval(
          child: SizedBox(
            width: _diameter,
            height: _diameter,
            child: OverflowBox(
              maxWidth: frameW * count * scale,
              maxHeight: frameH * scale,
              alignment: Alignment.topLeft,
              child: Transform.translate(
                offset: Offset(
                  _diameter / 2 - (index + 0.5) * frameW * scale,
                  _diameter / 2 - frameH * scale * 0.40,
                ),
                child: Image.asset(
                  'assets/images/${AssetPaths.customerEmotion}',
                  width: frameW * count * scale,
                  height: frameH * scale,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
