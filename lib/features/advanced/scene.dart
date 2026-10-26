import 'dart:math' as math;

import '../../core/physics/plot_range.dart';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/physics/advanced.dart';
import '../../core/physics/dynamics.dart' show Vec2;
import '../../core/rendering/apparatus.dart';
import '../../core/rendering/materials.dart';
import '../dynamics/scene.dart';

class AdvancedPainter extends ScientificScene {
  final int kind;
  final LabState s, p;
  final List<LabState> samples;
  final bool labels, overlays, trails;
  final ui.Image? texture;
  const AdvancedPainter({
    required this.kind,
    required this.s,
    required this.p,
    required this.samples,
    this.labels = true,
    this.overlays = true,
    this.trails = true,
    this.texture,
  });
  static const tool = DynamicsPainter(kind: 0, s: {}, p: {}, samples: []);
  double q(String k) => s[k] ?? 0;
  double v(String k, [double fallback = 0]) => p[k] ?? fallback;
  @override
  String get accessibleSummary =>
      'Computed apparatus, model $kind; time ${q('t')} s. ${s.entries.map((e) => '${e.key} ${e.value}').join('; ')}';
  @override
  bool shouldRepaint(covariant AdvancedPainter old) => true;
  double get orbitExtent {
    if (kind == 11) return v('a') * (1 + v('e')) * earthRadius * 1.12;
    return math.max(
      earthRadius * 2.5,
      math.max(q('radius') * 1.15, v('r') * earthRadius * 1.2),
    );
  }

  double get oscillatorScale {
    if (kind == 17) {
      // Energy bound guarantees distinct masses and positive drawn spring lengths.
      final energy = q('total'),
          bound = math.sqrt(2 * energy / math.min(v('k'), v('k2')));
      return math.min(200, 34 / math.max(.05, bound));
    }
    final amplitude = math.max(
      .3,
      math.max(
        q('x').abs(),
        math.sqrt(
          v('x0') * v('x0') + v('m', 1) / v('k', 20) * v('v0') * v('v0'),
        ),
      ),
    );
    return math.min(210, 100 / amplitude);
  }

  Map<String, double> interaction(Offset point) {
    if (kind >= 6 && kind <= 10) {
      final d = point - const Offset(180, 142), scale = 126 / orbitExtent;
      return {
        'r': d.distance / scale / earthRadius,
        if (kind == 7 || kind == 8)
          'angle': math.atan2(-d.dy, d.dx) * 180 / math.pi,
      };
    }
    if (kind == 11) {
      return {
        'a':
            (point.dx - 180).abs() /
            126 *
            orbitExtent /
            earthRadius /
            (1 + v('e')),
      };
    }
    if (kind == 13) {
      final d = point - const Offset(180, 45);
      return {'angle': math.atan2(d.dx, d.dy) * 180 / math.pi};
    }
    if (kind >= 12) {
      return {'x0': (point.dx - (kind == 17 ? 123 : 200)) / oscillatorScale};
    }
    return switch (kind) {
      0 => {
        'angle': math.atan2(160 - point.dy, point.dx - 180) * 180 / math.pi,
        'force': (point - const Offset(180, 160)).distance / 3,
      },
      1 => {'speed': (point.dx - 180) / 12},
      2 || 4 => {'height': (218 - point.dy) / 80 * math.max(1, v('height'))},
      3 => {
        'x0':
            (point.dx - 180) /
            145 *
            math.max(2.6, math.max(q('x').abs(), v('x0').abs()) * 1.1),
      },
      _ => {'eta': ((point.dx - 40) / 280)},
    };
  }

  void text(
    Canvas c,
    String value,
    Offset p, {
    Color color = const Color(0xff173458),
    double size = 10,
  }) {
    if (labels) tool.text(c, value, p, color: color, font: size);
  }

