import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../physics/measurement.dart';
import 'materials.dart';

/// One geometry for the apparatus, its scale lens and its hit mapping.
/// Physical opening is SI; camera and lens transforms never enter the model.
class MicrometerGeometry {
  final double opening, object, zero;
  const MicrometerGeometry(this.opening, this.object, this.zero);
  static const size = Size(440, 250);
  static const axis = 100.0, anvilFace = 86.0, pixelsPerMetre = 3000.0;
  static const pitch = .0005, divisions = 50;
  ScaleReading get reading => ScaleReading.micrometer(opening + zero);
  double get spindleFace => anvilFace + opening * pixelsPerMetre;
  double get edge => 223 + opening * pixelsPerMetre;
  double get sleeveZero => 223 - (reading.observed - opening) * pixelsPerMetre;
  double get turns => opening / pitch;
  Offset get scaleFocus => Offset(edge + 4, axis);
  Rect get thimble => Rect.fromLTWH(edge, 72, 76, 56);
  Rect get objectRect =>
      Rect.fromLTWH(anvilFace, 79, object * pixelsPerMetre, 42);
  bool get contact => (opening - object).abs() <= .000005;
  double graduationY(int index) =>
      axis -
      26 * math.sin((index - reading.observed / pitch * 50) * 2 * math.pi / 50);
  double sleeveMark(int halfMillimetres) => sleeveZero + halfMillimetres * 1.5;
  Offset toWorld(Offset point, Size viewport) {
    final scale = math.min(
      viewport.width / size.width,
      viewport.height / size.height,
    );
    return (point -
            Offset(
              (viewport.width - size.width * scale) / 2,
              (viewport.height - size.height * scale) / 2,
            )) /
        scale;
  }
}

class MicrometerPainter extends CustomPainter {
  final MicrometerGeometry geometry;
  final bool labels;
  const MicrometerPainter(this.geometry, {this.labels = true});
  @override
  bool shouldRepaint(covariant MicrometerPainter old) =>
      old.geometry.opening != geometry.opening ||
      old.geometry.object != geometry.object ||
      old.geometry.zero != geometry.zero ||
      old.labels != labels;
  void text(
    Canvas c,
    String value,
    Offset p, {
    double size = 9,
    Color color = const Color(0xff173458),
  }) {
    final t = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    t.paint(c, p);
  }

  void line(
    Canvas c,
    Offset a,
    Offset b, {
    double width = .8,
    Color color = const Color(0xff23394b),
  }) => c.drawLine(
    a,
    b,
    Paint()
      ..color = color
      ..strokeWidth = width,
  );
  @override
  void paint(Canvas c, Size size) {
    final fit = math.min(size.width / 440, size.height / 250);
    c.save();
    c.translate((size.width - 440 * fit) / 2, (size.height - 250 * fit) / 2);
    c.scale(fit);
    paintWorld(c);
    c.restore();
  }

