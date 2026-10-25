import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'materials.dart';

/// One distinct, dimensional scientific motif for each studio, drawn offline.
class StudioVignette {
  static void paint(Canvas c, int index) {
    const blue = Color(0xff245ce7),
        teal = Color(0xff008e95),
        amber = Color(0xffd39b30);
    void line(
      Offset a,
      Offset b, {
      Color color = const Color(0xff566d80),
      double width = 2,
    }) => c.drawLine(
      a,
      b,
      Paint()
        ..color = color
        ..strokeWidth = width,
    );
    void sphere(Offset p, double r, Color color) =>
        LabMaterials.sphere(c, p, r, color);
    void metal(Rect r) => LabMaterials.metal(c, r);
    void arrow(Offset a, Offset b, Color color) {
      line(a, b, color: color);
      final ang = (b - a).direction;
      line(
        b,
        b - Offset(math.cos(ang - .5), math.sin(ang - .5)) * 8,
        color: color,
      );
      line(
        b,
        b - Offset(math.cos(ang + .5), math.sin(ang + .5)) * 8,
        color: color,
      );
    }

    LabMaterials.shadow(c, const Rect.fromLTWH(55, 132, 210, 10));
    switch (index) {
      case 0:
        sphere(const Offset(214, 65), 26, blue);
        c.drawOval(
          const Rect.fromLTWH(165, 37, 99, 56),
          Paint()
            ..style = PaintingStyle.stroke
            ..color = teal,
        );
        LabMaterials.spring(
          c,
          const Offset(55, 95),
          const Offset(124, 95),
          turns: 8,
        );
        metal(const Rect.fromLTWH(123, 78, 28, 34));
        final prism = Path()
          ..moveTo(176, 132)
          ..lineTo(195, 100)
          ..lineTo(214, 132)
          ..close();
        c.drawPath(prism, Paint()..color = teal.withValues(alpha: .35));
        arrow(const Offset(145, 117), const Offset(187, 117), amber);
      case 2:
        LabMaterials.wood(c, const Rect.fromLTWH(52, 76, 215, 10));
        final pivot = Path()
          ..moveTo(149, 86)
          ..lineTo(132, 129)
          ..lineTo(166, 129)
          ..close();
        c.drawPath(pivot, Paint()..color = const Color(0xff768794));
        line(const Offset(84, 84), const Offset(84, 112));
        line(const Offset(231, 84), const Offset(231, 106));
        metal(const Rect.fromLTWH(72, 111, 24, 20));
        metal(const Rect.fromLTWH(219, 105, 24, 25));
        sphere(const Offset(257, 42), 13, const Color(0xff8799a4));
        line(const Offset(244, 42), const Offset(244, 72));
      case 3:
        metal(const Rect.fromLTWH(35, 122, 250, 8));
        for (int i = 0; i < 3; i++) {
          final x = 60.0 + i * 80;
          metal(Rect.fromLTWH(x, 92, 45, 24));
          sphere(Offset(x + 9, 119), 5, blue);
          sphere(Offset(x + 36, 119), 5, blue);
        }
        arrow(const Offset(90, 64), const Offset(242, 64), teal);
      case 4:
        LabMaterials.wood(c, const Rect.fromLTWH(132, 74, 55, 51));
        metal(const Rect.fromLTWH(50, 127, 220, 6));
        arrow(const Offset(160, 73), const Offset(160, 33), blue);
        arrow(const Offset(160, 125), const Offset(160, 151), amber);
        arrow(const Offset(187, 94), const Offset(252, 94), teal);
        arrow(const Offset(132, 94), const Offset(89, 94), amber);
      case 5:
        metal(const Rect.fromLTWH(56, 96, 78, 30));
        for (int i = 0; i < 7; i++) {
          line(
            Offset(64 + i * 9, 100),
            Offset(64 + i * 9, 122),
            color: blue,
            width: 4,
          );
        }
        sphere(const Offset(237, 44), 17, const Color(0xff82939c));
        line(
          const Offset(134, 106),
          const Offset(220, 44),
          color: const Color(0xff9d8754),
        );
        line(
          const Offset(254, 44),
          const Offset(254, 101),
          color: const Color(0xff9d8754),
        );
        metal(const Rect.fromLTWH(240, 101, 28, 30));
      case 6:
        sphere(const Offset(143, 84), 34, blue);
        c.drawOval(
          const Rect.fromLTWH(62, 32, 205, 100),
          Paint()
            ..style = PaintingStyle.stroke
            ..color = teal,
        );
        sphere(const Offset(249, 61), 9, amber);
        for (int i = 0; i < 4; i++) {
          final a = i * math.pi / 2;
          arrow(
            Offset(143 + 75 * math.cos(a), 84 + 60 * math.sin(a)),
            Offset(143 + 47 * math.cos(a), 84 + 40 * math.sin(a)),
            teal,
          );
        }
      case 7:
        metal(const Rect.fromLTWH(48, 49, 9, 78));
        metal(const Rect.fromLTWH(45, 126, 229, 8));
        LabMaterials.spring(c, const Offset(57, 93), const Offset(181, 93));
        LabMaterials.metal(
          c,
          const Rect.fromLTWH(180, 74, 36, 38),
          brass: true,
        );
        line(const Offset(265, 36), const Offset(242, 100));
        sphere(const Offset(242, 100), 11, amber);
      case 8:
        metal(const Rect.fromLTWH(54, 48, 38, 82));
        sphere(const Offset(73, 88), 19, const Color(0xff43586a));
        for (int i = 0; i < 3; i++) {
          c.drawArc(
            Rect.fromCenter(
              center: const Offset(112, 88),
              width: 60 + i * 44,
              height: 60 + i * 44,
            ),
            -.8,
            1.6,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = teal.withValues(alpha: .8 - i * .2),
          );
        }
      case 9:
        final p = Path()
          ..moveTo(137, 121)
          ..lineTo(177, 40)
          ..lineTo(216, 121)
          ..close();
        c.drawPath(p, Paint()..color = teal.withValues(alpha: .3));
        c.drawPath(
          p,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = teal,
        );
        line(const Offset(40, 95), const Offset(154, 95), color: amber);
        for (int i = 0; i < 5; i++) {
          line(
            Offset(197, 95),
            Offset(285, 86 + i * 10),
            color: [blue, teal, Colors.green, amber, Colors.red][i],
            width: 1.4,
          );
        }
      case 10:
        line(const Offset(80, 61), const Offset(80, 126), color: blue);
        line(const Offset(80, 126), const Offset(249, 126), color: blue);
        line(const Offset(249, 126), const Offset(249, 61), color: blue);
        line(const Offset(80, 61), const Offset(249, 61), color: blue);
        metal(const Rect.fromLTWH(66, 78, 28, 37));
        sphere(const Offset(249, 64), 20, amber);
        metal(const Rect.fromLTWH(236, 83, 26, 12));
      case 11:
        final path = Path()
          ..moveTo(113, 52)
          ..lineTo(113, 101)
          ..quadraticBezierTo(160, 165, 207, 101)
          ..lineTo(207, 52);
        c.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 24
            ..color = const Color(0xff708899),
        );
        line(
          const Offset(113, 53),
          const Offset(113, 75),
          color: blue,
          width: 24,
        );
        line(
          const Offset(207, 53),
          const Offset(207, 75),
          color: const Color(0xffbd6261),
          width: 24,
        );
        for (int i = 0; i < 3; i++) {
          arrow(Offset(188, 56 + i * 10), Offset(133, 56 + i * 10), teal);
        }
        for (final (label, point) in [
          ('S', const Offset(108, 53)),
          ('N', const Offset(202, 53)),
        ]) {
          final text = TextPainter(
            text: TextSpan(
              text: label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          text.paint(c, point);
          text.dispose();
        }
      case 12:
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(102, 51, 116, 77),
            const Radius.circular(8),
          ),
          Paint()..color = const Color(0xff1b554e),
        );
        for (int i = 0; i < 5; i++) {
          metal(Rect.fromLTWH(115 + i * 18, 42, 5, 13));
          metal(Rect.fromLTWH(115 + i * 18, 126, 5, 13));
        }
        c.drawRect(
          const Rect.fromLTWH(129, 70, 62, 35),
          Paint()..color = const Color(0xff213848),
        );
      case 13:
        metal(const Rect.fromLTWH(106, 63, 93, 66));
        metal(const Rect.fromLTWH(101, 52, 103, 11));
        metal(const Rect.fromLTWH(145, 25, 15, 29));
        line(
          const Offset(235, 42),
          const Offset(235, 122),
          color: const Color(0xffad5652),
          width: 5,
        );
        sphere(const Offset(235, 123), 9, const Color(0xffad5652));
      case 14:
        final p = Path()
          ..moveTo(58, 69)
          ..lineTo(58, 125)
          ..quadraticBezierTo(58, 141, 74, 141)
          ..lineTo(244, 141)
          ..quadraticBezierTo(260, 141, 260, 125)
          ..lineTo(260, 69);
        c.drawPath(
          p,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8
            ..color = const Color(0xff8dafbf),
        );
        c.drawPath(
          p,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..color = const Color(0xff6fbcce),
        );
        line(const Offset(57, 67), const Offset(57, 39), width: 12);
        line(const Offset(260, 67), const Offset(260, 33), width: 12);
      case 15:
        sphere(const Offset(160, 83), 10, amber);
        for (int i = 0; i < 3; i++) {
          c.save();
          c.translate(160, 83);
          c.rotate(i * math.pi / 3);
          c.drawOval(
            Rect.fromCenter(center: Offset.zero, width: 169, height: 63),
            Paint()
              ..style = PaintingStyle.stroke
              ..color = teal,
          );
          c.restore();
        }
        sphere(const Offset(237, 83), 6, blue);
      case 16:
        c.save();
        c.translate(158, 75);
        c.rotate(-.35);
        metal(const Rect.fromLTWH(-54, -16, 108, 32));
        metal(const Rect.fromLTWH(44, -21, 15, 42));
        c.restore();
        line(const Offset(158, 94), const Offset(130, 137), width: 5);
        line(const Offset(158, 94), const Offset(187, 137), width: 5);
        sphere(const Offset(252, 39), 13, amber);
    }
  }
}
