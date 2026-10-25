import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/physics/dynamics.dart';
import '../../core/rendering/apparatus.dart';

class WorldViewport {
  final Size size;
  final double scale;
  final Vec2 centre;
  const WorldViewport(this.size, this.scale, this.centre);
  Offset screen(Vec2 v) => Offset(
    size.width / 2 + (v.x - centre.x) * scale,
    size.height * .58 - (v.y - centre.y) * scale,
  );
  Vec2 world(Offset p) => Vec2(
    (p.dx - size.width / 2) / scale + centre.x,
    -(p.dy - size.height * .58) / scale + centre.y,
  );
}

class DynamicsPainter extends ScientificScene {
  final int kind, mode, frame;
  final Observation s;
  final Map<String, double> p;
  final List<Observation> samples;
  final bool isolated, components, labels, trails;
  const DynamicsPainter({
    required this.kind,
    required this.s,
    required this.p,
    required this.samples,
    this.mode = 0,
    this.frame = 0,
    this.isolated = false,
    this.components = true,
    this.labels = true,
    this.trails = true,
  });
  double get time => s['t'] ?? 0;
  double v(String key, [double fallback = 0]) => p[key] ?? fallback;
  double q(String key) => s[key] ?? 0;
  @override
  String get accessibleSummary =>
      '${isolated ? 'Isolated body diagram. ' : ''}World time ${time.toStringAsFixed(3)} seconds. Position (${q('x')},${q('y')}) m; velocity (${q('vx')},${q('vy')}) m/s; acceleration (${q('ax')},${q('ay')}) m/s². Force (${q('fx')},${q('fy')}) N.';
  @override
  bool shouldRepaint(covariant DynamicsPainter old) => true;
  void text(
    Canvas c,
    String value,
    Offset xy, {
    Color color = const Color(0xff173458),
    double font = 11,
  }) {
    final t = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: font,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 310);
    t.paint(c, xy);
  }

  void arrow(
    Canvas c,
    Offset from,
    Vec2 vector,
    Color color,
    String label, {
    double factor = 3,
  }) {
    if (vector.magnitude < 1e-9) {
      return;
    }
    final d = Offset(vector.x, -vector.y) * factor;
    final end = from + d;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4;
    c.drawLine(from, end, paint);
    final ang = math.atan2(d.dy, d.dx);
    c.drawLine(
      end,
      end - Offset(math.cos(ang - .45), math.sin(ang - .45)) * 8,
      paint,
    );
    c.drawLine(
      end,
      end - Offset(math.cos(ang + .45), math.sin(ang + .45)) * 8,
      paint,
    );
    if (labels) {
      text(c, label, end + const Offset(3, -12), color: color, font: 10);
    }
  }

  void metal(Canvas c, Rect r) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        r.shift(const Offset(0, 4)),
        const Radius.circular(4),
      ),
      Paint()
        ..color = Colors.black12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(4)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xff687f8c),
            Color(0xfff5fafb),
            Color(0xff9eafb6),
            Color(0xff476170),
          ],
        ).createShader(r),
    );
  }

  void wood(Canvas c, Rect r) {
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(3)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xffc79759), Color(0xfff0d3a3), Color(0xff996d38)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(r),
    );
    for (double y = r.top + 3; y < r.bottom; y += 4) {
      c.drawLine(
        Offset(r.left, y),
        Offset(r.right, y + 1),
        Paint()..color = const Color(0xff59371c).withValues(alpha: .16),
      );
    }
  }

  void cart(
    Canvas c,
    Offset point, {
    Color color = const Color(0xff245ce7),
    bool train = false,
    double width = 43,
  }) {
    final rect = Rect.fromCenter(
      center: point - const Offset(0, 17),
      width: train ? 86 : width,
      height: 28,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        rect.shift(const Offset(1, 5)),
        const Radius.circular(5),
      ),
      Paint()
        ..color = Colors.black12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(color, Colors.white, .35)!,
            color,
            Color.lerp(color, Colors.black, .4)!,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect),
    );
    if (train) {
      for (int i = 0; i < 4; i++) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(rect.left + 7 + i * 18, rect.top + 4, 12, 10),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xffc4e9f1),
        );
      }
    }
    for (final dx in [rect.width * -.32, rect.width * .32]) {
      c.drawCircle(
        point + Offset(dx, -1),
        6,
        Paint()..color = const Color(0xff172e41),
      );
      c.drawCircle(
        point + Offset(dx, -1),
        2,
        Paint()..color = const Color(0xffb5c7cf),
      );
    }
  }

  void block(Canvas c, Offset point) {
    final r = Rect.fromCenter(
      center: point - const Offset(0, 22),
      width: 49,
      height: 44,
    );
    wood(c, r);
    final line = Paint()
      ..color = const Color(0xff8f6535)
      ..strokeWidth = 3;
    c.drawLine(
      r.topLeft + const Offset(5, 5),
      r.bottomRight - const Offset(5, 5),
      line,
    );
    c.drawRect(
      r.deflate(4),
      Paint()
        ..color = const Color(0xff835e33)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  void paint(Canvas original, Size actual) {
    original.save();
    original.clipRect(Offset.zero & actual);
    original.scale(actual.width / 360, actual.height / 270);
    final c = original;
    c.drawRect(
      const Rect.fromLTWH(0, 0, 360, 270),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xffeaf3fc), Color(0xfff8fbfe), Color(0xffdce6ed)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(const Rect.fromLTWH(0, 0, 360, 270)),
    );
    const cobalt = Color(0xff245ce7),
        teal = Color(0xff009b94),
        amber = Color(0xffd39928),
        red = Color(0xffcb5355);
    if (kind == 2) {
      wood(c, const Rect.fromLTWH(32, 32, 296, 14));
      final shift = q('x') * 40;
      final points = mode == 0
          ? [Offset(145, 140 - shift), Offset(215, 140 + shift)]
          : [Offset(180, 145 - shift), Offset(280, 100 + 2 * shift)];
      final rope = Path();
      if (mode == 0) {
        rope.moveTo(145, points[0].dy);
        rope.lineTo(145, 68);
        rope.arcTo(
          const Rect.fromLTWH(145, 33, 70, 70),
          math.pi,
          math.pi,
          false,
        );
        rope.lineTo(215, points[1].dy);
      } else {
        rope.moveTo(155, 45);
        rope.lineTo(155, points[0].dy - 20);
        rope.arcTo(
          Rect.fromCenter(
            center: points[0] - const Offset(0, 20),
            width: 50,
            height: 50,
          ),
          math.pi,
          -math.pi,
          false,
        );
        rope.lineTo(205, 65);
        rope.arcTo(
          const Rect.fromLTWH(205, 27.5, 75, 75),
          math.pi,
          math.pi,
          false,
        );
        rope.lineTo(280, points[1].dy);
      }
      for (final wheel
          in mode == 0
              ? [const Rect.fromLTWH(145, 33, 70, 70)]
              : [
                  Rect.fromCenter(
                    center: points[0] - const Offset(0, 20),
                    width: 50,
                    height: 50,
                  ),
                  const Rect.fromLTWH(205, 27.5, 75, 75),
                ]) {
        c.drawOval(
          wheel,
          Paint()
            ..shader = const RadialGradient(
              colors: [
                Color(0xffeaf1f5),
                Color(0xff657e8c),
                Color(0xffd9e6eb),
                Color(0xff3c5565),
              ],
            ).createShader(wheel),
        );
        c.drawCircle(wheel.center, 4, Paint()..color = const Color(0xff203a51));
      }
      c.drawPath(
        rope,
        Paint()
          ..color = const Color(0xff8c744f)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      metal(c, const Rect.fromLTWH(153, 44, 49, 15));
      for (int i = 0; i < 2; i++) {
        final supportForce = q('tension') * (mode == 1 && i == 0 ? 2 : 1);
        final forceScale =
            55 /
            math.max(
              1,
              math.max(
                v('m') * standardGravity,
                math.max(v('m2') * standardGravity, supportForce),
              ),
            );
        metal(
          c,
          Rect.fromCenter(
            center: points[i] + const Offset(0, 18),
            width: 44,
            height: 35,
          ),
        );
        text(
          c,
          '${v(i == 0 ? 'm' : 'm2')} kg',
          points[i] + const Offset(-18, 14),
        );
        arrow(
          c,
          points[i],
          Vec2(0, supportForce),
          teal,
          '${mode == 1 && i == 0 ? '2T' : 'T'} ${supportForce.toStringAsFixed(2)} N',
          factor: forceScale,
        );
        arrow(
          c,
          points[i] + const Offset(0, 35),
          Vec2(0, -v(i == 0 ? 'm' : 'm2') * standardGravity),
          red,
          'mg',
          factor: forceScale,
        );
      }
      text(
        c,
        mode == 0
            ? 'Atwood · xA up, xB down'
            : 'Movable · load up x, effort down 2x',
        const Offset(20, 242),
      );
    } else if (kind == 3) {
      wood(c, const Rect.fromLTWH(28, 153, 304, 17));
      final pivot = 180 + v('pivot') * 65;
      final support = Path()
        ..moveTo(pivot, 170)
        ..lineTo(pivot - 23, 213)
        ..lineTo(pivot + 23, 213)
        ..close();
      c.drawPath(support, Paint()..color = const Color(0xff516876));
      for (int i = -2; i <= 2; i++) {
        text(c, '$i', Offset(177 + i * 65, 174), font: 9);
      }
      for (final tuple in [
        (r: v('r1'), f: v('force'), angle: v('angle'), color: cobalt),
        (r: v('r2'), f: v('force2'), angle: v('angle2'), color: teal),
      ]) {
        final pt = Offset(180 + tuple.r * 65, 151);
        c.drawCircle(pt, 6, Paint()..color = tuple.color);
        arrow(
          c,
          pt,
          Vec2.polar(tuple.f, tuple.angle * math.pi / 180),
          tuple.color,
          '${tuple.f.toStringAsFixed(1)} N',
          factor: .7,
        );
      }
      text(c, 'Static beam · anticlockwise +', const Offset(20, 22));
      text(
        c,
        'Net τ ${q('netTorque').toStringAsFixed(3)} N·m',
        const Offset(20, 235),
      );
    } else if (kind == 4) {
      final points = [
        Vec2(v('x0'), v('y1')),
        Vec2(v('x2'), v('y2')),
        Vec2(v('x3'), v('y3')),
      ];
      final centre = Vec2(q('x'), q('y'));
      final hang = Vec2(v('hangX'), v('hangY'));
      Vec2 rotation(Vec2 x) {
        if (mode == 0) {
          return x;
        }
        final d = x - hang, phi = q('suspensionAngle');
        return Vec2(
              d.x * math.cos(phi) - d.y * math.sin(phi),
              d.x * math.sin(phi) + d.y * math.cos(phi),
            ) +
            hang;
      }

      Offset screen(Vec2 x) {
        final pt = rotation(x);
        return Offset(180 + pt.x * 45, 222 - pt.y * 53);
      }

      final path = Path()
        ..moveTo(screen(points[0]).dx, screen(points[0]).dy)
        ..lineTo(screen(points[1]).dx, screen(points[1]).dy)
        ..lineTo(screen(points[2]).dx, screen(points[2]).dy)
        ..close();
      c.drawPath(
        path,
        Paint()
          ..color = const Color(0xff9eafb9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7,
      );
      for (int i = 0; i < 3; i++) {
        c.drawCircle(
          screen(points[i]),
          9 + v(['m', 'm2', 'm3'][i]) * 1.4,
          Paint()
            ..shader =
                const RadialGradient(
                  center: Alignment(-.4, -.4),
                  colors: [Colors.white, Color(0xff7b919d), Color(0xff354d60)],
                ).createShader(
                  Rect.fromCircle(center: screen(points[i]), radius: 20),
                ),
        );
        text(c, ['A', 'B', 'C'][i], screen(points[i]) - const Offset(3, 4));
      }
      c.drawCircle(screen(centre), 5, Paint()..color = red);
      text(c, 'COM', screen(centre) + const Offset(8, -8), color: red);
      if (mode == 1) {
        final top = screen(hang);
        c.drawLine(
          top,
          Offset(top.dx, 242),
          Paint()
            ..color = cobalt
            ..strokeWidth = 1.5,
        );
        c.drawCircle(top, 5, Paint()..color = cobalt);
        text(c, 'Plumb line', Offset(top.dx + 6, 35), color: cobalt);
      } else {
        wood(
          c,
          Rect.fromLTWH(
            180 + (v('support') - v('base') / 2) * 45,
            232,
            v('base') * 45,
            10,
          ),
        );
        c.drawLine(
          screen(centre),
          Offset(screen(centre).dx, 232),
          Paint()
            ..color = red
            ..strokeWidth = 1.5,
        );
        text(
          c,
          q('stable') == 1
              ? 'Inside base: support equilibrium feasible'
              : q('stable') == 0
              ? 'At edge: marginal'
              : 'Outside base: tips without a clamp',
          const Offset(15, 17),
          font: 10,
        );
      }
    } else if (kind == 11) {
      final r = v('radius');
      const centre = Offset(180, 137);
      const scale = 41.0;
      c.drawCircle(
        centre,
        r * scale,
        Paint()
          ..color = const Color(0xff7e9cae)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8,
      );
      c.drawCircle(
        centre,
        r * scale,
        Paint()
          ..color = const Color(0xffd3e4ec)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final pt = centre + Offset(q('x'), -q('y')) * scale;
      c.drawCircle(
        pt,
        10,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.4, -.4),
            colors: [Colors.white, cobalt, Color(0xff14356b)],
          ).createShader(Rect.fromCircle(center: pt, radius: 10)),
      );
      arrow(c, pt, Vec2(q('vx'), q('vy')), teal, 'v tangent', factor: 12);
      arrow(c, pt, Vec2(q('ax'), q('ay')), amber, 'a inward', factor: 5);
      text(
        c,
        'Horizontal circular constraint · plan view',
        const Offset(22, 242),
      );
    } else if (kind == 17) {
      final scale = math.min(30.0, 110 / (Vec2(q('x'), q('y')).magnitude + 1));
      final pt = Offset(180 + q('x') * scale, 145 - q('y') * scale);
      for (int i = 0; i < 7; i++) {
        c.drawLine(
          Offset(0, 35 + i * 30),
          Offset(360, 35 + i * 30),
          Paint()..color = const Color(0xffd7e4ee),
        );
      }
      cart(c, pt);
      for (int i = 1; i <= 3; i++) {
        arrow(
          c,
          pt - const Offset(0, 16),
          Vec2.polar(v('f$i'), v('d$i') * math.pi / 180),
          [cobalt, teal, amber][i - 1],
          'F$i',
          factor: 4,
        );
      }
      text(c, 'Top-down plane · x right, y up', const Offset(20, 242));
    } else if (kind == 9) {
      final range = math.max(1, q('range').abs()),
          height = math.max(2, q('maxHeight'));
      final sx = 290 / range, sy = 165 / height;
      Offset pt(double x, double y) => Offset(35 + x * sx, 218 - y * sy);
      wood(c, const Rect.fromLTWH(16, 219, 328, 12));
      metal(c, Rect.fromLTWH(19, 198 - v('height') * sy, 20, 20));
      final path = Path();
      for (int i = 0; i <= 60; i++) {
        final t = q('flight') * i / 60;
        final vel = Vec2.polar(v('speed'), v('angle') * math.pi / 180);
        final pos = pt(
          vel.x * t,
          math.max(0, v('height') + vel.y * t - .5 * v('g') * t * t),
        );
        if (i == 0) {
          path.moveTo(pos.dx, pos.dy);
        } else {
          path.lineTo(pos.dx, pos.dy);
        }
      }
      c.drawPath(
        path,
        Paint()
          ..color = amber.withValues(alpha: .6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      final ball = pt(q('x'), q('y'));
      arrow(
        c,
        pt(0, v('height')),
        Vec2.polar(v('speed'), v('angle') * math.pi / 180),
        cobalt,
        'launch handle',
        factor: 2,
      );
      c.drawCircle(
        ball,
        9,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.4, -.4),
            colors: [Colors.white, amber, Color(0xff8a5e12)],
          ).createShader(Rect.fromCircle(center: ball, radius: 9)),
      );
      arrow(c, ball, Vec2(q('vx'), q('vy')), teal, 'v', factor: 2);
      text(c, 'x →   y ↑ · uniform gravity · no drag', const Offset(18, 244));
    } else if (kind == 1) {
      final theta = v('angle') * math.pi / 180;
      const start = Offset(38, 61);
      final end = start + Offset(math.cos(theta), math.sin(theta)) * 280;
      metal(c, Rect.fromLTWH(start.dx + 7, start.dy + 8, 8, 220 - start.dy));
      metal(
        c,
        Rect.fromLTWH(end.dx - 12, end.dy + 8, 8, math.max(5, 220 - end.dy)),
      );
      c.save();
      c.translate(start.dx, start.dy);
      c.rotate(theta);
      wood(c, const Rect.fromLTWH(0, 0, 280, 12));
      c.restore();
      final point =
          start + Offset(math.cos(theta), math.sin(theta)) * q('x') * 56;
      c.save();
      c.translate(point.dx, point.dy);
      c.rotate(theta);
      block(c, Offset.zero);
      c.restore();
      final anchor =
          point + Offset(22 * math.sin(theta), -22 * math.cos(theta));
      final forceScale = 75 / (v('m') * standardGravity);
      arrow(
        c,
        anchor,
        Vec2(0, -v('m') * standardGravity),
        red,
        'mg',
        factor: forceScale,
      );
      arrow(
        c,
        anchor,
        Vec2(math.sin(theta), math.cos(theta)) * q('normal'),
        cobalt,
        'N',
        factor: forceScale,
      );
      arrow(
        c,
        anchor,
        Vec2(math.cos(theta), -math.sin(theta)) * q('friction'),
        teal,
        'friction',
        factor: forceScale,
      );
      if (components) {
        arrow(
          c,
          anchor,
          Vec2(math.cos(theta), -math.sin(theta)) *
              (v('m') * standardGravity * math.sin(theta)),
          red.withValues(alpha: .4),
          'mg parallel',
          factor: forceScale,
        );
        arrow(
          c,
          anchor,
          Vec2(-math.sin(theta), -math.cos(theta)) *
              (v('m') * standardGravity * math.cos(theta)),
          red.withValues(alpha: .4),
          'mg normal',
          factor: forceScale,
        );
      }
      text(c, 's downhill → · n outward ↗', const Offset(18, 244));
    } else {
      final observer = kind == 10
          ? (frame == 1
                ? v('v0')
                : frame == 2
                ? v('v2')
                : 0)
          : 0.0;
      final xa = q('x') - observer * time, xb = q('x2') - observer * time;
      final two = [5, 10, 14].contains(kind);
      final centre = two ? (xa + xb) / 2 : xa;
      final span = two ? math.max(3, (xb - xa).abs() + 2) : 4.5;
      final scale = 280 / span;
      Offset point(double x, [double y = 0]) =>
          Offset(180 + (x - centre) * scale, 199 - y * scale);
      if (!isolated) {
        metal(c, const Rect.fromLTWH(15, 202, 330, 10));
        if (kind == 10) {
          metal(c, const Rect.fromLTWH(15, 164, 330, 7));
          metal(c, const Rect.fromLTWH(15, 216, 330, 7));
        }
        for (int i = -3; i <= 3; i++) {
          final world = centre + i * span / 6;
          final px = point(world).dx;
          c.drawLine(
            Offset(px, 216),
            Offset(px, 222),
            Paint()..color = const Color(0xff657d94),
          );
          text(c, world.toStringAsFixed(1), Offset(px - 8, 225), font: 8);
        }
      }
      final anchor = point(xa) - const Offset(0, 23);
      if (trails && !isolated && kind != 10) {
        for (final sample
            in samples
                .where((e) => e['t']! <= time)
                .toList()
                .where((e) => ((e['t']! * 15).round() % 3) == 0)) {
          final xx = sample['x']! - observer * sample['t']!;
          c.drawCircle(
            point(xx) - const Offset(0, 8),
            2,
            Paint()..color = cobalt.withValues(alpha: .24),
          );
        }
      }
      if ([0, 15, 16].contains(kind)) {
        if (kind == 16 && mode == 0) {
          final up = q('y');
          final yy = 160 - up * 12;
          wood(c, const Rect.fromLTWH(50, 40, 260, 12));
          c.drawLine(
            const Offset(180, 52),
            Offset(180, yy),
            Paint()
              ..color = const Color(0xff8e7959)
              ..strokeWidth = 2,
          );
          metal(c, Rect.fromLTWH(158, yy, 44, 36));
          final forceScale =
              65 / math.max(1, math.max(q('weight'), q('tension')));
          arrow(
            c,
            Offset(180, yy + 17),
            Vec2(0, q('tension')),
            teal,
            'T',
            factor: forceScale,
          );
          arrow(
            c,
            Offset(180, yy + 17),
            Vec2(0, -q('weight')),
            red,
            'mg',
            factor: forceScale,
          );
        } else {
          block(c, point(xa));
          final forceScale =
              85 /
              [
                1.0,
                v('m') * standardGravity,
                q('normal'),
                Vec2(q('appliedX'), q('appliedY')).magnitude,
                q('friction').abs(),
              ].reduce(math.max);
          arrow(
            c,
            anchor,
            Vec2(0, -v('m') * standardGravity),
            red,
            'mg ${numberForce(v('m') * standardGravity)} N',
            factor: forceScale,
          );
          arrow(
            c,
            anchor,
            Vec2(0, q('normal')),
            cobalt,
            'N ${numberForce(q('normal'))}',
            factor: forceScale,
          );
          arrow(
            c,
            anchor,
            Vec2(q('appliedX'), q('appliedY')),
            teal,
            'F applied',
            factor: forceScale,
          );
          arrow(
            c,
            anchor,
            Vec2(q('friction'), 0),
            amber,
            'f ${numberForce(q('friction'))}',
            factor: forceScale,
          );
          if (components && kind == 0) {
            arrow(
              c,
              anchor,
              Vec2(q('appliedX'), 0),
              teal.withValues(alpha: .4),
              'Fx component',
              factor: forceScale,
            );
            arrow(
              c,
              anchor + Offset(q('appliedX') * forceScale, 0),
              Vec2(0, q('appliedY')),
              teal.withValues(alpha: .4),
              'Fy component',
              factor: forceScale,
            );
            text(
              c,
              'Fx ${q('appliedX').toStringAsFixed(2)} N; Fy ${q('appliedY').toStringAsFixed(2)} N',
              const Offset(15, 24),
              font: 10,
            );
          }
          if (kind == 0) {
            arrow(
              c,
              const Offset(180, 60),
              Vec2(q('fx'), 0),
              cobalt,
              'ΣF resultant (separate)',
              factor: forceScale,
            );
          }
        }
      } else if (kind == 12) {
        metal(c, const Rect.fromLTWH(18, 116, 324, 99));
        for (int i = 0; i < 23; i++) {
          for (int j = 0; j < 6; j++) {
            c.drawCircle(
              Offset(29 + i * 13, 126 + j * 15),
              1,
              Paint()..color = const Color(0xff67808e),
            );
          }
        }
        c.drawOval(
          Rect.fromCenter(
            center: point(xa) - const Offset(0, 10),
            width: 37,
            height: 15,
          ),
          Paint()..color = const Color(0xff244755),
        );
        arrow(c, anchor, Vec2(q('vx'), 0), teal, 'v · not a force', factor: 14);
      } else {
        final pointA = kind == 10 ? point(xa) - const Offset(0, 38) : point(xa);
        final pointB = kind == 10 ? point(xb) + const Offset(0, 14) : point(xb);
        cart(c, pointA, train: kind == 10, width: kind == 5 ? 0.8 * scale : 50);
        if (two) {
          cart(
            c,
            pointB,
            color: red,
            train: kind == 10,
            width: kind == 5 ? 0.8 * scale : 50,
          );
          text(c, 'A', pointA - const Offset(3, 50), color: cobalt);
          text(c, 'B', pointB - const Offset(3, 50), color: red);
        }
        if (kind == 14) {
          if (q('fx') != 0) {
            metal(
              c,
              Rect.fromLTRB(
                pointA.dx + 25,
                pointA.dy - 17,
                pointB.dx - 25,
                pointB.dy - 10,
              ),
            );
            text(
              c,
              'Prescribed internal actuator pulse',
              const Offset(45, 35),
              font: 10,
            );
          }
          arrow(c, anchor, Vec2(q('fx'), 0), cobalt, 'F on A', factor: 4);
          arrow(
            c,
            point(xb) - const Offset(0, 23),
            Vec2(q('force2'), 0),
            red,
            'F on B',
            factor: 4,
          );
        } else if (kind == 13) {
          arrow(c, anchor, Vec2(q('fx'), 0), teal, 'Net F', factor: 4);
        }
      }
      text(
        c,
        kind == 10
            ? 'Frame ${['Ground', 'A', 'B'][frame]} · relative velocity unchanged'
            : 'World coordinates in m · camera follows apparatus',
        const Offset(15, 250),
        font: 10,
      );
    }
    if (labels) {
      text(
        c,
        't = ${time.toStringAsFixed(3)} s',
        const Offset(15, 6),
        font: 10,
      );
    }
    original.restore();
  }

  String numberForce(double x) => x.toStringAsFixed(2);
}

class DynamicsGraph extends CustomPainter {
  final List<Observation> samples;
  final String channel, unit;
  final int cursor;
  final bool tangent, stepPlot, signedArea;
  const DynamicsGraph(
    this.samples,
    this.channel,
    this.unit,
    this.cursor, {
    this.tangent = false,
    this.stepPlot = false,
    this.signedArea = false,
  });
  @override
  bool shouldRepaint(covariant DynamicsGraph old) => true;
  @override
  void paint(Canvas c, Size size) {
    if (samples.isEmpty) {
      return;
    }
    final values = samples.map((s) => s[channel] ?? 0).toList();
    double low = math.min(0, values.reduce(math.min)),
        high = math.max(0, values.reduce(math.max));
    if ((high - low).abs() < 1e-9) {
      high = low + 1;
    }
    final end = math.max(.01, samples.last['t']!);
    final area = Rect.fromLTWH(48, 20, size.width - 65, size.height - 58);
    Offset pt(Observation s) => Offset(
      area.left + s['t']! / end * area.width,
      area.bottom - ((s[channel] ?? 0) - low) / (high - low) * area.height,
    );
    void label(String text, Offset offset) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(fontSize: 9, color: Color(0xff4f657c)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, offset);
    }

    for (int i = 0; i <= 4; i++) {
      final yy = area.bottom - i * area.height / 4;
      c.drawLine(
        Offset(area.left, yy),
        Offset(area.right, yy),
        Paint()..color = const Color(0xffdfe7ee),
      );
      label(
        (low + (high - low) * i / 4).toStringAsPrecision(3),
        Offset(0, yy - 5),
      );
      label(
        (end * i / 4).toStringAsFixed(2),
        Offset(area.left + i * area.width / 4 - 8, area.bottom + 8),
      );
    }
    final path = Path();
    for (int i = 0; i < samples.length; i++) {
      final p = pt(samples[i]);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        if (stepPlot) {
          path.lineTo(p.dx, pt(samples[i - 1]).dy);
        }
        path.lineTo(p.dx, p.dy);
      }
    }
    if (signedArea) {
      for (int i = 1; i < samples.length; i++) {
        final a = pt(samples[i - 1]),
            b = pt(samples[i]),
            zero = area.bottom - (0 - low) / (high - low) * area.height;
        final fill = Path()
          ..moveTo(a.dx, zero)
          ..lineTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..lineTo(b.dx, zero)
          ..close();
        c.drawPath(
          fill,
          Paint()
            ..color =
                ((samples[i - 1][channel] ?? 0) >= 0
                        ? const Color(0xff245ce7)
                        : const Color(0xffd39928))
                    .withValues(alpha: .12),
        );
      }
    }
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xff245ce7)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    final selected = samples[cursor.clamp(0, samples.length - 1)];
    final position = pt(selected);
    if (tangent) {
      final slope = selected['vx'] ?? 0,
          delta = end * .1,
          dx = delta / end * area.width,
          dy = slope * delta / (high - low) * area.height;
      c.save();
      c.clipRect(area);
      c.drawLine(
        position - Offset(dx, -dy),
        position + Offset(dx, -dy),
        Paint()
          ..color = const Color(0xff009b94)
          ..strokeWidth = 1.4,
      );
      c.restore();
      label(
        'tangent ${slope.toStringAsPrecision(4)} m/s',
        Offset(area.left + 5, area.top + 5),
      );
    }
    c.drawLine(
      Offset(position.dx, area.top),
      Offset(position.dx, area.bottom),
      Paint()
        ..color = const Color(0xffd39928)
        ..strokeWidth = 1,
    );
    c.drawCircle(position, 4, Paint()..color = const Color(0xff009b94));
    label('$channel ($unit)', const Offset(48, 1));
    label('Time (s)', Offset(size.width / 2 - 16, size.height - 10));
  }
}
