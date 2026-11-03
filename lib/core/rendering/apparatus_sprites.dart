import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Individual equipment sprites, never complete lab screens. The physical
/// renderer positions, rotates and deforms them using the live model geometry.
class ApparatusSprites {
  static ui.Image? _image;
  static Future<void> initialize() async {
    if (_image != null) return;
    final bytes = await rootBundle.load(
      'assets/textures/mechanics-apparatus-atlas-v1.png',
    );
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    try {
      _image = (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  // Measured opaque component bounds in the generated 1448 × 1086 atlas.
  static const bounds = [
    Rect.fromLTRB(37, 110, 366, 281),
    Rect.fromLTRB(399, 118, 727, 282),
    Rect.fromLTRB(763, 115, 1096, 283),
    Rect.fromLTRB(1142, 60, 1392, 311),
    Rect.fromLTRB(63, 370, 326, 690),
    Rect.fromLTRB(443, 391, 650, 676),
    Rect.fromLTRB(793, 394, 995, 679),
    Rect.fromLTRB(1098, 369, 1420, 693),
    Rect.fromLTRB(48, 732, 362, 1022),
    Rect.fromLTRB(423, 750, 706, 994),
    Rect.fromLTRB(829, 750, 996, 1009),
    Rect.fromLTRB(1171, 750, 1338, 1009),
  ];
  static bool draw(Canvas canvas, int index, Rect target) {
    final image = _image;
    if (image == null) return false;
    canvas.drawImageRect(
      image,
      bounds[index].inflate(2),
      target,
      Paint()..filterQuality = FilterQuality.high,
    );
    return true;
  }

  static bool plate(Canvas canvas, List<Offset> corners) {
    final image = _image;
    if (image == null) return false;
    final vertices = ui.Vertices(
      ui.VertexMode.triangles,
      corners,
      textureCoordinates: const [
        Offset(557, 777),
        Offset(449, 968),
        Offset(676, 970),
      ],
    );
    final paint = Paint()
      ..shader = ui.ImageShader(
        image,
        TileMode.clamp,
        TileMode.clamp,
        Float64List.fromList([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]),
      )
      ..filterQuality = FilterQuality.high;
    canvas.drawVertices(vertices, BlendMode.srcOver, paint);
    vertices.dispose();
    return true;
  }
}
