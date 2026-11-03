import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OpticsAssets {
  static ui.Image? image, environment;
  static Future<ui.Image> load(String path) async {
    final bytes = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  static Future<void> initialize() async {
    image ??= await load('assets/textures/optics-apparatus-atlas-v1.png');
    environment ??= await load('assets/textures/optics-lab-environment-v1.png');
  }

  static const bounds = [
    Rect.fromLTRB(55, 70, 377, 323),
    Rect.fromLTRB(458, 47, 674, 314),
    Rect.fromLTRB(850, 32, 972, 333),
    Rect.fromLTRB(1206, 41, 1330, 328),
    Rect.fromLTRB(51, 431, 343, 643),
    Rect.fromLTRB(409, 414, 705, 668),
    Rect.fromLTRB(797, 401, 1001, 688),
    Rect.fromLTRB(1170, 400, 1373, 687),
    Rect.fromLTRB(95, 706, 300, 1055),
    Rect.fromLTRB(469, 721, 597, 1050),
    Rect.fromLTRB(734, 742, 1095, 1027),
    Rect.fromLTRB(1166, 736, 1399, 1043),
  ];
  static bool draw(Canvas c, int index, Rect target, {double opacity = 1}) {
    final atlas = image;
    if (atlas == null) return false;
    c.drawImageRect(
      atlas,
      bounds[index],
      target,
      Paint()
        ..filterQuality = FilterQuality.high
        ..color = Colors.white.withValues(alpha: opacity),
    );
    return true;
  }

  static void emitter(Canvas c, Rect target) {
    final atlas = image;
    if (atlas != null) {
      c.drawImageRect(
        atlas,
        const Rect.fromLTRB(55, 70, 377, 194),
        target,
        Paint()..filterQuality = FilterQuality.high,
      );
    }
  }
}
