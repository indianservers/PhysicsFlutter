import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/physics/optical_library.dart';
import '../../core/physics/thermal_library.dart';

class OpticalBenchPainter extends CustomPainter {
  final OpticalBench bench;
  final List<TraceResult> traces;
  final int selected;
  final bool focus;
  OpticalBenchPainter(
    this.bench,
    this.traces,
    this.selected, {
    this.focus = false,
  });
  OVec get centre => focus
      ? bench.components[selected].position
      : bench.components.map((p) => p.position).reduce((a, b) => a + b) *
            (1 / bench.components.length);
  double get extent => focus
      ? 3.2 * bench.components[selected].size
      : math.max(
          4.8,
          bench.components
              .map((p) => (p.position - centre).length * 2 + 3)
              .reduce(math.max),
        );
  // Fixed world bench in metres. Camera transforms are applied outside this painter.
  double scale(Size s) =>
      math.min(s.width / extent, s.height / (extent * 5 / 9));
  Offset project(OVec p, Size s) => Offset(
    s.width / 2 + (p.x - centre.x) * scale(s),
    s.height / 2 - (p.y - centre.y) * scale(s),
  );
  OVec unproject(Offset p, Size s) => OVec(
    (p.dx - s.width / 2) / scale(s) + centre.x,
    -(p.dy - s.height / 2) / scale(s) + centre.y,
  );
  void label(
    Canvas c,
    String text,
    Offset at, {
    Color color = const Color(0xffbed5e3),
    double size = 10,
  }) {
    final t = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 220);
    t.paint(c, at);
  }

  @override
  void paint(Canvas c, Size s) {
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff102434), Color(0xff263e4d)],
        ).createShader(Offset.zero & s),
    );
    if (bench.grid) {
      for (double x = -4; x <= 4; x += .5) {
        c.drawLine(
          project(OVec(x, -2.5), s),
          project(OVec(x, 2.5), s),
          Paint()..color = const Color(0x155dafbf),
        );
      }
      for (double y = -2; y <= 2; y += .5) {
        c.drawLine(
          project(OVec(-4.5, y), s),
          project(OVec(4.5, y), s),
          Paint()..color = const Color(0x155dafbf),
        );
      }
    }
    for (int i = 0; i < bench.components.length; i++) {
      final optic = bench.components[i],
          definition = opticalComponent(optic.component);
      for (final solid in opticSolids(optic)) {
        final points = solid.outline
            .map((v) => project(optic.world(v), s))
            .toList();
        if (points.isEmpty) continue;
        final path = Path()..addPolygon(points, true),
            bounds = path.getBounds();
        c.save();
        c.translate(4, 7);
        c.drawPath(path, Paint()..color = const Color(0x55000000));
        c.restore();
        final mirror = definition.category == 'Mirror',
            liquid =
                definition.category == 'Liquid-containing element' &&
                solid.material == optic.material;
        c.drawPath(
          path,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: mirror
                  ? const [
                      Color(0xffccdce4),
                      Color(0xff526b80),
                      Color(0xffd7e5ee),
                    ]
                  : liquid
                  ? const [Color(0x905ea5c0), Color(0x354ea2b2)]
                  : const [
                      Color(0x7579c9da),
                      Color(0x194da3b5),
                      Color(0x68669eaf),
                    ],
            ).createShader(bounds),
        );
        c.drawPath(
          path,
          Paint()
            ..color = i == selected
                ? const Color(0xffb3efff)
                : const Color(0xff668d9e)
            ..strokeWidth = i == selected ? 2 : 1
            ..style = PaintingStyle.stroke,
        );
        c.save();
        c.clipPath(path);
        c.drawLine(
          bounds.topLeft + const Offset(3, 2),
          bounds.bottomRight - const Offset(3, 2),
          Paint()
            ..color = const Color(0x304b8ea7)
            ..strokeWidth = 3,
        );
        c.restore();
      }
      label(
        c,
        '${i + 1} · ${definition.name}',
        project(optic.position, s) + Offset(-40, optic.size * scale(s) * .85),
        size: 9,
      );
    }
    for (final trace in traces) {
      for (final ray in trace.segments) {
        if (ray.power < .002) continue;
        final color = ray.wavelength < 500
            ? const Color(0xff829bff)
            : ray.wavelength < 600
            ? const Color(0xff64efd3)
            : const Color(0xffffb17c);
        c.drawLine(
          project(ray.start, s),
          project(ray.end, s),
          Paint()
            ..color = color.withValues(alpha: (.2 + .8 * ray.power).clamp(0, 1))
            ..strokeWidth = 1 + ray.power,
        );
        if (ray.event != 'exit') {
          final p = project(ray.end, s);
          c.drawCircle(p, 2, Paint()..color = color);
          if (bench.normals) {
            c.drawLine(
              project(ray.end - ray.normal * .18, s),
              project(ray.end + ray.normal * .18, s),
              Paint()
                ..color = const Color(0xffc4d7db)
                ..strokeWidth = 1,
            );
          }
          if (bench.angles) {
            final angle =
                math.acos((-ray.direction.dot(ray.normal)).clamp(-1, 1)) *
                180 /
                math.pi;
            label(
              c,
              '${angle.toStringAsFixed(1)}°',
              p + const Offset(3, -14),
              color: color,
            );
          }
          if (bench.powers) {
            label(
              c,
              'P ${(ray.power * 100).toStringAsFixed(1)}%',
              p + const Offset(3, 3),
              color: color,
            );
          }
        }
      }
    }
    final source = project(bench.source, s);
    c.drawCircle(source, 5, Paint()..color = const Color(0xfff2ce93));
    label(
      c,
      'Educational ray overlay · ${bench.components.any((p) => p.component == 'corner') ? '3D paths, XY projection' : 'optical section'}',
      const Offset(10, 10),
    );
    if (bench.error.isNotEmpty) {
      label(
        c,
        bench.error,
        const Offset(10, 30),
        color: const Color(0xffffc9a8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant OpticalBenchPainter old) => true;
}

class ThermalBenchPainter extends CustomPainter {
  final ThermalBench bench;
  final bool graph;
  ThermalBenchPainter(this.bench, {this.graph = false});
  void text(
    Canvas c,
    String v,
    Offset p, {
    double size = 12,
    Color color = const Color(0xff263d51),
  }) {
    final t = TextPainter(
      text: TextSpan(
        text: v,
        style: TextStyle(color: color, fontSize: size),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 260);
    t.paint(c, p);
  }

  void sample(Canvas c, Rect rect, ThermalMaterial m) {
    final color = Color(m.color).withValues(
      alpha: m.texture == 'gas'
          ? .12
          : ['glass', 'liquid'].contains(m.texture)
          ? .42
          : 1,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        rect.shift(const Offset(3, 5)),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0x24364c59),
    );
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(7)));
    c.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, Colors.white, .42)!,
            color,
            Color.lerp(color, Colors.black, .35)!,
          ],
        ).createShader(rect),
    );
    c.save();
    c.clipPath(path);
    for (int i = 0; i < 110; i++) {
      final x = rect.left + (i * 71 % 101) / 101 * rect.width,
          y = rect.top + (i * 43 % 103) / 103 * rect.height;
      final paint = Paint()
        ..color = (i.isEven ? Colors.white : Colors.black).withValues(
          alpha: .12,
        )
        ..strokeWidth = .5;
      if (m.texture == 'brushed' || m.texture == 'polished') {
        c.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), paint);
      } else if (m.texture.startsWith('wood')) {
        final along = m.texture.endsWith('long');
        final line = Path()
          ..moveTo(along ? rect.left : x, along ? y : rect.top)
          ..quadraticBezierTo(
            rect.center.dx + (i % 5),
            rect.center.dy,
            along ? rect.right : x + 5,
            along ? y + 2 : rect.bottom,
          );
        c.drawPath(line, paint..style = PaintingStyle.stroke);
      } else if ([
        'granite',
        'granular',
        'porous',
        'foam',
      ].contains(m.texture)) {
        c.drawCircle(Offset(x, y), m.texture == 'foam' ? 2.5 : 1.5, paint);
      } else if (m.texture == 'fibres') {
        c.drawLine(Offset(x, y), Offset(x + 12, y + 7), paint);
      } else if (m.texture == 'marble') {
        final vein = Path()
          ..moveTo(x, rect.top)
          ..cubicTo(x + 14, y, x - 20, y, x + 8, rect.bottom);
        c.drawPath(vein, paint..style = PaintingStyle.stroke);
      }
    }
    if (['glass', 'liquid', 'gas'].contains(m.texture)) {
      c.drawPath(
        path,
        Paint()
          ..color = const Color(0xffc9f4ff)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      c.drawLine(
        rect.topLeft + const Offset(7, 5),
        rect.topRight - const Offset(7, -5),
        Paint()
          ..color = Colors.white.withValues(alpha: .6)
          ..strokeWidth = 2,
      );
    }
    c.restore();
  }

  @override
  void paint(Canvas c, Size size) {
    c.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xffeff4f4), Color(0xffd5e0e5)],
        ).createShader(Offset.zero & size),
    );
    final sx = size.width / 440, sy = size.height / 320;
    c.save();
    c.scale(sx, sy);
    final rows = bench.readings;
    if (graph) {
      final curves = bench.curves;
      if (curves.isEmpty) {
        text(c, bench.error, const Offset(16, 40));
        c.restore();
        return;
      }
      final values = curves.expand((v) => v),
          min = values.reduce(math.min),
          max = values.reduce(math.max);
      final span = math.max(.01, max - min);
      c.drawLine(
        const Offset(45, 260),
        const Offset(412, 260),
        Paint()..color = Colors.blueGrey,
      );
      c.drawLine(
        const Offset(45, 45),
        const Offset(45, 260),
        Paint()..color = Colors.blueGrey,
      );
      final colors = [Colors.deepOrange, Colors.blue, Colors.teal];
      for (int i = 0; i < curves.length; i++) {
        final path = Path();
        for (int j = 0; j < curves[i].length; j++) {
          final x = 45 + j * 350 / 40,
              y = 250 - (curves[i][j] - min) / span * 180;
          if (j == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        c.drawPath(
          path,
          Paint()
            ..color = colors[i]
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        text(
          c,
          thermalMaterial(bench.materials[i]).name,
          Offset(60, 12 + i * 15),
          color: colors[i],
          size: 10,
        );
      }
      text(
        c,
        '${min.toStringAsFixed(1)}–${max.toStringAsFixed(1)} K',
        const Offset(45, 270),
      );
      text(
        c,
        bench.mode == ThermalBench.modes[1]
            ? 'Time: 0–${bench.seconds} s'
            : 'Normalized position: 0–1 (each sample/layer)',
        const Offset(45, 290),
        size: 10,
      );
    } else {
      text(c, bench.mode, const Offset(16, 10), size: 14);
      final composite = bench.mode == ThermalBench.modes[2];
      for (int i = 0; i < bench.materials.length; i++) {
        final m = thermalMaterial(bench.materials[i]),
            rect = composite
                ? Rect.fromLTWH(55 + i * 112, 90, 110, 90)
                : Rect.fromLTWH(60, 58 + i * 76, 320, 32);
        sample(c, rect, m);
        if (bench.overlay && rows.isNotEmpty) {
          final row = rows[i];
          final lo = math.min(bench.hot, bench.cold);
          final hi = bench.mode == ThermalBench.modes[1]
              ? rows.map((v) => v['temperature']!).reduce(math.max)
              : math.max(bench.hot, bench.cold);
          Color temperature(double t) => Color.lerp(
            const Color(0x88427bbc),
            const Color(0x88dc5e35),
            ((t - lo) / math.max(.001, hi - lo)).clamp(0, 1),
          )!;
          final start = bench.mode == ThermalBench.modes[1]
              ? row['temperature']!
              : composite
              ? row['start']!
              : bench.hot;
          final end = bench.mode == ThermalBench.modes[1]
              ? start
              : composite
              ? row['end']!
              : bench.cold;
          c.drawRect(
            rect,
            Paint()
              ..shader = LinearGradient(
                colors: [temperature(start), temperature(end)],
              ).createShader(rect),
          );
        }
        text(
          c,
          m.name,
          composite ? Offset(55 + i * 112, 60) : Offset(62, 95 + i * 76),
          size: 10,
        );
        if (rows.isNotEmpty) {
          final row = rows[i];
          text(
            c,
            bench.mode == ThermalBench.modes[1]
                ? '${row['temperature']!.toStringAsFixed(2)} K · Q = ${row['stored']!.toStringAsFixed(1)} J'
                : '${row['power']!.toStringAsPrecision(4)} W${composite ? ' · ΔT ${(row['start']! - row['end']!).toStringAsFixed(2)} K' : ''}',
            composite ? Offset(55 + i * 112, 193) : Offset(62, 108 + i * 76),
            size: 10,
          );
        }
      }
      if (rows.isEmpty) {
        text(
          c,
          bench.error,
          const Offset(16, 264),
          size: 11,
          color: Colors.deepOrange.shade900,
        );
      } else {
        text(
          c,
          bench.mode == ThermalBench.modes[1]
              ? 'Equal ${bench.equalVolume ? 'volume' : 'mass'} · heater ${bench.power} W / sample · no losses'
              : '${bench.hot} K → ${bench.cold} K · same area ${bench.area} m²',
          const Offset(16, 273),
          size: 11,
        );
      }
      text(
        c,
        bench.overlay
            ? 'False color: blue ${bench.cold.toStringAsFixed(1)} K → orange ${(bench.mode == ThermalBench.modes[1] && rows.isNotEmpty ? rows.map((v) => v['temperature']!).reduce(math.max) : bench.hot).toStringAsFixed(1)} K'
            : 'Natural material appearance · ideal apparatus',
        const Offset(16, 300),
        size: 10,
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant ThermalBenchPainter old) => true;
}
