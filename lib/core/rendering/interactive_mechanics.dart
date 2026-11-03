import 'apparatus_sprites.dart';

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../features/workbench/instrument_types.dart';
import 'materials.dart';

const apparatusBlue = Color(0xff079bff), apparatusMint = Color(0xff36ffd2);

/// Rendered apparatus and touch targets share geometry and source-model state.
class InteractiveMechanics extends StatefulWidget {
  final String id;
  final Map<String, double> parameters, values;
  final List<InstrumentControl> controls;
  final double time;
  final int mode;
  final bool plumb;
  final VoidCallback pause, play;
  final ValueChanged<InstrumentControl>? inspect;
  const InteractiveMechanics({
    super.key,
    required this.id,
    required this.parameters,
    required this.values,
    required this.controls,
    required this.time,
    required this.pause,
    required this.play,
    this.mode = 0,
    this.plumb = true,
    this.inspect,
  });
  @override
  State<InteractiveMechanics> createState() => _InteractiveMechanicsState();
}

class _InteractiveMechanicsState extends State<InteractiveMechanics> {
  final surface = GlobalKey();
  ApparatusHandle? dragging;
  Offset start = Offset.zero, last = Offset.zero;
  Map<String, double> original = {};
  late ApparatusLayout frozen;
  InstrumentControl? control(String key) =>
      widget.controls.where((c) => c.keyName == key).firstOrNull;
  void setValue(String key, double value) {
    final c = control(key);
    if (c != null && value.isFinite) {
      final next = value.clamp(c.min, c.max);
      if ((next - c.value).abs() > 1e-10) c.change(next);
    }
  }

  Offset point(Offset global) {
    final box = surface.currentContext!.findRenderObject()! as RenderBox;
    return box.globalToLocal(global) * (720 / box.size.width);
  }

  void begin(ApparatusHandle handle, Offset global, ApparatusLayout layout) {
    widget.pause();
    frozen = layout;
    original = Map.of(widget.parameters);
    start = point(global);
    last = start;
    setState(() => dragging = handle);
  }

  void move(Offset global) {
    final handle = dragging;
    if (handle == null) return;
    final p = point(global), delta = p - start;
    last = p;
    double v(String key, [double fallback = 0]) => original[key] ?? fallback;
    switch (handle.action) {
      case 'force':
        final d = p - frozen.crateCentre;
        setValue('angle', math.atan2(-d.dy, d.dx) * 180 / math.pi);
        setValue(
          'force',
          v('force') +
              (d.distance - (start - frozen.crateCentre).distance) / 3.2,
        );
      case 'crate':
        setValue('x0', v('x0') + delta.dx / frozen.scale);
      case 'cart':
        setValue('x0', v('x0') + delta.dx / frozen.scale);
      case 'hanger':
        setValue('x0', v('x0') + delta.dy / frozen.scale);
      case 'pulleyA':
        setValue('release', v('release') - delta.dy / frozen.scale);
      case 'pulleyB':
        setValue(
          'release',
          v('release') + delta.dy / (frozen.scale * (widget.mode == 1 ? 2 : 1)),
        );
      case 'leverA':
        setValue('r1', v('r1') + delta.dx / frozen.scale);
      case 'leverB':
        setValue('r2', v('r2') + delta.dx / frozen.scale);
      case 'pivot':
        setValue('pivot', v('pivot') + delta.dx / frozen.scale);
      case 'forceA':
        setValue('force', v('force') + delta.dy / 3);
      case 'forceB':
        setValue('force2', v('force2') + delta.dy / 3);
      case 'pointA':
        setValue('x0', v('x0') + delta.dx / frozen.scale);
        setValue('y1', v('y1') - delta.dy / frozen.scale);
      case 'pointB':
        setValue('x2', v('x2') + delta.dx / frozen.scale);
        setValue('y2', v('y2') - delta.dy / frozen.scale);
      case 'pointC':
        setValue('x3', v('x3') + delta.dx / frozen.scale);
        setValue('y3', v('y3') - delta.dy / frozen.scale);
      case 'collisionA':
        setValue('x0', v('x0') + delta.dx / frozen.scale);
      case 'collisionB':
        setValue('x2', v('x2') + delta.dx / frozen.scale);
      case 'velocityA':
        setValue('v0', v('v0') + delta.dx / 45);
      case 'velocityB':
        setValue('v2', v('v2') + delta.dx / 45);
      case 'disk':
        final a = math.atan2(
              p.dy - frozen.diskCentre.dy,
              p.dx - frozen.diskCentre.dx,
            ),
            initial = math.atan2(
              start.dy - frozen.diskCentre.dy,
              start.dx - frozen.diskCentre.dx,
            );
        setValue(
          'omega0',
          math.atan2(math.sin(a - initial), math.cos(a - initial)) * 5,
        );
      case 'diskRadius':
        setValue('radius', v('radius') + delta.dx / 390);
      case 'rolling':
        final t = Offset(math.cos(frozen.incline), math.sin(frozen.incline));
        setValue(
          'start',
          (v('start') + (delta.dx * t.dx + delta.dy * t.dy) / frozen.scale)
              .clamp(0, v('length', 2) - .01),
        );
      case 'incline':
        setValue('incline', (v('incline') + delta.dy * .12).clamp(5, 45));
      case 'spring':
        setValue('extension', v('extension') + delta.dy / 1250);
      case 'tensile':
        setValue('force', v('force') + delta.dy * .7);
      case 'diameter':
        setValue('radius', v('radius') + delta.dx * .000005);
      case 'massBall':
        setValue('a', v('a') + delta.dy * .0002);
      case 'timeBall':
        setValue('v0', v('v0') + delta.dx * .008);
    }
  }