  void paintWorld(Canvas c) {
    final g = geometry;
    // Opposed faces are horizontal and their separation is exactly opening*scale.
    final frame = Path()
      ..moveTo(66, 88)
      ..cubicTo(15, 76, 13, 217, 95, 227)
      ..cubicTo(167, 241, 214, 216, 214, 115)
      ..lineTo(188, 115)
      ..cubicTo(188, 194, 153, 206, 101, 198)
      ..cubicTo(49, 192, 53, 119, 68, 115)
      ..close();
    c.drawShadow(frame, const Color(0x55304455), 5, false);
    c.drawPath(
      frame,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xff496876), Color(0xff112d3c), Color(0xff577c86)],
        ).createShader(const Rect.fromLTWH(20, 80, 205, 155)),
    );
    c.drawPath(
      frame,
      Paint()
        ..color = const Color(0xff8ba1a7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    LabMaterials.metal(c, const Rect.fromLTWH(65, 87, 21, 26));
    LabMaterials.metal(c, Rect.fromLTRB(g.spindleFace, 93, 231, 107));
    c.drawRect(
      g.objectRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xff795039), Color(0xffedc18a), Color(0xff80513a)],
        ).createShader(g.objectRect),
    );
    // The sleeve is fixed to the frame; the thimble translates and rotates over it.
    LabMaterials.metal(c, const Rect.fromLTWH(186, 79, 31, 42));
    LabMaterials.metal(c, Rect.fromLTRB(207, 79, g.edge + 8, 122));
    c.save();
    c.clipRect(Rect.fromLTRB(207, 79, g.edge, 122));
    line(c, const Offset(207, 100), Offset(g.edge, 100));
    for (int i = -2; i <= 52; i++) {
      final x = g.sleeveMark(i);
      if (x < 207 || x > g.edge + .00001) continue;
      line(c, Offset(x, 100), Offset(x, i.isEven ? 89 : 112));
      if (i >= 0 && i % 10 == 0) {
        text(c, '${i ~/ 2}', Offset(x - '${i ~/ 2}'.length * 5, 80), size: 8);
      }
    }
    c.restore();
    LabMaterials.metal(c, g.thimble);
    // The conical reading edge carries the circumferential 50-division scale.
    final bevel = Path()
      ..moveTo(g.edge, 79)
      ..lineTo(g.edge + 15, 72)
      ..lineTo(g.edge + 15, 128)
      ..lineTo(g.edge, 122)
      ..close();
    c.drawPath(
      bevel,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xffc4d0d4), Color(0xfff8fafb), Color(0xff8d9fa8)],
        ).createShader(g.thimble),
    );
    final phase = g.reading.observed / MicrometerGeometry.pitch * 50;
    c.save();
    c.clipRect(g.thimble);
    for (int i = 0; i < 50; i++) {
      final angle = (i - phase) * 2 * math.pi / 50;
      if (math.cos(angle) < .05) continue;
      final y = g.graduationY(i);
      line(
        c,
        Offset(g.edge + 1, y),
        Offset(g.edge + (i % 5 == 0 ? 18 : 11), y),
      );
      if (i % 5 == 0) text(c, '$i', Offset(g.edge + 21, y - 4.5), size: 8);
    }
    for (int i = 0; i < 12; i++) {
      final y = 100 - 27 * math.sin((i / 12 - g.turns) * 2 * math.pi);
      line(
        c,
        Offset(g.edge + 45, y),
        Offset(g.edge + 73, y),
        color: const Color(0xff8a9da7),
        width: .6,
      );
    }
    c.restore();
    LabMaterials.metal(c, Rect.fromLTWH(g.edge + 76, 86, 29, 28));
    for (int i = 0; i < 9; i++) {
      line(
        c,
        Offset(g.edge + 78 + i * 3, 88),
        Offset(g.edge + 78 + i * 3, 112),
        color: const Color(0xff6a7f88),
      );
    }
    line(c, const Offset(84, 87), const Offset(84, 113), width: 1.4);
    line(c, Offset(g.spindleFace, 93), Offset(g.spindleFace, 107), width: 1.4);
    if (labels) {
      text(c, 'Anvil', const Offset(48, 55));
      line(c, const Offset(70, 69), const Offset(76, 86));
      text(c, 'Spindle', const Offset(112, 55));
      line(c, const Offset(136, 69), Offset((g.spindleFace + 186) / 2, 92));
      text(c, 'Sleeve', const Offset(200, 49));
      line(c, const Offset(221, 63), const Offset(220, 78));
      text(c, 'Thimble', Offset(g.edge + 27, 41));
      line(c, Offset(g.edge + 50, 55), Offset(g.edge + 48, 71));
      text(c, 'Ratchet', Offset(g.edge + 78, 55));
      line(c, Offset(g.edge + 89, 68), Offset(g.edge + 90, 85));
      text(c, 'Frame', const Offset(77, 212), color: Colors.white);
      text(c, 'Object', const Offset(96, 153));
      line(c, const Offset(111, 151), Offset(g.objectRect.center.dx, 123));
    }
  }
}

/// A true crop of the same scale drawing, not a second approximate scale.
class MicrometerLensPainter extends CustomPainter {
  final MicrometerGeometry geometry;
  final double zoom;
  const MicrometerLensPainter(this.geometry, {this.zoom = 3});
  @override
  bool shouldRepaint(covariant MicrometerLensPainter old) =>
      geometry.opening != old.geometry.opening ||
      geometry.zero != old.geometry.zero ||
      zoom != old.zoom;
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.clipRect(Offset.zero & size);
    c.drawRect(Offset.zero & size, Paint()..color = const Color(0xfff5f8fa));
    c.translate(size.width / 2, size.height / 2);
    c.scale(zoom);
    c.translate(-geometry.scaleFocus.dx, -geometry.scaleFocus.dy);
    MicrometerPainter(geometry, labels: false).paintWorld(c);
    c.restore();
  }
}
