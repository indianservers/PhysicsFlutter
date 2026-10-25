import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/physics/fluid_modern_run.dart';
import '../../core/rendering/materials.dart';
import '../../core/rendering/scientific_text.dart';

class FMPainter extends CustomPainter {
  final FMRun run;
  final bool labels, overlays, motion;
  final int revision;
  FMPainter(
    this.run, {
    this.labels = true,
    this.overlays = true,
    this.motion = true,
  }) : revision = run.revision;
  static const pressureSurface = 58.0,
      pressureScale = 197.5,
      buoyancySurface = 100.0,
      buoyancyScale = 500.0,
      pipeScale = 900.0;
  static const navy = Color(0xff173458),
      blue = Color(0xff245ce7),
      teal = Color(0xff008e95),
      amber = Color(0xffcf982e);
  double v(String key, [double fallback = 0]) => run.p[key] ?? fallback;
  double q(String key, [double fallback = 0]) => run.state[key] ?? fallback;
  String num(double value) => value == 0
      ? '0'
      : value.abs() < .001 || value.abs() > 1e6
      ? value.toStringAsExponential(3)
      : value.toStringAsPrecision(5);
  void text(
    Canvas c,
    String value,
    Offset at, {
    double size = 10,
    Color color = navy,
  }) {
    if (labels) ScientificText.paint(c, value, at, color: color, font: size);
  }

  void line(
    Canvas c,
    Offset a,
    Offset b, {
    Color color = navy,
    double width = 1.5,
  }) => c.drawLine(
    a,
    b,
    Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round,
  );
  void box(Canvas c, Rect r, Color color, {double radius = 5}) => c.drawRRect(
    RRect.fromRectAndRadius(r, Radius.circular(radius)),
    Paint()..color = color,
  );
  void arrow(Canvas c, Offset a, Offset b, {Color color = teal}) {
    if ((b - a).distance < 1) return;
    line(c, a, b, color: color, width: 2);
    final dir = (b - a) / (b - a).distance, side = Offset(-dir.dy, dir.dx);
    line(c, b, b - dir * 6 + side * 3, color: color, width: 2);
    line(c, b, b - dir * 6 - side * 3, color: color, width: 2);
  }

  void stand(Canvas c, Offset base, double height) {
    LabMaterials.metal(c, Rect.fromLTWH(base.dx - 25, base.dy - 4, 50, 8));
    LabMaterials.metal(
      c,
      Rect.fromLTWH(base.dx - 3, base.dy - height, 6, height),
    );
  }