  void end(DragEndDetails details) {
    final handle = dragging;
    if (handle == null) return;
    if (handle.action == 'disk') {
      final r = last - frozen.diskCentre,
          velocity = details.velocity.pixelsPerSecond;
      final box = surface.currentContext!.findRenderObject()! as RenderBox;
      final angular =
          (r.dx * velocity.dy - r.dy * velocity.dx) *
          (720 / box.size.width) /
          math.max(1600, r.distanceSquared);
      if (angular.abs() > .2) setValue('omega0', angular.clamp(-15, 15));
    }
    setState(() => dragging = null);
    if (handle.release) widget.play();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final layout = ApparatusLayout(
            widget.id,
            widget.parameters,
            widget.values,
            widget.time,
            widget.mode,
            box.maxHeight * 720 / box.maxWidth,
          ),
          factor = box.maxWidth / 720;
      return ClipRect(
        child: Stack(
          key: surface,
          children: [
            const Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(painter: LaboratoryRoomPainter()),
              ),
            ),
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: RealisticMechanicsPainter(
                    layout,
                    plumb: widget.plumb,
                    selected: dragging?.action,
                  ),
                ),
              ),
            ),
            for (final handle in layout.handles)
              Positioned(
                left: handle.rect.left * factor,
                top: handle.rect.top * factor,
                width: handle.rect.width * factor,
                height: handle.rect.height * factor,
                child: Semantics(
                  label: handle.label,
                  button: true,
                  onIncrease: () {
                    final c = control(handle.edit);
                    if (c != null) {
                      widget.pause();
                      setValue(c.keyName, c.value + (c.max - c.min) / 30);
                    }
                  },
                  onDecrease: () {
                    final c = control(handle.edit);
                    if (c != null) {
                      widget.pause();
                      setValue(c.keyName, c.value - (c.max - c.min) / 30);
                    }
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: GestureDetector(
                      key: Key('apparatus-handle-${handle.action}'),
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (d) =>
                          begin(handle, d.globalPosition, layout),
                      onPanUpdate: (d) => move(d.globalPosition),
                      onPanEnd: end,
                      onPanCancel: () => setState(() => dragging = null),
                      onTap: () {
                        final c = control(handle.edit);
                        if (c != null) widget.inspect?.call(c);
                      },
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 8,
              child: IgnorePointer(
                child: Text(
                  dragging?.label ??
                      'Drag the objects • release to run • tap to edit',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xffc3d5e5),
                    shadows: [Shadow(color: Colors.black, blurRadius: 5)],
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

class ApparatusHandle {
  final String action, label, edit;
  final Rect rect;
  final bool release;
  const ApparatusHandle(
    this.action,
    this.label,
    this.edit,
    this.rect, {
    this.release = false,
  });
}

class ApparatusLayout {
  final String id;
  final Map<String, double> p, q;
  final double time, h;
  final int mode;
  final handles = <ApparatusHandle>[];
  double scale = 100, incline = 0;
  Offset crateCentre = Offset.zero,
      diskCentre = Offset.zero,
      pulley = Offset.zero,
      movable = Offset.zero,
      beamStart = Offset.zero,
      beamEnd = Offset.zero,
      pivot = Offset.zero,
      com = Offset.zero,
      rampStart = Offset.zero,
      rampEnd = Offset.zero,
      ball = Offset.zero;
  Rect crate = Rect.zero,
      cartA = Rect.zero,
      cartB = Rect.zero,
      weightA = Rect.zero,
      weightB = Rect.zero;
  List<Offset> points = [];
  double diskRadius = 120, ballRadius = 36, springEnd = 0, wireEnd = 0;
  double v(String key, [double fallback = 0]) => p[key] ?? fallback;
  double s(String key, [double fallback = 0]) => q[key] ?? fallback;
  double get floor => h * .83;
  void hit(
    String action,
    String label,
    String edit,
    Rect rect, {
    bool release = false,
  }) => handles.add(
    ApparatusHandle(action, label, edit, rect.inflate(9), release: release),
  );
  ApparatusLayout(this.id, this.p, this.q, this.time, this.mode, this.h) {
    switch (id) {
      case 's02-e00':
        scale = 65;
        final x = (360 + s('x', v('x0')) * scale).clamp(155.0, 540.0);
        crate = Rect.fromLTWH(x - 108, floor - 181, 216, 170);
        crateCentre = crate.center;
        hit('crate', 'Drag the crate and release', 'm', crate, release: true);
        final d = v('angle') * math.pi / 180,
            tip =
                crateCentre +
                Offset(math.cos(d), -math.sin(d)) *
                    math.max(160, v('force') * 3.2);
        hit(
          'force',
          'Drag the applied-force arrow',
          'force',
          Rect.fromCircle(center: tip, radius: 30),
          release: true,
        );
      case 's04-e01':
        scale = 125;
        final travel = s('x', v('x0'));
        cartA = Rect.fromLTWH(
          (90 + travel * scale).clamp(55, 430),
          h * .48,
          172,
          82,
        );
        pulley = Offset(598, h * .32);
        weightB = Rect.fromLTWH(
          603,
          (h * .57 + travel * scale).clamp(h * .48, h * .78),
          66,
          84,
        );
        hit(
          'cart',
          'Pull the cart and release',
          'm',
          cartA.inflate(12),
          release: true,
        );
        hit(
          'hanger',
          'Pull the hanging weight and release',
          'hanger',
          weightB,
          release: true,
        );
      case 's02-e02':
        scale = 120;
        final displacement = s('x', v('release'));
        pulley = Offset(465, h * .19);
        movable = Offset(260, h * .43 - displacement * scale);
        weightA = Rect.fromLTWH(208, movable.dy + 103, 104, 106);
        weightB = Rect.fromLTWH(
          506,
          h * .54 + displacement * scale * (mode == 1 ? 2 : 1),
          98,
          104,
        );
        if (mode == 0) {
          weightA = Rect.fromLTWH(
            352,
            h * .52 - displacement * scale,
            104,
            106,
          );
        }
        hit(
          'pulleyA',
          'Lift the load and release',
          'm',
          weightA,
          release: true,
        );
        hit(
          'pulleyB',
          'Pull the effort weight and release',
          'm2',
          weightB,
          release: true,
        );
      case 's02-e03':
        scale = 135;
        final y = h * .39;
        beamStart = Offset(65, y);
        beamEnd = Offset(656, y);
        pivot = Offset(360 + v('pivot') * scale, y + 25);
        weightA = Rect.fromLTWH(360 + v('r1') * scale - 46, y + 115, 92, 80);
        weightB = Rect.fromLTWH(360 + v('r2') * scale - 46, y + 115, 92, 80);
        hit('leverA', 'Slide weight A along the beam', 'r1', weightA);
        hit('leverB', 'Slide weight B along the beam', 'r2', weightB);
        hit(
          'pivot',
          'Move the fulcrum',
          'pivot',
          Rect.fromCenter(
            center: pivot + const Offset(0, 80),
            width: 110,
            height: 160,
          ),
        );
        hit(
          'forceA',
          'Pull to change force A',
          'force',
          Rect.fromCircle(
            center: weightA.topCenter + const Offset(0, -36),
            radius: 24,
          ),
        );
        hit(
          'forceB',
          'Pull to change force B',
          'force2',
          Rect.fromCircle(
            center: weightB.topCenter + const Offset(0, -36),
            radius: 24,
          ),
        );
      case 's02-e04':
        scale = 145;
        Offset project(double x, double y) =>
            Offset(360 + x * scale, h * .70 - y * scale);
        points = [
          project(v('x0'), v('y1')),
          project(v('x2'), v('y2')),
          project(v('x3'), v('y3')),
        ];
        com = project(s('x'), s('y'));
        for (int i = 0; i < 3; i++) {
          hit(
            ['pointA', 'pointB', 'pointC'][i],
            'Drag mass ${['A', 'B', 'C'][i]} in two dimensions',
            ['m', 'm2', 'm3'][i],
            Rect.fromCircle(center: points[i], radius: 30),
          );
        }
      case 's02-e05':
        final xa = s('x', v('x0')),
            xb = s('x2', v('x2', 3)),
            left = math.min(-3.0, math.min(xa, xb) - 1.5),
            right = math.max(5.0, math.max(xa, xb) + 1.5);
        scale = 570 / (right - left);
        final y = h * .62;
        cartA = Rect.fromLTWH(70 + (xa - left) * scale - 42, y, 94, 73);
        cartB = Rect.fromLTWH(70 + (xb - left) * scale - 42, y, 94, 73);
        hit(
          'collisionA',
          'Position cart A and release',
          'm',
          cartA.inflate(8),
          release: true,
        );
        hit(
          'collisionB',
          'Position cart B and release',
          'm2',
          cartB.inflate(8),
          release: true,
        );
        hit(
          'velocityA',
          'Drag the blue velocity arrow',
          'v0',
          Rect.fromCircle(
            center: cartA.topCenter + Offset(v('v0') * 45, -52),
            radius: 25,
          ),
        );
        hit(
          'velocityB',
          'Drag the red velocity arrow',
          'v2',
          Rect.fromCircle(
            center: cartB.topCenter + Offset(v('v2') * 45, -52),
            radius: 25,
          ),
        );
      case 's02-e06':
        diskCentre = Offset(315, h * .43);
        diskRadius = 65 + v('radius', .3) * 230;
        hit(
          'disk',
          'Spin the disk and release',
          'mass',
          Rect.fromCircle(center: diskCentre, radius: diskRadius),
          release: true,
        );
        hit(
          'diskRadius',
          'Drag the rim to change disk radius',
          'radius',
          Rect.fromCircle(
            center: diskCentre + Offset(diskRadius, 0),
            radius: 24,
          ),
        );
      case 's02-e07':
        incline = v('incline', 20) * math.pi / 180;
        scale = 510 / v('length', 2);
        rampStart = Offset(88, h * .35);
        rampEnd =
            rampStart + Offset(math.cos(incline), math.sin(incline)) * 510;
        ballRadius = 22 + v('radius', .1) * 190;
        final distance = s(
          'distance',
          v('start'),
        ).clamp(0.0, v('length', 2)).toDouble();
        ball =
            rampStart +
            Offset(math.cos(incline), math.sin(incline)) * distance * scale +
            Offset(math.sin(incline), -math.cos(incline)) * ballRadius;
        hit(
          'rolling',
          'Place the sphere and release',
          'mass',
          Rect.fromCircle(center: ball, radius: ballRadius),
          release: true,
        );
        hit(
          'incline',
          'Raise or lower the ramp',
          'incline',
          Rect.fromCircle(center: rampEnd, radius: 28),
        );
      case 's02-e08':
        springEnd = h * .30 + v('extension', .08) * 1250;
        weightA = Rect.fromLTWH(242, springEnd + 42, 126, 76);
        hit(
          'spring',
          'Pull the mass to stretch the spring',
          'extension',
          weightA.inflate(12),
        );
      case 's02-e09':
        wireEnd = h * .62 + s('length') * 200;
        weightA = Rect.fromLTWH(170, wireEnd, 150, 100);
        hit(
          'tensile',
          'Pull the load to apply tensile force',
          'force',
          weightA,
        );
        hit(
          'diameter',
          'Drag to change wire diameter',
          'radius',
          Rect.fromLTWH(224, h * .26, 54, h * .25),
        );
      case 's01-e04':
        incline = .26;
        rampStart = Offset(365, h * .31);
        rampEnd = Offset(682, h * .69);
        ball =
            rampStart +
            (rampEnd - rampStart) *
                (s('travelled') / v('distance', .5)).clamp(0, 1) -
            const Offset(0, 24);
        hit(
          'timeBall',
          'Drag the ball to change launch speed',
          'v0',
          Rect.fromCircle(center: ball, radius: 27),
          release: true,
        );
        hit(
          'massBall',
          'Drag the balance mass',
          'a',
          Rect.fromCircle(center: Offset(153, h * .42), radius: 38),
        );
    }
  }
}

class LaboratoryRoomPainter extends CustomPainter {
  const LaboratoryRoomPainter();
  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    c.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff152a35), Color(0xff092333), Color(0xff111b20)],
        ).createShader(r),
    );
    final scale = size.width / 720;
    c.save();
    c.scale(scale);
    final h = size.height / scale;
    c.saveLayer(
      Rect.fromLTWH(0, 0, 720, h),
      Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
    );
    for (int shelf = 0; shelf < 3; shelf++) {
      final y = h * (.15 + shelf * .23);
      c.drawRect(
        Rect.fromLTWH(0, y, 720, 12),
        Paint()..color = const Color(0xff172024),
      );
      for (int j = 0; j < 8; j++) {
        final x = 14 + j * 101.0 + (shelf.isOdd ? 25 : 0),
            height = 28.0 + (j * 19 + shelf * 11) % 55;
        final rect = Rect.fromLTWH(x, y - height, 33 + (j % 3) * 12.0, height);
        c.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(9)),
          Paint()
            ..color = [
              const Color(0xff213b44),
              const Color(0xff5a5140),
              const Color(0xff233744),
            ][j % 3],
        );
      }
    }
    c.drawRect(
      Rect.fromLTWH(566, 0, 12, h * .78),
      Paint()..color = const Color(0xff2b5671),
    );
    for (final p in [
      Offset(25, h * .17),
      Offset(689, h * .39),
      Offset(522, h * .68),
    ]) {
      c.drawCircle(
        p,
        27,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xffffe5a5), Color(0x88e5b973), Color(0x00e5b973)],
          ).createShader(Rect.fromCircle(center: p, radius: 27)),
      );
    }
    c.restore();
    final table = Rect.fromLTWH(0, h * .81, 720, h * .19);
    LabMaterials.wood(c, table);
    c.drawRect(
      table,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0x990b1720)],
        ).createShader(table),
    );
    c.drawLine(
      Offset(0, h * .81),
      Offset(720, h * .81),
      Paint()
        ..color = const Color(0xffb4a18b)
        ..strokeWidth = 2,
    );
    c.restore();
    c.drawRect(
      r,
      Paint()
        ..shader = const RadialGradient(
          radius: .9,
          colors: [Colors.transparent, Color(0x8c000b13)],
          stops: [.3, 1],
        ).createShader(r),
    );
  }

  @override
  bool shouldRepaint(covariant LaboratoryRoomPainter old) => false;
}

