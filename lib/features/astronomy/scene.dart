import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/physics/astronomy_run.dart';
import '../../core/rendering/materials.dart';
import '../../core/rendering/scientific_text.dart';

class AstronomyPainter extends CustomPainter {
  static final _orbitPaths = <bool, List<Path>>{};
  final AstronomyRun run;
  final Map<int, ui.Image> textures;
  final bool overlays, motion;
  AstronomyPainter(
    this.run, {
    this.textures = const {},
    this.overlays = true,
    this.motion = true,
  });
  void text(
    Canvas c,
    String s,
    Offset p, {
    double size = 10,
    Color color = Colors.white,
  }) => ScientificText.paint(c, s, p, font: size, color: color);
  void line(
    Canvas c,
    Offset a,
    Offset b, {
    Color color = Colors.tealAccent,
    double width = 1,
  }) => c.drawLine(
    a,
    b,
    Paint()
      ..color = color
      ..strokeWidth = width,
  );
  void globe(
    Canvas c,
    Offset centre,
    double radius,
    int index, {
    Offset sun = const Offset(180, 125),
  }) {
    LabMaterials.sphere(
      c,
      centre,
      radius,
      [
        Colors.grey,
        Colors.amber,
        Colors.blue,
        Colors.orange,
        Colors.brown,
        Colors.amber,
        Colors.cyan,
        Colors.blue,
      ][index],
      texture: textures[index],
    );
    final delta = sun - centre,
        unit = delta.distance == 0
            ? const Offset(-1, -1)
            : delta / delta.distance;
    c.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(unit.dx, unit.dy),
          end: Alignment(-unit.dx, -unit.dy),
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: .1),
            Colors.black.withValues(alpha: .92),
          ],
          stops: const [0, .45, 1],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 360, size.height / 270);
    final c = canvas;
    c.drawRect(
      const Rect.fromLTWH(0, 0, 360, 270),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xff051424), Color(0xff132d43)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(const Rect.fromLTWH(0, 0, 360, 270)),
    );
    for (int i = 0; i < 65; i++) {
      c.drawCircle(
        Offset((i * 137.29) % 360, (i * 73.19) % 238),
        i % 7 == 0 ? 1 : .45,
        Paint()..color = Colors.white.withValues(alpha: .25 + i % 4 * .12),
      );
    }
    if (run.invalid.isNotEmpty) {
      text(c, 'Unsupported configuration', const Offset(65, 120), size: 15);
      canvas.restore();
      return;
    }
    switch (run.kind) {
      case 0:
        orbits(c);
      case 1:
        star(c);
      case 2:
        spectrograph(c);
      case 3:
        galaxyScene(c);
      case 4:
        expansion(c);
      case 5:
        transitScene(c);
    }
    text(
      c,
      [
        'Educational J2000 model',
        'MIST reference visualization',
        'Synthetic spectrum · false-color strip',
        'Illustrative galaxy mass model',
        'FLRW schematic grid',
        'Synthetic uniform-disk transit',
      ][run.kind],
      const Offset(12, 251),
      size: 9,
    );
    canvas.restore();
  }

  void orbits(Canvas c) {
    const centre = Offset(160, 126);
    final compressed = run.v('scaleMode') > .5;
    Offset project(Map<String, double> s) {
      final r = math.sqrt(s['x']! * s['x']! + s['y']! * s['y']!) / au,
          scale = (compressed ? math.sqrt(r / 32) : r / 32) * 112;
      return centre +
          Offset(s['x']! / au / r * scale, -s['y']! / au / r * scale);
    }

    final paths = _orbitPaths.putIfAbsent(
      compressed,
      () => [
        for (final model in planets)
          (() {
            final path = Path();
            for (int i = 0; i <= 100; i++) {
              final pos = project(model.at(model.period * i / 100));
              if (i == 0) {
                path.moveTo(pos.dx, pos.dy);
              } else {
                path.lineTo(pos.dx, pos.dy);
              }
            }
            return path;
          })(),
      ],
    );
    for (int planet = 0; planet < 8; planet++) {
      final model = planets[planet], path = paths[planet];
      c.drawPath(
        path,
        Paint()
          ..color = planet == run.mode
              ? Colors.tealAccent.withValues(alpha: .7)
              : Colors.white24
          ..style = PaintingStyle.stroke,
      );
      final p = project(run.orbitStates[planet]);
      globe(c, p, planet == run.mode ? 8 : 4, planet, sun: centre);
      if (overlays && planet == run.mode) {
        text(c, model.name, Offset(12, 27), size: 13);
      }
    }
    c.drawCircle(
      centre,
      9,
      Paint()
        ..shader = const RadialGradient(
          colors: [Colors.white, Colors.amber, Colors.deepOrange],
        ).createShader(Rect.fromCircle(center: centre, radius: 9)),
    );
    globe(c, const Offset(319, 51), 25, run.mode, sun: const Offset(270, 30));
    text(
      c,
      [
        'Mariner10 partial mosaic',
        'Magellan radar composite',
        'USGS topographic illustration',
        'Viking mosaic',
        'Voyager processed mosaic',
        'Davis artist impression',
        'Seal artist impression',
        'Davis artist impression',
      ][run.mode],
      const Offset(12, 207),
      size: 9,
    );
    text(
      c,
      compressed
          ? 'Compressed radius: √(r/32AU)'
          : 'Physical distance:112px=32AU',
      const Offset(12, 221),
      size: 10,
    );
    text(
      c,
      'Bodies exaggerated • ecliptic projection • no live sky',
      const Offset(12, 236),
      size: 9,
    );
  }

  void star(Canvas c) {
    final s = run.state,
        T = s['temperature']!,
        radius = (25 + math.log(1 + s['radius']! / solarRadius) * 20)
            .clamp(26, 85)
            .toDouble();
    final color = T < 4500
        ? Colors.deepOrange
        : T < 7500
        ? Colors.amber.shade100
        : Colors.lightBlue.shade100;
    c.drawCircle(
      const Offset(175, 130),
      radius,
      Paint()
        ..shader =
            RadialGradient(
              center: const Alignment(-.25, -.3),
              colors: [
                Colors.white,
                color,
                Color.lerp(color, Colors.black, .55)!,
              ],
            ).createShader(
              Rect.fromCircle(center: const Offset(175, 130), radius: radius),
            ),
    );
    c.save();
    c.clipPath(
      Path()..addOval(
        Rect.fromCircle(center: const Offset(175, 130), radius: radius),
      ),
    );
    for (int i = 0; i < 170; i++) {
      final a = i * 2.39996,
          r = radius * math.sqrt((i + .5) / 170),
          p = Offset(175 + math.cos(a) * r, 130 + math.sin(a) * r);
      c.drawCircle(
        p,
        1.3 + (i % 3) * .5,
        Paint()..color = Colors.black.withValues(alpha: .04 + (i % 5) * .016),
      );
    }
    c.restore();
    text(c, stellarPhase(s['phase']!), const Offset(15, 20), size: 13);
    text(c, 'Teff ${T.toStringAsFixed(0)} K', const Offset(15, 42));
    if (overlays) {
      line(c, const Offset(175, 130), Offset(175 + radius, 130));
      text(
        c,
        'R=${(s['radius']! / solarRadius).toStringAsPrecision(4)} R☉',
        const Offset(15, 200),
      );
    }
    text(c, 'Schematic surface • log-compressed radius', const Offset(15, 220));
    text(c, 'Color illustrative, not a photograph', const Offset(15, 234));
  }

  void spectrograph(Canvas c) {
    LabMaterials.metal(c, const Rect.fromLTWH(53, 93, 171, 42));
    c.drawOval(
      const Rect.fromLTWH(207, 91, 30, 45),
      Paint()..color = Colors.black87,
    );
    line(
      c,
      const Offset(128, 132),
      const Offset(132, 213),
      color: Colors.blueGrey,
      width: 9,
    );
    line(
      c,
      const Offset(132, 190),
      const Offset(87, 236),
      color: Colors.grey,
      width: 6,
    );
    line(
      c,
      const Offset(132, 190),
      const Offset(179, 236),
      color: Colors.grey,
      width: 6,
    );
    LabMaterials.metal(c, const Rect.fromLTWH(253, 123, 83, 62));
    line(
      c,
      const Offset(225, 113),
      const Offset(253, 140),
      color: Colors.amber,
      width: 2,
    );
    for (int i = 0; i < 80; i++) {
      final wavelength = 350e-9 + i / 79 * 450e-9,
          s = spectrumAt(
            wavelength,
            run.v('temperature'),
            run.v('velocity'),
            run.v('resolution'),
            lines: run.mode == 0,
          );
      c.drawRect(
        Rect.fromLTWH(258 + i * .9, 132, .95, 35),
        Paint()
          ..color = HSVColor.fromAHSV(
            1,
            270 - i / 79 * 270,
            .8,
            (s['syntheticFlux']! * .8 + .15).clamp(0, 1),
          ).toColor(),
      );
    }
    text(
      c,
      'Telescope → slit / grating → detector',
      const Offset(20, 25),
      size: 12,
    );
    text(c, 'Normalized Bλ + synthetic line template', const Offset(20, 45));
    text(
      c,
      'Vacuum Balmer wavelengths • not observed Vega',
      const Offset(15, 231),
      size: 9,
    );
    if (overlays) {
      final x = 258 + (run.v('wavelength') - 350e-9) / 450e-9 * 71;
      line(c, Offset(x, 129), Offset(x, 171), color: Colors.amber, width: 2);
      text(
        c,
        'Cursor ${(run.v('wavelength') * 1e9).toStringAsFixed(2)} nm',
        const Offset(15, 203),
      );
    }
  }

  void galaxyScene(Canvas c) {
    const centre = Offset(180, 126);
    final p = Paint();
    for (int i = 0; i < 2100; i++) {
      final r = 110 * math.sqrt((i + .5) / 2100),
          theta = i * 2.39996323,
          arm = math.cos(2 * (theta - 2 * math.log(1 + r / 8))),
          bright = (math.exp(-r / 45) * (.35 + .65 * arm * arm)).clamp(0, 1);
      p.color = Color.lerp(
        const Color(0xff8ac7ec),
        const Color(0xffffd8aa),
        math.exp(-r / 30),
      )!.withValues(alpha: bright * .8);
      c.drawCircle(
        centre + Offset(r * math.cos(theta), .6 * r * math.sin(theta)),
        .8 + (i % 3) * .3,
        p,
      );
    }
    c.drawCircle(
      centre,
      17,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.amber.shade50, Colors.amber.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: centre, radius: 17)),
    );
    final x = 180 + run.v('radiusKpc') / 30 * 110;
    if (overlays) {
      line(c, centre, Offset(x, 126), color: Colors.amber, width: 2);
      c.drawCircle(Offset(x, 126), 4, Paint()..color = Colors.white);
    }
    text(
      c,
      'R=${run.v('radiusKpc').toStringAsFixed(2)} kpc',
      const Offset(18, 23),
      size: 12,
    );
    text(
      c,
      'Schematic morphology; probe is model radius',
      const Offset(15, 225),
    );
    text(
      c,
      'No photometric fit or unique mass inference',
      const Offset(15, 238),
      size: 9,
    );
  }

  void expansion(Canvas c) {
    final a = run.state['scaleFactor']!,
        spacing = 90 * a,
        nx = (180 / spacing).ceil() + 1,
        ny = (100 / (spacing * .65)).ceil() + 1;
    for (int i = -nx; i <= nx; i++) {
      for (int j = -ny; j <= ny; j++) {
        final p = Offset(180 + i * spacing, 130 + j * spacing * .65);
        if (p.dx > 10 && p.dx < 350 && p.dy > 65 && p.dy < 220) {
          c.drawCircle(p, 3, Paint()..color = Colors.white70);
          line(
            c,
            p,
            p + Offset(spacing, 0),
            color: Colors.teal.withValues(alpha: .3),
          );
          line(
            c,
            p,
            p + Offset(0, spacing * .65),
            color: Colors.teal.withValues(alpha: .3),
          );
        }
      }
    }
    if (overlays) {
      line(
        c,
        const Offset(20, 211),
        Offset(20 + 120 * a, 211),
        color: Colors.amber,
        width: 2,
      );
      text(c, 'Ruler length ∝ a', const Offset(160, 207), size: 9);
    }
    text(
      c,
      'a = ${a.toStringAsFixed(4)} • z=${run.v('redshift').toStringAsFixed(3)}',
      const Offset(18, 20),
      size: 13,
    );
    text(
      c,
      'Homogeneous comoving grid • no preferred centre',
      const Offset(14, 40),
    );
    text(
      c,
      'Spacing tracks scale factor; no explosion into space',
      const Offset(14, 232),
      size: 9,
    );
  }

  void transitScene(Canvas c) {
    final s = run.state,
        star = s['starRadius']!,
        ratio = s['planetRadius']! / star;
    const centre = Offset(180, 128), radius = 83.0;
    c.drawCircle(centre, radius, Paint()..color = const Color(0xffffd78e));
    // Uniform intensity is required by the exact model: no decorative limb darkening.
    c.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.amber,
    );
    final p = centre + Offset(s['x']! / star * radius, s['y']! / star * radius);
    if (s['front'] == 1 &&
        (p - centre).distance < radius + ratio * radius + 30) {
      c.drawCircle(p, ratio * radius, Paint()..color = const Color(0xff0b1827));
    }
    if (overlays) {
      line(
        c,
        const Offset(25, 128),
        const Offset(335, 128),
        color: Colors.white24,
      );
    }
    text(
      c,
      'Model F/F₀=${s['flux']!.toStringAsFixed(6)}',
      const Offset(16, 22),
      size: 14,
    );
    text(
      c,
      'b=${s['impactParameter']!.toStringAsFixed(3)} • exact circle overlap',
      const Offset(16, 44),
    );
    text(
      c,
      'Projected Rs/Rp geometry to scale • uniform disk',
      const Offset(15, 225),
    );
    text(
      c,
      'No limb darkening • unnamed synthetic system',
      const Offset(15, 239),
      size: 9,
    );
  }

  @override
  bool shouldRepaint(covariant AstronomyPainter old) => true;
}
