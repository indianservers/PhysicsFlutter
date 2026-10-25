import 'package:flutter/material.dart';

/// Bounded native paragraph reuse for small Canvas labels, including earlier labs.
/// Positions are not cached; every label still follows its current apparatus.
class ScientificText {
  static final _labels = <(String, int, double), TextPainter>{};
  static void paint(
    Canvas canvas,
    String value,
    Offset point, {
    required Color color,
    required double font,
  }) {
    final key = (value, color.toARGB32(), font);
    var painter = _labels[key];
    if (painter == null) {
      if (_labels.length >= 192) {
        _labels.remove(_labels.keys.first)!.dispose();
      }
      painter = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            color: color,
            fontSize: font,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 310);
      _labels[key] = painter;
    }
    painter.paint(canvas, point);
  }
}