  void meniscus(Canvas c, Rect r, double top, Color color) {
    c.drawOval(
      Rect.fromLTWH(r.left + 3, top - 4, r.width - 6, 8),
      Paint()..color = color.withValues(alpha: .65),
    );
    c.drawArc(
      Rect.fromLTWH(r.left + 3, top - 4, r.width - 6, 8),
      0,
      math.pi,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: .7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void glass(
    Canvas c,
    Rect r, {
    double? liquidTop,
    Color liquid = const Color(0xff258eb7),
  }) {
    LabMaterials.shadow(
      c,
      Rect.fromLTWH(r.left - 5, r.bottom - 3, r.width + 10, 13),
    );
    final shape = RRect.fromRectAndRadius(r, const Radius.circular(8));
    c.drawRRect(
      shape,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: .45),
            const Color(0xffc5e3eb).withValues(alpha: .1),
            Colors.white.withValues(alpha: .5),
          ],
          stops: const [0, .5, 1],
        ).createShader(r),
    );
    if (liquidTop != null) {
      c.save();
      c.clipRRect(shape);
      final fill = Rect.fromLTRB(
        r.left + math.min(3, r.width * .15),
        liquidTop,
        r.right - math.min(3, r.width * .15),
        r.bottom - 3,
      );
      if (fill.height > 0) {
        c.drawRect(
          fill,
          Paint()
            ..shader = LinearGradient(
              colors: [
                liquid.withValues(alpha: .30),
                liquid.withValues(alpha: .70),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(fill),
        );
      }
      meniscus(c, r, liquidTop, liquid);
      c.restore();
    }
    c.drawRRect(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xff8dabb9)
        ..strokeWidth = 1.5,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(r.deflate(3), const Radius.circular(6)),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: .8)
        ..strokeWidth = 1,
    );
    line(
      c,
      Offset(r.left + math.min(8, r.width * .25), r.top + 10),
      Offset(r.left + math.min(8, r.width * .25), r.bottom - 12),
      color: Colors.white.withValues(alpha: .8),
      width: 2,
    );
    c.drawOval(
      Rect.fromLTWH(r.left, r.top - 4, r.width, 8),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xff91adb5)
        ..strokeWidth = 1.2,
    );
  }

  void meter(Canvas c, Rect r, String label, String value) {
    LabMaterials.metal(c, r);
    box(c, r.deflate(5), const Color(0xff102f40), radius: 3);
    text(
      c,
      value,
      r.topLeft + const Offset(10, 10),
      size: 12,
      color: const Color(0xffb9f9f5),
    );
    text(c, label, Offset(r.left + 8, r.bottom + 4), size: 9);
  }

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 360, size.height / 270);
    c.clipRect(const Rect.fromLTWH(0, 0, 360, 270));
    if (run.invalid.isNotEmpty) {
      text(
        c,
        'No supported scientific state assigned',
        const Offset(45, 101),
        size: 13,
      );
      text(
        c,
        'Adjust inputs using the validity explanation.',
        const Offset(42, 133),
        size: 10,
      );
      c.restore();
      return;
    }
    switch (run.kind) {
      case 0:
        pressure(c);
      case 1:
        hydro(c);
      case 2:
        floatBlock(c);
      case 3 || 4:
        pipe(c);
      case 5:
        viscometer(c);
      case 6:
        well(c);
      case 7:
        photocell(c);
      case 8:
        matter(c);
      case 9:
        spectra(c);
      case 10:
        nucleus(c);
      case 11:
        radioactivity(c);
    }
    text(
      c,
      run.invalid.isEmpty
          ? 'Calculated state • ${num(run.time)} physical s'
          : 'Outside model validity — see explanation',
      const Offset(12, 249),
      size: 9,
      color: run.invalid.isEmpty ? navy : Colors.red,
    );
    c.restore();
  }

  void pressure(Canvas c) {
    const vessel = Rect.fromLTWH(58, 38, 184, 182);
    glass(c, vessel, liquidTop: pressureSurface);
    LabMaterials.metal(c, const Rect.fromLTWH(49, 219, 202, 8));
    for (int i = 0; i <= 8; i++) {
      final y = pressureSurface + i * .1 * pressureScale;
      line(c, Offset(39, y), Offset(53, y), color: navy, width: 1);
      text(c, '${i * 10}', Offset(16, y - 5), size: 8);
    }
    text(c, 'depth cm', const Offset(10, 25), size: 8);
    text(c, 'Free surface h=0', const Offset(83, 42), size: 9);
    final y = pressureSurface + v('depth') * pressureScale;
    final hose = Path()
      ..moveTo(211, y)
      ..lineTo(263, y)
      ..cubicTo(270, y, 258, 80, 281, 65);
    c.drawPath(
      hose,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.black87
        ..strokeWidth = 2.5,
    );
    LabMaterials.metal(c, Rect.fromLTWH(202, y - 7, 13, 14));
    c.drawCircle(Offset(204, y), 2, Paint()..color = teal);
    if (overlays) {
      line(c, Offset(62, y), Offset(200, y), color: amber, width: 1);
    }
    meter(
      c,
      const Rect.fromLTWH(265, 30, 83, 42),
      'gauge kPa',
      run.invalid.isEmpty ? num(q('gaugePressure') / 1000) : '—',
    );
    final side = (math.pow(v('objectVolume'), 1 / 3) * 400).toDouble();
    LabMaterials.metal(
      c,
      Rect.fromLTWH(290 - side / 2, 167 - side, side, side),
    );
    text(c, 'Separate m/V specimen', const Offset(250, 174), size: 8);
    text(c, 'ρ=${num(q('objectDensity'))}', const Offset(256, 189), size: 8);
    text(c, 'kg/m³', const Offset(278, 202), size: 8);
    text(c, 'Model liquid • fixed reference T', const Offset(70, 230), size: 9);
  }

  void hydro(Canvas c) {
    const datum = 215.0, scale = 350.0;
    final wl = 2 * math.sqrt(v('areaLeft') / math.pi) * scale,
        wr = 2 * math.sqrt(v('areaRight') / math.pi) * scale;
    final connector = Path()
      ..moveTo(94, 194)
      ..lineTo(94, 215)
      ..quadraticBezierTo(177, 231, 260, 215)
      ..lineTo(260, 194);
    c.drawPath(
      connector,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xff9ec8d6)
        ..strokeWidth = 17,
    );
    c.drawPath(
      connector,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xffe6f6fa)
        ..strokeWidth = 13,
    );
    c.drawPath(
      connector,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xff349fc2).withValues(alpha: .65)
        ..strokeWidth = 9,
    );
    final left = Rect.fromLTWH(94 - wl / 2, 22.5, wl, 192.5),
        right = Rect.fromLTWH(260 - wr / 2, 22.5, wr, 192.5);
    final inter = datum - q('interfaceLevel', .4) * scale,
        top = datum - q('leftLevel', .4) * scale,
        rtop = datum - q('rightLevel', .4) * scale;
    glass(c, left, liquidTop: inter);
    LabMaterials.metal(c, Rect.fromLTWH(left.left - 3, 18, left.width + 6, 8));
    line(c, const Offset(94, 18), const Offset(94, 10), color: navy, width: 3);
    text(c, 'Applied sealed-left pressure', const Offset(124, 28), size: 8);
    glass(c, right, liquidTop: rtop);
    if (run.mode == 1 && run.invalid.isEmpty) {
      box(
        c,
        Rect.fromLTRB(left.left + 4, top, left.right - 4, inter),
        amber.withValues(alpha: .55),
        radius: 0,
      );
      meniscus(c, left, top, amber);
    }
    if (overlays) {
      line(
        c,
        const Offset(25, 215),
        const Offset(335, 215),
        color: navy,
        width: 1,
      );
      text(c, 'z=0 datum', const Offset(146, 220), size: 8);
      line(c, Offset(135, inter), Offset(210, inter), color: teal, width: 1);
      arrow(c, Offset(178, rtop), Offset(178, inter), color: amber);
      text(
        c,
        'Δh=${num(q('heightDifference'))} m',
        const Offset(133, 100),
        size: 8,
      );
    }
    text(c, 'Δp=${num(v('deltaPressure'))} Pa', const Offset(95, 13));
    text(
      c,
      'Conserved base-liquid branch volume',
      const Offset(55, 234),
      size: 9,
    );
    text(c, 'L ${num(q('leftLevel'))} m', const Offset(48, 45), size: 8);
    text(c, 'R ${num(q('rightLevel'))} m', const Offset(226, 45), size: 8);
  }

  void floatBlock(Canvas c) {
    const tank = Rect.fromLTWH(25, 70, 308, 146);
    glass(c, tank, liquidTop: buoyancySurface);
    final w = v('width') * buoyancyScale,
        h = v('height') * buoyancyScale,
        depth = v('length') * buoyancyScale * .28,
        top =
            buoyancySurface + (q('bottomDepth') - v('height')) * buoyancyScale,
        r = Rect.fromLTWH(180 - w / 2, top, w, h);
    LabMaterials.shadow(c, Rect.fromLTWH(r.left - 8, 211, r.width + 16, 8));
    final side = Path()
      ..moveTo(r.right, r.top)
      ..lineTo(r.right + depth, r.top - depth * .5)
      ..lineTo(r.right + depth, r.bottom - depth * .5)
      ..lineTo(r.right, r.bottom)
      ..close();
    c.drawPath(side, Paint()..color = const Color(0xff8a653b));
    LabMaterials.wood(c, r);
    final topFace = Path()
      ..moveTo(r.left, r.top)
      ..lineTo(r.left + depth, r.top - depth * .5)
      ..lineTo(r.right + depth, r.top - depth * .5)
      ..lineTo(r.right, r.top)
      ..close();
    c.drawPath(topFace, Paint()..color = const Color(0xffd2ad78));
    if (r.bottom > buoyancySurface) {
      c.save();
      c.clipRect(
        Rect.fromLTRB(
          r.left,
          math.max(r.top, buoyancySurface),
          r.right + depth,
          r.bottom,
        ),
      );
      c.drawRect(
        r.inflate(10),
        Paint()..color = const Color(0xff2898c2).withValues(alpha: .24),
      );
      c.restore();
    }
    line(
      c,
      const Offset(30, buoyancySurface),
      const Offset(328, buoyancySurface),
      color: Colors.white.withValues(alpha: .7),
      width: 1,
    );
    if (overlays) {
      final fb = q('buoyantForce'),
          weight = q('weight'),
          scale = math.max(fb, weight) > 0 ? 40 / math.max(fb, weight) : 0.0;
      arrow(
        c,
        Offset(r.center.dx, r.center.dy),
        Offset(r.center.dx, r.center.dy - fb * scale),
        color: teal,
      );
      arrow(
        c,
        Offset(r.center.dx + 15, r.center.dy),
        Offset(r.center.dx + 15, r.center.dy + weight * scale),
        color: amber,
      );
      text(c, 'Fb ${num(fb)} N', const Offset(35, 20), color: teal);
      text(c, 'W ${num(weight)} N', const Offset(221, 20), color: amber);
    }
    LabMaterials.metal(c, const Rect.fromLTWH(20, 210, 320, 13));
    text(
      c,
      'Fixed surface • overflow reservoir',
      const Offset(68, 231),
      size: 9,
    );
    text(
      c,
      run.mode == 1
          ? 'Held position; external support reported'
          : [
              'Floating equilibrium',
              'Neutral fully immersed state',
              'Denser body: bottom-supported end state',
            ][q('regime').toInt().clamp(0, 2)],
      const Offset(37, 43),
      size: 9,
    );
  }

  void pipe(Canvas c) {
    final model = run.pipe;
    if (model == null) {
      text(c, 'Unsupported pipe configuration', const Offset(65, 120));
      return;
    }
    const scale = pipeScale, cy = 153.0;
    final body = Path();
    Offset top(double x) {
      final slope = model.slope(x),
          normal = math.sqrt(1 + slope * slope),
          r = model.radius(x);
      return Offset(
        180 + x * scale - r * slope / normal * scale,
        cy - model.at(x)['elevation']! * scale - r / normal * scale,
      );
    }

    Offset bottom(double x) {
      final slope = model.slope(x),
          normal = math.sqrt(1 + slope * slope),
          r = model.radius(x);
      return Offset(
        180 + x * scale + r * slope / normal * scale,
        cy - model.at(x)['elevation']! * scale + r / normal * scale,
      );
    }

    for (int i = 0; i <= 80; i++) {
      final x = -PipeModel.halfLength + 2 * PipeModel.halfLength * i / 80,
          p = top(x);
      if (i == 0) {
        body.moveTo(p.dx, p.dy);
      } else {
        body.lineTo(p.dx, p.dy);
      }
    }
    for (int i = 80; i >= 0; i--) {
      final p = bottom(
        -PipeModel.halfLength + 2 * PipeModel.halfLength * i / 80,
      );
      body.lineTo(p.dx, p.dy);
    }
    body.close();
    c.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xffc9eef6).withValues(alpha: .35),
            const Color(0xff319ec1).withValues(alpha: .6),
            Colors.white.withValues(alpha: .6),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(const Rect.fromLTWH(35, 120, 290, 65)),
    );
    c.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xffa6cbd7)
        ..strokeWidth = 5,
    );
    c.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: .8)
        ..strokeWidth = 1.1,
    );
    for (final x in [
      180 - PipeModel.halfLength * scale,
      180 + PipeModel.halfLength * scale,
    ]) {
      LabMaterials.metal(
        c,
        Rect.fromLTWH(
          x - 4,
          cy - v('radius1') * scale - 4,
          8,
          2 * v('radius1') * scale + 8,
        ),
      );
      stand(c, Offset(x, 220), 220 - (cy + v('radius1') * scale));
    }
    if (motion) {
      for (int i = 0; i < 24; i++) {
        final x = model.tracer(run.time, i), at = model.at(x);
        c.drawCircle(
          Offset(180 + x * scale, cy - at['elevation']! * scale),
          1.8,
          Paint()..color = blue.withValues(alpha: .7),
        );
      }
    }
    final probe = v('probeX'), at = model.at(probe), px = 180 + probe * scale;
    line(
      c,
      Offset(px, cy - at['elevation']! * scale - 18),
      Offset(px, cy - at['elevation']! * scale + 18),
      color: amber,
      width: 1.5,
    );
    if (run.kind == 4) {
      for (final x in [-PipeModel.halfLength, 0.0]) {
        final s = model.at(x),
            px = 180 + x * scale,
            base = cy - s['elevation']! * scale;
        final topY = cy - s['columnTop']! * scale;
        glass(
          c,
          Rect.fromLTRB(px - 5, cy - .14 * scale, px + 5, base),
          liquidTop: topY,
        );
        text(c, '${num(s['head']!)} m', Offset(px - 29, topY - 15), size: 8);
      }
      text(
        c,
        'Open piezometers • same physical geometry scale',
        const Offset(29, 11),
        size: 9,
      );
    } else {
      text(c, 'Q=${num(v('flow'))} m³/s', const Offset(88, 53));
      text(
        c,
        'Circular radii/areas share one geometry',
        const Offset(63, 78),
        size: 9,
      );
    }
    text(c, 'v₁=${num(q('inletSpeed'))}', const Offset(25, 184), size: 9);
    text(c, 'v₂=${num(q('throatSpeed'))} m/s', const Offset(204, 184), size: 9);
    text(
      c,
      'Passive volume markers • no CFD / molecular claim',
      const Offset(32, 235),
      size: 9,
    );
  }

  void viscometer(Canvas c) {
    const vessel = Rect.fromLTWH(130, 31, 70, 187),
        surface = 43.0,
        scale = 700.0;
    glass(c, vessel, liquidTop: surface, liquid: const Color(0xff58a8a7));
    LabMaterials.metal(c, const Rect.fromLTWH(119, 216, 92, 8));
    final start = surface + .025 * scale,
        y = start + q('position') * scale,
        r = v('radius') * scale;
    LabMaterials.sphere(c, Offset(165, y), r, const Color(0xff70818b));
    for (int i = 0; i <= 4; i++) {
      final at = start + i * .05 * scale;
      line(c, Offset(203, at), Offset(213, at), width: 1);
      text(c, '${i * 5} cm', Offset(216, at - 4), size: 8);
    }
    if (overlays) {
      line(c, Offset(126, start), Offset(202, start), color: amber, width: 1);
      line(
        c,
        Offset(126, start + v('travel') * scale),
        Offset(202, start + v('travel') * scale),
        color: amber,
        width: 1,
      );
    }
    c.drawCircle(
      const Offset(286, 113),
      29,
      Paint()..color = Colors.white.withValues(alpha: .75),
    );
    LabMaterials.sphere(
      c,
      const Offset(286, 113),
      r * 12,
      const Color(0xff647985),
    );
    text(c, 'Bead ×12 inset', const Offset(247, 148), size: 8);
    text(c, 'μ ${num(v('viscosity'))} Pa·s', const Offset(18, 27), size: 9);
    text(c, 'Reₜ ${num(q('terminalReynolds'))}', const Offset(16, 48), size: 9);
    text(c, 'Travel ${num(q('position'))} m', const Offset(17, 69), size: 9);
    text(
      c,
      'Model liquid • fixed reference temperature',
      const Offset(48, 234),
      size: 9,
    );
  }

  void well(Canvas c) {
    LabMaterials.metal(c, const Rect.fromLTWH(30, 211, 300, 11));
    glass(c, const Rect.fromLTWH(43, 46, 222, 159));
    final wall = Paint()..color = navy;
    c.drawRect(const Rect.fromLTWH(55, 64, 5, 129), wall);
    c.drawRect(const Rect.fromLTWH(248, 64, 5, 129), wall);
    final psi = Path(), density = Path();
    for (int i = 0; i <= 160; i++) {
      final x = v('wellWidth') * i / 160,
          fn = wellPsi(x, v('wellWidth'), v('mass'), v('n').round()),
          u = fn / math.sqrt(2 / v('wellWidth')),
          px = 60 + 188 * i / 160;
      if (i == 0) {
        psi.moveTo(px, 102 - u * 26);
        density.moveTo(px, 174 - u * u * 42);
      } else {
        psi.lineTo(px, 102 - u * 26);
        density.lineTo(px, 174 - u * u * 42);
      }
    }
    c.drawPath(
      psi,
      Paint()
        ..color = blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    c.drawPath(
      density,
      Paint()
        ..color = teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    text(c, 'ψ: scaled amplitude', const Offset(69, 53), size: 8, color: blue);
    text(
      c,
      '|ψ|²: stationary density',
      const Offset(69, 122),
      size: 8,
      color: teal,
    );
    if (motion && overlays) {
      for (final x in run.positions) {
        c.drawCircle(
          Offset(60 + 188 * x / v('wellWidth'), 190),
          1.1,
          Paint()..color = amber.withValues(alpha: .4),
        );
      }
    }
    for (int n = 1; n <= 6; n++) {
      final y = 200 - 145 * n * n / 36;
      line(
        c,
        Offset(281, y),
        Offset(320, y),
        color: n == v('n') ? amber : navy,
        width: n == v('n') ? 3 : 1,
      );
      if (n > 1) text(c, 'n=$n', Offset(324, y - 5), size: 8);
    }
    text(
      c,
      'Infinite-well model • not an electron photograph',
      const Offset(35, 15),
      size: 10,
    );
    text(
      c,
      'x/L frame; L=${num(v('wellWidth'))} m',
      const Offset(86, 229),
      size: 9,
    );
  }

  void photocell(Canvas c) {
    stand(c, const Offset(127, 218), 61);
    stand(c, const Offset(254, 218), 61);
    glass(c, const Rect.fromLTWH(86, 78, 204, 88));
    LabMaterials.metal(c, const Rect.fromLTWH(101, 93, 9, 57));
    LabMaterials.metal(c, const Rect.fromLTWH(262, 93, 7, 57));
    final lamp = Rect.fromLTWH(23, 75, 38, 38);
    LabMaterials.metal(c, lamp);
    final beam = Path()
      ..moveTo(60, 90)
      ..lineTo(105, 104)
      ..lineTo(105, 136)
      ..lineTo(60, 103)
      ..close();
    c.drawPath(
      beam,
      Paint()..color = blue.withValues(alpha: v('intensity') == 0 ? 0 : .18),
    );
    text(c, 'λ=${num(q('wavelength'))} m', const Offset(24, 35), size: 10);
    text(c, 'Monochromatic input ray schematic', const Offset(24, 53), size: 8);
    if (overlays && q('current') > 0) {
      arrow(c, const Offset(134, 124), const Offset(238, 124), color: teal);
    }
    text(c, 'Emitter', const Offset(85, 173), size: 9);
    text(c, 'Collector', const Offset(243, 173), size: 9);
    line(
      c,
      const Offset(106, 150),
      const Offset(106, 201),
      color: Colors.deepOrange,
      width: 2,
    );
    line(
      c,
      const Offset(267, 150),
      const Offset(267, 201),
      color: Colors.deepOrange,
      width: 2,
    );
    line(
      c,
      const Offset(106, 201),
      const Offset(267, 201),
      color: Colors.deepOrange,
      width: 2,
    );
    meter(
      c,
      const Rect.fromLTWH(152, 184, 77, 38),
      'Calculated current A',
      run.invalid.isEmpty ? num(q('current')) : '—',
    );
    text(
      c,
      'No literal electron paths or measured particles',
      const Offset(40, 235),
      size: 9,
    );
  }

  void matter(Canvas c) {
    stand(c, const Offset(66, 217), 65);
    LabMaterials.metal(c, const Rect.fromLTWH(25, 103, 74, 44));
    LabMaterials.metal(c, const Rect.fromLTWH(168, 64, 16, 133));
    final sep = (v('separation') / 100e-9 * 22).clamp(15, 44).toDouble(),
        a = (v('slitWidth') / v('separation') * sep).clamp(2, 12).toDouble();
    for (final sign in [-1, 1]) {
      box(
        c,
        Rect.fromLTWH(168, 130 + sign * sep / 2 - a / 2, 16, a),
        const Color(0xffedf3f5),
        radius: 0,
      );
    }
    box(c, const Rect.fromLTWH(286, 38, 42, 175), const Color(0xff112c41));
    final dist = run.distribution;
    if (dist != null) {
      final peak = dist.density.reduce(math.max);
      for (int i = 0; i < 160; i++) {
        final y = -v('window') + 2 * v('window') * (i + .5) / 160,
            d = dist.probabilityDensity(y) / peak;
        box(
          c,
          Rect.fromLTWH(291, 43.0 + i, 32, 1.2),
          blue.withValues(alpha: (.12 + .78 * d).clamp(0, 1)),
          radius: 0,
        );
      }
      if (motion && overlays) {
        for (final y in run.positions) {
          c.drawCircle(
            Offset(307, 123 + 80 * y / v('window')),
            1.35,
            Paint()..color = amber.withValues(alpha: .5),
          );
        }
      }
    }
    text(c, 'λ=${num(q('wavelength'))} m', const Offset(30, 19), size: 10);
    text(c, 'Source', const Offset(43, 158), size: 9);
    text(c, 'Two slits', const Offset(144, 204), size: 9);
    text(c, 'Detector', const Offset(283, 217), size: 9);
    text(
      c,
      'Schematic scale • probability strip, no trajectory',
      const Offset(28, 235),
      size: 9,
    );
  }

  Color spectralColor(double wavelength) {
    final nm = wavelength * 1e9;
    if (nm < 380 || nm > 780) return Colors.blueGrey;
    if (nm < 450) return const Color(0xff7a43d9);
    if (nm < 495) return const Color(0xff2d7be7);
    if (nm < 570) return const Color(0xff25a768);
    if (nm < 590) return const Color(0xffd5b72b);
    if (nm < 620) return const Color(0xffe28632);
    return const Color(0xffd84c52);
  }

  void spectra(Canvas c) {
    stand(c, const Offset(80, 219), 68);
    glass(c, const Rect.fromLTWH(63, 62, 31, 116));
    box(
      c,
      const Rect.fromLTWH(71, 71, 15, 99),
      const Color(0xffa36bc3).withValues(alpha: run.mode >= 3 ? 0 : .4),
    );
    text(c, 'Hydrogen', const Offset(35, 184), size: 9);
    LabMaterials.metal(c, const Rect.fromLTWH(124, 103, 57, 38));
    box(
      c,
      const Rect.fromLTWH(202, 65, 131, 124),
      run.mode >= 3 ? const Color(0xfff0efe0) : navy,
    );
    final lower = 1 + run.mode % 3;
    for (int upper = lower + 1; upper <= 8; upper++) {
      final w = hydrogenTransition(lower, upper)['wavelength']!,
          xmin = lower == 1
              ? 90e-9
              : lower == 2
              ? 380e-9
              : 800e-9,
          xmax = lower == 1
              ? 130e-9
              : lower == 2
              ? 800e-9
              : 2100e-9,
          px = 212 + (w - xmin) / (xmax - xmin) * 110;
      line(
        c,
        Offset(px, 81),
        Offset(px, 170),
        color: run.mode >= 3 ? Colors.black87 : spectralColor(w),
        width: upper == v('upper') ? 3 : 1,
      );
    }
    final w = q('wavelength');
    text(c, 'λ ${num(w * 1e9)} nm vacuum', const Offset(102, 20), size: 10);
    text(
      c,
      ['UV', 'Visible (illustrative RGB)', 'Infrared'][q('spectralRegion')
          .toInt()
          .clamp(0, 2)],
      const Offset(202, 194),
      size: 8,
    );
    if (overlays) {
      for (int n = 1; n <= 8; n++) {
        final y = 35 + 65 / (n * n);
        line(
          c,
          Offset(133, y),
          Offset(178, y),
          color: n == lower || n == v('upper') ? amber : blue,
          width: n == lower || n == v('upper') ? 2 : 1,
        );
      }
      final yu = 35 + 65 / (v('upper') * v('upper')),
          yl = 35 + 65 / (lower * lower);
      arrow(
        c,
        Offset(154, run.mode >= 3 ? yl : yu),
        Offset(154, run.mode >= 3 ? yu : yl),
        color: amber,
      );
    }
    text(
      c,
      'Line heights schematic • no calibrated intensities',
      const Offset(30, 235),
      size: 9,
    );
  }

  void nucleus(Canvas c) {
    final isotope = isotopes[run.mode],
        az = v('azimuth'),
        points = <(double, double, double, bool)>[];
    for (int i = 0; i < isotope.a; i++) {
      final z = 1 - 2 * (i + .5) / isotope.a,
          phi = i * 2.399963229728653,
          r = math.sqrt(1 - z * z),
          shell = .45 + .55 * ((i % 4) + 1) / 4,
          x = r * math.cos(phi) * shell,
          y = r * math.sin(phi) * shell,
          depth = z * shell,
          rx = x * math.cos(az) + depth * math.sin(az),
          rz = -x * math.sin(az) + depth * math.cos(az),
          isProton =
              ((i + 1) * isotope.z / isotope.a).floor() !=
              (i * isotope.z / isotope.a).floor();
      points.add((rx, y, rz, isProton));
    }
    points.sort((a, b) => a.$3.compareTo(b.$3));
    LabMaterials.shadow(c, const Rect.fromLTWH(109, 203, 143, 16));
    for (final p in points) {
      LabMaterials.sphere(
        c,
        Offset(
          180 + p.$1 * 15 * math.pow(isotope.a, 1 / 3),
          130 + p.$2 * 15 * math.pow(isotope.a, 1 / 3),
        ),
        6.5 + 2 * (p.$3 + 1) / 2,
        p.$4 ? const Color(0xffc45e5c) : blue,
      );
    }
    text(
      c,
      '${isotope.a}_${isotope.z} ${isotope.symbol} • ${isotope.label}',
      const Offset(116, 17),
      size: 13,
    );
    text(
      c,
      'P+ ${isotope.z}',
      const Offset(26, 93),
      size: 11,
      color: const Color(0xffaa4d4d),
    );
    text(
      c,
      'N⁰ ${isotope.neutrons}',
      const Offset(284, 93),
      size: 11,
      color: blue,
    );
    text(
      c,
      'Schematic arbitrary nucleon positions • not to scale',
      const Offset(24, 234),
      size: 9,
    );
  }

  void radioactivity(Canvas c) {
    stand(c, const Offset(251, 218), 65);
    LabMaterials.metal(c, const Rect.fromLTWH(178, 109, 144, 40));
    c.drawOval(
      const Rect.fromLTWH(174, 109, 15, 40),
      Paint()..color = const Color(0xff273e4b),
    );
    LabMaterials.metal(c, const Rect.fromLTWH(43, 156, 48, 53));
    text(c, decayNames[run.mode], const Offset(41, 141), size: 10);
    meter(
      c,
      const Rect.fromLTWH(24, 30, 153, 49),
      'Simulated cumulative detector counts',
      num(q('detectorCounts')),
    );
    text(c, 'η=${num(v('efficiency'))}', const Offset(218, 57), size: 10);
    text(c, 'b=${num(v('background'))} s⁻¹', const Offset(205, 76), size: 9);
    if (overlays) {
      arrow(c, const Offset(94, 178), const Offset(168, 134), color: teal);
      text(c, 'Detector coupling', const Offset(94, 191), size: 8);
    }
    text(
      c,
      'Sealed-source simulation • no shielding/dose model',
      const Offset(25, 235),
      size: 9,
    );
  }

  @override
  bool shouldRepaint(covariant FMPainter old) =>
      old.run != run ||
      old.revision != revision ||
      old.labels != labels ||
      old.overlays != overlays ||
      old.motion != motion;
}
