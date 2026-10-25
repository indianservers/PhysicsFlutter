import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../physics/measurement.dart';

/// Model coordinates are SI. Canvas scale and InteractiveViewer affect only the view.
abstract class ScientificScene extends CustomPainter {
  const ScientificScene();
  String get accessibleSummary;
}

class ApparatusPainter extends ScientificScene {
  final int kind;
  final double a, b, zero, time;
  final double? progress;
  final bool guides;
  final List<double> samples;
  const ApparatusPainter(
    this.kind, {
    this.a = .012,
    this.b = .066,
    this.zero = 0,
    this.time = 0,
    this.progress,
    this.guides = true,
    this.samples = const [],
  });
  @override
  String get accessibleSummary =>
      'Scientific model, instrument $kind, primary value $a SI, secondary value $b SI';
  @override
  bool shouldRepaint(covariant ApparatusPainter old) =>
      kind != old.kind ||
      a != old.a ||
      b != old.b ||
      zero != old.zero ||
      time != old.time ||
      progress != old.progress ||
      guides != old.guides ||
      samples != old.samples;
  void label(
    Canvas c,
    String text,
    Offset p, {
    double size = 12,
    Color color = const Color(0xff142b50),
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, p);
  }

  void line(
    Canvas c,
    Offset a,
    Offset b, {
    Color color = const Color(0xff45556b),
    double width = 1,
  }) => c.drawLine(
    a,
    b,
    Paint()
      ..color = color
      ..strokeWidth = width,
  );
  void metal(Canvas c, Rect r, {double radius = 4}) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        r.shift(const Offset(1, 5)),
        Radius.circular(radius),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: .13)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(radius)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xff687981),
            Color(0xfff5f7f8),
            Color(0xffa6b0b4),
            Color(0xffedf1f3),
            Color(0xff718087),
          ],
        ).createShader(r),
    );
    for (double y = r.top + 2; y < r.bottom; y += 3) {
      line(
        c,
        Offset(r.left + 2, y),
        Offset(r.right - 2, y),
        color: Colors.white.withValues(alpha: .16),
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 360, size.height / 240);
    final c = canvas;
    c.drawRect(
      const Rect.fromLTWH(0, 0, 360, 240),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xfff7fafc), Color(0xffe9eff4)],
        ).createShader(const Rect.fromLTWH(0, 0, 360, 240)),
    );
    if (kind == 0) {
      final r = const Rect.fromLTWH(16, 116, 328, 77);
      c.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(6)),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xffbd833b), Color(0xfff4d49b), Color(0xffc08b46)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(r),
      );
      for (int i = 0; i < 36; i++) {
        line(
          c,
          Offset(20, 120 + i * 2),
          Offset(342, 120 + i * 2),
          color: const Color(0xff6b461b).withValues(alpha: .07),
        );
      }
      for (int i = 0; i <= 100; i++) {
        double x = 22 + i * 3.16;
        line(
          c,
          Offset(x, 117),
          Offset(
            x,
            117 +
                (i % 10 == 0
                    ? 27
                    : i % 5 == 0
                    ? 19
                    : 12),
          ),
          color: const Color(0xff543719),
        );
        if (i % 10 == 0) {
          label(c, '${i ~/ 10}', Offset(x - 3, 148));
        }
      }
      label(c, 'cm', const Offset(22, 172));
      double x1 = 22 + a * 3160, x2 = 22 + b * 3160;
      metal(c, Rect.fromLTRB(x1, 72, x2, 115));
      if (guides) {
        for (final x in [x1, x2]) {
          line(
            c,
            Offset(x, 44),
            Offset(x, 128),
            color: const Color(0xff235ce8),
            width: 1.5,
          );
          c.drawCircle(
            Offset(x, 120),
            5,
            Paint()..color = const Color(0xff235ce8),
          );
        }
        label(c, 'A', Offset(x1 - 5, 25), color: const Color(0xff235ce8));
        label(c, 'B', Offset(x2 - 5, 25), color: const Color(0xff235ce8));
      }
      label(
        c,
        '1 mm graduations · ideal ruler',
        const Offset(72, 211),
        size: 11,
      );
    } else if (kind == 1) {
      final reading = ScaleReading.vernier(a + zero);
      final origin = 50 - zero * 5000;
      final x = 50 + a * 5000;
      metal(c, const Rect.fromLTWH(22, 83, 320, 38));
      metal(c, const Rect.fromLTWH(38, 51, 12, 132));
      metal(c, const Rect.fromLTWH(38, 171, 37, 13));
      metal(c, Rect.fromLTWH(x, 68, 16, 115));
      metal(c, Rect.fromLTWH(x - 24, 171, 40, 13));
      for (int i = -2; i < 58; i++) {
        double px = origin + i * 5;
        if (px > 340) {
          break;
        }
        line(c, Offset(px, 88), Offset(px, 88 + (i % 10 == 0 ? 20 : 10)));
        if (i % 10 == 0) {
          label(c, '$i', Offset(px - 4, 72), size: 9);
        }
      }
      metal(c, Rect.fromLTWH(x - 4, 116, 65, 31));
      for (int i = 0; i <= 10; i++) {
        double vx = x + i * 4.5;
        line(
          c,
          Offset(vx, 119),
          Offset(vx, 132),
          color: i == reading.division
              ? const Color(0xff005ce6)
              : const Color(0xff45556b),
          width: i == reading.division ? 2 : 1,
        );
        if (i % 5 == 0) {
          label(c, '$i', Offset(vx - 3, 133), size: 9);
        }
      }
      metal(c, Rect.fromLTWH(51, 150, (x - 51).clamp(0, 290), 20));
      label(
        c,
        'External jaws · 10 vernier divisions = 9 mm',
        const Offset(35, 207),
        size: 11,
      );
      if (guides) {
        label(
          c,
          'Drag jaw ↔',
          Offset(x.clamp(100, 250), 30),
          color: const Color(0xff235ce8),
        );
      }
    } else if (kind == 2) {
      final r = ScaleReading.micrometer(a + zero);
      final path = Path()
        ..moveTo(130, 70)
        ..cubicTo(15, 5, 0, 222, 117, 207)
        ..lineTo(151, 181)
        ..lineTo(130, 160)
        ..cubicTo(48, 199, 51, 77, 117, 98)
        ..close();
      c.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xff0b2033), Color(0xff365c72), Color(0xff112d40)],
          ).createShader(const Rect.fromLTWH(0, 20, 150, 190)),
      );
      metal(c, const Rect.fromLTWH(69, 85, 30, 15));
      final thimble = 160 + a * 4000;
      final spindle = 99 + a * 4000;
      metal(c, Rect.fromLTWH(spindle, 85, thimble - spindle + 1, 15));
      c.drawRect(
        Rect.fromLTWH(99, 66, (b * 4000).clamp(1, 40), 53),
        Paint()..color = const Color(0xffb2784f),
      );
      metal(c, Rect.fromLTWH(151, 66, thimble - 151, 53));
      line(c, const Offset(158, 92), Offset(thimble, 92));
      for (int i = 0; i <= 50; i++) {
        double x = 160 - zero * 4000 + i * 2;
        if (x > thimble) {
          break;
        }
        line(c, Offset(x, 92), Offset(x, i.isEven ? 77 : 105));
        if (i % 10 == 0) {
          label(c, '${i ~/ 2}', Offset(x - 2, 68), size: 8);
        }
      }
      metal(c, Rect.fromLTWH(thimble, 60, 60, 67));
      metal(c, Rect.fromLTWH(thimble + 60, 71, 30, 46));
      for (int i = -5; i <= 5; i++) {
        final d = (r.division + i + 50) % 50;
        double y = 92 + i * 5;
        line(
          c,
          Offset(thimble + 1, y),
          Offset(thimble + (d % 5 == 0 ? 19 : 11), y),
        );
        if (d % 5 == 0) {
          label(c, '$d', Offset(thimble + 23, y - 5), size: 9);
        }
      }
      for (int i = 0; i < 12; i++) {
        line(
          c,
          Offset(thimble + 62 + i * 2.2, 72),
          Offset(thimble + 62 + i * 2.2, 116),
          color: const Color(0xff64747f),
        );
      }
      label(c, '0–25 mm', const Offset(77, 155), color: Colors.white);
      label(
        c,
        'Pitch 0.5 mm · 50 divisions · LC 0.01 mm',
        const Offset(31, 219),
        size: 11,
      );
      if (guides) {
        label(
          c,
          'Rotate / drag ↔',
          const Offset(219, 32),
          color: const Color(0xff235ce8),
        );
      }
    } else if (kind == 3) {
      c.drawOval(
        const Rect.fromLTWH(36, 160, 286, 57),
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xffd4f4f4), Color(0xff64a7ad)],
          ).createShader(const Rect.fromLTWH(36, 160, 286, 57)),
      );
      final h = (a - zero) * 9000;
      final arc = Path()
        ..moveTo(58, 184)
        ..quadraticBezierTo(180, 184 - h, 303, 184);
      c.drawPath(
        arc,
        Paint()
          ..color = const Color(0xff329da6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      final legOffset = b * 1400;
      metal(c, Rect.fromLTWH(180 + legOffset * .45, 67, 10, 90));
      for (final x in [180 - legOffset, 180 + legOffset]) {
        metal(
          c,
          Rect.fromLTWH(x - 5, x == 180 ? 110 : 99, 10, x == 180 ? 62 : 85),
        );
      }
      metal(c, Rect.fromLTWH(170 - legOffset, 88, legOffset * 2 + 20, 17));
      metal(c, Rect.fromLTWH(173, 40, 14, 145 - h / 2));
      metal(c, const Rect.fromLTWH(154, 27, 52, 23));
      for (int i = 0; i < 12; i++) {
        line(
          c,
          Offset(157 + i * 4, 28),
          Offset(157 + i * 4, 48),
          color: const Color(0xff657782),
        );
      }
      label(c, 'r = centre → outer leg', const Offset(111, 218), size: 11);
      if (guides) {
        line(
          c,
          const Offset(180, 191),
          const Offset(272, 191),
          color: const Color(0xff235ce8),
          width: 2,
        );
        label(
          c,
          'h (signed)',
          const Offset(208, 131),
          color: const Color(0xff235ce8),
        );
      }
    } else if (kind == 4) {
      metal(c, const Rect.fromLTWH(17, 83, 120, 112));
      metal(c, const Rect.fromLTWH(22, 71, 110, 16));
      c.drawCircle(
        const Offset(77, 62),
        19,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.4, -.5),
            colors: [Colors.white, Color(0xffadb6b7), Color(0xff3a474e)],
          ).createShader(const Rect.fromLTWH(58, 43, 38, 38)),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(27, 110, 100, 38),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xffc7d6b5),
      );
      label(
        c,
        '${((a - zero) * 1000).toStringAsFixed(2)} g',
        const Offset(34, 118),
        size: 18,
      );
      label(c, 'SIMULATED', const Offset(39, 165), size: 10);
      line(
        c,
        const Offset(159, 101),
        const Offset(337, 165),
        color: const Color(0xffc39552),
        width: 12,
      );
      line(
        c,
        const Offset(159, 94),
        const Offset(337, 158),
        color: const Color(0xfff0d8ae),
        width: 4,
      );
      final f = (progress ?? time / b).clamp(0.0, 1.0);
      final p = Offset(161 + 172 * f, 82 + 63 * f);
      c.drawCircle(
        p,
        12,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.4, -.5),
            colors: [Colors.white, Color(0xff77818b), Color(0xff263444)],
          ).createShader(Rect.fromCircle(center: p, radius: 12)),
      );
      label(c, '${time.toStringAsFixed(3)} s', const Offset(198, 43), size: 22);
      label(c, 'Ideal track · not to scale', const Offset(164, 208), size: 11);
    } else if (kind == 5) {
      label(
        c,
        'Repeated readings · standard uncertainty',
        const Offset(28, 20),
        size: 12,
      );
      for (int i = 0; i < 5; i++) {
        line(
          c,
          Offset(45, 55 + i * 30),
          Offset(335, 55 + i * 30),
          color: const Color(0xffd5dfe9),
        );
      }
      line(c, const Offset(45, 47), const Offset(45, 195));
      if (samples.isEmpty) {
        label(
          c,
          'Add measurements to draw error bars',
          const Offset(60, 115),
          size: 12,
        );
      } else {
        final stats = Statistics(samples, a);
        final mean = stats.mean!;
        final span = math.max(
          math.max(mean.abs() * .01, 1e-12),
          math.max(
            (samples.reduce(math.max) - samples.reduce(math.min)) * 1.5,
            a * 6,
          ),
        );
        final min = mean - span / 2;
        double y(double v) => 185 - (v - min) / span * 120;
        for (int i = 0; i < 5; i++) {
          final value = min + span * i / 4;
          label(
            c,
            value.toStringAsPrecision(3),
            Offset(2, y(value) - 4),
            size: 8,
          );
        }
        line(
          c,
          Offset(45, y(mean)),
          Offset(335, y(mean)),
          color: const Color(0xffd99e2b),
          width: 2,
        );
        for (int i = 0; i < samples.length; i++) {
          double x = 60 + i * 265 / math.max(1, samples.length - 1),
              v = samples[i],
              u = stats.instrument ?? 0;
          line(
            c,
            Offset(x, y(v - u)),
            Offset(x, y(v + u)),
            color: const Color(0xff009b9e),
            width: 1.5,
          );
          line(
            c,
            Offset(x - 4, y(v - u)),
            Offset(x + 4, y(v - u)),
            color: const Color(0xff009b9e),
          );
          line(
            c,
            Offset(x - 4, y(v + u)),
            Offset(x + 4, y(v + u)),
            color: const Color(0xff009b9e),
          );
          c.drawCircle(
            Offset(x, y(v)),
            4,
            Paint()..color = const Color(0xff009b9e),
          );
          if (samples.length <= 12) {
            label(c, '${i + 1}', Offset(x - 3, 193), size: 9);
          }
        }
        label(
          c,
          'Mean ${mean.toStringAsPrecision(5)} SI',
          const Offset(65, 210),
          size: 11,
        );
      }
    }
    canvas.restore();
  }
}