  void beam(Canvas c, Rect r) => LabMaterials.metal(c, r);
  void load(Canvas c, Offset bottom, {double width = 35}) {
    LabMaterials.shadow(
      c,
      Rect.fromCenter(
        center: Offset(bottom.dx + 4, 218),
        width: width + 8,
        height: 7,
      ),
    );
    beam(c, Rect.fromLTWH(bottom.dx - width / 2, bottom.dy - 36, width, 36));
    c.drawArc(
      Rect.fromCircle(center: bottom - const Offset(0, 39), radius: 4),
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xff354b5d),
    );
  }

  void pulley(Canvas c, Offset at, double angle) {
    LabMaterials.sphere(c, at, 16, const Color(0xff82909a));
    c.drawCircle(
      at,
      12,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xff334957),
    );
    for (int i = 0; i < 4; i++) {
      final a = angle + i * math.pi / 2;
      c.drawLine(
        at,
        at + Offset(math.cos(a), math.sin(a)) * 11,
        Paint()
          ..color = const Color(0xffa5b3ba)
          ..strokeWidth = 2,
      );
    }
    LabMaterials.screw(c, at);
  }

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
    const blue = Color(0xff245ce7),
        teal = Color(0xff008e95),
        amber = Color(0xffd39b30);
    final celestial = kind >= 6 && kind <= 11;
    c.drawRect(
      const Rect.fromLTWH(0, 0, 360, 270),
      Paint()
        ..shader = LinearGradient(
          colors: celestial
              ? const [Color(0xff07182d), Color(0xff102c48)]
              : const [Color(0xfff8fafc), Color(0xffe5eaed)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(const Rect.fromLTWH(0, 0, 360, 270)),
    );
    if (celestial) {
      for (int i = 0; i < 72; i++) {
        c.drawCircle(
          Offset((i * 71 % 349).toDouble() + 4, (i * 53 % 225).toDouble() + 18),
          i % 7 == 0 ? .8 : .4,
          Paint()
            ..color = Colors.white.withValues(alpha: i % 3 == 0 ? .6 : .25),
        );
      }
      final extent = orbitExtent, scale = 126 / extent;
      Offset point(double x, double y) =>
          Offset(180 + x * scale, 142 - y * scale);
      final planet = const Offset(180, 142),
          realRadius = kind == 6
              ? math.max(28.0, earthRadius * scale)
              : earthRadius * scale;
      // Force-comparison body sizes and satellite icons are explicitly illustrative.
      LabMaterials.sphere(c, planet, realRadius, blue, texture: texture);
      if (kind == 7 || kind == 8) {
        for (int ring = 1; ring <= 3; ring++) {
          final rr = (earthRadius * (1 + ring) * scale).clamp(
            realRadius + 3,
            120.0,
          );
          if (overlays) {
            c.drawCircle(
              planet,
              rr,
              Paint()
                ..style = PaintingStyle.stroke
                ..color = teal.withValues(alpha: .45)
                ..strokeWidth = .7,
            );
          }
          if (kind == 7 && overlays) {
            for (int j = 0; j < 10; j++) {
              final a = j * math.pi / 5,
                  xy = planet + Offset(math.cos(a), math.sin(a)) * rr;
              tool.arrow(
                c,
                xy,
                Vec2(-math.cos(a), math.sin(a)),
                teal,
                '',
                factor: 9,
              );
            }
          }
        }
      }
      if (kind == 11 && overlays) {
        final mu = earthMu * v('source'),
            a = v('a') * earthRadius,
            e = v('e'),
            period = 2 * math.pi * math.sqrt(a * a * a / mu),
            interval = period / 12;
        for (int j = 0; j < 2; j++) {
          final start = q('t') + j * period / 2,
              path = Path()..moveTo(planet.dx, planet.dy);
          for (int i = 0; i <= 30; i++) {
            final state = keplerAt(mu, a, e, start + interval * i / 30),
                xy = point(state['x']!, state['y']!);
            path.lineTo(xy.dx, xy.dy);
          }
          path.close();
          c.drawPath(
            path,
            Paint()..color = (j == 0 ? teal : amber).withValues(alpha: .22),
          );
        }
        final orbit = Path();
        for (int i = 0; i <= 160; i++) {
          final state = keplerAt(mu, a, e, period * i / 160),
              xy = point(state['x']!, state['y']!);
          if (i == 0) {
            orbit.moveTo(xy.dx, xy.dy);
          } else {
            orbit.lineTo(xy.dx, xy.dy);
          }
        }
        c.drawPath(
          orbit,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = Colors.white54,
        );
      }
      if (trails && samples.length > 1 && kind >= 9) {
        final path = Path();
        for (int i = 0; i < samples.length; i++) {
          final xy = point(samples[i]['x'] ?? 0, samples[i]['y'] ?? 0);
          if (i == 0) {
            path.moveTo(xy.dx, xy.dy);
          } else {
            path.lineTo(xy.dx, xy.dy);
          }
        }
        c.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..color = const Color(0xff6ec5f1),
        );
      }
      final probe = point(q('x'), q('y'));
      if (kind == 6) {
        LabMaterials.sphere(
          c,
          probe,
          math.max(5, realRadius * .273),
          const Color(0xffb2b4ad),
        );
        if (overlays) {
          tool.arrow(
            c,
            planet,
            const Vec2(1, 0),
            teal,
            labels ? 'F' : '',
            factor: 22,
          );
          tool.arrow(
            c,
            probe,
            const Vec2(-1, 0),
            amber,
            labels ? '−F' : '',
            factor: 22,
          );
        }
      } else {
        c.save();
        c.translate(probe.dx, probe.dy);
        c.rotate(math.atan2(-q('vy'), q('vx')));
        beam(c, const Rect.fromLTWH(-5, -5, 10, 10));
        c.drawRect(const Rect.fromLTWH(-18, -3, 11, 6), Paint()..color = blue);
        c.drawRect(const Rect.fromLTWH(7, -3, 11, 6), Paint()..color = blue);
        for (int i = 0; i < 3; i++) {
          c.drawLine(
            Offset(-17 + i * 3, -3),
            Offset(-17 + i * 3, 3),
            Paint()
              ..color = Colors.white54
              ..strokeWidth = .4,
          );
          c.drawLine(
            Offset(8 + i * 3, -3),
            Offset(8 + i * 3, 3),
            Paint()
              ..color = Colors.white54
              ..strokeWidth = .4,
          );
        }
        c.restore();
        if (overlays && kind == 7) {
          final d = planet - probe;
          tool.arrow(
            c,
            probe,
            Vec2(d.dx, -d.dy) * (1 / d.distance),
            teal,
            labels ? 'g (direction)' : '',
            factor: 24,
          );
        }
      }
      if (kind >= 9 && overlays && q('speed') > 0) {
        tool.arrow(
          c,
          probe,
          Vec2(q('vx'), q('vy')) * (1 / q('speed')),
          teal,
          labels ? 'v (direction)' : '',
          factor: 24,
        );
      }
      text(
        c,
        'Exterior spherical model · source at focus',
        const Offset(12, 12),
        color: Colors.white70,
      );
      text(
        c,
        'r = ${(q('radius') / 1000).toStringAsFixed(0)} km',
        const Offset(12, 235),
        color: Colors.white,
      );
      text(
        c,
        kind >= 9
            ? 'Time 480× · satellite size exaggerated'
            : kind == 6
            ? 'Body sizes exaggerated · r is centre-to-centre'
            : 'Body surface map illustrative · probe size exaggerated',
        const Offset(12, 252),
        color: Colors.white70,
        size: 9,
      );
    } else if (kind >= 12) {
      beam(c, const Rect.fromLTWH(24, 223, 312, 11));
      if (kind == 13) {
        final length = v('length'),
            lengthScale = math.min(150.0, 150 / length),
            pivot = const Offset(180, 45),
            bob =
                pivot +
                Offset(math.sin(q('x')), math.cos(q('x'))) *
                    length *
                    lengthScale;
        beam(c, const Rect.fromLTWH(90, 32, 262, 12));
        beam(c, const Rect.fromLTWH(343, 44, 8, 179));
        beam(c, const Rect.fromLTWH(86, 223, 269, 9));
        c.drawLine(
          pivot,
          bob,
          Paint()
            ..color = const Color(0xff675d45)
            ..strokeWidth = 1.6,
        );
        LabMaterials.screw(c, pivot);
        LabMaterials.sphere(c, bob, 12, amber);
        if (overlays) {
          c.drawLine(
            pivot,
            pivot + Offset(0, length * lengthScale),
            Paint()
              ..color = teal.withValues(alpha: .45)
              ..strokeWidth = .7,
          );
        }
        text(
          c,
          'Taut string · angle from downward vertical',
          const Offset(12, 13),
        );
      } else {
        final scale = oscillatorScale,
            origin = kind == 17 ? 123.0 : 200.0,
            body = Offset(origin + q('x') * scale, 166);
        beam(c, const Rect.fromLTWH(25, 132, 9, 78));
        if (overlays) {
          for (final equilibrium in kind == 17 ? [123.0, 237.0] : [200.0]) {
            c.drawLine(
              Offset(equilibrium, 122),
              Offset(equilibrium, 190),
              Paint()
                ..color = teal.withValues(alpha: .4)
                ..strokeWidth = .8,
            );
          }
          text(
            c,
            'Equilibrium markers',
            const Offset(35, 112),
            color: teal,
            size: 9,
          );
        }
        if (kind == 17) {
          final right = Offset(237 + q('x2') * scale, 166);
          beam(c, const Rect.fromLTWH(326, 132, 9, 78));
          LabMaterials.spring(
            c,
            const Offset(34, 166),
            body - const Offset(16, 0),
          );
          LabMaterials.spring(
            c,
            body + const Offset(16, 0),
            right - const Offset(16, 0),
          );
          LabMaterials.spring(
            c,
            right + const Offset(16, 0),
            const Offset(326, 166),
          );
          LabMaterials.metal(
            c,
            Rect.fromCenter(center: right, width: 32, height: 36),
          );
          text(c, 'k₁', const Offset(60, 141));
          text(c, 'kc', const Offset(173, 141));
          text(c, 'k₂', const Offset(278, 141));
          text(c, 'wall – k₁ – m₁ – kc – m₂ – k₂ – wall', const Offset(35, 21));
        } else {
          LabMaterials.spring(
            c,
            const Offset(34, 158),
            body - const Offset(18, 8),
          );
          if (kind == 15 || kind == 16) {
            beam(c, const Rect.fromLTWH(40, 190, 65, 12));
            c.drawLine(
              const Offset(105, 196),
              Offset(body.dx, 196),
              Paint()
                ..color = const Color(0xff637886)
                ..strokeWidth = 2,
            );
            c.drawLine(
              body + const Offset(0, 18),
              Offset(body.dx, 196),
              Paint()
                ..color = const Color(0xff637886)
                ..strokeWidth = 2,
            );
            text(c, 'viscous dashpot', const Offset(42, 207), size: 9);
          }
          if (kind == 16 && overlays) {
            tool.arrow(
              c,
              body,
              Vec2(q('force'), 0),
              blue,
              labels ? 'drive F(t)' : '',
              factor: 14,
            );
          }
          text(
            c,
            'Horizontal spring · x from equilibrium',
            const Offset(20, 21),
          );
        }
        LabMaterials.shadow(
          c,
          Rect.fromCenter(
            center: body + const Offset(0, 30),
            width: 45,
            height: 8,
          ),
        );
        LabMaterials.metal(
          c,
          Rect.fromCenter(center: body, width: 32, height: 36),
          brass: true,
        );
        for (final dx in [-10.0, 10.0]) {
          LabMaterials.sphere(
            c,
            body + Offset(dx, 22),
            4,
            const Color(0xff3e515d),
          );
        }
        beam(c, const Rect.fromLTWH(34, 192, 292, 5));
        text(
          c,
          'View auto-fits computed motion · dimensions illustrative',
          const Offset(12, 250),
          size: 9,
        );
      }
    } else {
      beam(c, const Rect.fromLTWH(22, 218, 316, 12));
      if (kind == 0) {
        final point = const Offset(180, 218);
        tool.block(c, point);
        if (overlays) {
          final a = v('angle') * math.pi / 180;
          tool.arrow(
            c,
            const Offset(180, 160),
            Vec2(math.cos(a), math.sin(a)) * v('force'),
            blue,
            labels ? 'F' : '',
            factor: 3,
          );
        }
        text(
          c,
          'Following view · signed x ${q('x').toStringAsFixed(2)} m',
          const Offset(15, 20),
        );
        for (int i = 0; i < 13; i++) {
          final x = 20 + i * 26.0;
          c.drawLine(
            Offset(x, 232),
            Offset(x, 238),
            Paint()..color = const Color(0xff788895),
          );
          text(
            c,
            (q('x') + (x - 180) / 40).toStringAsFixed(1),
            Offset(x - 8, 240),
            size: 8,
          );
        }
      } else if (kind == 1) {
        tool.cart(c, const Offset(180, 211), width: 58);
        beam(c, const Rect.fromLTWH(20, 211, 320, 7));
        if (overlays) {
          tool.arrow(
            c,
            const Offset(180, 164),
            Vec2(v('speed'), 0),
            teal,
            labels ? 'v' : '',
            factor: 12,
          );
        }
        text(
          c,
          'Following camera · translational energy only',
          const Offset(15, 20),
        );
        text(
          c,
          'World x ${q('x').toStringAsFixed(2)} m',
          const Offset(15, 245),
        );
      } else if (kind == 3) {
        final r = v('radius'),
            bound = math.max(2.6, math.max(q('x').abs(), v('x0').abs()) * 1.1),
            sx = 145 / bound,
            sy = 130 / (bound * bound / (2 * r) + .3),
            path = Path();
        Offset position(double x) =>
            Offset(180 + x * sx, 210 - x * x / (2 * r) * sy);
        for (int i = 0; i <= 100; i++) {
          final x = -bound + 2 * bound * i / 100, pt = position(x);
          if (i == 0) {
            path.moveTo(pt.dx, pt.dy);
          } else {
            path.lineTo(pt.dx, pt.dy);
          }
        }
        c.drawPath(
          path.shift(const Offset(0, 3)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7
            ..color = const Color(0xff778996),
        );
        c.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = const Color(0xffeff7fa),
        );
        LabMaterials.sphere(c, position(q('x')), 8, blue);
        text(
          c,
          'Captive bead · y = x²/(2R) · unequal axis scales',
          const Offset(12, 18),
        );
      } else {
        final maxHeight = kind == 5
                ? math.max(1, v('input') * v('eta') / (v('m') * 9.80665))
                : math.max(1, v('height')),
            height = q('y'),
            y = 218 - height / maxHeight * 80;
        beam(c, const Rect.fromLTWH(302, 45, 8, 174));
        beam(c, const Rect.fromLTWH(50, 38, 260, 10));
        final angle = -height / maxHeight * 5, pulleyAt = const Offset(265, 81);
        pulley(c, pulleyAt, angle);
        // Rope joins the top tangent of the sheave to a vertical segment and load eye.
        final rope = Path()
          ..moveTo(100, 65)
          ..lineTo(265, 65)
          ..arcTo(
            const Rect.fromLTWH(249, 65, 32, 32),
            -math.pi / 2,
            math.pi / 2,
            false,
          )
          ..lineTo(281, y - 40);
        c.drawPath(
          rope,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.7
            ..color = const Color(0xff72634b),
        );
        load(c, Offset(281, y));
        if (kind == 4 && overlays && q('vy') > 0) {
          tool.arrow(
            c,
            Offset(312, y - 18),
            const Vec2(0, 1),
            teal,
            labels ? 'v' : '',
            factor: 22,
          );
        }
        final motor = const Rect.fromLTWH(48, 59, 55, 34);
        c.drawRRect(
          RRect.fromRectAndRadius(motor, const Radius.circular(7)),
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xff86b4d1), blue, Color(0xff163e6a)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(motor),
        );
        for (int i = 0; i < 7; i++) {
          c.drawLine(
            Offset(55 + i * 6, 63),
            Offset(55 + i * 6, 89),
            Paint()
              ..color = const Color(0xff123b70)
              ..strokeWidth = 1,
          );
        }
        beam(c, const Rect.fromLTWH(42, 95, 73, 7));
        if (kind == 2 && overlays) {
          final zeroY = 218 - v('zero') / maxHeight * 80;
          c.drawLine(
            Offset(140, zeroY),
            Offset(326, zeroY),
            Paint()
              ..color = teal
              ..strokeWidth = 1,
          );
          text(c, 'U=0 plane', Offset(135, zeroY - 14), color: teal);
        }
        text(
          c,
          kind == 5
              ? 'Specified passive converter · η is a parameter'
              : kind == 4
              ? 'Constant-speed segment · transients excluded'
              : 'Prescribed quasi-static lift · uniform g',
          const Offset(12, 18),
          size: 9,
        );
        text(
          c,
          'Rise ${height.toStringAsFixed(3)} m · illustrated vertical scale',
          const Offset(12, 247),
          size: 9,
        );
      }
    }
    c.restore();
  }
}

