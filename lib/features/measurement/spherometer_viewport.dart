import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/physics/spherometer.dart';
import 'experiment.dart';

class SpherometerViewport extends StatefulWidget {
  final Experiment experiment;
  const SpherometerViewport({super.key, required this.experiment});
  @override
  State<SpherometerViewport> createState() => _SpherometerViewportState();
}

class _SpherometerViewportState extends State<SpherometerViewport> {
  bool turning = false;
  double dragReading = 0;
  Experiment get e => widget.experiment;
  SpherometerSetup get s => e.spherometer!;
  void scale() => showDialog<void>(
    context: context,
    builder: (c) => Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(title: const Text('Circular scale · 50 divisions')),
        body: ListenableBuilder(
          listenable: e,
          builder: (c, _) => Column(
            children: [
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: SpherometerScalePainter(e.a),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Pitch 0.50 mm/turn · LC 0.01 mm\nCurrent ${(e.a * 1000).toStringAsFixed(2)} mm',
                  textAlign: TextAlign.center,
                ),
              ),
              Wrap(
                children: [
                  IconButton(
                    tooltip: 'Raise screw by one division',
                    onPressed: () => e.setA(e.a + .00001),
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    tooltip: 'Lower screw by one division',
                    onPressed: () => e.setA(e.a - .00001),
                    icon: const Icon(Icons.remove),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: e,
    builder: (c, _) => LayoutBuilder(
      builder: (c, b) => Column(
        children: [
          if (b.maxHeight > 120)
            SizedBox(
              height: 48,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final v in ['Perspective', 'Top', 'Section'])
                      TextButton(
                        onPressed: () {
                          s.view = v;
                          e.changed();
                        },
                        child: Text(
                          v,
                          softWrap: false,
                          style: TextStyle(
                            fontWeight: s.view == v ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                    IconButton(
                      tooltip: 'Scale magnifier',
                      onPressed: scale,
                      icon: const Icon(Icons.zoom_in),
                    ),
                    IconButton(
                      tooltip: 'Geometry labels',
                      isSelected: s.labels,
                      onPressed: () {
                        s.labels = !s.labels;
                        e.changed();
                      },
                      icon: const Icon(Icons.label_outline),
                    ),
                    if (s.view != 'Top')
                      IconButton(
                        tooltip: 'Exaggerate vertical curvature ×12',
                        isSelected: s.exaggerated,
                        onPressed: () {
                          s.exaggerated = !s.exaggerated;
                          e.changed();
                        },
                        icon: const Icon(Icons.height),
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (c, box) {
                final fit = math.min(box.maxWidth / 440, box.maxHeight / 290),
                    origin = Offset(
                      (box.maxWidth - 440 * fit) / 2,
                      (box.maxHeight - 290 * fit) / 2,
                    );
                return GestureDetector(
                  key: const Key('spherometer-apparatus'),
                  behavior: HitTestBehavior.opaque,
                  onPanDown: (d) {
                    final p = (d.localPosition - origin) / fit;
                    dragReading = e.a;
                    turning =
                        (p - const Offset(220, 90)).distance < 45 &&
                        s.view != 'Top';
                  },
                  onPanUpdate: (d) {
                    if (turning) {
                      dragReading -=
                          d.delta.dy / fit / 70 * SpherometerSetup.pitch;
                      dragReading = math.max(dragReading, s.contactStop);
                      e.setA(dragReading);
                    }
                  },
                  onPanEnd: (_) {
                    turning = false;
                  },
                  onPanCancel: () {
                    turning = false;
                  },
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: SpherometerPainter(e.a, e.b, s),
                  ),
                );
              },
            ),
          ),
          if (b.maxHeight > 120)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                '${s.atContact(e.a) ? 'Contact' : 'Open gap'} · ${s.exaggerated && s.view != 'Top' ? 'vertical curvature ×12 · ' : ''}dimensions unchanged',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
              ),
            ),
        ],
      ),
    ),
  );
}

class SpherometerPainter extends CustomPainter {
  final double indication, r;
  final SpherometerSetup s;
  SpherometerPainter(this.indication, this.r, this.s);
  void text(
    Canvas c,
    String v,
    Offset p, {
    double size = 11,
    Color color = const Color(0xff283b50),
  }) {
    final t = TextPainter(
      text: TextSpan(
        text: v,
        style: TextStyle(fontSize: size, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 210);
    t.paint(c, p);
  }

  void line(
    Canvas c,
    Offset a,
    Offset b, {
    Color color = const Color(0xff8c9da8),
    double width = 1,
  }) => c.drawLine(
    a,
    b,
    Paint()
      ..color = color
      ..strokeWidth = width,
  );
  void metal(Canvas c, Offset a, Offset b, double width) {
    line(
      c,
      a + const Offset(2, 2),
      b + const Offset(2, 2),
      color: const Color(0x22344755),
      width: width + 3,
    );
    line(c, a, b, color: const Color(0xff657782), width: width);
    line(
      c,
      a - const Offset(2, 0),
      b - const Offset(2, 0),
      color: const Color(0xffe0e9eb),
      width: width * .28,
    );
  }

  @override
  void paint(Canvas c, Size size) {
    final fit = math.min(size.width / 440, size.height / 290);
    c.save();
    c.translate((size.width - 440 * fit) / 2, (size.height - 290 * fit) / 2);
    c.scale(fit);
    final gain = s.exaggerated ? 12.0 : 1.0;
    Offset p(double x, double y, double z) => Offset(
      220 + (x * math.cos(.35) - y * math.sin(.35)) * 118,
      210 + (x * math.sin(.35) + y * math.cos(.35)) * 60 - z * 100,
    );
    final legs = s.legs(r);
    if (s.view == 'Top') {
      final pts = legs
          .map((v) => Offset(210 + v.x / r * 90, 140 + v.y / r * 90))
          .toList();
      final path = Path()..addPolygon(pts, true);
      c.drawPath(path, Paint()..color = const Color(0x334da8bc));
      c.drawPath(
        path,
        Paint()
          ..color = const Color(0xff9cabaf)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12,
      );
      for (int i = 0; i < 3; i++) {
        c.drawCircle(pts[i], 7, Paint()..color = const Color(0xff344e60));
        text(c, '${i + 1}', pts[i] + const Offset(9, 0));
      }
      const centre = Offset(210, 140);
      c.drawCircle(centre, 10, Paint()..color = const Color(0xff697a80));
      line(c, centre, pts[0], color: Colors.blue);
      line(
        c,
        pts[1] + const Offset(0, 20),
        pts[2] + const Offset(0, 20),
        color: Colors.blue,
      );
      text(c, 'r = ${(r * 1000).toStringAsFixed(1)} mm', const Offset(218, 88));
      text(
        c,
        'l = ${(math.sqrt(3) * r * 1000).toStringAsFixed(1)} mm',
        const Offset(150, 220),
      );
      text(c, 'l = √3 r', const Offset(180, 245), size: 14);
    } else if (s.view == 'Section') {
      final path = Path();
      for (int i = 0; i <= 100; i++) {
        final x = -1.05 + i * 2.1 / 100,
            z = s.surfaceHeight(x.abs() * r, r) / r * gain;
        final pt = Offset(220 + x * 140, 185 - z * 210);
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      path.lineTo(367, 223);
      path.lineTo(73, 223);
      path.close();
      c.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0x707ac5d0), Color(0x25b4dbe6)],
          ).createShader(const Rect.fromLTWH(60, 130, 320, 100)),
      );
      c.drawPath(
        path,
        Paint()
          ..color = const Color(0xff81aab8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      line(
        c,
        const Offset(60, 185),
        const Offset(380, 185),
        color: const Color(0xff54778a),
      );
      for (final x in [-1.0, 1.0]) {
        metal(c, Offset(220 + x * 140, 130), Offset(220 + x * 140, 184), 7);
        c.drawCircle(
          Offset(220 + x * 140, 185),
          3,
          Paint()..color = Colors.black87,
        );
      }
      final screwY = 185 - (indication - s.offset) / r * gain * 210;
      metal(c, const Offset(220, 65), Offset(220, screwY), 9);
      metal(c, const Offset(72, 130), const Offset(368, 130), 12);
      final surfaceY = 185 - s.target / r * gain * 210;
      line(
        c,
        const Offset(250, 185),
        Offset(250, surfaceY),
        color: Colors.blue,
        width: 2,
      );
      line(
        c,
        Offset(244, surfaceY),
        Offset(256, surfaceY),
        color: Colors.blue,
        width: 2,
      );
      text(c, 'h (signed)', const Offset(264, 155));
      text(c, 'Outer-contact plane · z = 0', const Offset(66, 236));
      text(c, 'Convex +h / +R · concave −h / −R', const Offset(66, 255));
    } else {
      // Mesh vertices follow the same spherical cap that defines the contact target.
      for (int ring = 20; ring >= 0; ring--) {
        final rad = 1.12 * ring / 20;
        final path = Path();
        for (int i = 0; i <= 80; i++) {
          final theta = i * 2 * math.pi / 80;
          final pt = p(
            rad * math.cos(theta),
            rad * math.sin(theta),
            s.surfaceHeight(rad * r, r) / r * gain - .045,
          );
          if (i == 0) {
            path.moveTo(pt.dx, pt.dy);
          } else {
            path.lineTo(pt.dx, pt.dy);
          }
        }
        c.drawPath(
          path,
          Paint()
            ..color = Color.lerp(
              const Color(0x754891a8),
              const Color(0x15e3ffff),
              1 - ring / 20,
            )!
            ..style = ring == 20 ? PaintingStyle.fill : PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
      final rim = Path();
      for (int i = 0; i <= 100; i++) {
        final t = i * 2 * math.pi / 100,
            pt = p(
              1.12 * math.cos(t),
              1.12 * math.sin(t),
              s.surfaceHeight(1.12 * r, r) / r * gain,
            );
        if (i == 0) {
          rim.moveTo(pt.dx, pt.dy);
        } else {
          rim.lineTo(pt.dx, pt.dy);
        }
      }
      c.drawPath(
        rim,
        Paint()
          ..color = const Color(0xffa9d9df)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
      final tops = <Offset>[];
      int tipNumber = 1;
      for (final leg in legs) {
        final x = leg.x / r, y = leg.y / r;
        final foot = p(x, y, 0), top = p(x, y, .65);
        c.drawOval(
          Rect.fromCenter(
            center: foot + const Offset(1, 4),
            width: 19,
            height: 6,
          ),
          Paint()..color = const Color(0x33354c59),
        );
        metal(c, top, foot - const Offset(0, 3), 9);
        c.drawCircle(foot, 3, Paint()..color = const Color(0xff253b44));
        if (s.labels) {
          text(c, '${tipNumber++}', foot + const Offset(7, 3), size: 10);
        }
        tops.add(top);
      }
      for (int i = 0; i < 3; i++) {
        metal(c, tops[i], tops[(i + 1) % 3], 13);
        metal(c, tops[i], p(0, 0, .65), 10);
      }
      final tip = p(0, 0, (indication - s.offset) / r * gain);
      metal(c, p(0, 0, 1.1), tip, 10);
      for (int i = 0; i < 15; i++) {
        final y = 100 + i * 5.0;
        line(
          c,
          Offset(214, y),
          Offset(226, y + 3),
          color: const Color(0xff516571),
        );
      }
      final knob = Rect.fromCenter(
        center: const Offset(220, 90),
        width: 68,
        height: 25,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(knob, const Radius.circular(5)),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xff405567), Color(0xffcbd7db), Color(0xff405567)],
          ).createShader(knob),
      );
      for (int i = 0; i < 18; i++) {
        final x = 188 + i * 3.5;
        line(c, Offset(x, 80), Offset(x, 100), color: const Color(0xff687b86));
      }
      c.save();
      c.translate(220, 78);
      c.scale(1, .32);
      SpherometerScalePainter.drawDial(
        c,
        Offset.zero,
        39,
        indication,
        labels: false,
      );
      c.restore();
      line(
        c,
        const Offset(236, 109),
        const Offset(236, 212),
        color: Colors.blue,
        width: 2,
      );
      for (int division = -6; division <= 6; division++) {
        final indicated = division * SpherometerSetup.pitch;
        final y = 210 - (indicated - s.offset) / r * gain * 100;
        if (y < 109 || y > 212) continue;
        line(c, Offset(234, y), Offset(division.isEven ? 248 : 243, y));
        if (division.isEven) {
          text(
            c,
            (indicated * 1000).toStringAsFixed(1),
            Offset(250, y - 5),
            size: 8,
          );
        }
      }
      text(c, '0.50 mm/turn', const Offset(280, 106), size: 10);
      if (s.labels) {
        text(c, 'Three fixed tips', const Offset(24, 258));
        text(c, 'Rigid frame', const Offset(25, 105));
        text(c, 'Central screw', const Offset(290, 125));
        text(
          c,
          s.surface == 0 ? 'Plane reference plate' : 'Curved glass cap',
          const Offset(272, 243),
        );
      }
    }
    if (s.lens && s.view != 'Top') {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(14, 12, 119, 79),
          const Radius.circular(10),
        ),
        Paint()..color = const Color(0xf5f0f7fa),
      );
      SpherometerScalePainter.drawDial(c, const Offset(53, 49), 30, indication);
      text(
        c,
        '${(indication * 1000).toStringAsFixed(2)} mm',
        const Offset(86, 38),
        size: 10,
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant SpherometerPainter old) => true;
}

class SpherometerScalePainter extends CustomPainter {
  final double indication;
  SpherometerScalePainter(this.indication);
  static void drawDial(
    Canvas c,
    Offset centre,
    double radius,
    double a, {
    bool labels = true,
  }) {
    c.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xfff8f8f1), Color(0xffbdcbd0)],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );
    final turns = a / SpherometerSetup.pitch;
    for (int i = 0; i < 50; i++) {
      final angle = (i / 50 - turns) * 2 * math.pi - math.pi / 2;
      Offset p(double r) =>
          centre + Offset(math.cos(angle), math.sin(angle)) * r;
      c.drawLine(
        p(radius),
        p(radius - (i % 5 == 0 ? radius * .2 : radius * .1)),
        Paint()
          ..color = const Color(0xff2b4758)
          ..strokeWidth = 1,
      );
      if (labels && i % 10 == 0) {
        final t = TextPainter(
          text: TextSpan(
            text: '$i',
            style: TextStyle(
              color: const Color(0xff243f50),
              fontSize: math.max(6, radius * .16),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        t.paint(c, p(radius * .57) - Offset(t.width / 2, t.height / 2));
      }
    }
    c.drawLine(
      centre - Offset(0, radius * 1.2),
      centre - Offset(0, radius * .85),
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 2,
    );
  }

  @override
  void paint(Canvas c, Size s) {
    drawDial(
      c,
      Offset(s.width / 2, s.height / 2),
      math.min(s.width, s.height) * .38,
      indication,
    );
  }

  @override
  bool shouldRepaint(covariant SpherometerScalePainter old) =>
      indication != old.indication;
}
