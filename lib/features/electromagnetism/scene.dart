import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/physics/electromagnetism.dart';
import '../../core/rendering/apparatus.dart';
import '../../core/rendering/materials.dart';
import '../dynamics/scene.dart' show DynamicsPainter;

class EMPainter extends ScientificScene {
  final EMRun run;
  final bool labels, overlays, fieldLines, electrons;
  final double azimuth, elevation;
  final String? selected;
  final int revision, layoutHash;
  EMPainter(
    this.run, {
    this.labels = true,
    this.overlays = true,
    this.fieldLines = true,
    this.electrons = true,
    this.azimuth = .6,
    this.elevation = .4,
    this.selected,
  }) : revision = run.revision,
       layoutHash = Object.hashAll(
         run.circuit.parts.map((p) => Object.hash(p.id, p.x, p.y)),
       );
  static const tool = DynamicsPainter(kind: 0, s: {}, p: {}, samples: []),
      navy = Color(0xff173458),
      blue = Color(0xff245ce7),
      teal = Color(0xff008e95),
      amber = Color(0xffca9225),
      copper = Color(0xffb9622b);
  double v(String k, [double fallback = 0]) => run.p[k] ?? fallback;
  double q(String k) => run.state[k] ?? 0;
  int get kind => run.kind;
  double get solenoidScale => math.min(240 / v('length'), 90 / v('radius'));
  double get coulombScale => math.min(1000, 270 / v('distance'));
  @override
  String get accessibleSummary =>
      'Computed electromagnetic apparatus $kind. ${run.invalid.isEmpty ? run.state.entries.map((e) => '${e.key} ${emNumber(e.value)}').join('; ') : run.invalid}';
  @override
  bool shouldRepaint(covariant EMPainter old) =>
      old.run != run ||
      old.revision != revision ||
      old.layoutHash != layoutHash ||
      old.labels != labels ||
      old.overlays != overlays ||
      old.fieldLines != fieldLines ||
      old.electrons != electrons ||
      old.azimuth != azimuth ||
      old.elevation != elevation ||
      old.selected != selected;
  void text(
    Canvas c,
    String s,
    Offset p, {
    double size = 9,
    Color color = navy,
  }) {
    if (labels) tool.text(c, s, p, font: size, color: color);
  }

  void line(
    Canvas c,
    Offset a,
    Offset b, {
    Color color = navy,
    double width = 1.3,
  }) => c.drawLine(
    a,
    b,
    Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round,
  );
  void arrow(
    Canvas c,
    Offset a,
    Offset b, {
    Color color = teal,
    double width = 1.4,
  }) {
    if ((b - a).distance < .1) return;
    line(c, a, b, color: color, width: width);
    final angle = (b - a).direction;
    for (final s in [-.5, .5]) {
      line(
        c,
        b,
        b - Offset(math.cos(angle + s), math.sin(angle + s)) * 5,
        color: color,
        width: width,
      );
    }
  }

