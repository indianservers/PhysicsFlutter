import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/physics/live_optics.dart';
import '../../core/physics/optical_library.dart' show OVec;
import '../../core/rendering/interactive_mechanics.dart'
    show LaboratoryRoomPainter;
import '../../core/rendering/materials.dart';
import '../../core/rendering/optics_assets.dart';

Color laserColor(double metres) {
  final n = metres * 1e9;
  double r = 0, g = 0, b = 0;
  if (n < 440) {
    r = (440 - n) / 40;
    b = 1;
  } else if (n < 490) {
    g = (n - 440) / 50;
    b = 1;
  } else if (n < 510) {
    g = 1;
    b = (510 - n) / 20;
  } else if (n < 580) {
    r = (n - 510) / 70;
    g = 1;
  } else if (n < 645) {
    r = 1;
    g = (645 - n) / 65;
  } else {
    r = 1;
  }
  return Color.fromRGBO(
    (255 * r.clamp(0, 1)).round(),
    (255 * g.clamp(0, 1)).round(),
    (255 * b.clamp(0, 1)).round(),
    1,
  );
}

class LightRay {
  final Offset a, b;
  final double wavelength, power;
  final bool dashed;
  const LightRay(
    this.a,
    this.b,
    this.wavelength,
    this.power, {
    this.dashed = false,
  });
}

class OpticsHandle {
  final String name, key, label;
  final Rect bounds;
  const OpticsHandle(this.name, this.key, this.label, this.bounds);
}

class OpticalGeometry {
  final LiveOpticsModel model;
  final double h;
  final rays = <LightRay>[], handles = <OpticsHandle>[], spots = <Offset>[];
  late double axis, bench, opticX, scale, objectX, imageX, screenX;
  Offset hit = Offset.zero,
      source = Offset.zero,
      sourceDirection = const Offset(1, 0),
      analyzer = Offset.zero;
  Rect glass = Rect.zero, screen = Rect.zero, lens = Rect.zero;
  double imageY = 0;
  bool realImage = false;
  List<Offset> prism = [];
  double v(String k, [double fallback = 0]) => model.v(k, fallback);
  void ray(
    Offset a,
    Offset b, [
    double power = 1,
    double? lambda,
    bool dashed = false,
  ]) {
    if (a.dx.isFinite && a.dy.isFinite && b.dx.isFinite && b.dy.isFinite) {
      rays.add(
        LightRay(a, b, lambda ?? v('wavelength'), power, dashed: dashed),
      );
    }
  }

