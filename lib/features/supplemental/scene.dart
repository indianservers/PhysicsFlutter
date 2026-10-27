import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/physics/supplemental_labs.dart';

/// Schematic apparatus driven solely by the analytic model, never stored observations.
class SupplementalPainter extends CustomPainter {
  final SupplementalLab lab;
  final Map<String, double> parameters, state;
  final double time;
  const SupplementalPainter(this.lab, this.parameters, this.state, this.time);
  static const ink = Color(0xff0a194c),
      blue = Color(0xff1261ef),
      copper = Color(0xffc87a38),
      teal = Color(0xff009ba5);
  @override
  bool shouldRepaint(covariant SupplementalPainter old) => true;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 360, size.height / 270);
    void line(Offset a, Offset b, [Color color = ink, double width = 2]) =>
        canvas.drawLine(
          a,
          b,
          Paint()
            ..color = color
            ..strokeWidth = width,
        );
    void text(
      String s,
      double x,
      double y, [
      Color color = ink,
      double font = 12,
    ]) {
      final t = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            color: color,
            fontSize: font,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
      )..layout(maxWidth: 326 - x.clamp(0, 160));
      t.paint(canvas, Offset(x, y));
    }

    void ball(Offset c, double r, [Color color = blue]) => canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white, color, ink],
          center: const Alignment(-.5, -.5),
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    void box(Rect r, [Color color = copper]) => canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(5)),
      Paint()
        ..shader = LinearGradient(
          colors: [
            color.withValues(alpha: .4),
            color,
            color.withValues(alpha: .7),
          ],
        ).createShader(r),
    );
    void spring(double x, double y, double end, [Color color = ink]) {
      final p = Path()..moveTo(x, y);
      for (int i = 0; i <= 24; i++) {
        p.lineTo(
          x + (end - x) * i / 24,
          y + (i == 0 || i == 24 ? 0 : (i.isEven ? 8 : -8)),
        );
      }
      canvas.drawPath(
        p,
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke,
      );
    }

    void wire(List<Offset> points, [Color color = ink]) {
      final p = Path()..addPolygon(points, false);
      canvas.drawPath(
        p,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    void wave(
      double y,
      double amplitude,
      double frequency, [
      bool rectified = false,
    ]) {
      final p = Path();
      for (int i = 0; i <= 280; i++) {
        var q = math.sin(
          i / 280 * math.pi * frequency +
              time * 2 * math.pi * parameters['frequency'].orZero,
        );
        if (rectified) q = q.abs();
        final pt = Offset(40 + i.toDouble(), y - amplitude * q);
        if (i == 0) {
          p.moveTo(pt.dx, pt.dy);
        } else {
          p.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(
        p,
        Paint()
          ..color = blue
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke,
      );
    }

    double v(String k, [double fallback = 0]) => parameters[k] ?? fallback;
    double s(String k, [double fallback = 0]) => state[k] ?? fallback;
    text(
      'CALCULATED APPARATUS · SCHEMATIC',
      18,
      12,
      const Color(0xff7b86a4),
      10,
    );
    if (state.isEmpty) {
      text('Outside model range', 45, 112, Colors.deepOrange, 20);
      text('Adjust inputs in Inspect to resume.', 45, 150);
      canvas.restore();
      return;
    }
    final k = lab.kind;
    switch (k) {
      case 0:
      case 5:
        line(const Offset(180, 48), const Offset(180, 126), ink, 3);
        canvas.drawOval(
          const Rect.fromLTWH(95, 105, 170, 70),
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xffeff4fa), Color(0xff687d94), Color(0xffccd7e4)],
            ).createShader(const Rect.fromLTWH(95, 105, 170, 70)),
        );
        final a = s('angle');
        line(
          const Offset(180, 140),
          Offset(180 + 75 * math.cos(a), 140 + 28 * math.sin(a)),
          blue,
          5,
        );
        ball(const Offset(180, 140), 7, copper);
        if (k == 5) {
          spring(180, 45, 210, copper);
          text('Twisting suspension', 205, 62);
        } else {
          text('Fixed-axis solid disk', 98, 193);
        }
        text(
          k == 5 ? 'Restoring torque = −κθ' : 'Constant applied torque',
          67,
          220,
          teal,
        );
      case 1:
        final a = Offset(45, 85), b = Offset(310, 205);
        line(a, b, ink, 5);
        final fraction = (s('distance') / v('length')).clamp(0.0, 1.0),
            c = Offset.lerp(a, b, fraction)! + const Offset(0, -18);
        ball(c, 18, copper);
        final angle = s('distance') / v('radius');
        line(
          c,
          c + Offset(15 * math.cos(angle), 15 * math.sin(angle)),
          Colors.white,
          2,
        );
        text('Solid sphere · no slipping', 35, 227);
        text('θ = ${v('incline').toStringAsFixed(1)}°', 40, 180, teal);
      case 2:
        line(const Offset(35, 75), const Offset(35, 190), ink, 5);
        final end = 180 + v('extension') * 600;
        spring(37, 130, end);
        box(Rect.fromLTWH(end, 105, 34, 50));
        line(
          Offset(end + 35, 130),
          Offset(math.min(335, end + 70), 130),
          blue,
          4,
        );
        text('Extension x', 120, 190);
        text('F = kx · force magnitude', 65, 221, teal);
      case 3:
        box(const Rect.fromLTWH(50, 50, 260, 15), ink);
        final extra = (s('strain') * 15000).clamp(0.0, 70.0);
        line(const Offset(180, 65), Offset(180, 175 + extra), copper, 4);
        box(Rect.fromLTWH(160, 175 + extra, 40, 28));
        line(const Offset(215, 65), Offset(215, 175 + extra), blue);
        text('Wire extension exaggerated', 49, 232, teal);
      case 4:
        line(const Offset(50, 224), const Offset(310, 224), ink, 5);
        final y = 210 - 155 * s('height') / v('height');
        ball(Offset(180, y), 15, copper);
        line(const Offset(230, 55), const Offset(230, 210), teal);
        text('Released from rest · vacuum', 48, 240);
        text('g ↓', 260, 130);
      case 6:
        for (int j = 0; j < 2; j++) {
          final y = 85.0 + j * 72;
          line(Offset(35, y), Offset(325, y), const Color(0xffdce4ee));
          final path = Path();
          for (int i = 0; i <= 280; i++) {
            final x = 40 + i.toDouble(),
                local = i / 280 * .025,
                f = v('frequency') + (j == 0 ? 0 : v('difference'));
            final yy = y - 22 * math.sin(2 * math.pi * f * (time + local));
            if (i == 0) {
              path.moveTo(x, yy);
            } else {
              path.lineTo(x, yy);
            }
          }
          canvas.drawPath(
            path,
            Paint()
              ..color = (j == 0 ? blue : teal)
              ..strokeWidth = 2
              ..style = PaintingStyle.stroke,
          );
          text(
            '${(v('frequency') + (j == 0 ? 0 : v('difference'))).toStringAsFixed(1)} Hz',
            40,
            y - 36,
          );
        }
        text('25 ms carrier window · graph shows envelope', 24, 216, ink, 11);
        text(
          'Beat rate = ${s('frequency').toStringAsFixed(2)} Hz',
          85,
          242,
          teal,
        );
      case 7:
        line(const Offset(28, 140), const Offset(330, 140), copper, 4);
        for (int j = 0; j < 2; j++) {
          final x = 115.0 + j * 125;
          canvas.drawOval(
            Rect.fromCenter(center: Offset(x, 140), width: 46, height: 132),
            Paint()..color = blue.withValues(alpha: .13),
          );
          final a = (j == 0 ? 0 : v('angle')) * math.pi / 180;
          line(
            Offset(x - 16 * math.sin(a), 140 - 58 * math.cos(a)),
            Offset(x + 16 * math.sin(a), 140 + 58 * math.cos(a)),
            blue,
            3,
          );
          text(j == 0 ? 'Polarizer' : 'Analyzer', x - 34, 218);
        }
        text('Unpolarized → linear → projected', 39, 49, teal);
        text('I / I₀ = ${s('transmission').toStringAsFixed(3)}', 110, 245);
      case 8:
        final r = Rect.fromLTWH(
          48,
          110,
          264,
          (12 + v('radius') * 14000).clamp(14, 40),
        );
        box(r);
        for (int i = 0; i < 7; i++) {
          final x = 62.0 + i * 36;
          line(Offset(x, 175), Offset(x + 16, 175), blue, 3);
        }
        text('Uniform cylindrical conductor', 51, 62);
        text('Current →', 132, 196, blue);
        text('Cross section A = πr²', 102, 232, teal);
      case 9:
        final top = const Offset(180, 55),
            bottom = const Offset(180, 215),
            left = const Offset(75, 135),
            right = const Offset(285, 135);
        wire([top, left, bottom, right, top]);
        line(left, right, teal);
        ball(const Offset(180, 135), 20, teal);
        text('ΔV', 169, 127, Colors.white);
        text('R1', 83, 77);
        text('R2', 83, 179);
        text('R3', 252, 77);
        text('Rx', 252, 179);
        text('+ supply', 147, 30);
        text('0 V', 169, 226);
        text('Ideal null detector', 112, 250, teal);
      case 10:
        wire(const [
          Offset(45, 175),
          Offset(45, 80),
          Offset(315, 80),
          Offset(315, 175),
          Offset(45, 175),
        ]);
        box(const Rect.fromLTWH(95, 70, 40, 20));
        spring(155, 80, 220, copper);
        line(const Offset(260, 63), const Offset(260, 97), blue, 3);
        line(const Offset(270, 63), const Offset(270, 97), blue, 3);
        ball(const Offset(45, 140), 18, blue);
        text('~', 38, 129, Colors.white, 20);
        text('R', 110, 43);
        text('L', 183, 43);
        text('C', 261, 43);
        text('Steady-state series AC circuit', 52, 210, teal);
        text(
          'φ = ${(s('phase') * 180 / math.pi).toStringAsFixed(1)}°',
          132,
          243,
        );
      case 11:
        box(const Rect.fromLTWH(110, 70, 140, 125), const Color(0xff6b7d91));
        box(const Rect.fromLTWH(140, 95, 80, 75), Colors.white);
        for (int j = 0; j < 8; j++) {
          canvas.drawOval(
            Rect.fromLTWH(98, 78 + j * 13.0, 40, 10),
            Paint()
              ..color = copper
              ..strokeWidth = 4
              ..style = PaintingStyle.stroke,
          );
          canvas.drawOval(
            Rect.fromLTWH(222, 78 + j * 13.0, 40, 10),
            Paint()
              ..color = blue
              ..strokeWidth = 4
              ..style = PaintingStyle.stroke,
          );
        }
        text('AC primary', 22, 216);
        text('AC secondary', 224, 216);
        text('Ideal magnetic core · RMS readings', 51, 244, teal);
      case 12:
        wire(const [
          Offset(65, 75),
          Offset(120, 40),
          Offset(175, 75),
          Offset(120, 110),
          Offset(65, 75),
        ]);
        for (final c in [
          const Offset(92, 57),
          const Offset(148, 57),
          const Offset(92, 93),
          const Offset(148, 93),
        ]) {
          box(Rect.fromCenter(center: c, width: 15, height: 9), copper);
        }
        text('Ideal bridge', 205, 60);
        line(const Offset(40, 200), const Offset(320, 200), ink);
        wave(200, 47, 4, true);
        text('Unsmoothed full-wave output', 58, 232, teal);
      case 13:
      case 14:
        final r = const Rect.fromLTWH(105, 75, 150, 135);
        box(r, const Color(0xffd5e3ed));
        canvas.drawRect(
          const Rect.fromLTWH(115, 125, 130, 75),
          Paint()..color = blue.withValues(alpha: .3),
        );
        line(const Offset(270, 60), const Offset(270, 205), ink, 4);
        ball(const Offset(270, 195), 9, Colors.red);
        line(
          const Offset(270, 190),
          Offset(270, 185 - (s('temperature') - 253.15).clamp(0, 125)),
          Colors.red,
          4,
        );
        if (k == 13) {
          box(const Rect.fromLTWH(147, 138, 62, 37));
          text('Adiabatic equilibrium', 57, 234, teal);
        } else {
          box(const Rect.fromLTWH(98, 213, 164, 13), Colors.deepOrange);
          text(
            s('vapourFraction') >= 1
                ? 'Vaporization complete'
                : s('temperature') < 273.15
                ? 'Warming ice'
                : s('meltFraction') < 1
                ? 'Melting at 0°C'
                : s('temperature') < 373.15
                ? 'Warming water'
                : 'Boiling at 100°C',
            63,
            242,
            teal,
          );
        }
        text(
          '${(s('temperature') - 273.15).toStringAsFixed(1)} °C',
          128,
          42,
          ink,
          20,
        );
      case 15:
        canvas.drawRect(
          const Rect.fromLTWH(55, 150, 250, 65),
          Paint()..color = blue.withValues(alpha: .25),
        );
        wire(const [
          Offset(55, 130),
          Offset(55, 215),
          Offset(305, 215),
          Offset(305, 130),
        ]);
        line(const Offset(168, 55), const Offset(168, 204), ink);
        line(const Offset(192, 55), const Offset(192, 204), ink);
        final h = s('length'), top = 150 - 85 * (h / .03).clamp(-.65, 1.0);
        canvas.drawRect(
          Rect.fromLTWH(170, top, 20, 205 - top),
          Paint()..color = blue.withValues(alpha: .55),
        );
        line(const Offset(215, 150), Offset(215, top), teal, 3);
        text('Bulk liquid level', 55, 123);
        text('Signed rise / depression · scale exaggerated', 24, 240, teal, 11);
      case 16:
        ball(const Offset(185, 145), 18, copper);
        text('+Ze', 171, 137, Colors.white);
        final y = 120 - v('impact') * .45;
        line(Offset(30, y), Offset(160, y), blue, 3);
        final a = s('angle') * math.pi / 180;
        line(
          Offset(160, y),
          Offset(160 + 140 * math.cos(a), y - 100 * math.sin(a)),
          blue,
          3,
        );
        text('α incident', 28, 55);
        text('Scattering asymptotes', 60, 220, teal);
        text('Deflection ${s('angle').toStringAsFixed(1)}°', 95, 245);
      case 17:
        box(const Rect.fromLTWH(65, 80, 230, 30), teal);
        box(Rect.fromLTWH(65, 153, 230 / s('gamma'), 30), blue);
        text('Rest-frame length L₀', 65, 51);
        text('Observer length L₀ / γ', 65, 202);
        text('γ = ${s('gamma').toStringAsFixed(3)}', 118, 238, teal);
      case 18:
        final star = const Offset(180, 65),
            a = const Offset(80, 200),
            b = const Offset(280, 200);
        canvas.drawOval(
          const Rect.fromLTWH(78, 175, 204, 50),
          Paint()
            ..color = ink
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke,
        );
        ball(star, 12, copper);
        ball(a, 8, blue);
        ball(b, 8, blue);
        line(a, star, teal);
        line(b, star, teal);
        line(const Offset(180, 200), star, const Color(0xffa0abc0));
        text('Nearby star', 140, 30);
        text('−B', 65, 218);
        text('+B', 270, 218);
        text(
          'Opposite orbital positions · angles exaggerated',
          22,
          245,
          teal,
          11,
        );
      case 19:
        box(const Rect.fromLTWH(45, 92, 245, 24), const Color(0xff9eabba));
        box(Rect.fromLTWH(45, 158, 245 + 35 * s('strain') / .005, 24));
        text('Original rod', 46, 60);
        text('Heated rod · extension exaggerated', 46, 208);
        text(
          'ΔL = ${(s('length') * 1000).toStringAsFixed(3)} mm',
          92,
          243,
          teal,
        );
    }
    canvas.restore();
  }
}

extension on double? {
  double get orZero => this ?? 0;
}
