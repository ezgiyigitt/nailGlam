import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Decodes a bundled image once and paints a source rectangle into a real box.
class CroppedAsset extends StatefulWidget {
  const CroppedAsset({
    required this.asset,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.topFade = 0,
    super.key,
  });

  /// Path under `assets/images/`.
  final String asset;
  final Rect source;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Fraction of the drawn dest faded from the top. 0 keeps a hard edge.
  final double topFade;

  @override
  State<CroppedAsset> createState() => _CroppedAssetState();
}

class _CroppedAssetState extends State<CroppedAsset> {
  ui.Image? get _image => AssetImageCache.decoded[widget.asset];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CroppedAsset oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      await AssetImageCache.load(widget.asset);
    } catch (_) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Rect _clampedSource(ui.Image image) {
    final bounds = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final hit = widget.source.intersect(bounds);
    if (hit.width >= 1 && hit.height >= 1) {
      return hit;
    }
    return bounds;
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) {
      return SizedBox(width: widget.width, height: widget.height);
    }
    final src = _clampedSource(image);
    final aspect = src.width / src.height;
    var width = widget.width;
    var height = widget.height;
    if (width == null && height != null) {
      width = height * aspect;
    } else if (height == null && width != null) {
      height = width / aspect;
    } else if (width == null && height == null) {
      width = src.width;
      height = src.height;
    }
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        size: Size(width!, height!),
        painter: _CropPainter(
          image: image,
          source: src,
          fit: widget.fit,
          topFade: widget.topFade,
        ),
      ),
    );
  }
}

/// Even-cell strip: each frame is `image.width / frameCount` wide.
class StripFrame extends StatefulWidget {
  const StripFrame({
    required this.asset,
    required this.frame,
    required this.frameCount,
    this.width,
    this.height,
    super.key,
  });

  final String asset;
  final int frame;
  final int frameCount;
  final double? width;
  final double? height;

  @override
  State<StripFrame> createState() => _StripFrameState();
}

class _StripFrameState extends State<StripFrame> {
  ui.Image? get _image => AssetImageCache.decoded[widget.asset];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(StripFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      await AssetImageCache.load(widget.asset);
    } catch (_) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) {
      return SizedBox(width: widget.width, height: widget.height);
    }
    final count = widget.frameCount.clamp(1, 64);
    final cell = image.width / count;
    final index = widget.frame.clamp(0, count - 1);
    return CroppedAsset(
      asset: widget.asset,
      source: Rect.fromLTWH(
        cell * index,
        0,
        cell,
        image.height.toDouble(),
      ),
      width: widget.width,
      height: widget.height,
    );
  }
}

/// Shared decode cache so the demo does not reload PNGs every frame.
abstract final class AssetImageCache {
  static final Map<String, ui.Image> decoded = <String, ui.Image>{};
  static final Map<String, Future<ui.Image>> _pending = <String, Future<ui.Image>>{};

  static Future<ui.Image> load(String asset) {
    final hit = decoded[asset];
    if (hit != null) {
      return Future<ui.Image>.value(hit);
    }
    return _pending.putIfAbsent(asset, () async {
      final data = await rootBundle.load('assets/images/$asset');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      decoded[asset] = frame.image;
      return frame.image;
    });
  }
}

class _CropPainter extends CustomPainter {
  const _CropPainter({
    required this.image,
    required this.source,
    required this.fit,
    required this.topFade,
  });

  final ui.Image image;
  final Rect source;
  final BoxFit fit;
  final double topFade;

  @override
  void paint(Canvas canvas, Size size) {
    if (source.width <= 0 || source.height <= 0 || size.isEmpty) {
      return;
    }
    final fitted = applyBoxFit(fit, source.size, size);
    final dest = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    if (topFade > 0) {
      canvas.saveLayer(dest.inflate(4), Paint());
    }
    canvas.drawImageRect(
      image,
      source,
      dest,
      Paint()
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = true,
    );
    if (topFade > 0) {
      canvas.drawRect(
        dest,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = ui.Gradient.linear(
            Offset(dest.left, dest.top),
            Offset(dest.left, dest.top + dest.height * topFade),
            const <Color>[
              Color(0x00FFFFFF),
              Color(0x99FFFFFF),
              Color(0xFFFFFFFF),
            ],
            const <double>[0, 0.45, 1],
          ),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CropPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.source != source ||
      oldDelegate.fit != fit ||
      oldDelegate.topFade != topFade;
}