  void handle(String name, String key, String label, Rect rect) =>
      handles.add(OpticsHandle(name, key, label, rect.inflate(12)));
  OpticalGeometry(this.model, this.h) {
    axis = h * .48;
    bench = h * .82;
    scale = 1050;
    opticX = 340 + v('optic') * scale;
    imageX = 0;
    objectX = 0;
    screenX = 580;
    final kind = model.definition.kind, q = model.state;
    switch (kind) {
      case 0:
        hit = Offset(opticX, axis);
        final i = v('angle') * math.pi / 180;
        source = hit - const Offset(250, 0);
        sourceDirection = const Offset(1, 0);
        ray(source, hit);
        final reflected = Offset(-math.cos(2 * i), -math.sin(2 * i));
        ray(hit, hit + reflected * 550);
        spots.add(hit);
        lens = Rect.fromCenter(center: hit, width: 28, height: 180);
        handle(
          'mirror',
          'angle',
          'Rotate the mirror',
          Rect.fromCircle(center: hit, radius: 105),
        );
        handle(
          'source',
          'angle',
          'Aim the laser',
          Rect.fromCenter(
            center: source - const Offset(45, 0),
            width: 110,
            height: 70,
          ),
        );
      case 1:
        glass = Rect.fromLTWH(opticX - 100, axis - 65, 230, 160);
        hit = Offset(opticX - 40, glass.top);
        final i = v('angle') * math.pi / 180,
            d = Offset(math.sin(i), math.cos(i));
        final length = math.min(
          240.0,
          math.max(80.0, (hit.dy - 85) / math.max(.1, d.dy)),
        );
        source = hit - d * length;
        sourceDirection = d;
        ray(source, hit);
        final r = (q['Transmitted angle (°)'] ?? 0) * math.pi / 180,
            reflection = q['Reflected power']!;
        ray(hit, hit + Offset(d.dx, -d.dy) * 250, reflection);
        if (q['TIR'] == 0) {
          final paths = traceRectangularSlab(
            width: glass.width,
            height: glass.height,
            entry: OVec(hit.dx - glass.left, 0),
            direction: OVec(math.sin(r), math.cos(r)),
            insideIndex: v('n2'),
            outsideIndex: v('n1'),
            power: 1 - reflection,
          );
          for (final segment in paths.segments) {
            final a = glass.topLeft + Offset(segment.start.x, segment.start.y);
            final b = glass.topLeft + Offset(segment.end.x, segment.end.y);
            ray(a, b, segment.power);
            if (segment.inside) spots.add(b);
          }
        }
        spots.add(hit);
        handle(
          'source',
          'angle',
          'Change the angle of incidence',
          Rect.fromCenter(center: source, width: 100, height: 75),
        );
        handle('block', 'n2', 'Change the glass index', glass);
      case 2:
      case 3:
        final u = v('u'),
            f = v('focal') * (model.mode == 0 ? 1 : -1),
            distance = q['Image distance (m)'];
        realImage = distance != null && distance > 0;
        final imageWorld = distance == null
            ? 0.0
            : (kind == 2 ? distance : -distance).clamp(-1.2, 1.2).toDouble();
        final minWorld = math.min(-u, imageWorld),
            maxWorld = math.max(0.0, imageWorld);
        scale = math.min(1050, 630 / math.max(.45, maxWorld - minWorld));
        opticX = 55 - minWorld * scale + v('optic') * scale;
        objectX = opticX - u * scale;
        final height = v('height') * 2700,
            objectTip = Offset(objectX, axis - height),
            centre = Offset(opticX, axis);
        lens = Rect.fromCenter(center: centre, width: 40, height: 210);
        if (distance != null) {
          imageX = opticX + (kind == 2 ? 1 : -1) * distance * scale;
          imageY = axis - (q['Image height (m)'] ?? 0) * 2700;
        }
        final direction = kind == 2 ? 1.0 : -1.0;
        void outgoing(Offset at, int color) {
          final nm = [650e-9, 530e-9, 460e-9][color];
          Offset d;
          if (distance == null) {
            d = kind == 2
                ? Offset(1, height / (u * scale))
                : Offset(-1, height / (u * scale));
          } else {
            d = Offset(imageX, imageY) - at;
            if (!realImage) d = -d;
            if (d.distance > .00001) {
              d = d / d.distance;
            } else {
              d = Offset(direction, 0);
            }
          }
          ray(at, at + d * 1100, 1, nm);
          if (distance != null && !realImage) {
            ray(at, Offset(imageX, imageY), .35, nm, true);
          }
        }
        final first = Offset(opticX, objectTip.dy);
        ray(objectTip, first, 1, 650e-9);
        outgoing(first, 0);
        ray(objectTip, centre, 1, 530e-9);
        outgoing(centre, 1);
        final focus = opticX - f * scale, den = focus - objectX;
        if (den.abs() > 1e-5) {
          final y =
              objectTip.dy + (axis - objectTip.dy) * (opticX - objectX) / den;
          final at = Offset(opticX, y.clamp(axis - 120, axis + 120));
          ray(objectTip, at, 1, 460e-9);
          outgoing(at, 2);
        }
        handle(
          'object',
          'u',
          'Slide the object',
          Rect.fromLTWH(objectX - 25, axis - height - 12, 50, height + 28),
        );
        handle('lens', 'optic', 'Slide the optical element', lens.inflate(6));
        handle(
          'focus',
          'focal',
          'Move the focal marker',
          Rect.fromCircle(
            center: Offset(
              opticX + (kind == 2 ? 1 : -1) * f * scale,
              axis + 20,
            ),
            radius: 18,
          ),
        );
      case 4:
      case 5:
        source = Offset(100, axis);
        final slit = Offset(270, axis);
        screenX = 540 + (v('screen') - .5) * 60;
        screen = Rect.fromLTWH(screenX, axis - 132, 125, 265);
        ray(source, slit);
        if (model.invalid.isNotEmpty) {
          handle(
            'slit',
            'aperture',
            'Adjust the slit aperture',
            Rect.fromLTWH(230, axis - 125, 80, 240),
          );
          handle('screen', 'screen', 'Slide the observation screen', screen);
          break;
        }
        final gap = kind == 4 ? 10.0 : 0.0;
        for (int i = 0; i <= 16; i++) {
          final lateral = -.03 + .06 * i / 16,
              intensity = model.profile(lateral),
              target = Offset(
                screenX + (i / 16) * screen.width,
                axis + (i / 16 - .5) * 120,
              );
          for (final dy in kind == 4 ? [-gap / 2, gap / 2] : [0.0]) {
            ray(slit + Offset(0, dy), target, intensity * .22);
          }
        }
        handle(
          'slit',
          'aperture',
          'Adjust the slit aperture',
          Rect.fromLTWH(230, axis - 125, 80, 240),
        );
        handle('screen', 'screen', 'Slide the observation screen', screen);
        handle(
          'detector',
          'probe',
          'Move the intensity detector',
          Rect.fromCircle(
            center: Offset(
              screenX + screen.width * (v('probe') / .06 + .5),
              axis,
            ),
            radius: 18,
          ),
        );
      case 6:
        source = Offset(95, axis);
        analyzer = Offset(480 + v('optic') * 500, axis);
        final first = Offset(260, axis);
        final incident = v('intensity') / 60;
        ray(source, first, incident);
        ray(first, analyzer, .5 * incident);
        ray(
          analyzer,
          Offset(740, axis),
          q['Transmission']! * (v('intensity') / 60),
        );
        handle(
          'analyzer',
          'angle',
          'Rotate the analyzer ring',
          Rect.fromCircle(center: analyzer, radius: 82),
        );
        handle(
          'polarizer',
          'intensity',
          'Adjust incident intensity',
          Rect.fromCircle(center: first, radius: 75),
        );
      case 7:
        opticX = 370 + v('optic') * 250;
        scale = 210;
        final rotation = (30 - v('angle')) * math.pi / 180;
        Offset map(double x, double y) =>
            Offset(opticX + x * scale, axis - y * scale);
        prism = [
          for (final point in [
            const Offset(-.5, -.2886751346),
            const Offset(.5, -.2886751346),
            const Offset(0, .5773502692),
          ])
            map(
              point.dx * math.cos(rotation) - point.dy * math.sin(rotation),
              point.dx * math.sin(rotation) + point.dy * math.cos(rotation),
            ),
        ];
        final traces = model.prismTraces(spectrum: model.spectrum);
        source = map(-1.25, traces.first.segments.first.start.y);
        for (final trace in traces) {
          for (final segment in trace.segments) {
            if (segment.power < .015) continue;
            ray(
              segment.depth == 0
                  ? source
                  : map(segment.start.x, segment.start.y),
              map(segment.end.x, segment.end.y),
              segment.power / (model.spectrum ? 9 : 1),
              segment.wavelength * 1e-9,
            );
            if (segment.depth > 0) {
              spots.add(map(segment.start.x, segment.start.y));
            }
          }
        }
        handle(
          'prism',
          'angle',
          'Rotate the prism',
          Rect.fromLTWH(opticX - 130, axis - 145, 260, 245),
        );
      case 8:
        glass = Rect.fromLTWH(300, axis - 135, 230, 230);
        hit = Offset(
          glass.center.dx,
          glass.inflate(24).top + glass.inflate(24).height * .37,
        );
        final a = v('angle') * math.pi / 180,
            d = Offset(math.cos(a), math.sin(a));
        source = hit - d * 280;
        sourceDirection = d;
        ray(source, hit);
        final r = q['Reflectance']!;
        ray(hit, hit + Offset(-d.dx, d.dy) * 400, r);
        ray(hit, hit + d * 450, 1 - r);
        spots.add(hit);
        handle('film', 'thickness', 'Drag to vary film thickness', glass);
      case 9:
        scale = math.min(950, 390 / v('separation'));
        opticX = 210 + v('optic') * scale;
        final second = opticX + v('separation') * scale;
        source = Offset(75, axis);
        final f1 = v('f1'),
            f2 = v('f2'),
            d = v('separation'),
            vertical = 2300.0;
        for (final initialHeight in [-.014, 0.0, .014]) {
          var theta = 0.0;
          double objectHeight = 0;
          if (model.mode == 1) {
            final u = q['Objective object distance (m)'];
            if (u == null) continue;
            objectHeight = .001;
            theta = (initialHeight - objectHeight) / u;
            final objectAt = Offset(
              opticX - u * scale,
              axis - objectHeight * vertical,
            );
            ray(
              objectAt,
              Offset(opticX, axis - initialHeight * vertical),
              1,
              650e-9,
            );
          } else {
            ray(
              Offset(80, axis - initialHeight * vertical),
              Offset(opticX, axis - initialHeight * vertical),
            );
          }
          final after1 = theta - initialHeight / f1,
              y2 = initialHeight + d * after1,
              after2 = after1 - y2 / f2;
          final a = Offset(opticX, axis - initialHeight * vertical),
              b = Offset(second, axis - y2 * vertical),
              end = Offset(
                730,
                axis - (y2 + (730 - second) / scale * after2) * vertical,
              );
          ray(a, b);
          ray(b, end);
        }
        handle(
          'objective',
          'optic',
          'Slide the objective lens',
          Rect.fromCenter(center: Offset(opticX, axis), width: 65, height: 190),
        );
        handle(
          'eyepiece',
          'separation',
          'Slide the eyepiece',
          Rect.fromCenter(center: Offset(second, axis), width: 65, height: 160),
        );
        handle(
          'objectiveFocus',
          'f1',
          'Change objective focal length',
          Rect.fromCircle(center: Offset(opticX, axis - 110), radius: 20),
        );
        handle(
          'eyepieceFocus',
          'f2',
          'Change eyepiece focal length',
          Rect.fromCircle(center: Offset(second, axis - 95), radius: 20),
        );
    }
  }
}