class StudioIllustration extends CustomPainter {
  final int index;
  const StudioIllustration(this.index);
  @override
  bool shouldRepaint(covariant StudioIllustration old) => old.index != index;
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 320, s.height / 160);
    final bg = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xffe9f1fc),
          index % 3 == 0 ? const Color(0xffe2f3f1) : const Color(0xfff4f7fb),
        ],
      ).createShader(const Rect.fromLTWH(0, 0, 320, 160));
    c.drawRect(const Rect.fromLTWH(0, 0, 320, 160), bg);
    final p = Paint()
      ..color = const Color(0xff245cdf)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    if (index == 1) {
      c.save();
      c.translate(48, 4);
      c.scale(.72, .64);
      const ApparatusPainter(1, a: .0236).paint(c, const Size(320, 240));
      c.restore();
    } else if ([0, 6, 15, 16].contains(index)) {
      for (int i = 0; i < 3; i++) {
        c.save();
        c.translate(160, 80);
        c.rotate(i * math.pi / 3);
        c.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 200, height: 70),
          p..color = const Color(0xff2463db).withValues(alpha: .45),
        );
        c.restore();
      }
      c.drawCircle(
        const Offset(160, 80),
        26,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.4, -.4),
            colors: [Color(0xff60c6cc), Color(0xff15488e)],
          ).createShader(const Rect.fromLTWH(134, 54, 52, 52)),
      );
      c.drawCircle(
        const Offset(253, 69),
        7,
        Paint()..color = const Color(0xffe0ad50),
      );
    } else if ([7, 8, 9, 11, 12].contains(index)) {
      final path = Path();
      for (int i = 0; i < 280; i++) {
        double x = 20 + i.toDouble(),
            y = 80 + math.sin(i / 25) * (index == 9 ? i * .15 : 32);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      c.drawPath(path, p);
      c.drawLine(
        const Offset(20, 80),
        const Offset(300, 80),
        p
          ..color = const Color(0xff95b1c7)
          ..strokeWidth = .6,
      );
      if (index == 9) {
        c.drawOval(
          const Rect.fromLTWH(145, 25, 30, 110),
          Paint()..color = const Color(0xff56b7c9).withValues(alpha: .25),
        );
      }
    } else if ([10, 13, 14].contains(index)) {
      for (int i = 0; i < 4; i++) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              68 + i * 48,
              55 - (i % 2) * 17,
              30,
              72 + (i % 2) * 17,
            ),
            const Radius.circular(8),
          ),
          p..color = const Color(0xff477b9c),
        );
        c.drawRect(
          Rect.fromLTWH(72 + i * 48, 95 - (i % 3) * 10, 22, 28 + (i % 3) * 10),
          Paint()..color = const Color(0xff36a7b2).withValues(alpha: .5),
        );
      }
    } else {
      c.drawLine(
        const Offset(40, 132),
        const Offset(280, 91),
        p
          ..color = const Color(0xffc08e45)
          ..strokeWidth = 9,
      );
      final rect = const Rect.fromLTWH(124, 60, 63, 49);
      c.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xff75a1c1), Color(0xff17416f)],
          ).createShader(rect),
      );
      c.drawLine(
        const Offset(155, 57),
        const Offset(195, 26),
        p
          ..color = const Color(0xffdfaa3a)
          ..strokeWidth = 3,
      );
      c.drawLine(const Offset(195, 26), const Offset(183, 29), p);
      c.drawLine(const Offset(195, 26), const Offset(190, 39), p);
    }
    c.restore();
  }
}

class MagnifiedScalePainter extends CustomPainter {
  final ApparatusPainter apparatus;
  const MagnifiedScalePainter(this.apparatus);
  @override
  bool shouldRepaint(covariant MagnifiedScalePainter old) =>
      apparatus.shouldRepaint(old.apparatus);
  @override
  void paint(Canvas c, Size size) {
    final focus = switch (apparatus.kind) {
      0 => Offset(22 + apparatus.b * 3160, 133),
      1 => Offset(50 + apparatus.a * 5000 + 20, 115),
      _ => Offset(160 + apparatus.a * 4000, 92),
    };
    c.save();
    c.clipRect(Offset.zero & size);
    c.translate(size.width / 2, size.height / 2);
    c.scale(3);
    c.translate(-focus.dx, -focus.dy);
    apparatus.paint(c, const Size(360, 240));
    c.restore();
  }
}