class LabPlot extends CustomPainter {
  final List<LabState> data;
  final List<String> keys;
  final String xLabel, unit;
  final int cursor;
  final bool scatter;
  final Set<String> histogramKeys;
  final Map<String, String> errorKeys;
  const LabPlot(
    this.data,
    this.keys,
    this.xLabel,
    this.unit,
    this.cursor, {
    this.scatter = false,
    this.histogramKeys = const {},
    this.errorKeys = const {},
  });
  static const colors = [
    Color(0xff245ce7),
    Color(0xff008e95),
    Color(0xffd39b30),
    Color(0xff67788d),
  ];
  @override
  bool shouldRepaint(covariant LabPlot old) => true;
  @override
  void paint(Canvas c, Size size) {
    if (data.isEmpty) return;
    final values = [
      for (final s in data)
        for (final key in keys)
          if (s[key]?.isFinite ?? false) s[key]!,
    ];
    for (final row in data) {
      for (final entry in errorKeys.entries) {
        final y = row[entry.key], err = row[entry.value];
        if (y != null && err != null && y.isFinite && err.isFinite && err >= 0) {
          values.addAll([y - err, y + err]);
        }
      }
    }
    if (values.isEmpty) return;
    final yrange = plotRange(values, includeZero: true),
        xrange = plotRange(data.map((s) => s['t']!));
    final lo = yrange.min, hi = yrange.max;
    final halfBin = histogramKeys.isNotEmpty && data.length > 1
        ? (data[1]['t']! - data[0]['t']!).abs() / 2
        : 0.0;
    final xmin = xrange.min - halfBin,
        xmax = xrange.max + halfBin,
        area = Rect.fromLTWH(65, 20, size.width - 82, size.height - 58);
    Offset point(LabState s, String key) => Offset(
      area.left + (s['t']! - xmin) / (xmax - xmin) * area.width,
      area.bottom - ((s[key] ?? 0) - lo) / (hi - lo) * area.height,
    );
    final pen = Paint()
      ..color = const Color(0xffdce5ee)
      ..strokeWidth = .7;
    for (int i = 0; i <= 4; i++) {
      final y = area.top + area.height * i / 4;
      c.drawLine(Offset(area.left, y), Offset(area.right, y), pen);
      AdvancedPainter.tool.text(
        c,
        (hi - (hi - lo) * i / 4).toStringAsPrecision(3),
        Offset(0, y - 6),
        font: 9,
      );
    }
    for (int j = 0; j < keys.length; j++) {
      if (scatter || histogramKeys.contains(keys[j])) {
        for (final row in data) {
          if (!(row[keys[j]]?.isFinite ?? false)) continue;
          final pt = point(row, keys[j]);
          if (scatter) {
            final err = row[errorKeys[keys[j]]];
            if (err != null && err.isFinite && err >= 0) {
              final upper = point({
                    ...row,
                    keys[j]: row[keys[j]]! + err,
                  }, keys[j]),
                  lower = point({
                    ...row,
                    keys[j]: row[keys[j]]! - err,
                  }, keys[j]),
                  pen = Paint()
                    ..color = colors[j % colors.length]
                    ..strokeWidth = 1;
              c.drawLine(upper, lower, pen);
              c.drawLine(
                upper - const Offset(3, 0),
                upper + const Offset(3, 0),
                pen,
              );
              c.drawLine(
                lower - const Offset(3, 0),
                lower + const Offset(3, 0),
                pen,
              );
            }
            c.drawCircle(pt, 3.5, Paint()..color = colors[j % colors.length]);
          } else {
            final width = area.width / data.length,
                zero = area.bottom - ((0 - lo) / (hi - lo)) * area.height;
            c.drawRect(
              Rect.fromLTRB(
                pt.dx - width * .46,
                math.min(pt.dy, zero),
                pt.dx + width * .46,
                math.max(pt.dy, zero),
              ),
              Paint()..color = colors[j % colors.length].withValues(alpha: .55),
            );
          }
        }
        continue;
      }
      final path = Path();
      bool started = false;
      for (final s in data) {
        if (!(s[keys[j]]?.isFinite ?? false)) {
          started = false;
          continue;
        }
        final pt = point(s, keys[j]);
        if (started) {
          path.lineTo(pt.dx, pt.dy);
        } else {
          path.moveTo(pt.dx, pt.dy);
          started = true;
        }
      }
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..color = colors[j % colors.length],
      );
    }
    final selected = data[cursor.clamp(0, data.length - 1)],
        px = point(selected, keys.first).dx;
    c.drawLine(
      Offset(px, area.top),
      Offset(px, area.bottom),
      Paint()
        ..color = const Color(0xff7e90a7)
        ..strokeWidth = .8,
    );
    AdvancedPainter.tool.text(c, unit, Offset(area.left, 1), font: 9);
    AdvancedPainter.tool.text(
      c,
      xmin.toStringAsPrecision(3),
      Offset(area.left, area.bottom + 5),
      font: 9,
    );
    AdvancedPainter.tool.text(
      c,
      xmax.toStringAsPrecision(3),
      Offset(area.right - 35, area.bottom + 5),
      font: 9,
    );
    AdvancedPainter.tool.text(
      c,
      xLabel,
      Offset(area.left + area.width * .25, size.height - 16),
      font: 10,
    );
  }
}
