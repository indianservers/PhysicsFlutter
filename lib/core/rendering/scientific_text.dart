import 'package:flutter/material.dart';

import 'dart:math' as math;

/// Bounded native paragraph reuse for small Canvas labels, including earlier labs.
/// Positions are not cached; every label still follows its current apparatus.
class ScientificText {
  static final _labels = <(String, int, double), TextPainter>{};
  static final _callouts = <Rect>[];
  static void beginCallouts() => _callouts.clear();
  static void callout(Canvas canvas, String value, Offset anchor, Color color) {
    final matrix = canvas.getTransform();
    final scale = math.sqrt(matrix[0] * matrix[0] + matrix[1] * matrix[1]);
    final font = math.max(11.0, 11 / math.max(.4, scale));
    final key = ('callout::$value', color.toARGB32(), font);
    var text = _labels[key];
    if (text == null) {
      if (_labels.length >= 192) {
        _labels.remove(_labels.keys.first)!.dispose();
      }
      text = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            color: color,
            fontSize: font,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 170);
      _labels[key] = text;
    }
    var position = Offset(
      anchor.dx.clamp(6, math.max(6, 354 - text.width)),
      anchor.dy.clamp(6, math.max(6, 258 - text.height)),
    );
    for (final shift in [0.0, -18.0, 18.0, -36.0, 36.0]) {
      final candidate = Offset(
        position.dx,
        (position.dy + shift).clamp(6, math.max(6, 258 - text.height)),
      );
      final rect = candidate & text.size;
      if (!_callouts.any((other) => other.inflate(2).overlaps(rect))) {
        position = candidate;
        break;
      }
    }
    final rect = position & text.size;
    _callouts.add(rect);
    if ((position - anchor).distance > 12) {
      canvas.drawLine(
        anchor,
        rect.center,
        Paint()
          ..color = color
          ..strokeWidth = .8,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(3)),
      Paint()..color = const Color(0xe6ffffff),
    );
    text.paint(canvas, position);
  }

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