class RealisticMechanicsPainter extends CustomPainter {
  final ApparatusLayout l;
  final bool plumb;
  final String? selected;
  const RealisticMechanicsPainter(this.l, {this.plumb = true, this.selected});
  double v(String key, [double fallback = 0]) => l.v(key, fallback);
  double q(String key, [double fallback = 0]) => l.s(key, fallback);
  static const ink = Color(0xffeef7ff),
      steel = Color(0xffa9bdc8),
      blue = Color(0xff078bff),
      red = Color(0xffff4945);
  void line(Canvas c, Offset a, Offset b, Color color, [double width = 2]) =>
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
    double size = 19,
    Color color = ink,
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
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 3, offset: Offset(0, 1)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 650);
    if (plate) {
      final r = Rect.fromLTWH(
        at.dx - 10,
        at.dy - 7,
        tp.width + 20,
        tp.height + 14,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(9)),
        Paint()..color = const Color(0xeb0a2433),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(9)),
        Paint()
          ..color = const Color(0xff4c7891)
          ..style = PaintingStyle.stroke,
      );
    }
    tp.paint(c, at);
  }

  void shadow(Canvas c, Rect r) => c.drawOval(
    r,
    Paint()
      ..color = const Color(0x99000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
  );
  void body(
    Canvas c,
    Rect r, {
    bool wood = false,
    Color? color,
    Offset depth = const Offset(18, -14),
  }) {
    shadow(c, Rect.fromLTWH(r.left - 5, r.bottom - 3, r.width + 40, 20));
    final top = Path()
      ..moveTo(r.left, r.top)
      ..lineTo(r.left + depth.dx, r.top + depth.dy)
      ..lineTo(r.right + depth.dx, r.top + depth.dy)
      ..lineTo(r.right, r.top)
      ..close();
    final side = Path()
      ..moveTo(r.right, r.top)
      ..lineTo(r.right + depth.dx, r.top + depth.dy)
      ..lineTo(r.right + depth.dx, r.bottom + depth.dy)
      ..lineTo(r.right, r.bottom)
      ..close();
    c.drawPath(
      side,
      Paint()
        ..shader = LinearGradient(
          colors: wood
              ? const [Color(0xff885a2c), Color(0xff49351e)]
              : [
                  Color.lerp(color ?? steel, Colors.white, .3)!,
                  Color.lerp(color ?? steel, Colors.black, .7)!,
                ],
        ).createShader(r),
    );
    if (wood) {
      LabMaterials.wood(c, r);
    } else if (color == null) {
      LabMaterials.metal(c, r);
    } else {
      c.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(7)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, Colors.white, .45)!,
              color,
              Color.lerp(color, Colors.black, .55)!,
            ],
            stops: const [0, .25, 1],
          ).createShader(r),
      );
      LabMaterials.texture(c, r, 1, opacity: .25);
    }
    c.drawPath(
      top,
      Paint()
        ..shader = LinearGradient(
          colors: wood
              ? const [Color(0xffffdf9b), Color(0xffb78040)]
              : [Color.lerp(color ?? steel, Colors.white, .7)!, color ?? steel],
        ).createShader(r),
    );
    c.drawPath(
      top,
      Paint()
        ..color = const Color(0x99f2f5ef)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    c.drawRect(
      r.deflate(1),
      Paint()
        ..color = const Color(0x77f4f4d8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    for (final p in [
      r.topLeft + const Offset(8, 8),
      r.topRight + const Offset(-8, 8),
      r.bottomLeft + const Offset(8, -8),
      r.bottomRight + const Offset(-8, -8),
    ]) {
      c.save();
      c.translate(p.dx, p.dy);
      c.scale(2);
      LabMaterials.screw(c, Offset.zero);
      c.restore();
    }
  }

  void cylinder(Canvas c, Rect r, {bool brass = false}) {
    final colors = brass
        ? const [
            Color(0xff6b4415),
            Color(0xffe8bc64),
            Color(0xffffefb4),
            Color(0xff99702f),
            Color(0xff4e3515),
          ]
        : const [
            Color(0xff162b38),
            Color(0xff8ba0aa),
            Color(0xfff5fbff),
            Color(0xff8e9da4),
            Color(0xff263946),
          ];
    shadow(c, Rect.fromLTWH(r.left - 12, r.bottom - 6, r.width + 35, 21));
    c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          colors: colors,
          stops: const [0, .28, .42, .67, 1],
        ).createShader(r),
    );
    c.drawOval(
      Rect.fromLTWH(r.left, r.bottom - 10, r.width, 20),
      Paint()..shader = LinearGradient(colors: colors).createShader(r),
    );
    c.drawOval(
      Rect.fromLTWH(r.left, r.top - 11, r.width, 22),
      Paint()
        ..shader = LinearGradient(colors: colors.reversed.toList())
            .createShader(r),
    );
    c.drawOval(
      Rect.fromLTWH(r.left, r.top - 11, r.width, 22),
      Paint()
        ..color = const Color(0xffdfebef)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    c.save();
    c.clipRect(r);
    LabMaterials.texture(c, r, brass ? 3 : 1, opacity: .32);
    c.restore();
  }

  void wheel(
    Canvas c,
    Offset centre,
    double radius,
    double angle, {
    Color? tint,
  }) {
    final r = Rect.fromCircle(center: centre, radius: radius);
    if (radius > 20 && ApparatusSprites.draw(c, l.id == 's02-e06' ? 7 : 4, r)) {
      final u = Offset(math.cos(angle), math.sin(angle));
      line(
        c,
        centre + u * radius * .36,
        centre + u * radius * .75,
        apparatusBlue,
        2.4,
      );
      return;
    }

    c.drawOval(
      r.shift(const Offset(13, 0)),
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xff101d24),
            Color(0xfff1f7ff),
            Color(0xff344653),
            Color(0xff0b1923),
          ],
        ).createShader(r),
    );
    c.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.45, -.5),
          colors: [
            const Color(0xfff7faf9),
            tint ?? const Color(0xffb5c0c3),
            const Color(0xff3b4c57),
            const Color(0xffa7b8c0),
          ],
          stops: const [0, .4, .91, 1],
        ).createShader(r),
    );
    c.save();
    c.clipPath(Path()..addOval(r));
    LabMaterials.texture(c, r, 1, opacity: .4);
    for (int i = 0; i < 120; i++) {
      final a = i * math.pi / 60;
      line(
        c,
        centre,
        centre + Offset(math.cos(a), math.sin(a)) * radius,
        Colors.white.withValues(alpha: i % 3 == 0 ? .13 : .04),
        .7,
      );
    }
    c.drawArc(
      r.deflate(3),
      -.7,
      2.7,
      false,
      Paint()
        ..color = const Color(0x99f4faff)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    final marker =
        centre + Offset(math.cos(angle), math.sin(angle)) * (radius * .78);
    line(
      c,
      centre + Offset(math.cos(angle), math.sin(angle)) * 20,
      marker,
      tint ?? apparatusBlue,
      4,
    );
    c.restore();
    c.drawCircle(
      centre,
      radius,
      Paint()
        ..color = const Color(0xffd5e1e6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    c.drawCircle(
      centre,
      16,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xffeaf3f9), Color(0xff687c89), Color(0xff172936)],
        ).createShader(Rect.fromCircle(center: centre, radius: 16)),
    );
    c.drawCircle(centre, 5, Paint()..color = const Color(0xff081c2c));
  }

  void sphere(Canvas c, Offset centre, double radius, double rotation) {
    final r = Rect.fromCircle(center: centre, radius: radius);
    if (ApparatusSprites.draw(c, 3, r)) {
      final dot =
          centre +
          Offset(math.sin(rotation), -math.cos(rotation)) * radius * .75;
      c.drawCircle(
        dot,
        math.max(2, radius * .045),
        Paint()..color = const Color(0xff243c4d),
      );
      return;
    }

    shadow(
      c,
      Rect.fromCenter(
        center: centre + Offset(10, radius + 5),
        width: radius * 2.5,
        height: radius * .35,
      ),
    );
    c.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.45, -.6),
          radius: 1.3,
          colors: [
            Color(0xfff9f5db),
            Color(0xffbdc9c6),
            Color(0xff213843),
            Color(0xff0b1520),
          ],
          stops: [0, .22, .62, 1],
        ).createShader(r),
    );
    c.save();
    c.clipPath(Path()..addOval(r));
    LabMaterials.texture(c, r, 1, opacity: .35);
    c.drawOval(
      Rect.fromCenter(
        center: centre + Offset(-radius * .15, -radius * .48),
        width: radius * 1.65,
        height: radius * .65,
      ),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xfffcf9dc), Color(0x44fcf9dc), Color(0x00fcf9dc)],
        ).createShader(r)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    c.drawArc(
      r.deflate(radius * .18),
      rotation,
      math.pi * .8,
      false,
      Paint()
        ..color = const Color(0xaa8fd5f4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    c.restore();
    c.drawCircle(
      centre,
      radius,
      Paint()
        ..color = const Color(0x99e8f0ed)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    c.drawCircle(
      centre + Offset(-radius * .38, -radius * .5),
      radius * .13,
      Paint()
        ..color = const Color(0xaafffce6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  void rope(Canvas c, Path path) {
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0x88000000)
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke,
    );
    c.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xfff8d58c), Color(0xffa87330), Color(0xffffedbc)],
        ).createShader(Rect.fromLTWH(0, 0, 720, l.h))
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke,
    );
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xfff8d590)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  void rail(Canvas c, double y) {
    body(c, Rect.fromLTWH(20, y, 673, 30), depth: const Offset(20, -16));
    for (int i = 0; i < 18; i++) {
      final x = 35 + i * 37.0;
      line(
        c,
        Offset(x, y + 6),
        Offset(x + 8, y + 6),
        const Color(0xff091722),
        2,
      );
    }
    line(c, Offset(22, y - 3), Offset(708, y - 19), const Color(0xffe5eff2), 3);
    cylinder(c, Rect.fromLTWH(96, y + 30, 22, math.max(18, l.floor - y - 30)));
    cylinder(c, Rect.fromLTWH(597, y + 30, 22, math.max(18, l.floor - y - 30)));
  }

  void cart(
    Canvas c,
    Rect r,
    Color color,
    String name,
    double mass,
    double position,
  ) {
    if (ApparatusSprites.draw(
      c,
      color == red ? 2 : 1,
      Rect.fromLTRB(r.left, r.top - 8, r.right + 16, r.bottom + 19),
    )) {
      text(c, name, r.topLeft + Offset(r.width * .44, 7), size: 24);
      text(
        c,
        '${mass.toStringAsFixed(2)} kg',
        r.bottomLeft + const Offset(10, -22),
        size: 15,
      );
      for (final x in [r.left + r.width * .20, r.left + r.width * .78]) {
        final hub = Offset(x, r.bottom + 1), a = position * 6;
        line(
          c,
          hub,
          hub + Offset(math.cos(a), math.sin(a)) * 8,
          const Color(0xffe1eaf0),
          1.7,
        );
      }
      return;
    }
    shadow(c, Rect.fromLTWH(r.left - 12, r.bottom + 4, r.width + 35, 20));
    body(c, r, color: color, depth: const Offset(15, -12));
    for (final x in [r.left + r.width * .16, r.right - r.width * .14]) {
      final centre = Offset(x, r.bottom + 4);
      c.drawCircle(centre, 18, Paint()..color = const Color(0xff07131b));
      wheel(c, centre, 12, position * 6);
    }
    text(c, name, r.topLeft + Offset(r.width * .42, 8), size: 24);
    text(
      c,
      '${mass.toStringAsFixed(2)} kg',
      r.bottomLeft + const Offset(12, -27),
      size: 15,
    );
    cylinder(c, Rect.fromLTWH(r.right - 3, r.top + 20, 20, 30));
  }

  void arrow(Canvas c, Offset from, Offset to, Color color, String label) {
    final d = to - from;
    if (d.distance < 3) return;
    final unit = d / d.distance, normal = Offset(-unit.dy, unit.dx);
    line(c, from, to, color.withValues(alpha: .3), 11);
    line(c, from, to, color, 5);
    line(
      c,
      from + normal * 2,
      to - unit * 18 + normal * 2,
      const Color(0xffcffff5),
      1,
    );
    final head = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(
        (to - unit * 22 + normal * 12).dx,
        (to - unit * 22 + normal * 12).dy,
      )
      ..lineTo(
        (to - unit * 22 - normal * 12).dx,
        (to - unit * 22 - normal * 12).dy,
      )
      ..close();
    c.drawPath(head, Paint()..color = color);
    c.drawPath(
      head,
      Paint()
        ..color = const Color(0xffd3fff0)
        ..style = PaintingStyle.stroke,
    );
    if (label.isNotEmpty) {
      text(
        c,
        label,
        Offset((to.dx + 12).clamp(12, 540), (to.dy - 24).clamp(18, l.h - 40)),
        size: 20,
        plate: true,
      );
    }
  }

  void handle(Canvas c, Offset p) {
    c.drawCircle(p, 9, Paint()..color = const Color(0xaa008bff));
    c.drawCircle(
      p,
      9,
      Paint()
        ..color = const Color(0xffb9ecff)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void weight(Canvas c, Rect r, double mass, {bool brass = false}) {
    if (ApparatusSprites.draw(
      c,
      brass ? 5 : 6,
      Rect.fromLTRB(r.left, r.top - 24, r.right, r.bottom),
    )) {
      text(
        c,
        '${mass.toStringAsFixed(2)} kg',
        r.topLeft + const Offset(4, 33),
        size: 20,
        plate: true,
      );
      return;
    }
    cylinder(
      c,
      Rect.fromLTWH(r.center.dx - 9, r.top - 24, 18, 24),
      brass: brass,
    );
    cylinder(c, r, brass: brass);
    text(
      c,
      '${mass.toStringAsFixed(2)} kg',
      r.topLeft + const Offset(6, 29),
      size: 20,
      plate: true,
    );
  }

  void ruler(Canvas c, Rect r, double length) {
    body(c, r, wood: true, depth: const Offset(10, -6));
    for (int i = 0; i <= 100; i++) {
      final x = r.left + r.width * i / 100;
      line(
        c,
        Offset(x, r.top + 3),
        Offset(
          x,
          r.top +
              (i % 10 == 0
                  ? 24
                  : i % 5 == 0
                  ? 17
                  : 10),
        ),
        const Color(0xff342410),
        i % 10 == 0 ? 1.8 : 1,
      );
      if (i % 20 == 0) {
        text(
          c,
          (length * i / 100).toStringAsFixed(1),
          Offset(x - 6, r.top + 26),
          size: 13,
          color: const Color(0xff38220e),
        );
      }
    }
  }

  void spring(Canvas c, Offset start, Offset end) {
    final length = end.dy - start.dy;
    line(c, start, start + const Offset(0, 18), steel, 5);
    for (int i = 0; i < 16; i++) {
      final y = start.dy + 18 + (length - 36) * i / 16,
          r = Rect.fromLTWH(start.dx - 36, y, 72, (length - 36) / 16 + 9);
      c.drawArc(
        r,
        0,
        math.pi,
        false,
        Paint()
          ..color = const Color(0xff233745)
          ..strokeWidth = 5
          ..style = PaintingStyle.stroke,
      );
      c.drawArc(
        r,
        math.pi,
        math.pi,
        false,
        Paint()
          ..shader = const LinearGradient(
            colors: [
              Color(0xff8d764c),
              Color(0xfff3e4b3),
              Color(0xff9aacae),
              Color(0xff253946),
            ],
          ).createShader(r)
          ..strokeWidth = 5
          ..style = PaintingStyle.stroke,
      );
      c.drawArc(
        r.deflate(1),
        math.pi,
        math.pi * .7,
        false,
        Paint()
          ..color = const Color(0xfff4f0cb)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }
    line(c, Offset(start.dx, end.dy - 18), end, steel, 5);
  }

  @override
  void paint(Canvas original, Size size) {
    original.save();
    original.scale(size.width / 720);
    switch (l.id) {
      case 's02-e00':
        drawForces(original);
      case 's04-e01':
        drawCartHanger(original);
      case 's02-e02':
        drawPulleys(original);
      case 's02-e03':
        drawLever(original);
      case 's02-e04':
        drawCentre(original);
      case 's02-e05':
        drawCollisions(original);
      case 's02-e06':
        drawDisk(original);
      case 's02-e07':
        drawRolling(original);
      case 's02-e08':
        drawSpring(original);
      case 's02-e09':
        drawWire(original);
      case 's01-e04':
        drawMassTime(original);
    }
    original.restore();
  }

  void drawForces(Canvas c) {
    rail(c, l.floor - 10);
    if (!ApparatusSprites.draw(c, 0, l.crate.inflate(8))) {
      body(c, l.crate, wood: true, depth: const Offset(25, -21));
    }
    text(
      c,
      'm = ${v('m').toStringAsFixed(2)} kg',
      l.crate.center + const Offset(-78, -3),
      size: 24,
      plate: true,
    );
    final centre = l.crateCentre,
        weight = v('m') * 9.80665,
        angle = v('angle') * math.pi / 180;
    final start = centre + Offset(math.cos(angle), -math.sin(angle)) * 110,
        end =
            centre +
            Offset(math.cos(angle), -math.sin(angle)) *
                math.max(160, v('force') * 3.2);
    arrow(c, start, end, apparatusMint, 'F ${v('force').toStringAsFixed(1)} N');
    handle(c, end);
    final n = q('normal', weight);
    arrow(
      c,
      l.crate.topCenter,
      l.crate.topCenter - Offset(0, math.min(145, n * 4)),
      apparatusBlue,
      'N ${n.toStringAsFixed(2)} N',
    );
    arrow(
      c,
      l.crate.bottomCenter,
      l.crate.bottomCenter + Offset(0, math.min(85, weight * 4)),
      red,
      'mg ${weight.toStringAsFixed(2)} N',
    );
    final f = q('friction');
    if (f.abs() > .01) {
      arrow(
        c,
        l.crate.centerLeft,
        l.crate.centerLeft + Offset(f.sign * math.min(140, f.abs() * 11), 0),
        const Color(0xffffb132),
        'f ${f.abs().toStringAsFixed(2)} N',
      );
    }
    text(
      c,
      'x ${q('x').toStringAsFixed(3)} m   v ${q('vx').toStringAsFixed(3)} m/s',
      const Offset(26, 25),
      size: 20,
      plate: true,
    );
  }

  void drawCartHanger(Canvas c) {
    rail(c, l.cartA.bottom + 22);
    cylinder(
      c,
      Rect.fromLTWH(
        l.pulley.dx - 13,
        l.pulley.dy + 15,
        26,
        l.floor - l.pulley.dy - 15,
      ),
    );
    body(c, Rect.fromLTWH(l.pulley.dx - 53, l.floor, 113, 18));
    final path = Path()
      ..moveTo(l.cartA.right, l.cartA.top + 22)
      ..lineTo(l.pulley.dx - 15, l.pulley.dy - 28)
      ..quadraticBezierTo(
        l.pulley.dx + 40,
        l.pulley.dy - 45,
        l.pulley.dx + 41,
        l.pulley.dy + 7,
      )
      ..lineTo(l.weightB.center.dx, l.weightB.top - 20);
    rope(c, path);
    wheel(c, l.pulley, 43, q('x') / .1);
    cart(c, l.cartA, blue, 'A', v('m'), q('x'));
    weight(c, l.weightB, v('hanger', .5));
    text(
      c,
      't = ${l.time.toStringAsFixed(3)} s\na = ${q('ax').toStringAsFixed(3)} m/s²\nv = ${q('vx').toStringAsFixed(3)} m/s\nx = ${q('x').toStringAsFixed(3)} m',
      const Offset(24, 26),
      size: 22,
      plate: true,
    );
  }

  void drawPulleys(Canvas c) {
    body(c, Rect.fromLTWH(70, l.h * .08, 550, 25), wood: true);
    final top = l.pulley, low = l.movable;
    cylinder(c, Rect.fromLTWH(top.dx - 11, l.h * .08, 22, top.dy - l.h * .08));
    final path = Path();
    if (l.mode == 1) {
      path.moveTo(low.dx - 58, l.h * .10);
      path.lineTo(low.dx - 58, low.dy);
      path.arcTo(
        Rect.fromCircle(center: low, radius: 58),
        math.pi,
        -math.pi,
        false,
      );
      path.lineTo(top.dx - 65, top.dy);
      path.arcTo(
        Rect.fromCircle(center: top, radius: 65),
        math.pi,
        math.pi,
        false,
      );
      path.lineTo(l.weightB.center.dx, l.weightB.top - 20);
      rope(c, path);
      wheel(c, low, 54, -q('x') / .08);
      wheel(c, top, 62, q('x') * 2 / .1);
      line(
        c,
        low + const Offset(0, 12),
        l.weightA.topCenter - const Offset(0, 20),
        steel,
        10,
      );
    } else {
      path.moveTo(l.weightA.center.dx, l.weightA.top - 20);
      path.lineTo(top.dx - 65, top.dy);
      path.arcTo(
        Rect.fromCircle(center: top, radius: 65),
        math.pi,
        math.pi,
        false,
      );
      path.lineTo(l.weightB.center.dx, l.weightB.top - 20);
      rope(c, path);
      wheel(c, top, 62, q('x') / .1);
    }
    weight(c, l.weightA, v('m'));
    weight(c, l.weightB, v('m2'));
    final tension = q('tension');
    text(
      c,
      'MA = ${l.mode == 1 ? 2 : 1}\nT = ${tension.toStringAsFixed(2)} N\na = ${q('ax').toStringAsFixed(3)} m/s²',
      Offset(27, l.h * .25),
      size: 22,
      plate: true,
    );
    if (l.mode == 1) {
      arrow(
        c,
        low + const Offset(-73, 90),
        low + const Offset(-73, 25),
        apparatusMint,
        '2T ${(2 * tension).toStringAsFixed(2)} N',
      );
    }
  }

  void drawLever(Canvas c) {
    final y = l.beamStart.dy,
        support = Path()
          ..moveTo(l.pivot.dx, y + 15)
          ..lineTo(l.pivot.dx - 65, l.floor)
          ..lineTo(l.pivot.dx + 68, l.floor)
          ..close();
    shadow(c, Rect.fromLTWH(l.pivot.dx - 90, l.floor - 5, 190, 30));
    c.drawPath(
      support,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xff1f303a), Color(0xffa8a99b), Color(0xff4c514d)],
          stops: [0, .5, 1],
        ).createShader(Rect.fromLTWH(l.pivot.dx - 65, y, 130, l.floor - y)),
    );
    c.drawPath(
      support,
      Paint()
        ..color = const Color(0xffc7cfcc)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    body(c, Rect.fromLTWH(l.pivot.dx - 80, l.floor, 170, 22));
    ApparatusSprites.draw(
      c,
      8,
      Rect.fromLTRB(l.pivot.dx - 75, y + 25, l.pivot.dx + 75, l.floor + 8),
    );
    ruler(
      c,
      Rect.fromLTWH(l.beamStart.dx, y, l.beamEnd.dx - l.beamStart.dx, 40),
      4,
    );
    for (int i = 0; i < 2; i++) {
      final r = i == 0 ? l.weightA : l.weightB;
      rope(
        c,
        Path()
          ..moveTo(r.center.dx, y + 40)
          ..lineTo(r.center.dx, r.top - 24),
      );
      cylinder(
        c,
        Rect.fromLTWH(r.center.dx - 23, r.top - 44, 46, 36),
        brass: i == 0,
      );
      if (!ApparatusSprites.draw(
        c,
        i == 0 ? 10 : 11,
        Rect.fromLTRB(r.left, r.top - 40, r.right, r.bottom),
      )) {
        body(c, r, color: i == 0 ? blue : red, depth: const Offset(14, -10));
      }
      text(
        c,
        '${v(i == 0 ? 'force' : 'force2').toStringAsFixed(1)} N',
        r.topLeft + const Offset(8, 28),
        size: 23,
      );
      final arm = (v(i == 0 ? 'r1' : 'r2') - v('pivot')).abs();
      line(
        c,
        Offset(l.pivot.dx, r.bottom + 26),
        Offset(r.center.dx, r.bottom + 26),
        ink,
        1,
      );
      text(
        c,
        '${arm.toStringAsFixed(2)} m',
        Offset((l.pivot.dx + r.center.dx) / 2 - 30, r.bottom + 35),
        size: 18,
      );
      handle(c, r.topCenter + const Offset(0, -36));
    }
    handle(c, l.pivot + const Offset(0, 80));
    text(
      c,
      'Στ = ${q('netTorque').toStringAsFixed(3)} N·m',
      const Offset(28, 30),
      size: 24,
      plate: true,
    );
  }

  void drawCentre(Canvas c) {
    cylinder(c, Rect.fromLTWH(84, 45, 24, l.floor - 45));
    body(c, Rect.fromLTWH(42, l.floor, 130, 22));
    final path = Path()..addPolygon(l.points, true);
    shadow(c, Rect.fromLTWH(160, l.floor - 8, 430, 30));
    c.drawPath(
      path.shift(const Offset(8, 9)),
      Paint()..color = const Color(0xff1b2b34),
    );
    c.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xffe2e2cf),
            Color(0xff8d9a9c),
            Color(0xff4d5e67),
            Color(0xffbdc5bf),
          ],
          stops: [0, .32, .75, 1],
        ).createShader(path.getBounds()),
    );
    c.save();
    c.clipPath(path);
    LabMaterials.texture(c, path.getBounds(), 1, opacity: .65);
    for (int i = 0; i < 32; i++) {
      final x = 140 + (i * 47) % 450.0, y = l.h * .25 + (i * 37) % 170;
      c.drawCircle(
        Offset(x, y.toDouble()),
        1.3,
        Paint()..color = const Color(0xff495f65),
      );
    }
    c.restore();
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xffe0e4db)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    ApparatusSprites.plate(c, l.points);
    if (plumb) {
      line(
        c,
        Offset(l.com.dx, 25),
        Offset(l.com.dx, l.floor + 10),
        apparatusBlue,
        3,
      );
      text(
        c,
        'Plumb line',
        Offset((l.com.dx + 18).clamp(10, 540), 53),
        size: 19,
      );
    }
    for (int i = 0; i < l.points.length; i++) {
      sphere(c, l.points[i], 17, 0);
      c.drawCircle(
        l.points[i],
        11,
        Paint()..color = red.withValues(alpha: .85),
      );
      text(
        c,
        ['A', 'B', 'C'][i],
        l.points[i] + const Offset(14, -29),
        size: 24,
      );
    }
    c.drawCircle(l.com, 11, Paint()..color = red);
    c.drawCircle(
      l.com,
      17,
      Paint()
        ..color = red
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    text(
      c,
      'COM (${q('x').toStringAsFixed(2)}, ${q('y').toStringAsFixed(2)}) m',
      l.com + const Offset(17, 8),
      size: 20,
      color: const Color(0xffff7060),
      plate: true,
    );
  }

  void drawCollisions(Canvas c) {
    rail(c, l.cartA.bottom + 22);
    cart(c, l.cartA, blue, 'A', v('m'), q('x'));
    cart(c, l.cartB, red, 'B', v('m2'), q('x2'));
    arrow(
      c,
      l.cartA.topCenter - const Offset(0, 52),
      l.cartA.topCenter + Offset(v('v0') * 45, -52),
      apparatusBlue,
      '${q('vx', v('v0')).toStringAsFixed(2)} m/s',
    );
    arrow(
      c,
      l.cartB.topCenter - const Offset(0, 52),
      l.cartB.topCenter + Offset(v('v2') * 45, -52),
      red,
      '${q('v2', v('v2')).toStringAsFixed(2)} m/s',
    );
    handle(c, l.cartA.topCenter + Offset(v('v0') * 45, -52));
    handle(c, l.cartB.topCenter + Offset(v('v2') * 45, -52));
    text(
      c,
      'p = ${q('momentum', v('m') * v('v0') + v('m2') * v('v2')).toStringAsFixed(3)} kg·m/s\ne = ${v('e', 1).toStringAsFixed(2)}   t = ${l.time.toStringAsFixed(3)} s',
      const Offset(25, 30),
      size: 23,
      plate: true,
    );
  }

  void drawDisk(Canvas c) {
    final centre = l.diskCentre, r = l.diskRadius;
    for (final x in [85.0, 565.0]) {
      cylinder(c, Rect.fromLTWH(x, centre.dy + 14, 27, l.floor - centre.dy));
      body(c, Rect.fromLTWH(x - 30, l.floor, 93, 20));
      body(c, Rect.fromLTWH(x - 20, centre.dy - 30, 70, 60));
    }
    cylinder(c, Rect.fromLTWH(40, centre.dy - 9, 590, 22));
    wheel(c, centre, r, q('angle'));
    handle(c, centre + Offset(r, 0));
    final a = q('angle'),
        point = centre + Offset(math.cos(a), math.sin(a)) * (r * .72);
    sphere(c, point, 7, a);
    text(
      c,
      'I = ${q('inertia', .5 * v('mass') * v('radius') * v('radius')).toStringAsFixed(4)} kg·m²\nω = ${q('angularSpeed').toStringAsFixed(2)} rad/s\nα = ${q('angularAcceleration').toStringAsFixed(2)} rad/s²',
      Offset(27, l.h - 114),
      size: 22,
      plate: true,
    );
    text(
      c,
      'R ${v('radius').toStringAsFixed(2)} m',
      Offset(centre.dx + r - 45, centre.dy - r - 35),
      size: 21,
      plate: true,
    );
  }

  void drawRolling(Canvas c) {
    final start = l.rampStart,
        end = l.rampEnd,
        triangle = Path()
          ..moveTo(start.dx, start.dy)
          ..lineTo(end.dx, end.dy)
          ..lineTo(end.dx, l.floor)
          ..lineTo(start.dx, l.floor)
          ..close();
    shadow(c, Rect.fromLTWH(start.dx, l.floor - 4, end.dx - start.dx + 25, 20));
    c.drawPath(triangle, Paint()..color = const Color(0xffac733b));
    c.save();
    c.clipPath(triangle);
    LabMaterials.wood(c, triangle.getBounds());
    c.restore();
    line(
      c,
      start + const Offset(0, 5),
      end + const Offset(0, 5),
      const Color(0xff223844),
      17,
    );
    line(c, start, end, steel, 10);
    line(
      c,
      start - const Offset(0, 3),
      end - const Offset(0, 3),
      const Color(0xfff3f6ed),
      2,
    );
    sphere(c, l.ball, l.ballRadius, q('distance') / v('radius', .1));
    handle(c, end);
    text(
      c,
      'θ = ${v('incline').toStringAsFixed(1)}°',
      Offset(350, l.h * .25),
      size: 26,
      plate: true,
    );
    text(
      c,
      'v = ${q('speed').toStringAsFixed(3)} m/s\ns = ${q('distance').toStringAsFixed(3)} m',
      Offset(420, l.h * .68),
      size: 22,
      plate: true,
    );
    final centre = Offset(140, l.floor - 8);
    c.drawArc(
      Rect.fromCircle(center: centre, radius: 70),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xff93a1a2)
        ..strokeWidth = 35,
    );
    for (int i = 0; i <= 18; i++) {
      final a = math.pi + i * math.pi / 18;
      line(
        c,
        centre + Offset(math.cos(a), math.sin(a)) * 56,
        centre + Offset(math.cos(a), math.sin(a)) * (i % 3 == 0 ? 74 : 66),
        const Color(0xff172b3b),
        1.5,
      );
    }
    line(
      c,
      centre,
      centre - Offset(math.sin(l.incline), math.cos(l.incline)) * 65,
      red,
      5,
    );
  }

  void drawSpring(Canvas c) {
    cylinder(c, Rect.fromLTWH(108, 35, 20, l.floor - 35));
    body(c, Rect.fromLTWH(62, l.floor, 330, 22));
    cylinder(c, Rect.fromLTWH(116, 68, 200, 17), brass: true);
    cylinder(c, const Rect.fromLTWH(265, 66, 80, 29), brass: true);
    final end = Offset(305, l.springEnd);
    spring(c, const Offset(305, 106), end);
    rope(
      c,
      Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(l.weightA.center.dx, l.weightA.top),
    );
    if (!ApparatusSprites.draw(
      c,
      5,
      Rect.fromLTRB(
        l.weightA.left,
        l.weightA.top - 14,
        l.weightA.right,
        l.weightA.bottom,
      ),
    )) {
      cylinder(c, l.weightA, brass: true);
    }
    text(
      c,
      '${q('force', v('stiffness') * v('extension')).toStringAsFixed(2)} N',
      l.weightA.topLeft + const Offset(20, 22),
      size: 24,
    );
    final rulerRect = Rect.fromLTWH(
      400,
      120,
      58,
      math.max(200, l.springEnd - 75),
    );
    LabMaterials.metal(c, rulerRect);
    for (int i = 0; i <= 40; i++) {
      final y = 140 + i * 7.0;
      line(
        c,
        Offset(401, y),
        Offset(i % 5 == 0 ? 430 : 417, y),
        const Color(0xff102637),
        1,
      );
      if (i % 10 == 0) {
        text(
          c,
          '${i * 5}',
          Offset(432, y - 7),
          size: 12,
          color: const Color(0xff122630),
        );
      }
    }
    arrow(
      c,
      const Offset(473, 140),
      Offset(473, 140 + v('extension') * 1250),
      red,
      '${(v('extension') * 1000).toStringAsFixed(1)} mm',
    );
    text(
      c,
      'F = kx\nk = ${v('stiffness').toStringAsFixed(1)} N/m\nx = ${v('extension').toStringAsFixed(3)} m\nU = ${q('energy').toStringAsFixed(3)} J',
      const Offset(488, 44),
      size: 21,
      plate: true,
    );
  }

  void drawWire(Canvas c) {
    cylinder(c, Rect.fromLTWH(88, 20, 34, l.floor - 20));
    body(c, Rect.fromLTWH(40, l.floor, 360, 22));
    body(c, const Rect.fromLTWH(115, 55, 270, 48));
    cylinder(c, const Rect.fromLTWH(215, 98, 60, 46));
    final top = const Offset(245, 143),
        end = Offset(245, l.wireEnd),
        width = 2 + v('radius') * 6000;
    line(c, top, end, const Color(0xff526c7e), width + 3);
    line(
      c,
      top - const Offset(1, 0),
      end - const Offset(1, 0),
      const Color(0xffeffaff),
      width * .4,
    );
    body(c, Rect.fromLTWH(207, l.wireEnd - 26, 76, 28));
    if (!ApparatusSprites.draw(
      c,
      6,
      Rect.fromLTRB(
        l.weightA.left,
        l.weightA.top - 14,
        l.weightA.right,
        l.weightA.bottom,
      ),
    )) {
      cylinder(c, l.weightA);
    }
    text(
      c,
      '${v('force').toStringAsFixed(1)} N',
      l.weightA.topLeft + const Offset(24, 30),
      size: 26,
    );
    final magnifier = Rect.fromLTWH(440, 105, 232, 160);
    c.drawOval(magnifier, Paint()..color = const Color(0xff0a1e2a));
    c.drawOval(
      magnifier,
      Paint()
        ..color = const Color(0xffb7ddec)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final delta = q('length'), pixels = delta * 180000;
    line(c, const Offset(478, 153), const Offset(585, 153), steel, 7);
    line(c, Offset(478, 153 + pixels), Offset(585, 153 + pixels), steel, 7);
    arrow(c, const Offset(609, 153), Offset(609, 153 + pixels), red, '');
    text(
      c,
      'ΔL ${(delta * 1e6).toStringAsFixed(1)} μm',
      const Offset(450, 280),
      size: 23,
      plate: true,
    );
    text(
      c,
      'L = ${v('length').toStringAsFixed(3)} m\nA = ${(q('area') * 1e6).toStringAsFixed(3)} mm²\nE = ${(v('modulus') / 1e9).toStringAsFixed(1)} GPa',
      Offset(435, l.h * .63),
      size: 22,
      plate: true,
    );
    text(c, 'Magnified extension', const Offset(462, 80), size: 16);
  }

  void drawMassTime(Canvas c) {
    body(
      c,
      Rect.fromLTWH(45, l.h * .57, 225, 80),
      depth: const Offset(14, -15),
    );
    body(c, Rect.fromLTWH(62, l.h * .50, 198, 20));
    sphere(c, Offset(153, l.h * .42), 35, 0);
    text(
      c,
      '${(v('a') * 1000).toStringAsFixed(2)} g',
      Offset(75, l.h * .64),
      size: 27,
      color: const Color(0xff11cfff),
      plate: true,
    );
    cylinder(c, Rect.fromLTWH(346, l.h * .35, 18, l.h * .43));
    c.save();
    c.translate(l.rampStart.dx, l.rampStart.dy);
    final d = l.rampEnd - l.rampStart;
    c.rotate(math.atan2(d.dy, d.dx));
    ruler(c, Rect.fromLTWH(0, 0, d.distance, 45), v('distance') * 1000);
    c.restore();
    sphere(c, l.ball, 23, q('travelled') / .023);
    text(
      c,
      't ${q('timerReading', l.time).toStringAsFixed(3)} s',
      const Offset(445, 25),
      size: 29,
      plate: true,
    );
  }

  @override
  bool shouldRepaint(covariant RealisticMechanicsPainter old) => true;
}
