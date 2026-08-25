import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'package:nail_glam/model/nail_care_tools.dart';
import 'package:nail_glam/model/sprite_atlas.dart';
import 'package:nail_glam/controller/nail_glam_game.dart';

/// Crops a tool PNG to its opaque artwork so drag ghosts have no empty canvas.
class AtlasToolImage extends StatefulWidget {
  const AtlasToolImage({
    required this.game,
    required this.toolId,
    required this.iconPath,
    required this.width,
    super.key,
  });

  final NailGlamGame game;
  final NailCareToolId toolId;
  final String iconPath;
  final double width;

  @override
  State<AtlasToolImage> createState() => _AtlasToolImageState();
}

class _AtlasToolImageState extends State<AtlasToolImage> {
  ui.Image? _image;

  SpriteRegion get _region {
    switch (widget.toolId) {
      case NailCareToolId.handSoap:
        return SpriteAtlas.handSoap;
      case NailCareToolId.nailSpray:
        return _clamped(SpriteAtlas.nailSpray);
      case NailCareToolId.nailBuffer:
        return SpriteAtlas.nailBuffer;
      case NailCareToolId.nailClips:
        return _clamped(SpriteAtlas.nailClips);
      case NailCareToolId.nailPolish:
        final image = _image;
        // Standalone bottle PNGs are wide; the brush sheet is a narrow stick.
        if (image != null && image.width > 200) {
          return SpriteRegion(
            Vector2.zero(),
            Vector2(image.width.toDouble(), image.height.toDouble()),
          );
        }
        return _clamped(SpriteAtlas.polishBrush);
    }
  }

  SpriteRegion _clamped(SpriteRegion region) {
    final image = _image;
    if (image == null) {
      return region;
    }
    final maxW = image.width.toDouble();
    final maxH = image.height.toDouble();
    final left = region.position.x.clamp(0.0, maxW);
    final top = region.position.y.clamp(0.0, maxH);
    final width = region.size.x.clamp(1.0, (maxW - left).clamp(1.0, maxW));
    final height = region.size.y.clamp(1.0, (maxH - top).clamp(1.0, maxH));
    return SpriteRegion(
      Vector2(left.toDouble(), top.toDouble()),
      Vector2(width.toDouble(), height.toDouble()),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AtlasToolImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.iconPath != widget.iconPath) {
      _load();
    }
  }

  Future<void> _load() async {
    final image = await widget.game.images.load(widget.iconPath);
    if (!mounted) {
      return;
    }
    setState(() => _image = image);
  }

  @override
  Widget build(BuildContext context) {
    final region = _region;
    final height = widget.width * region.size.y / region.size.x;
    final image = _image;
    if (image == null) {
      return SizedBox(width: widget.width, height: height);
    }
    return SizedBox(
      width: widget.width,
      height: height,
      child: CustomPaint(
        painter: _CropPainter(
          image: image,
          source: Rect.fromLTWH(
            region.position.x,
            region.position.y,
            region.size.x,
            region.size.y,
          ),
        ),
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  const _CropPainter({required this.image, required this.source});

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
  bool shouldRepaint(_CropPainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.source != source;
}