class InteractiveOpticsScene extends StatefulWidget {
  final LiveOpticsModel model;
  final VoidCallback pause, changed;
  final ValueChanged<String> inspect;
  const InteractiveOpticsScene({
    super.key,
    required this.model,
    required this.pause,
    required this.changed,
    required this.inspect,
  });
  @override
  State<InteractiveOpticsScene> createState() => _InteractiveOpticsSceneState();
}

class _InteractiveOpticsSceneState extends State<InteractiveOpticsScene> {
  final surface = GlobalKey();
  Map<String, double> original = {};
  Offset start = Offset.zero;
  OpticsHandle? active;
  late OpticalGeometry frozen;
  Offset local(Offset global) {
    final box = surface.currentContext!.findRenderObject()! as RenderBox;
    return box.globalToLocal(global) * (740 / box.size.width);
  }

  void begin(OpticsHandle handle, Offset global, OpticalGeometry geometry) {
    widget.pause();
    original = Map.of(widget.model.p);
    start = local(global);
    frozen = geometry;
    setState(() => active = handle);
  }

  void drag(Offset global) {
    final h = active;
    if (h == null) return;
    final p = local(global), d = p - start, m = widget.model;
    double v(String key) => original[key]!;
    switch (h.name) {
      case 'mirror':
        m.set('angle', v('angle') + d.dy * .22);
      case 'source':
        m.set('angle', v('angle') - d.dy * .22);
      case 'block':
        m.set('n2', v('n2') + d.dx * .004);
      case 'object':
        m.set('u', v('u') - d.dx / frozen.scale);
      case 'lens':
        m.set('optic', v('optic') + d.dx / frozen.scale);
        m.set('u', v('u') + d.dx / frozen.scale);
      case 'focus':
        m.set(
          'focal',
          v('focal') + (m.definition.kind == 3 ? -1 : 1) * d.dx / frozen.scale,
        );
      case 'slit':
        m.set('aperture', v('aperture') + d.dx * 8e-7);
      case 'screen':
        m.set('screen', v('screen') + d.dx / 60);
      case 'detector':
        m.set('probe', v('probe') + d.dx / frozen.screen.width * .06);
      case 'analyzer':
        final a = math.atan2(
              p.dy - frozen.analyzer.dy,
              p.dx - frozen.analyzer.dx,
            ),
            b = math.atan2(
              start.dy - frozen.analyzer.dy,
              start.dx - frozen.analyzer.dx,
            );
        m.set('angle', (v('angle') + (a - b) * 180 / math.pi) % 180);
      case 'polarizer':
        m.set('intensity', v('intensity') - d.dy * .5);
      case 'prism':
        m.set('angle', v('angle') + d.dx * .2);
      case 'film':
        m.set('thickness', v('thickness') + d.dy * 5e-9);
      case 'objective':
        m.set('optic', v('optic') + d.dx / frozen.scale);
        m.set('separation', v('separation') - d.dx / frozen.scale);
      case 'eyepiece':
        m.set('separation', v('separation') + d.dx / frozen.scale);
      case 'objectiveFocus':
        m.set('f1', v('f1') - d.dy * .001);
      case 'eyepieceFocus':
        m.set('f2', v('f2') - d.dy * .0005);
    }
    widget.changed();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final geometry = OpticalGeometry(
            widget.model,
            box.maxHeight * 740 / box.maxWidth,
          ),
          factor = box.maxWidth / 740;
      return ClipRect(
        child: Stack(
          key: surface,
          children: [
            const Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(painter: OpticalEnvironmentPainter()),
              ),
            ),
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: LiveOpticsPainter(geometry, selected: active?.name),
                ),
              ),
            ),
            for (final handle in geometry.handles)
              Positioned(
                left: handle.bounds.left * factor,
                top: handle.bounds.top * factor,
                width: handle.bounds.width * factor,
                height: handle.bounds.height * factor,
                child: Semantics(
                  label: handle.label,
                  button: true,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: GestureDetector(
                      key: Key('optics-object-${handle.name}'),
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (d) =>
                          begin(handle, d.globalPosition, geometry),
                      onPanUpdate: (d) => drag(d.globalPosition),
                      onPanEnd: (_) => setState(() => active = null),
                      onPanCancel: () => setState(() => active = null),
                      onTap: () => widget.inspect(handle.key),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 6,
              child: IgnorePointer(
                child: Text(
                  (widget.model.invalid.isNotEmpty
                          ? widget.model.invalid
                          : active?.label) ??
                      'Drag the apparatus • tap a part to edit its value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xffa7c5d8),
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class OpticalEnvironmentPainter extends CustomPainter {
  const OpticalEnvironmentPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final image = OpticsAssets.environment;
    if (image == null) {
      const LaboratoryRoomPainter().paint(canvas, size);
      return;
    }
    final sourceSize = Size(image.width.toDouble(), image.height.toDouble());
    final fitted = applyBoxFit(BoxFit.cover, sourceSize, size);
    final source = Alignment.center.inscribe(
      fitted.source,
      Offset.zero & sourceSize,
    );
    canvas.drawImageRect(
      image,
      source,
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x33001727), Color(0x55001220)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant OpticalEnvironmentPainter old) => false;
}

class LiveOpticsPainter extends CustomPainter {
  final OpticalGeometry g;
  final String? selected;
  const LiveOpticsPainter(this.g, {this.selected});
  static const white = Color(0xffebf7ff),
      blue = Color(0xff00a6ff),
      gold = Color(0xffffbd32);
  double v(String key, [double fallback = 0]) => g.v(key, fallback);
  Map<String, double> get q => g.model.state;
  void line(Canvas c, Offset a, Offset b, Color color, [double width = 1]) =>
      c.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
  void text(
    Canvas c,
    String value,
    Offset at, {
    Color color = white,
    double size = 17,
    bool plate = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: 'HomeManrope',
          fontSize: size,
          color: color,
          fontWeight: FontWeight.w600,
          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 700);
    if (plate) {
      final r = Rect.fromLTWH(
        at.dx - 7,
        at.dy - 5,
        tp.width + 14,
        tp.height + 10,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(7)),
        Paint()..color = const Color(0xe8082232),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(7)),
        Paint()
          ..color = const Color(0xff2b6c8c)
          ..style = PaintingStyle.stroke,
      );
    }
    tp.paint(c, at);
  }

  void dash(Canvas c, Offset a, Offset b, Color color) {
    final d = b - a;
    if (d.distance < .01) return;
    final u = d / d.distance;
    for (double t = 0; t < d.distance; t += 13) {
      line(c, a + u * t, a + u * math.min(t + 7, d.distance), color, 1.4);
    }
  }

  void bloom(Canvas c, Offset p, Color color, [double strength = 1]) {
    c.drawCircle(
      p,
      23,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: .65 * strength),
            color.withValues(alpha: .16 * strength),
            Colors.transparent,
          ],
          stops: const [0, .32, 1],
        ).createShader(Rect.fromCircle(center: p, radius: 23)),
    );
    c.drawCircle(
      p,
      3,
      Paint()
        ..color = Colors.white.withValues(alpha: strength.clamp(0, 1))
        ..blendMode = BlendMode.plus,
    );
  }

  /// Additive, linear-path beam layers. Zero physical power produces no glow.
  void beam(Canvas c, LightRay ray) {
    if (ray.power < 1e-7) return;
    final color = laserColor(ray.wavelength),
        power = ray.power * v('power', 1),
        brightness = math.pow(power.clamp(0, 5), .45).toDouble().clamp(0, 1);
    if (ray.dashed) {
      dash(c, ray.a, ray.b, color.withValues(alpha: .5));
      return;
    }
    final width = 1 + math.sqrt(power.clamp(0, 5));
    for (final layer in [(24.0, 9.0, .16), (10.0, 3.0, .38), (2.4, 0.0, .95)]) {
      final paint = Paint()
        ..color = color.withValues(alpha: layer.$3 * brightness)
        ..strokeWidth = layer.$1 * width * .5
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.plus;
      if (layer.$2 > 0) {
        paint.maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          layer.$2 * width * .5,
        );
      }
      c.drawLine(ray.a, ray.b, paint);
    }
    line(
      c,
      ray.a,
      ray.b,
      Colors.white.withValues(
        alpha: (g.model.definition.kind == 7 ? .14 : .9) * brightness,
      ),
      .85,
    );
  }

  void stand(Canvas c, double x, double top, {double width = 68}) {
    c.drawOval(
      Rect.fromLTWH(x - width * .6, g.bench + 9, width * 1.5, 16),
      Paint()
        ..color = const Color(0x99000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    if (g.bench - top > 0) {
      LabMaterials.metal(c, Rect.fromLTWH(x - 8, top, 16, g.bench - top));
    }
    LabMaterials.metal(c, Rect.fromLTWH(x - width / 2, g.bench - 2, width, 18));
    for (final dx in [-width * .34, width * .34]) {
      c.save();
      c.translate(x + dx, g.bench + 7);
      c.scale(2);
      LabMaterials.screw(c, Offset.zero);
      c.restore();
    }
  }

  void table(Canvas c) {
    final front = Rect.fromLTWH(0, g.bench, 740, math.max(35, g.h - g.bench));
    LabMaterials.metal(c, front);
    final top = Path()
      ..moveTo(0, g.bench)
      ..lineTo(90, g.bench - 38)
      ..lineTo(740, g.bench - 38)
      ..lineTo(740, g.bench)
      ..close();
    c.drawPath(
      top,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff20313c), Color(0xff9caab0), Color(0xff263944)],
        ).createShader(front),
    );
    for (int row = 0; row < 3; row++) {
      for (int i = 0; i < 20; i++) {
        final p = Offset(i * 38.0 + row * 12, g.bench - 6 - row * 11);
        c.drawOval(
          Rect.fromCenter(center: p, width: 6, height: 3),
          Paint()..color = const Color(0xff061723),
        );
      }
    }
    line(
      c,
      Offset(0, g.bench),
      Offset(740, g.bench),
      const Color(0xffe3f2f8),
      2,
    );
    final rail = Rect.fromLTWH(28, g.bench + 18, 680, 16);
    LabMaterials.metal(c, rail);
    final kind = g.model.definition.kind;
    final origin = kind == 4 || kind == 5
        ? 270.0
        : g.opticX - v('optic') * g.scale;
    final scale = kind == 4 || kind == 5
        ? (g.screenX - 270) / v('screen')
        : kind == 7
        ? 2100.0
        : g.scale;
    final minCm = ((30 - origin) / scale * 100).floor(),
        maxCm = ((710 - origin) / scale * 100).ceil();
    for (int cm = minCm; cm <= maxCm; cm++) {
      final x = origin + cm / 100 * scale;
      line(
        c,
        Offset(x, g.bench + 35),
        Offset(
          x,
          g.bench +
              (cm % 10 == 0
                  ? 48
                  : cm % 5 == 0
                  ? 44
                  : 40),
        ),
        white,
        .8,
      );
      if (cm % 10 == 0) text(c, '$cm', Offset(x - 8, g.bench + 48), size: 12);
    }
    text(c, 'cm', Offset(704, g.bench + 45), size: 13);
  }

  void laser(Canvas c) {
    final d = g.sourceDirection,
        angle = math.atan2(d.dy, d.dx),
        bodyCentre = g.source - d * 65;
    stand(c, bodyCentre.dx, bodyCentre.dy + 24, width: 75);
    c.save();
    c.translate(g.source.dx, g.source.dy);
    c.rotate(angle);
    if (OpticsAssets.image != null) {
      OpticsAssets.emitter(c, const Rect.fromLTWH(-135, -26, 139, 54));
    } else {
      LabMaterials.metal(c, const Rect.fromLTWH(-135, -26, 139, 54));
    }
    c.restore();
    bloom(c, g.source, laserColor(v('wavelength')));
  }

  void glassLens(
    Canvas c,
    double x,
    double radius,
    bool diverging, {
    double height = 180,
  }) {
    stand(c, x, g.axis + height * .48);
    final r = Rect.fromCenter(
          center: Offset(x, g.axis),
          width: radius,
          height: height,
        ),
        path = Path();
    if (diverging) {
      path.moveTo(r.left, r.top);
      path.quadraticBezierTo(x + radius * .22, g.axis, r.left, r.bottom);
      path.lineTo(r.right, r.bottom);
      path.quadraticBezierTo(x - radius * .22, g.axis, r.right, r.top);
      path.close();
    } else {
      path.moveTo(x, r.top);
      path.cubicTo(
        r.left - radius * .12,
        r.top + height * .25,
        r.left - radius * .12,
        r.bottom - height * .25,
        x,
        r.bottom,
      );
      path.cubicTo(
        r.right + radius * .12,
        r.bottom - height * .25,
        r.right + radius * .12,
        r.top + height * .25,
        x,
        r.top,
      );
      path.close();
    }
    c.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0x33c2efff),
            Color(0x9963a6c9),
            Color(0x11ecfcff),
            Color(0x99c7e9ff),
          ],
          stops: [0, .17, .55, 1],
        ).createShader(r),
    );
    c.save();
    c.clipPath(path);
    OpticsAssets.draw(c, diverging ? 3 : 2, r.inflate(4), opacity: .62);
    c.restore();
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xffbdeaff)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    line(
      c,
      Offset(x - 4, g.axis - height * .41),
      Offset(x - 4, g.axis + height * .30),
      const Color(0x99f4faff),
      1,
    );
  }

  void arrow(
    Canvas c,
    double x,
    double y,
    String label, {
    Color color = const Color(0xffff5035),
  }) {
    final start = Offset(x, g.axis), end = Offset(x, y);
    if ((y - g.axis).abs() < 2) return;
    line(c, start, end, color.withValues(alpha: .35), 12);
    line(c, start, end, color, 4);
    line(c, start, end, white, 1);
    final sign = y < g.axis ? 1.0 : -1.0;
    line(c, end, end + Offset(-9, 14 * sign), color, 3);
    line(c, end, end + Offset(9, 14 * sign), color, 3);
    text(
      c,
      label,
      Offset((x - 24).clamp(10, 670), y < g.axis ? g.axis + 22 : y + 10),
      size: 16,
    );
  }

  void protractor(Canvas c, Offset centre, double normalAngle) {
    final r = Rect.fromCircle(center: centre, radius: 115);
    c.drawArc(
      r,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xaa1c526d)
        ..strokeWidth = 22
        ..style = PaintingStyle.stroke,
    );
    for (int n = 0; n <= 36; n++) {
      final a = math.pi + n * math.pi / 36;
      line(
        c,
        centre + Offset(math.cos(a), math.sin(a)) * 100,
        centre + Offset(math.cos(a), math.sin(a)) * (n % 6 == 0 ? 121 : 112),
        const Color(0xff88c7e2),
        .9,
      );
    }
    final normal = Offset(math.cos(normalAngle), math.sin(normalAngle));
    dash(c, centre - normal * 140, centre + normal * 140, white);
  }

  void screenPattern(Canvas c) {
    final r = g.screen;
    c.drawRect(
      r.shift(const Offset(9, -6)),
      Paint()..color = const Color(0xff82979e),
    );
    c.drawRect(r, Paint()..color = const Color(0xff030c13));
    final color = laserColor(v('wavelength'));
    // Actual physical lateral coordinate spans ±30 mm across the screen face.
    for (int i = 0; g.model.invalid.isEmpty && i < 240; i++) {
      final lateral = -.03 + .06 * (i + .5) / 240,
          intensity = g.model.profile(lateral),
          x = r.left + r.width * i / 240;
      final display = math.pow(intensity, .65).toDouble();
      c.drawRect(
        Rect.fromLTWH(x, r.top + 9, r.width / 240 + 1, r.height - 18),
        Paint()..color = color.withValues(alpha: display * .95),
      );
    }
    for (final x in [r.left, r.right]) {
      LabMaterials.metal(c, Rect.fromLTWH(x - 3, r.top, 6, r.height));
    }
    stand(c, r.center.dx, r.bottom, width: 105);
    final at = r.left + r.width * (v('probe') / .06 + .5);
    line(
      c,
      Offset(at, r.top + 4),
      Offset(at, r.bottom - 4),
      const Color(0x99e2fcff),
      1,
    );
    c.drawCircle(
      Offset(at, r.center.dy),
      6,
      Paint()
        ..color = white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  void spectralFan(Canvas c) {
    final strongest = <double, LightRay>{};
    for (final ray in g.rays) {
      if (ray.a.dx <= g.opticX + 12 ||
          ray.b.dx < ray.a.dx + 100 ||
          ray.power < .02) {
        continue;
      }
      if (strongest[ray.wavelength] == null ||
          strongest[ray.wavelength]!.power < ray.power) {
        strongest[ray.wavelength] = ray;
      }
    }
    final ordered = strongest.values.toList()
      ..sort((a, b) => a.wavelength.compareTo(b.wavelength));
    for (int i = 1; i < ordered.length; i++) {
      final a = ordered[i - 1],
          b = ordered[i],
          path = Path()..addPolygon([a.a, a.b, b.b, b.a], true);
      c.drawPath(
        path,
        Paint()
          ..color = laserColor((a.wavelength + b.wavelength) / 2)
              .withValues(alpha: .58),
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 740);
    final c = canvas;
    table(c);
    final kind = g.model.definition.kind;
    if ([0, 1, 4, 5, 6, 7, 8, 9].contains(kind)) laser(c);
    if (kind == 2 || kind == 3) {
      dash(c, Offset(25, g.axis), Offset(725, g.axis), const Color(0xff577c92));
    }
    if (kind == 4 || kind == 5) screenPattern(c);
    // Optical glass and surface glow are overlaid after light has been traced.
    for (final ray in g.rays) {
      beam(c, ray);
    }
    for (final p in g.spots) {
      bloom(c, p, laserColor(v('wavelength')), .8);
    }
    switch (kind) {
      case 0:
        final angle = v('angle') * math.pi / 180;
        stand(c, g.hit.dx, g.hit.dy + 65);
        protractor(c, g.hit, angle + math.pi);
        c.save();
        c.translate(g.hit.dx, g.hit.dy);
        c.rotate(angle);
        OpticsAssets.draw(c, 1, const Rect.fromLTWH(-12, -100, 24, 200));
        c.restore();
        bloom(c, g.hit, laserColor(v('wavelength')));
        text(
          c,
          'θi = ${v('angle').toStringAsFixed(1)}°',
          Offset(55, 45),
          color: const Color(0xff35dbff),
          size: 24,
          plate: true,
        );
        text(
          c,
          'θr = ${v('angle').toStringAsFixed(1)}°',
          Offset(450, 45),
          color: gold,
          size: 24,
          plate: true,
        );
      case 1:
        final r = g.glass;
        stand(c, r.center.dx, r.bottom, width: r.width + 20);
        OpticsAssets.draw(c, 4, r, opacity: .35);
        c.drawRect(r, Paint()..color = const Color(0x225ce3ff));
        c.drawRect(
          r,
          Paint()
            ..color = const Color(0xffade9ff)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
        dash(
          c,
          Offset(g.hit.dx, r.top - 95),
          Offset(g.hit.dx, r.bottom + 60),
          white,
        );
        text(
          c,
          'n₁ ${v('n1').toStringAsFixed(2)}',
          const Offset(45, 26),
          color: const Color(0xffa4d9ee),
          size: 20,
        );
        text(
          c,
          'n₂ ${v('n2').toStringAsFixed(2)}',
          Offset(r.right - 90, 26),
          size: 20,
        );
        text(
          c,
          'θi ${v('angle').toStringAsFixed(1)}°',
          Offset((g.hit.dx - 170).clamp(20, 530), r.top - 45),
          color: laserColor(v('wavelength')),
          size: 22,
        );
        text(
          c,
          q['TIR'] == 1
              ? 'Total internal reflection'
              : 'θr ${q['Transmitted angle (°)']!.toStringAsFixed(1)}°',
          Offset(r.left + 12, r.center.dy),
          color: gold,
          size: 22,
          plate: true,
        );
      case 2:
      case 3:
        if (kind == 2) {
          glassLens(
            c,
            g.opticX,
            (62 - v('focal') * 90).clamp(20, 65),
            g.model.mode == 1,
            height: 210,
          );
        } else {
          stand(c, g.opticX, g.axis + 105);
          c.save();
          if (g.model.mode == 1) {
            c.translate(g.opticX * 2, 0);
            c.scale(-1, 1);
          }
          OpticsAssets.draw(
            c,
            9,
            Rect.fromCenter(
              center: Offset(g.opticX - 8, g.axis),
              width: 45,
              height: 218,
            ),
          );
          c.restore();
        }
        arrow(c, g.objectX, g.axis - v('height') * 2700, 'Object');
        final f = v('focal') * (g.model.mode == 0 ? 1 : -1),
            fX = g.opticX + (kind == 2 ? 1 : -1) * f * g.scale;
        c.drawCircle(Offset(fX, g.axis), 4, Paint()..color = white);
        text(c, 'F', Offset(fX - 5, g.axis + 17), size: 17);
        if (kind == 3) {
          final x = g.opticX - 2 * f * g.scale;
          c.drawCircle(Offset(x, g.axis), 4, Paint()..color = white);
          text(c, 'C', Offset(x - 5, g.axis + 17), size: 17);
        }
        if (q['At infinity'] == 1) {
          text(
            c,
            'Parallel rays • image at ∞',
            const Offset(35, 28),
            color: gold,
            size: 22,
            plate: true,
          );
        } else if (g.imageX >= 10 && g.imageX <= 730) {
          arrow(
            c,
            g.imageX,
            g.imageY,
            g.realImage ? 'Real image' : 'Virtual image',
            color: g.realImage
                ? const Color(0xffff6548)
                : const Color(0xffffc555),
          );
        } else {
          text(
            c,
            'Image ${((q['Image distance (m)'] ?? 0) * 100).toStringAsFixed(1)} cm • outside view',
            const Offset(28, 28),
            size: 19,
            plate: true,
          );
        }
      case 4:
      case 5:
        final rect = Rect.fromLTWH(
          220,
          g.axis - 125,
          100,
          g.bench - g.axis + 125,
        );
        OpticsAssets.draw(c, kind == 4 ? 6 : 7, rect);
        c.drawRect(
          Rect.fromLTWH(260, g.axis - 58, 24, 116),
          Paint()..color = const Color(0xff060f16),
        );
        final gap = 4 + v('aperture') * 120000;
        for (final dx in kind == 4 ? [-gap / 2, gap / 2] : [0.0]) {
          final r = Rect.fromCenter(
            center: Offset(270 + dx, g.axis),
            width: kind == 4 ? 3 : (gap * .35).clamp(2, 10),
            height: 90,
          );
          c.drawRect(r, Paint()..color = const Color(0xff90b3c4));
          c.drawLine(
            r.topCenter,
            r.bottomCenter,
            Paint()
              ..color = laserColor(v('wavelength'))
              ..strokeWidth = 1.6,
          );
        }
        text(
          c,
          g.model.invalid.isNotEmpty
              ? 'Far-field model unavailable'
              : kind == 4
              ? 'Fringe spacing ${(q['Fringe spacing (m)']! * 1000).toStringAsFixed(3)} mm'
              : 'Central width ${(q['Central width (m)']! * 1000).toStringAsFixed(2)} mm',
          const Offset(340, 27),
          color: const Color(0xffff6f6c),
          size: 22,
          plate: true,
        );
        text(
          c,
          'L ${v('screen').toStringAsFixed(2)} m',
          Offset(g.screenX - 20, g.screen.top - 32),
          size: 18,
        );
      case 6:
        for (final x in [260.0, g.analyzer.dx]) {
          final r = Rect.fromLTWH(
            x - 68,
            g.axis - 76,
            136,
            g.bench - g.axis + 80,
          );
          OpticsAssets.draw(c, 8, r);
        }
        final a = v('angle') * math.pi / 180,
            u = Offset(math.sin(a), -math.cos(a));
        line(
          c,
          const Offset(260, 0) + Offset(0, g.axis - 50),
          Offset(260, g.axis + 50),
          const Color(0xffedf7ff),
          1.3,
        );
        line(
          c,
          g.analyzer - u * 53,
          g.analyzer + u * 53,
          const Color(0xffedf7ff),
          2,
        );
        c.drawCircle(g.analyzer + u * 64, 7, Paint()..color = blue);
        text(c, 'Polarizer', Offset(205, g.axis - 110), size: 19);
        text(
          c,
          'Analyzer ${v('angle').toStringAsFixed(0)}°',
          Offset(g.analyzer.dx - 78, g.axis - 110),
          size: 19,
        );
        text(
          c,
          'I = ${q['Transmitted intensity (W/m²)']!.toStringAsFixed(2)} W/m²',
          Offset(400, g.axis + 120),
          color: const Color(0xff29ff85),
          size: 24,
          plate: true,
        );
      case 7:
        if (g.model.spectrum) spectralFan(c);
        final bounds = Path()..addPolygon(g.prism, true);
        final rect = bounds.getBounds();
        stand(c, g.opticX, rect.bottom, width: 200);
        c.drawPath(bounds, Paint()..color = const Color(0x225acbff));
        c.save();
        c.clipPath(bounds);
        OpticsAssets.draw(c, 5, rect, opacity: .40);
        c.restore();
        c.drawPath(
          bounds,
          Paint()
            ..color = const Color(0xffb9eaff)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        text(
          c,
          '${g.model.definition.modes[g.model.mode]}\nn(λ) ${q['Index']!.toStringAsFixed(4)}',
          const Offset(420, 26),
          size: 19,
          plate: true,
        );
      case 8:
        final r = g.glass;
        final frame = r.inflate(24),
            window = Rect.fromLTRB(
              frame.left + frame.width * .23,
              frame.top + frame.height * .09,
              frame.left + frame.width * .80,
              frame.top + frame.height * .65,
            );
        c.save();
        c.clipRect(window);
        for (int i = 0; i < 96; i++) {
          final thickness = v('thickness') * (.72 + .56 * i / 95),
              red = filmReflectance(
                650e-9,
                thickness,
                v('filmIndex'),
                v('angle'),
              ),
              green = filmReflectance(
                530e-9,
                thickness,
                v('filmIndex'),
                v('angle'),
              ),
              blueValue = filmReflectance(
                450e-9,
                thickness,
                v('filmIndex'),
                v('angle'),
              );
          double exposed(double r) => g.model.mode == 0
              ? math.sqrt((r / .12).clamp(0, 1))
              : math.sqrt(1 - r);
          final color = Color.fromRGBO(
            (255 * exposed(red)).round(),
            (255 * exposed(green)).round(),
            (255 * exposed(blueValue)).round(),
            .85,
          );
          final wave = math.sin(i * .17) * 10;
          c.drawRect(
            Rect.fromLTWH(
              window.left,
              window.top + i * window.height / 96 + wave,
              window.width,
              window.height / 96 + 2,
            ),
            Paint()..color = color,
          );
        }
        c.restore();
        OpticsAssets.draw(c, 10, frame);
        text(
          c,
          'R ${(q['Reflectance']! * 100).toStringAsFixed(2)}%\nT ${(q['Transmittance']! * 100).toStringAsFixed(2)}%',
          const Offset(555, 40),
          size: 23,
          plate: true,
        );
      case 9:
        final second = g.opticX + v('separation') * g.scale;
        glassLens(c, g.opticX, 43, false, height: 170);
        glassLens(c, second, 30, false, height: 132);
        text(c, 'Objective f₁', Offset(g.opticX - 65, g.axis - 130), size: 19);
        text(c, 'Eyepiece f₂', Offset(second - 55, g.axis - 110), size: 19);
        if (g.model.mode == 1 && q['Valid microscope'] == 0) {
          text(
            c,
            'Increase lens separation\nto form an intermediate real image',
            const Offset(245, 30),
            size: 19,
            color: gold,
            plate: true,
          );
        } else if (g.model.mode == 0 && q['Afocal'] == 0) {
          text(
            c,
            'Defocused telescope\nSet spacing to ${(q['Afocal separation (m)']! * 100).toStringAsFixed(1)} cm',
            const Offset(385, 28),
            size: 21,
            plate: true,
          );
        } else {
          text(
            c,
            'M = ${(q['Angular magnification'] ?? q['Magnification'])!.toStringAsFixed(2)}×',
            const Offset(430, 28),
            size: 24,
            plate: true,
          );
        }
        if (g.model.mode == 0 && q['Defocus (m)']!.abs() < 1e-5) {
          text(c, 'Final image at ∞', Offset(565, g.axis + 90), size: 19);
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LiveOpticsPainter old) => true;
}