  Offset world(V3 p) => Offset(180 + p.x * 350, 145 - p.y * 350);
  V3 inverse(Offset p) => V3((p.dx - 180) / 350, (145 - p.dy) / 350);
  Offset terminal(CircuitPart p, bool a) =>
      Offset(28 + p.x * 304 + (a ? -23 : 23), 52 + p.y * 165);
  void wire(
    Canvas c,
    List<Offset> points, {
    Color color = copper,
    double width = 3,
  }) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    c.drawPath(
      path.shift(const Offset(1, 2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width + 2
        ..color = Colors.black.withValues(alpha: .12)
        ..strokeJoin = StrokeJoin.round,
    );
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color
        ..strokeJoin = StrokeJoin.round,
    );
    c.drawPath(
      path.shift(const Offset(0, -.7)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7
        ..color = const Color(0xfff5bb7c),
    );
  }

  void support(
    Canvas c,
    Offset centre, {
    double radius = 13,
    Color color = amber,
    String sign = '',
  }) {
    LabMaterials.shadow(
      c,
      Rect.fromCenter(center: Offset(centre.dx, 224), width: 42, height: 8),
    );
    LabMaterials.metal(c, Rect.fromLTWH(centre.dx - 18, 216, 36, 8));
    LabMaterials.metal(
      c,
      Rect.fromLTWH(
        centre.dx - 3,
        centre.dy + radius,
        6,
        214 - centre.dy - radius,
      ),
    );
    c.drawRect(
      Rect.fromLTWH(centre.dx - 5, centre.dy + radius + 3, 10, 12),
      Paint()..color = const Color(0xff768590),
    );
    LabMaterials.sphere(c, centre, radius, color);
    text(c, sign, centre - const Offset(4, 6), size: 12, color: Colors.white);
  }

  void battery(Canvas c, Offset centre, double voltage, {String unit = 'V'}) {
    LabMaterials.shadow(
      c,
      Rect.fromCenter(
        center: centre + const Offset(0, 22),
        width: 46,
        height: 8,
      ),
    );
    final r = Rect.fromCenter(center: centre, width: 42, height: 40);
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(4)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xff1d2c38), Color(0xff475c68), Color(0xff172b3a)],
        ).createShader(r),
    );
    LabMaterials.metal(
      c,
      Rect.fromLTWH(centre.dx - 26, centre.dy - 5, 7, 10),
      brass: true,
    );
    LabMaterials.metal(c, Rect.fromLTWH(centre.dx + 19, centre.dy - 5, 7, 10));
    text(
      c,
      unit == 'A'
          ? (voltage >= 0 ? 'I →' : 'I ←')
          : (voltage >= 0 ? '+       −' : '−       +'),
      centre + const Offset(-17, -17),
      color: Colors.white,
      size: 10,
    );
    text(
      c,
      '${emNumber(voltage)} $unit',
      centre + const Offset(-18, 3),
      color: Colors.white,
      size: 8,
    );
  }

  void resistor(
    Canvas c,
    Offset centre, {
    bool lamp = false,
    double power = 0,
  }) {
    if (lamp) {
      LabMaterials.metal(
        c,
        Rect.fromLTWH(centre.dx - 14, centre.dy + 13, 28, 7),
      );
      final bulb = Rect.fromCircle(center: centre, radius: 18);
      c.drawOval(
        bulb,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Color.lerp(
                const Color(0xfff8fbfd),
                const Color(0xffffd262),
                power / (power + .5),
              )!,
              const Color(0xffd5e2e5),
            ],
          ).createShader(bulb),
      );
      c.drawOval(
        bulb,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xff96afb9),
      );
      line(
        c,
        centre + const Offset(-6, 9),
        centre + const Offset(-4, -3),
        color: amber,
      );
      line(
        c,
        centre + const Offset(-4, -3),
        centre + const Offset(4, -3),
        color: amber,
      );
      line(
        c,
        centre + const Offset(4, -3),
        centre + const Offset(6, 9),
        color: amber,
      );
    } else {
      final r = Rect.fromCenter(center: centre, width: 34, height: 15);
      c.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(5)),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xffad8e58), Color(0xfff1dcb3), Color(0xffb09869)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(r),
      );
      for (final x in [-10.0, -4.0, 3.0, 11.0]) {
        line(
          c,
          centre + Offset(x, -6),
          centre + Offset(x, 6),
          color: x == 11 ? amber : navy,
          width: 2,
        );
      }
    }
  }

  void gauge(
    Canvas c,
    Offset centre,
    double value,
    String unit, {
    double fullScale = 1,
  }) {
    final r = Rect.fromCenter(center: centre, width: 74, height: 59);
    LabMaterials.shadow(c, r.shift(const Offset(1, 4)));
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(5)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xff50656d), Color(0xff172b39)],
        ).createShader(r),
    );
    c.drawRect(r.deflate(5), Paint()..color = const Color(0xfff5f3e8));
    final pivot = centre + const Offset(0, 16);
    for (int i = 0; i <= 10; i++) {
      final a = -math.pi + math.pi * i / 10;
      line(
        c,
        pivot + Offset(math.cos(a), math.sin(a)) * 22,
        pivot + Offset(math.cos(a), math.sin(a)) * 25,
        color: navy,
        width: .7,
      );
    }
    text(
      c,
      '±${emNumber(fullScale)} $unit FS',
      centre + const Offset(-30, 20),
      size: 6,
    );
    final angle = -math.pi / 2 + (value / fullScale).clamp(-1, 1) * 1.2;
    line(
      c,
      pivot,
      pivot + Offset(math.cos(angle), math.sin(angle)) * 24,
      color: blue,
      width: 1.5,
    );
    text(
      c,
      '${emNumber(value)} $unit',
      centre + const Offset(-29, -16),
      size: 7,
    );
  }

  void compass(Canvas c, Offset point, double? angle) {
    c.drawCircle(
      point,
      19,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xfffbfcf4), Color(0xffbdc9cc)],
        ).createShader(Rect.fromCircle(center: point, radius: 19)),
    );
    c.drawCircle(
      point,
      19,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xff536773),
    );
    if (angle != null) {
      final d = Offset(math.cos(angle), -math.sin(angle)) * 15;
      arrow(c, point - d, point + d, color: Colors.red, width: 2);
    }
    text(
      c,
      angle == null ? 'B=0' : 'N',
      point + const Offset(-3, -29),
      size: 8,
    );
  }

  void coil(Canvas c, Rect bounds, int n, {bool caption = true}) {
    final shown = math.min(32, math.max(4, n));
    LabMaterials.metal(
      c,
      Rect.fromLTWH(bounds.left - 4, bounds.top - 5, 7, bounds.height + 10),
    );
    LabMaterials.metal(
      c,
      Rect.fromLTWH(bounds.right - 3, bounds.top - 5, 7, bounds.height + 10),
    );
    for (int i = 0; i < shown; i++) {
      final x = bounds.left + i * bounds.width / (shown - 1),
          r = Rect.fromCenter(
            center: Offset(x, bounds.center.dy),
            width: 11,
            height: bounds.height,
          );
      c.drawOval(
        r.shift(const Offset(1, 1)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.8
          ..color = const Color(0xff763910),
      );
      c.drawOval(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..shader = const LinearGradient(
            colors: [Color(0xfff5c17d), Color(0xff9c4e24), Color(0xffd88d4c)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(r),
      );
    }
    if (caption) {
      text(
        c,
        '$n turns / $shown shown',
        Offset(bounds.left, bounds.bottom + 14),
        size: 8,
      );
    }
  }

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 360, size.height / 280);
    c.clipRect(const Rect.fromLTWH(0, 0, 360, 280));
    c.drawRect(
      const Rect.fromLTWH(0, 0, 360, 280),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xfffcfdff), Color(0xffeaf0f3)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(const Rect.fromLTWH(0, 0, 360, 280)),
    );
    if (kind == 0) {
      electroPair(c);
    } else if ([1, 2, 6, 8].contains(kind)) {
      fieldBoard(c);
    } else if (kind == 3) {
      currentLoop(c);
    } else if (kind == 4) {
      circuitBoard(c);
    } else if (kind == 5) {
      capacitors(c);
    } else if (kind == 7) {
      particle(c);
    } else if (kind == 9) {
      solenoid(c);
    } else if (kind == 10) {
      induction(c);
    } else {
      electromagnet(c);
    }
    if (run.invalid.isNotEmpty) {
      text(
        c,
        'Outside model / invalid wiring: read explanation below',
        const Offset(12, 263),
        color: Colors.red,
        size: 8,
      );
    }
    c.restore();
  }

  void electroPair(Canvas c) {
    LabMaterials.metal(c, const Rect.fromLTWH(22, 226, 316, 6));
    final scale = coulombScale,
        left = Offset(180 - v('distance') / 2 * scale, 123),
        right = Offset(180 + v('distance') / 2 * scale, 123);
    support(
      c,
      left,
      radius: 20,
      color: v('q1') >= 0 ? const Color(0xffbc605c) : blue,
      sign: v('q1') == 0
          ? '0'
          : v('q1') > 0
          ? '+'
          : '−',
    );
    support(
      c,
      right,
      radius: 20,
      color: v('q2') >= 0 ? const Color(0xffbc605c) : blue,
      sign: v('q2') == 0
          ? '0'
          : v('q2') > 0
          ? '+'
          : '−',
    );
    text(c, '${emNumber(v('q1'))} C', left + const Offset(-30, 23), size: 8);
    text(c, '${emNumber(v('q2'))} C', right + const Offset(-30, 23), size: 8);
    line(c, Offset(left.dx, 185), Offset(right.dx, 185), color: teal);
    for (final x in [left.dx, right.dx]) {
      line(c, Offset(x, 180), Offset(x, 190), color: teal);
    }
    text(c, 'Centres ${emNumber(v('distance'))} m', Offset(110, 191), size: 9);
    if (overlays && q('force') > 0) {
      final pixelsPerNewton = math.min(50 / q('force'), 20000.0),
          delta = q('fx') * pixelsPerNewton;
      arrow(c, right + const Offset(0, -25), right + Offset(delta, -25));
      arrow(c, left + const Offset(0, -25), left + Offset(-delta, -25));
      text(
        c,
        'Force scale ${emNumber(pixelsPerNewton)} px/N',
        const Offset(12, 244),
        size: 8,
      );
    }
    text(
      c,
      'Point-source approximation · sphere size illustrative',
      const Offset(12, 15),
    );
  }

  void fieldBoard(Canvas c) {
    final board = const Rect.fromLTWH(20, 35, 320, 220);
    c.drawRRect(
      RRect.fromRectAndRadius(board, const Radius.circular(5)),
      Paint()..color = Colors.white.withValues(alpha: .7),
    );
    if (kind == 1 || kind == 2) {
      if (fieldLines && overlays) {
        if (kind == 2) {
          var path = _contourPaths[run.contours];
          if (path == null) {
            path = Path();
            for (final segment in run.contours) {
              final a = world(segment.$1), b = world(segment.$2);
              path.moveTo(a.dx, a.dy);
              path.lineTo(b.dx, b.dy);
            }
            if (_contourPaths.length >= 4) {
              _contourPaths.remove(_contourPaths.keys.first);
            }
            _contourPaths[run.contours] = path;
          }
          c.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeWidth = .8
              ..color = teal.withValues(alpha: .5),
          );
        } else {
          for (final path in run.lines) {
            drawTrace(c, path);
          }
        }
      }
      if (overlays && kind == 1) {
        for (final pair in run.arrows) {
          final a = world(pair.$1), b = pair.$2.unit;
          arrow(
            c,
            a,
            a + Offset(b.x, -b.y) * 10,
            color: blue.withValues(alpha: .4),
            width: .7,
          );
        }
      }
      for (final source in run.sources) {
        final point = world(source.position);
        c.drawCircle(
          point,
          .03 * 350,
          Paint()..color = Colors.grey.withValues(alpha: .15),
        );
        LabMaterials.sphere(
          c,
          point,
          7,
          source.charge >= 0 ? const Color(0xffc9665c) : blue,
        );
        text(
          c,
          source.charge == 0
              ? '0'
              : source.charge > 0
              ? '+'
              : '−',
          point - const Offset(3, 6),
          color: Colors.white,
          size: 10,
        );
      }
      final p = world(V3(v('probeX'), v('probeY')));
      LabMaterials.sphere(c, p, 4, amber);
      if (overlays && run.invalid.isEmpty && q('field') > 1e-15) {
        final e = V3(q('ex'), q('ey')).unit;
        arrow(c, p, p + Offset(e.x, -e.y) * 24);
        if (v('testCharge') != 0) {
          arrow(
            c,
            p + const Offset(0, 4),
            p +
                const Offset(0, 4) +
                Offset(e.x, -e.y) * v('testCharge').sign * 18,
            color: amber,
          );
        }
      }
      text(
        c,
        kind == 1
            ? 'E teal / F(test) amber: normalized directions; 12 seeds/source'
            : 'V contours (V) · zero at infinity · holes excluded',
        const Offset(12, 15),
        size: 8,
      );
    } else if (kind == 6) {
      c.drawCircle(
        world(V3.zero),
        .08 * 350,
        Paint()..color = Colors.grey.withValues(alpha: .12),
      );
      if (fieldLines && overlays) {
        for (final path in run.lines) {
          drawTrace(c, path);
        }
      }
      final nRight = v('moment') >= 0;
      final r = const Rect.fromLTWH(166, 137, 28, 16);
      c.drawRect(
        Rect.fromLTWH(r.left, r.top, 14, r.height),
        Paint()..color = nRight ? blue : const Color(0xffbd5654),
      );
      c.drawRect(
        Rect.fromLTWH(180, r.top, 14, r.height),
        Paint()..color = nRight ? const Color(0xffbd5654) : blue,
      );
      text(
        c,
        nRight ? 'S  N' : 'N  S',
        const Offset(168, 140),
        size: 7,
        color: Colors.white,
      );
      compass(
        c,
        world(V3(v('probeX'), v('probeY'))),
        q('field') > 0 ? run.state['compass'] : null,
      );
      text(
        c,
        'Exterior dipole segments · r < 0.08 m excluded',
        const Offset(12, 15),
        size: 8,
      );
      text(
        c,
        'Lines close through source region (not solved here)',
        const Offset(12, 257),
        size: 8,
      );
    } else {
      final centre = world(V3.zero);
      LabMaterials.sphere(c, centre, 5, copper);
      text(
        c,
        v('current') > 0
            ? '•'
            : v('current') < 0
            ? '×'
            : '0',
        centre - const Offset(3, 6),
        size: 10,
        color: Colors.white,
      );
      if (overlays) {
        for (final r in [.05, .1, .15, .2]) {
          c.drawCircle(
            centre,
            r * 350,
            Paint()
              ..style = PaintingStyle.stroke
              ..color = teal.withValues(alpha: .45),
          );
          if (v('current') != 0) {
            for (int i = 0; i < 4; i++) {
              final a = i * math.pi / 2,
                  p = centre + Offset(math.cos(a), -math.sin(a)) * r * 350,
                  b = V3(-math.sin(a), math.cos(a)) * v('current').sign;
              arrow(c, p, p + Offset(b.x, -b.y) * 9, color: teal, width: 1);
            }
          }
        }
      }
      compass(
        c,
        world(V3(v('probeX'), v('probeY'))),
        q('field') > 0 ? run.state['compass'] : null,
      );
      text(
        c,
        'Infinite exterior wire · +I out of board • · −I into ×',
        const Offset(12, 15),
        size: 8,
      );
    }
    text(
      c,
      'Board spans x ±0.45 m · +y up · probe via drag / numbers',
      const Offset(12, 272),
      size: 8,
    );
  }

  static final _tracePaths = <List<V3>, Path>{};
  static final _contourPaths = <List<(V3, V3)>, Path>{};
  void drawTrace(Canvas c, List<V3> points) {
    if (points.length < 2) return;
    var path = _tracePaths[points];
    if (path == null) {
      path = Path()..moveTo(world(points.first).dx, world(points.first).dy);
      for (final p in points.skip(1)) {
        path.lineTo(world(p).dx, world(p).dy);
      }
      if (_tracePaths.length >= 80) _tracePaths.remove(_tracePaths.keys.first);
      _tracePaths[points] = path;
    }
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .9
        ..color = teal.withValues(alpha: .65),
    );
    for (int i = 25; i < points.length; i += 70) {
      arrow(c, world(points[i - 2]), world(points[i]), color: teal, width: 1);
    }
  }

  void currentLoop(Canvas c) {
    const a = Offset(62, 98), r = Offset(235, 98);
    wire(c, [
      const Offset(39, 98),
      const Offset(39, 198),
      const Offset(298, 198),
      const Offset(298, 98),
      r,
    ]);
    wire(c, [const Offset(85, 98), const Offset(139, 98)]);
    wire(c, [const Offset(170, 98), r]);
    battery(c, a, v('voltage'));
    resistor(c, r);
    LabMaterials.metal(c, const Rect.fromLTWH(138, 92, 5, 12));
    LabMaterials.metal(c, const Rect.fromLTWH(168, 92, 5, 12));
    line(
      c,
      const Offset(141, 98),
      v('closed') > 0 ? const Offset(170, 98) : const Offset(167, 78),
      color: navy,
      width: 3,
    );
    gauge(
      c,
      const Offset(176, 198),
      q('current'),
      'A',
      fullScale: math.max(1, q('current').abs()),
    );
    if (overlays && q('current') != 0) {
      final sign = q('current').sign;
      arrow(
        c,
        const Offset(248, 179),
        Offset(248 + sign * 24, 179),
        color: teal,
      );
      text(c, 'I conventional', const Offset(238, 158), size: 8);
    }
    if (electrons && q('current') != 0) {
      final inset = const Rect.fromLTWH(88, 125, 200, 15);
      c.drawRRect(
        RRect.fromRectAndRadius(inset, const Radius.circular(6)),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xfff1bf85), Color(0xff9a542f), Color(0xffd99753)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(inset),
      );
      text(c, 'Copper-conductor drift inset', const Offset(100, 146), size: 7);
      for (int i = 0; i < 9; i++) {
        final f = (i / 9 + q('drift') * run.time * 10000 / 1.4) % 1;
        LabMaterials.sphere(c, Offset(93 + f * 190, 132), 2.7, blue);
      }
      text(
        c,
        'Electron drift: displacement ×10000 · size/count illustrative',
        const Offset(12, 244),
        size: 8,
      );
    }
    text(
      c,
      'Ideal DC loop · switch sets conduction state',
      const Offset(12, 15),
    );
    text(
      c,
      'Q = ${emNumber(q('charge'))} C · P = ${emNumber(q('power'))} W',
      const Offset(12, 264),
      size: 8,
    );
  }

  void circuitBoard(Canvas c) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(12, 38, 336, 207),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0xffe0e8ed),
    );
    final all = {for (final p in run.circuit.parts) p.id: p};
    Offset? end(String t) {
      final pair = t.split(':');
      final p = all[pair.first];
      return p == null ? null : terminal(p, pair.last == 'a');
    }

    for (final w in run.circuit.wires) {
      final a = end(w[0]), b = end(w[1]);
      if (a != null && b != null) {
        wire(c, [
          a,
          Offset(a.dx, (a.dy + b.dy) / 2),
          Offset(b.dx, (a.dy + b.dy) / 2),
          b,
        ], width: 2);
      }
    }
    for (final p in run.circuit.parts) {
      final a = terminal(p, true), b = terminal(p, false), centre = (a + b) / 2;
      if (p.id == selected) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: centre, width: 64, height: 60),
            const Radius.circular(5),
          ),
          Paint()..color = blue.withValues(alpha: .1),
        );
      }
      line(c, a, b, color: copper, width: 2);
      switch (p.type) {
        case 'source':
          battery(c, centre, p.value);
        case 'resistor' || 'lamp':
          resistor(
            c,
            centre,
            lamp: p.type == 'lamp',
            power: run.network?.valid == true
                ? run.network!.powers[p.id] ?? 0
                : 0,
          );
        case 'switch':
          line(
            c,
            a + const Offset(4, 0),
            p.closed ? b - const Offset(4, 0) : centre + const Offset(12, -18),
            width: 3,
          );
        case 'ammeter' || 'voltmeter':
          c.drawCircle(centre, 15, Paint()..color = Colors.white);
          c.drawCircle(
            centre,
            15,
            Paint()
              ..style = PaintingStyle.stroke
              ..color = navy,
          );
          text(
            c,
            p.type == 'ammeter' ? 'A' : 'V',
            centre - const Offset(4, 7),
            size: 12,
          );
      }
      for (final point in [a, b]) {
        c.drawCircle(point, 3, Paint()..color = amber);
      }
      text(c, '${p.id} a→b', centre + const Offset(-23, 25), size: 7);
    }
    text(
      c,
      'Terminal graph · move parts without changing connections',
      const Offset(12, 15),
      size: 8,
    );
    text(
      c,
      'Gold terminals · lamp brightness P/(P+0.5 W), illustrative',
      const Offset(12, 255),
      size: 8,
    );
  }

  void capacitors(Canvas c) {
    final gap = run.mode >= 2 ? 22.0 : 12 + v('gap') * 12000;
    final centre = Offset(run.mode >= 2 ? 260 : 203, 145);
    final height = run.mode >= 2 ? 65.0 : 65 + math.sqrt(v('area')) * 350;
    final left = centre.dx - gap / 2, right = centre.dx + gap / 2;
    if (run.mode >= 2) {
      battery(c, const Offset(65, 145), v('voltage'));
      resistor(c, const Offset(170, 70));
      wire(c, [Offset(left, 145), Offset(left, 70), const Offset(187, 70)]);
      wire(c, [
        Offset(right, 145),
        Offset(right, 225),
        Offset(run.mode == 2 ? 88 : 120, 225),
      ]);
      if (run.mode == 2) {
        wire(c, [
          const Offset(42, 145),
          const Offset(42, 70),
          const Offset(153, 70),
        ]);
        wire(c, [const Offset(88, 145), const Offset(88, 225)]);
      } else {
        wire(c, [
          const Offset(153, 70),
          const Offset(120, 70),
          const Offset(120, 225),
        ]);
      }
      text(
        c,
        'τ=${emNumber(q('tau'))} s · ${run.mode == 2 ? 'source connected' : 'source disconnected'}',
        const Offset(12, 40),
        size: 8,
      );
    } else {
      battery(c, const Offset(64, 145), v('voltage'));
      final colour = run.mode == 1 ? Colors.grey : copper;
      wire(c, [
        const Offset(41, 145),
        const Offset(41, 75),
        Offset(left, 75),
        Offset(left, 145),
      ], color: colour);
      wire(c, [
        const Offset(87, 145),
        const Offset(87, 225),
        Offset(right, 225),
        Offset(right, 145),
      ], color: colour);
      if (run.mode == 1) {
        // Both supply leads are disconnected; retained plate charge is explicit.
        for (final x in [left, right]) {
          line(
            c,
            Offset(x, run.mode == 1 && x == left ? 75 : 225),
            Offset(x, run.mode == 1 && x == left ? 75 : 225) +
                const Offset(0, 8),
            color: Colors.white,
            width: 6,
          );
        }
      }
    }
    for (final sign in [-1, 1]) {
      final x = centre.dx + sign * gap / 2;
      LabMaterials.metal(
        c,
        Rect.fromLTWH(x - 4, centre.dy - height / 2, 8, height),
      );
      text(
        c,
        sign < 0 ? '+' : '−',
        Offset(x - 3, centre.dy - height / 2 - 16),
        color: blue,
        size: 12,
      );
    }
    c.drawRect(
      Rect.fromCenter(center: centre, width: gap - 8, height: height - 8),
      Paint()
        ..color = teal.withValues(
          alpha: run.mode < 2 ? .1 + .03 * v('epsilonR') : .12,
        ),
    );
    if (overlays && q('voltage') != 0) {
      for (int j = -2; j <= 2; j++) {
        final y = centre.dy + j * height / 7;
        arrow(
          c,
          Offset(centre.dx - gap / 2 + 6, y),
          Offset(centre.dx + gap / 2 - 6, y),
          color: teal,
          width: 1,
        );
      }
    }
    text(
      c,
      run.mode == 0
          ? 'Connected: voltage fixed'
          : run.mode == 1
          ? 'Isolated: Q held; gap change may do mechanical work'
          : 'RC analytic charging/discharging; finite R',
      const Offset(12, 15),
      size: 8,
    );
    text(
      c,
      'Plate gap/area exaggerated · no fringing solution',
      const Offset(12, 264),
      size: 8,
    );
  }

  void particle(Canvas c) {
    final points = [V3.zero, ...run.trail, run.position];
    V3 rotate(V3 p) {
      final x = p.x * math.cos(azimuth) - p.y * math.sin(azimuth),
          y = p.x * math.sin(azimuth) + p.y * math.cos(azimuth);
      return V3(x, y * math.cos(elevation) - p.z * math.sin(elevation));
    }

    final transformed = points.map(rotate).toList();
    double extent = .02;
    for (final p in transformed) {
      extent = math.max(extent, math.max(p.x.abs(), p.y.abs()));
    }
    final scale = math.min(1800.0, 105 / extent);
    Offset screen(V3 p) {
      final r = rotate(p);
      return Offset(180 + r.x * scale, 144 - r.y * scale);
    }

    if (overlays) {
      for (final axis in [
        const V3(.04, 0),
        const V3(0, .04),
        const V3(0, 0, .04),
      ]) {
        arrow(c, screen(V3.zero), screen(axis), color: Colors.grey);
      }
      for (final (index, axis) in [
        const V3(.04, 0),
        const V3(0, .04),
        const V3(0, 0, .04),
      ].indexed) {
        text(c, ['x', 'y', 'z'][index], screen(axis), size: 8);
      }
    }
    if (run.trail.length > 1) {
      final path = Path()
        ..moveTo(screen(run.trail.first).dx, screen(run.trail.first).dy);
      for (final p in run.trail.skip(1)) {
        path.lineTo(screen(p).dx, screen(p).dy);
      }
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = blue,
      );
    }
    final point = screen(run.position);
    LabMaterials.sphere(
      c,
      point,
      6,
      v('charge') >= 0 ? const Color(0xffca625e) : blue,
    );
    if (overlays) {
      final vel = run.velocity.unit, force = V3(q('fx'), q('fy'), q('fz')).unit;
      arrow(
        c,
        point,
        point + (screen(vel * .02) - screen(V3.zero)),
        color: teal,
      );
      if (q('force') > 0) {
        arrow(
          c,
          point,
          point + (screen(force * .02) - screen(V3.zero)),
          color: amber,
        );
      }
    }
    text(c, '3-D projection · B along signed z · E=0', const Offset(12, 15));
    text(
      c,
      'Auto-fit ${emNumber(scale)} px/m · particle size exaggerated',
      const Offset(12, 244),
      size: 8,
    );
    text(
      c,
      'v teal / F amber: unit-direction glyphs · t=${emNumber(run.time)} s',
      const Offset(12, 263),
      size: 8,
    );
  }

  void solenoid(Canvas c) {
    final scale = solenoidScale;
    final length = v('length') * scale,
        radius = v('radius') * scale,
        bounds = Rect.fromCenter(
          center: const Offset(180, 135),
          width: length,
          height: radius * 2,
        );
    for (final x in [bounds.left + length * .2, bounds.right - length * .2]) {
      LabMaterials.metal(
        c,
        Rect.fromLTWH(
          x - 4,
          bounds.bottom + 3,
          8,
          math.max(2, 230 - bounds.bottom - 3),
        ),
      );
      LabMaterials.metal(c, Rect.fromLTWH(x - 12, 230, 24, 5));
    }
    coil(c, bounds, v('turns').round());
    final x = 180 + v('probe') * scale;
    if (overlays) {
      line(
        c,
        const Offset(24, 135),
        const Offset(336, 135),
        color: Colors.grey,
        width: .7,
      );
      if (q('field') != 0) {
        arrow(
          c,
          Offset(x, 135),
          Offset(x + q('field').sign * 28, 135),
          color: teal,
        );
      }
      LabMaterials.sphere(c, Offset(x, 135), 3, amber);
    }
    text(
      c,
      'Finite air-core solenoid · on-axis field only',
      const Offset(12, 15),
    );
    text(
      c,
      'L=${emNumber(v('length'))} m · R=${emNumber(v('radius'))} m',
      const Offset(12, 38),
      size: 8,
    );
    text(
      c,
      'Scale ${emNumber(scale)} px/m · ${x < 24 || x > 336 ? 'probe outside view' : 'probe x=${emNumber(v('probe'))} m'}',
      const Offset(12, 264),
      size: 8,
    );
  }

  void induction(Canvas c) {
    final z = q('position'), y = 145 - z * 260;
    wire(c, [
      const Offset(125, 163),
      const Offset(65, 163),
      const Offset(65, 228),
      const Offset(275, 228),
      const Offset(275, 167),
    ]);
    c.save();
    c.translate(129, 145);
    c.rotate(math.pi / 2);
    coil(
      c,
      Rect.fromCenter(
        center: Offset.zero,
        width: 30,
        height: 2 * v('radius') * 700,
      ),
      v('turns').round(),
      caption: false,
    );
    c.restore();
    text(
      c,
      '${v('turns').round()} turns · R=${emNumber(v('radius'))} m',
      const Offset(12, 237),
      size: 8,
    );
    c.drawRect(
      Rect.fromLTWH(
        129 - v('sourceRadius') * 700,
        y - 33,
        2 * v('sourceRadius') * 700,
        66,
      ),
      Paint()..color = blue,
    );
    c.drawRect(
      Rect.fromLTWH(
        129 - v('sourceRadius') * 700,
        y - 33,
        2 * v('sourceRadius') * 700,
        33,
      ),
      Paint()..color = const Color(0xffc2645b),
    );
    text(
      c,
      v('moment') >= 0 ? 'N' : 'S',
      Offset(124, y - 28),
      color: Colors.white,
    );
    text(
      c,
      v('moment') >= 0 ? 'S' : 'N',
      Offset(124, y + 16),
      color: Colors.white,
    );
    gauge(
      c,
      const Offset(276, 146),
      v('closed') > 0 ? q('current') : q('emf'),
      v('closed') > 0 ? 'A' : 'V',
      fullScale: v('closed') > 0 ? .001 : .05,
    );
    text(
      c,
      v('closed') > 0 ? 'Closed ε/R; L neglected' : 'Open circuit: EMF only',
      const Offset(210, 195),
      size: 7,
    );
    if (overlays && v('velocity') != 0) {
      arrow(
        c,
        Offset(161, y),
        Offset(161, y - v('velocity').sign * 25),
        color: teal,
      );
    }
    text(
      c,
      'Equivalent finite-loop magnetic source · coaxial passage',
      const Offset(12, 15),
      size: 8,
    );
    text(
      c,
      'Actual loop flux · normal +z · meter scale clips at ±FS',
      const Offset(12, 254),
      size: 8,
    );
  }

  void electromagnet(Canvas c) {
    final gap = 8 + v('gap') * 1200;
    final thickness = math.sqrt(v('area')) * 900;
    LabMaterials.metal(
      c,
      Rect.fromLTWH(138 - thickness / 2, 65, thickness, 132),
    );
    LabMaterials.metal(
      c,
      Rect.fromLTWH(
        138 - thickness / 2,
        65 - thickness,
        76 + thickness,
        thickness,
      ),
    );
    LabMaterials.metal(
      c,
      Rect.fromLTWH(214 - thickness / 2, 65, thickness, 132 + gap + thickness),
    );
    coil(c, const Rect.fromLTWH(103, 88, 70, 78), v('turns').round());
    LabMaterials.metal(
      c,
      Rect.fromLTWH(138 - thickness / 2, 197 + gap, 76 + thickness, thickness),
    );
    line(c, Offset(189, 197), Offset(189, 197 + gap), color: teal);
    text(c, 'g=${emNumber(v('gap'))} m', Offset(196, 197 + gap / 2), size: 8);
    battery(c, const Offset(274, 119), v('current'), unit: 'A');
    text(
      c,
      'Current drive ${emNumber(v('current'))} A',
      const Offset(220, 155),
      size: 7,
    );
    wire(c, [
      const Offset(247, 119),
      const Offset(196, 119),
      const Offset(173, 99),
    ]);
    wire(c, [
      const Offset(301, 119),
      const Offset(316, 194),
      const Offset(103, 194),
      const Offset(103, 163),
    ]);
    text(
      c,
      run.mode == 1 ? 'Air core μr=1' : 'Educational linear core · |B|≤0.3 T',
      const Offset(12, 15),
      size: 8,
    );
    text(
      c,
      'Closed return path · armature held at g (exaggerated)',
      const Offset(12, 246),
      size: 8,
    );
    text(
      c,
      'Ideal F=${emNumber(q('force'))} N / load W=${emNumber(q('weight'))} N',
      const Offset(12, 264),
      size: 8,
    );
  }
}
