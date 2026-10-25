import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/physics/waves_optics.dart';
import '../../core/physics/dynamics.dart' show Vec2;
import '../../core/rendering/apparatus.dart';
import '../../core/rendering/materials.dart';
import '../dynamics/scene.dart' show DynamicsPainter;

Color wavelengthColor(double meters) {
  final nm = meters * 1e9;
  return nm < 440
      ? Color.lerp(
          const Color(0xff6424cf),
          const Color(0xff2558e7),
          ((nm - 380) / 60).clamp(0, 1),
        )!
      : nm < 500
      ? Color.lerp(
          const Color(0xff2558e7),
          const Color(0xff00ad9b),
          (nm - 440) / 60,
        )!
      : nm < 580
      ? Color.lerp(
          const Color(0xff00ad9b),
          const Color(0xffe5b127),
          (nm - 500) / 80,
        )!
      : nm < 650
      ? Color.lerp(
          const Color(0xffe5b127),
          const Color(0xffcf333c),
          (nm - 580) / 70,
        )!
      : const Color(0xffcf333c);
}

class WavePainter extends ScientificScene {
  final WaveOpticsRun run;
  final bool labels, overlays, comparison, intensity, microphone;
  const WavePainter(
    this.run, {
    this.labels = true,
    this.overlays = true,
    this.comparison = false,
    this.intensity = false,
    this.microphone = false,
  });
  static const tool = DynamicsPainter(kind: 0, s: {}, p: {}, samples: []);
  int get kind => run.kind;
  WaveState get s => run.state;
  double q(String k) => s[k] ?? 0;
  double v(String k, [double fallback = 0]) => run.p[k] ?? fallback;
  @override
  String get accessibleSummary =>
      'Computed apparatus ${run.kind}; physical time ${run.time} seconds. ${s.entries.map((x) => '${x.key}: ${x.value}').join('; ')}';
  @override
  bool shouldRepaint(covariant WavePainter old) => true;
  static const blue = Color(0xff245ce7),
      teal = Color(0xff008e95),
      amber = Color(0xffcf9b2b),
      navy = Color(0xff173458);
  void text(
    Canvas c,
    String str,
    Offset p, {
    Color color = navy,
    double size = 10,
  }) {
    if (labels) tool.text(c, str, p, color: color, font: size);
  }

  void line(
    Canvas c,
    Offset a,
    Offset b, {
    Color color = navy,
    double width = 1.5,
    bool dashed = false,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width;
    if (!dashed) {
      c.drawLine(a, b, paint);
      return;
    }
    final d = b - a;
    if (d.distance < .01) return;
    for (double t = 0; t < d.distance; t += 8) {
      c.drawLine(
        a + d * (t / d.distance),
        a + d * (math.min(t + 4, d.distance) / d.distance),
        paint,
      );
    }
  }

  void ray(Canvas c, Offset a, Offset b, Color color, {bool dashed = false}) {
    line(c, a, b, color: color, dashed: dashed, width: 1.4);
    if (!dashed) {
      final middle = a + (b - a) * .6, ang = (b - a).direction;
      line(
        c,
        middle,
        middle - Offset(math.cos(ang - .5), math.sin(ang - .5)) * 6,
        color: color,
      );
      line(
        c,
        middle,
        middle - Offset(math.cos(ang + .5), math.sin(ang + .5)) * 6,
        color: color,
      );
    }
  }

  double get imagingExtent =>
      [.4, v('u'), v('screen'), 4 * v('focal')].reduce(math.max);
  Map<String, double> interaction(Offset at) => switch (kind) {
    0 => {'probe': (at.dx - 30) / 150},
    1 => {'probe': (at.dx - 30) / 150 - 1},
    2 => {'probe': (at.dx - 30) / 150 - 1, 'z': (.5 - (at.dy - 70) / 150)},
    3 => {'probe': (at.dx - 30) / 300 * v('length')},
    4 => {'frequency': 100 + (at.dx - 30) / 300 * 1900},
    5 => {
      'observer':
          (at.dx - 180) /
          (140 /
              (math.max(
                240.0,
                math.max(q('sourceX').abs(), v('observer').abs()) + 100,
              ))),
    },
    6 || 7 => {
      'angle':
          math.atan2(
            (180 + v('hit') * 250 - at.dx).abs(),
            (150 - at.dy).abs(),
          ) *
          180 /
          math.pi,
    },
    8 || 9 => {'u': (160 - at.dx) / (140 / imagingExtent)},
    _ => {'probe': (at.dy - 142.5) / 88.5 * .03},
  };
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.clipRect(Offset.zero & size);
    final scale = math.min(size.width / 360, size.height / 270);
    c.translate(
      (size.width - 360 * scale) / 2,
      (size.height - 270 * scale) / 2,
    );
    c.scale(scale);
    c.drawRect(
      const Rect.fromLTWH(0, 0, 360, 270),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xfffcfdfe), Color(0xffe5ecf1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(const Rect.fromLTWH(0, 0, 360, 270)),
    );
    if (kind == 0 || kind == 2) {
      tank(c);
    } else if (kind == 1 || kind == 3) {
      string(c);
    } else if (kind == 4) {
      sound(c);
    } else if (kind == 5) {
      dopplerScene(c);
    } else if (kind == 6 || kind == 7) {
      boundary(c);
    } else if (kind == 8 || kind == 9) {
      imaging(c);
    } else {
      slits(c);
    }
    c.restore();
  }

  void tank(Canvas c) {
    const tank = Rect.fromLTWH(30, 70, 300, 150);
    LabMaterials.shadow(c, const Rect.fromLTWH(24, 232, 312, 10));
    LabMaterials.metal(c, const Rect.fromLTWH(20, 224, 320, 12));
    c.drawRect(
      tank,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xffb3e0e9), Color(0xff78b9cf)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(tank),
    );
    c.save();
    c.clipRect(tank);
    if (kind == 2) {
      final values = intensity ? run.intensityGrid : run.grid,
          limit = v('amplitude') * (1 + v('ratio'));
      final paint = Paint();
      for (int j = 0; j < 32; j++) {
        for (int i = 0; i < 64; i++) {
          final n = values.isEmpty ? 0.0 : values[j * 64 + i],
              fraction = intensity
                  ? n
                  : ((n / limit + 1) / 2).clamp(0, 1).toDouble();
          paint.color = intensity
              ? Color.lerp(const Color(0xffe9f2f5), teal, fraction)!
              : fraction < .5
              ? Color.lerp(
                  const Color(0xff164a7a),
                  const Color(0xff82c4da),
                  fraction * 2,
                )!
              : Color.lerp(
                  const Color(0xff82c4da),
                  const Color(0xffeefbff),
                  fraction * 2 - 1,
                )!;
          c.drawRect(
            Rect.fromLTWH(
              tank.left + i * tank.width / 64,
              tank.top + j * tank.height / 32,
              tank.width / 64 + .2,
              tank.height / 32 + .2,
            ),
            paint,
          );
        }
      }
    } else {
      for (int j = 0; j < 10; j++) {
        final path = Path();
        for (int i = 0; i < run.profile.length; i++) {
          final p = run.profile[i],
              x = 30 + p['t']! * 150,
              y = 82 + j * 13 - (p['sum'] ?? 0) * 500;
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        c.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = j.isEven ? 1.8 : 1
            ..color = (j.isEven ? Colors.white : teal).withValues(alpha: .65),
        );
      }
    }
    c.restore();
    // Transparent front and side walls; their edges are independent of the wave field.
    c.drawRect(
      const Rect.fromLTWH(28, 208, 304, 17),
      Paint()..color = const Color(0x468bd4e6),
    );
    for (final x in [28.0, 332.0]) {
      line(
        c,
        Offset(x, 67),
        Offset(x, 225),
        color: const Color(0xff5994aa),
        width: 2,
      );
      line(
        c,
        Offset(x + 2, 68),
        Offset(x + 2, 221),
        color: Colors.white,
        width: 1,
      );
    }
    line(
      c,
      const Offset(28, 70),
      const Offset(332, 70),
      color: const Color(0xff6b9eac),
    );
    line(
      c,
      const Offset(28, 225),
      const Offset(332, 225),
      color: const Color(0xff477d96),
      width: 2,
    );
    if (kind == 2) {
      for (final sign in [-1, 1]) {
        final x = 180 + sign * v('spacing') / 2 * 150;
        LabMaterials.metal(c, Rect.fromLTWH(x - 8, 42, 16, 12));
        line(c, Offset(x, 54), Offset(x, 145), color: navy, width: 2);
        LabMaterials.sphere(c, Offset(x, 145), 3, amber);
      }
      final point = Offset(180 + v('probe') * 150, 70 + (.5 - v('z')) * 150);
      if (overlays) {
        line(
          c,
          point - const Offset(7, 0),
          point + const Offset(7, 0),
          color: amber,
        );
        line(
          c,
          point - const Offset(0, 7),
          point + const Offset(0, 7),
          color: amber,
        );
      }
      text(
        c,
        intensity
            ? 'Normalized mean squared displacement'
            : 'Instantaneous signed displacement (not intensity)',
        const Offset(12, 15),
        size: 9,
      );
    } else {
      LabMaterials.metal(c, const Rect.fromLTWH(30, 42, 32, 17));
      line(
        c,
        const Offset(46, 59),
        Offset(
          46,
          130 -
              harmonic(
                    0,
                    (s['t'] ?? run.time),
                    v('amplitude'),
                    v('frequency'),
                    v('wavelength'),
                    v('phase'),
                    run.mode == 0 ? 1 : -1,
                  ) *
                  500,
        ),
        width: 3,
      );
      final point = Offset(30 + v('probe') * 150, 145 - q('sum') * 500);
      if (overlays) {
        line(
          c,
          Offset(point.dx, 75),
          Offset(point.dx, 207),
          color: amber,
          width: 1,
        );
        LabMaterials.sphere(c, point, 4, amber);
      }
      text(
        c,
        'Analytic height field · local probe x is fixed',
        const Offset(12, 15),
        size: 9,
      );
    }
    text(
      c,
      'Top view · 2 m span · height/color exaggerated',
      const Offset(15, 248),
      size: 9,
    );
  }

  void string(Canvas c) {
    final extent = kind == 3 ? v('length') : 2.0,
        offset = kind == 1 ? -1.0 : 0.0,
        maxAmplitude = kind == 1
            ? v('a1').abs() + v('a2').abs()
            : v('amplitude'),
        heightScale = math.min(2000.0, 65 / math.max(.001, maxAmplitude));
    Offset at(WaveState p, String key) => Offset(
      30 + (p['t']! - offset) / extent * 300,
      150 - (p[key] ?? 0) * heightScale,
    );
    LabMaterials.metal(c, const Rect.fromLTWH(20, 230, 320, 8));
    if (kind == 3) {
      for (final x in [30.0, 330.0]) {
        LabMaterials.metal(c, Rect.fromLTWH(x - 7, 74, 14, 155));
        LabMaterials.screw(c, Offset(x, 150));
      }
    }
    for (final key in [
      if (comparison) 'first',
      if (comparison) 'second',
      'sum',
    ]) {
      final path = Path();
      for (int i = 0; i < run.profile.length; i++) {
        final p = at(run.profile[i], key);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = key == 'sum' ? 2.6 : 1.3
          ..color = key == 'sum'
              ? navy
              : key == 'first'
              ? blue
              : amber,
      );
    }
    if (overlays) {
      if (kind == 3) {
        final n = v('harmonic').toInt();
        for (int j = 0; j <= n; j++) {
          final x = 30 + 300 * j / n;
          c.drawCircle(Offset(x, 150), 3, Paint()..color = teal);
        }
        for (int j = 0; j < n; j++) {
          text(
            c,
            'A',
            Offset(30 + 300 * (j + .5) / n - 3, 92),
            color: amber,
            size: 9,
          );
        }
      }
      final x = 30 + (v('probe') - offset) / extent * 300;
      line(c, Offset(x, 87), Offset(x, 215), color: teal, width: .8);
      LabMaterials.sphere(c, Offset(x, 150 - q('sum') * heightScale), 4, amber);
    }
    text(
      c,
      kind == 3
          ? 'Fixed endpoints · n=${v('harmonic').toInt()} · nodes n+1'
          : 'Infinite-string window · pulses continue after overlap',
      const Offset(12, 15),
      size: 9,
    );
    text(
      c,
      'Displacement exaggerated · navy=sum${comparison ? ' · blue/amber=components' : ''}',
      const Offset(12, 250),
      size: 9,
    );
  }

  void sound(Canvas c) {
    LabMaterials.shadow(c, const Rect.fromLTWH(45, 229, 255, 11));
    LabMaterials.metal(c, const Rect.fromLTWH(65, 216, 86, 12));
    LabMaterials.metal(c, const Rect.fromLTWH(102, 123, 8, 94));
    c.save();
    c.translate(108, 105);
    c.rotate(-.25);
    final barrel = const Rect.fromLTWH(-13, -23, 65, 39);
    c.drawRRect(
      RRect.fromRectAndRadius(barrel, const Radius.circular(16)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xffdbe4e8), Color(0xff566977), Color(0xff142c3d)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(barrel),
    );
    for (int i = 0; i < 12; i++) {
      line(
        c,
        Offset(8 + i * 3, -18),
        Offset(8 + i * 3, 10),
        color: const Color(0xff2a404d),
        width: .8,
      );
    }
    for (int j = 0; j < 6; j++) {
      line(
        c,
        Offset(5, -17 + j * 5),
        Offset(45, -17 + j * 5),
        color: const Color(0xffedf2f4),
        width: .5,
      );
    }
    c.restore();
    LabMaterials.wood(c, const Rect.fromLTWH(235, 213, 60, 15));
    LabMaterials.metal(c, const Rect.fromLTWH(260, 152, 8, 61));
    final fork = Path()
      ..moveTo(245, 86)
      ..lineTo(245, 137)
      ..quadraticBezierTo(263, 169, 281, 137)
      ..lineTo(281, 86);
    c.drawPath(
      fork,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = const Color(0xffaebdc6),
    );
    c.drawPath(
      fork,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
    text(
      c,
      microphone
          ? 'Actual microphone input · no synthetic replacement'
          : 'Generated educational signal · no audio playback',
      const Offset(12, 17),
      size: 9,
    );
    text(
      c,
      'PCM full-scale / relative amplitude · not certified SPL',
      const Offset(12, 249),
      size: 9,
    );
  }

  void dopplerScene(Canvas c) {
    final extent = math.max(
          240.0,
          math.max(q('sourceX').abs(), v('observer').abs()) + 100,
        ),
        scale = 140 / extent;
    Offset at(double x) => Offset(180 + x * scale, 150);
    c.save();
    c.clipRect(const Rect.fromLTWH(12, 44, 336, 178));
    for (final front in run.fronts) {
      c.drawCircle(
        at(front['x']!),
        front['radius']! * scale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8
          ..color = blue.withValues(alpha: .4),
      );
    }
    c.restore();
    LabMaterials.metal(c, const Rect.fromLTWH(12, 181, 336, 7));
    final source = at(q('sourceX'));
    tool.cart(c, source + const Offset(0, 27), width: 38);
    LabMaterials.sphere(c, source, 7, blue);
    final observer = at(v('observer'));
    LabMaterials.metal(c, Rect.fromLTWH(observer.dx - 3, 150, 6, 31));
    LabMaterials.sphere(c, observer, 7, const Color(0xff728594));
    if (overlays) {
      final ret = at(q('retardedSourceX'));
      line(c, ret, observer, color: amber, dashed: true);
      c.drawCircle(ret, 3, Paint()..color = amber);
      text(
        c,
        'retarded source',
        ret - const Offset(35, 20),
        color: amber,
        size: 9,
      );
    }
    text(
      c,
      'Stationary observer · source/observer on the same axis',
      const Offset(12, 15),
      size: 9,
    );
    text(
      c,
      'Each circle uses its actual emission centre/time',
      const Offset(12, 233),
      size: 9,
    );
    text(
      c,
      'Displayed every ${q('frontStride').toInt()}th crest · view auto-fits',
      const Offset(12, 250),
      size: 9,
    );
  }

  void boundary(Canvas c) {
    Offset at(Vec2 p) => Offset(180 + p.x * 250, 150 - p.y * 180);
    final hit = Vec2(q('hitX'), 0),
        incoming = Vec2(q('ix'), q('iy')),
        origin = hit - incoming * .35,
        ref = Vec2(q('rx'), q('ry'));
    if (kind == 7) {
      c.drawRect(
        const Rect.fromLTWH(25, 150, 310, 90),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0x666eb9cc), Color(0x2296c9d8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(const Rect.fromLTWH(25, 150, 310, 90)),
      );
      line(
        c,
        const Offset(25, 150),
        const Offset(335, 150),
        color: teal,
        width: 2,
      );
    } else {
      LabMaterials.metal(c, const Rect.fromLTWH(25, 150, 310, 8));
      LabMaterials.metal(c, const Rect.fromLTWH(77, 158, 7, 63));
      LabMaterials.metal(c, const Rect.fromLTWH(275, 158, 7, 63));
    }
    LabMaterials.metal(c, const Rect.fromLTWH(25, 231, 310, 8));
    final o = at(origin), h = at(hit);
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate((h - o).direction);
    LabMaterials.metal(c, const Rect.fromLTWH(-31, -8, 31, 16));
    c.restore();
    if (overlays) {
      ray(c, o, h, blue);
      ray(c, h, at(hit + ref * .5), amber);
      line(
        c,
        at(hit + const Vec2(0, .55)),
        at(hit + const Vec2(0, -.45)),
        color: navy,
        dashed: true,
        width: .8,
      );
      if (kind == 7 && s.containsKey('tx')) {
        ray(c, h, at(hit + Vec2(q('tx'), q('ty')) * .48), teal);
      }
      text(c, 'Normal', h - const Offset(15, 100), size: 9);
      text(
        c,
        'θi ${v('angle').toStringAsFixed(1)}°',
        h + const Offset(-80, -32),
        color: blue,
      );
      text(
        c,
        'θr ${v('angle').toStringAsFixed(1)}°',
        h + const Offset(24, -32),
        color: amber,
      );
    }
    text(
      c,
      kind == 7
          ? 'n₁ ${v('n1')} → n₂ ${v('n2')} ${q('tir') == 1 ? '· TOTAL INTERNAL REFLECTION' : ''}'
          : 'Plane mirror · reflection at computed intersection',
      const Offset(12, 15),
      size: 9,
    );
    text(
      c,
      'Geometric ray overlays · not visible clear-air beams',
      const Offset(12, 251),
      size: 9,
    );
  }

  void imaging(Canvas c) {
    final extent = imagingExtent,
        scale = 140 / extent,
        yscale = 10 * scale,
        f = q('focal'),
        u = v('u'),
        height = v('height');
    Offset at(double x, double y) => Offset(160 + x * scale, 150 - y * yscale);
    LabMaterials.metal(c, const Rect.fromLTWH(12, 222, 336, 9));
    line(
      c,
      const Offset(15, 150),
      const Offset(345, 150),
      color: const Color(0xff8ca0b0),
      width: .7,
    );
    final device = at(0, 0);
    LabMaterials.metal(c, Rect.fromLTWH(device.dx - 4, 189, 8, 34));
    LabMaterials.metal(c, Rect.fromLTWH(device.dx - 18, 216, 36, 7));
    if (kind == 8) {
      final path = Path()..moveTo(device.dx, 94);
      if (run.mode == 0) {
        path.cubicTo(device.dx - 18, 120, device.dx - 18, 176, device.dx, 202);
        path.cubicTo(device.dx + 18, 176, device.dx + 18, 120, device.dx, 94);
      } else {
        path.lineTo(device.dx - 12, 94);
        path.quadraticBezierTo(device.dx + 3, 150, device.dx - 12, 202);
        path.lineTo(device.dx + 12, 202);
        path.quadraticBezierTo(device.dx - 3, 150, device.dx + 12, 94);
      }
      path.close();
      c.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0x4472bfd2), Color(0xcce2f7ff), Color(0x775e98b0)],
          ).createShader(const Rect.fromLTWH(140, 90, 40, 115)),
      );
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xff6598ac),
      );
    } else {
      final radius = 2 * f.abs(), path = Path();
      for (int i = 0; i <= 80; i++) {
        final y = (-1 + 2 * i / 80) * math.min(radius * .3, .05),
            x = f > 0
                ? -radius + math.sqrt(radius * radius - y * y)
                : radius - math.sqrt(radius * radius - y * y),
            p = at(x, y);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = const Color(0xff637a88),
      );
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xffedfaff),
      );
    }
    final object = at(-u, height), foot = at(-u, 0);
    ray(c, foot, object, blue);
    LabMaterials.metal(c, Rect.fromLTWH(foot.dx - 2, foot.dy, 4, 72));
    final imageDistance = s['imageDistance'], imageHeight = s['imageHeight'];
    if (overlays) {
      if (kind == 8) {
        final parallel = at(0, height);
        ray(c, object, parallel, amber);
        ray(c, parallel, at(extent, height - extent * height / f), amber);
        ray(c, object, at(extent, -extent * height / u), teal);
        if (imageDistance != null && imageDistance < 0) {
          ray(
            c,
            parallel,
            at(imageDistance, imageHeight!),
            amber,
            dashed: true,
          );
          ray(c, device, at(imageDistance, imageHeight), teal, dashed: true);
        }
      } else {
        final radius = 2 * f.abs(),
            hitX = f > 0
                ? -radius + math.sqrt(radius * radius - height * height)
                : radius - math.sqrt(radius * radius - height * height),
            centre = Vec2(f > 0 ? -radius : radius, 0),
            hit = Vec2(hitX, height),
            ref = reflected(const Vec2(1, 0), unit(hit - centre)),
            second = reflected(unit(Vec2(u, -height)), const Vec2(1, 0));
        ray(c, object, at(hit.x, hit.y), amber);
        ray(
          c,
          at(hit.x, hit.y),
          at(hit.x + ref.x * extent * 2, hit.y + ref.y * extent * 2),
          amber,
        );
        ray(c, object, device, teal);
        ray(c, device, at(second.x * extent * 2, second.y * extent * 2), teal);
        if (imageDistance != null && imageDistance < 0) {
          ray(c, device, at(-imageDistance, imageHeight!), teal, dashed: true);
          ray(
            c,
            at(hit.x, hit.y),
            at(-imageDistance, imageHeight),
            amber,
            dashed: true,
          );
        }
      }
      final imageX = kind == 8 ? (imageDistance ?? 0) : -(imageDistance ?? 0);
      if (imageDistance != null &&
          imageX.abs() < extent &&
          imageHeight!.abs() * yscale < 100) {
        ray(
          c,
          at(imageX, 0),
          at(imageX, imageHeight),
          teal,
          dashed: imageDistance < 0,
        );
        text(
          c,
          imageDistance > 0 ? 'Real image' : 'Virtual image',
          at(imageX, 0) + const Offset(-20, 10),
          color: teal,
          size: 9,
        );
      }
      for (final x in kind == 8 ? [-f, f] : [-f, -2 * f]) {
        final p = at(x, 0);
        c.drawCircle(p, 2.3, Paint()..color = navy);
        text(
          c,
          kind == 9 && x == -2 * f ? 'C' : 'F',
          p + const Offset(-3, 10),
          size: 9,
        );
      }
    }
    if (imageDistance != null && imageDistance > 0) {
      final x = at((kind == 8 ? 1 : -1) * v('screen'), 0).dx;
      line(
        c,
        Offset(x, 95),
        Offset(x, 204),
        color: const Color(0xff7c8c96),
        width: 4,
      );
      text(c, 'screen', Offset(x - 16, 207), size: 8);
      if (q('focusError') < .001) {
        text(c, 'In focus', Offset(x - 20, 81), color: teal, size: 9);
      }
    }
    text(
      c,
      kind == 8
          ? 'Thin lens · ${run.mode == 0 ? 'converging' : 'diverging'}'
          : 'Spherical mirror · ${run.mode == 0 ? 'concave' : 'convex'}',
      const Offset(12, 15),
      size: 9,
    );
    text(
      c,
      q('infinity') == 1
          ? 'Image at infinity · paraxial rays parallel'
          : '${s['imageType'] == 1 ? 'Real / inverted' : 'Virtual / upright'} · image may lie outside this view',
      const Offset(12, 36),
      size: 9,
    );
    text(
      c,
      'Paraxial image · vertical scale ×10 · paths instructional',
      const Offset(12, 250),
      size: 9,
    );
  }

  void slits(Canvas c) {
    final color = wavelengthColor(v('wavelength'));
    LabMaterials.shadow(c, const Rect.fromLTWH(21, 229, 317, 11));
    LabMaterials.metal(c, const Rect.fromLTWH(20, 230, 320, 8));
    LabMaterials.metal(c, const Rect.fromLTWH(34, 145, 6, 84));
    LabMaterials.metal(c, const Rect.fromLTWH(18, 124, 55, 20));
    final plate = const Rect.fromLTWH(122, 67, 10, 151);
    c.drawRect(
      plate,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xff2d414e), Color(0xff94a6b1), Color(0xff253944)],
        ).createShader(plate),
    );
    LabMaterials.metal(c, const Rect.fromLTWH(119, 214, 17, 16));
    for (final y in kind == 10 ? [143.0, 157.0] : [150.0]) {
      line(
        c,
        Offset(124, y - 3),
        Offset(130, y + 3),
        color: Colors.white,
        width: 1,
      );
    }
    final screen = const Rect.fromLTWH(298, 54, 29, 177);
    c.drawRect(screen, Paint()..color = const Color(0xff0c1b2e));
    final paint = Paint();
    for (int i = 0; i < run.profile.length; i++) {
      final entry = run.profile[i];
      paint.color = Color.lerp(
        const Color(0xff0b1625),
        color,
        entry['intensity']!,
      )!;
      c.drawRect(
        Rect.fromLTWH(
          screen.left + 2,
          screen.top + screen.height * i / run.profile.length,
          screen.width - 4,
          screen.height / run.profile.length + .1,
        ),
        paint,
      );
    }
    if (overlays) {
      ray(c, const Offset(73, 134), const Offset(123, 150), color);
      for (final y in [70.0, 150.0, 220.0]) {
        ray(
          c,
          const Offset(132, 150),
          Offset(298, y),
          color.withValues(alpha: .35),
        );
      }
      final detectorY = screen.center.dy + v('probe') / .03 * screen.height / 2;
      line(
        c,
        Offset(291, detectorY),
        Offset(334, detectorY),
        color: teal,
        width: 1.4,
      );
      if (kind == 11) {
        for (int order = -4; order <= 4; order++) {
          final y = diffractionMinimum(
            v('wavelength'),
            v('aperture'),
            v('screen'),
            order,
          );
          if (y != null && y.abs() <= .03) {
            final pixel = screen.center.dy + y / .03 * screen.height / 2;
            line(
              c,
              Offset(327, pixel),
              Offset(333, pixel),
              color: amber,
              width: 1,
            );
          }
        }
      }
    }
    text(
      c,
      kind == 10
          ? 'Ideal narrow double slit · Fraunhofer'
          : 'Single slit · Fraunhofer sinc²',
      const Offset(12, 15),
      size: 9,
    );
    text(
      c,
      'Physical brightness uses the same I(y) as the graph',
      const Offset(12, 36),
      size: 9,
    );
    text(
      c,
      'Slits/paths enlarged · illustrative wavelength RGB',
      const Offset(12, 250),
      size: 9,
    );
  }
}
