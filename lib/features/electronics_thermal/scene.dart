import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/physics/electronics_thermal.dart';
import '../../core/rendering/scientific_text.dart';
import '../../core/rendering/materials.dart';

/// Independent repaint boundary: texture/grid work is invariant during playback.
class ETBackdrop extends CustomPainter {
  final bool electronics;
  const ETBackdrop({required this.electronics});
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 360, size.height / 270);
    c.drawRect(
      const Rect.fromLTWH(0, 0, 360, 270),
      Paint()..color = const Color(0xffedf3f5),
    );
    LabMaterials.wood(c, const Rect.fromLTWH(0, 225, 360, 45));
    if (electronics) {
      LabMaterials.shadow(c, const Rect.fromLTWH(18, 193, 324, 22));
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(15, 65, 330, 145),
          const Radius.circular(8),
        ),
        Paint()..color = const Color(0xfffaf7ed),
      );
      for (int row = 0; row < 6; row++) {
        for (int group = 0; group < 2; group++) {
          for (int col = 0; col < 5; col++) {
            c.drawCircle(
              Offset(30 + group * 175 + col * 23, 88 + row * 18),
              1.7,
              Paint()..color = const Color(0xffa4a7a0),
            );
          }
        }
      }
      c.drawLine(
        const Offset(20, 72),
        const Offset(340, 72),
        Paint()
          ..color = Colors.red.shade400
          ..strokeWidth = 2,
      );
      c.drawLine(
        const Offset(20, 202),
        const Offset(340, 202),
        Paint()
          ..color = Colors.blue.shade400
          ..strokeWidth = 2,
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant ETBackdrop old) =>
      old.electronics != electronics;
}

/// Original vector apparatus. Positions and readouts are derived from ET state;
/// carrier dots and thermal colours are explanatory diagrams, not microscopes.
class ETPainter extends CustomPainter {
  final ETRun run;
  final bool labels, overlays;
  final int revision;
  ETPainter(this.run, {this.labels = true, this.overlays = true})
    : revision = run.revision;
  void text(
    Canvas c,
    String s,
    Offset p, {
    double size = 12,
    Color color = const Color(0xff17324d),
  }) {
    if (!labels) return;
    ScientificText.paint(c, s, p, color: color, font: size);
  }

  void line(Canvas c, Offset a, Offset b, Color color, [double width = 2]) =>
      c.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = width,
      );
  void box(Canvas c, Rect r, Color color, {double radius = 8}) => c.drawRRect(
    RRect.fromRectAndRadius(r, Radius.circular(radius)),
    Paint()..color = color,
  );
  String num(double? x) => x == null
      ? '—'
      : x.abs() != 0 && (x.abs() < .001 || x.abs() > 1e6)
      ? x.toStringAsExponential(3)
      : x.toStringAsPrecision(5);
  @override
  void paint(Canvas canvas, Size size) {
    final c = canvas;
    c.save();
    c.scale(size.width / 360, size.height / 270);
    final k = run.kind, s = run.state, p = run.p, m = run.mode;
    if (k < 6) {
      if (k == 0) {
        box(c, const Rect.fromLTWH(95, 90, 170, 104), const Color(0xff36485c));
        for (int x = 0; x < 5; x++) {
          for (int y = 0; y < 3; y++) {
            final at = Offset(111 + x * 32, 108 + y * 31);
            if (x < 4) {
              line(
                c,
                at,
                at + const Offset(32, 0),
                Colors.blueGrey.shade200,
                1,
              );
            }
            c.drawCircle(
              at,
              6,
              Paint()
                ..color =
                    (m == 1
                            ? Colors.blue
                            : m == 2
                            ? Colors.orange
                            : Colors.grey)
                        .shade300,
            );
          }
        }
        text(c, 'Neutral bulk • schematic lattice', const Offset(78, 43));
        if (overlays) {
          line(c, const Offset(20, 22), const Offset(115, 22), Colors.blue);
          line(c, const Offset(20, 42), const Offset(115, 42), Colors.orange);
          text(c, 'Eg 1.12 eV', const Offset(125, 20));
          final y = 32 - 20 * (s['fermiOffset'] ?? 0) / (s['bandGap'] ?? 1);
          line(c, Offset(20, y), Offset(115, y), Colors.teal, 1);
          text(
            c,
            'EF offset ${num(s['fermiOffset'])} J',
            const Offset(148, 3),
            size: 9,
          );
        }
      } else if (k == 1) {
        line(
          c,
          const Offset(45, 130),
          const Offset(300, 130),
          Colors.deepOrange,
          3,
        );
        line(
          c,
          const Offset(300, 130),
          const Offset(300, 187),
          Colors.deepOrange,
          3,
        );
        line(
          c,
          const Offset(300, 187),
          const Offset(45, 187),
          Colors.blueGrey,
          3,
        );
        line(
          c,
          const Offset(45, 187),
          const Offset(45, 144),
          Colors.blueGrey,
          3,
        );
        line(
          c,
          const Offset(45, 115),
          const Offset(45, 130),
          Colors.deepOrange,
          3,
        );
        c.drawCircle(
          const Offset(45, 130),
          14,
          Paint()..color = const Color(0xffedf3f5),
        );
        c.drawCircle(
          const Offset(45, 130),
          14,
          Paint()
            ..color = Colors.blueGrey
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        text(c, '±', const Offset(40, 121), size: 14);
        text(c, 'Vs ${num(p['supply'])} V', const Offset(60, 169), size: 10);
        box(c, const Rect.fromLTWH(90, 119, 56, 22), const Color(0xffcfb08b));
        for (int x = 0; x < 3; x++) {
          box(
            c,
            Rect.fromLTWH(102 + x * 12, 119, 4, 22),
            [Colors.brown, Colors.black, Colors.red][x],
            radius: 0,
          );
        }
        box(c, const Rect.fromLTWH(207, 120, 52, 20), Colors.grey.shade800);
        box(
          c,
          const Rect.fromLTWH(248, 120, 5, 20),
          Colors.grey.shade300,
          radius: 0,
        );
        text(c, 'R', const Offset(108, 100));
        text(c, 'A    diode    K', const Offset(197, 151));
        text(c, 'I = ${num(s['current'])} A', const Offset(50, 37));
      } else if (k == 2) {
        for (int i = 0; i < 3; i++) {
          line(
            c,
            Offset(156 + i * 23, 139),
            Offset(156 + i * 23, 191),
            Colors.grey.shade600,
            4,
          );
        }
        box(c, const Rect.fromLTWH(139, 87, 86, 65), Colors.grey.shade900);
        text(c, 'NPN', const Offset(165, 108), color: Colors.white);
        text(c, 'E      B      C', const Offset(150, 193));
        text(
          c,
          ['Cutoff', 'Forward active', 'Saturation'][(s['region'] ?? 0)
              .toInt()],
          const Offset(25, 30),
        );
        text(c, 'Generic E–B–C model', const Offset(113, 65));
        line(
          c,
          const Offset(156, 191),
          const Offset(156, 211),
          Colors.blueGrey,
          2,
        );
        line(
          c,
          const Offset(136, 211),
          const Offset(172, 211),
          Colors.blueGrey,
          2,
        );
        line(
          c,
          const Offset(179, 191),
          const Offset(74, 191),
          Colors.deepOrange,
          2,
        );
        box(
          c,
          const Rect.fromLTWH(72, 163, 13, 28),
          const Color(0xffcfb08b),
          radius: 1,
        );
        line(
          c,
          const Offset(79, 163),
          const Offset(79, 107),
          Colors.deepOrange,
          2,
        );
        text(c, 'Vdrive', const Offset(29, 89), size: 10);
        text(c, 'Rb', const Offset(52, 168), size: 10);
        line(
          c,
          const Offset(202, 191),
          const Offset(282, 191),
          Colors.deepOrange,
          2,
        );
        line(
          c,
          const Offset(282, 191),
          const Offset(282, 130),
          Colors.deepOrange,
          2,
        );
        box(
          c,
          const Rect.fromLTWH(275, 102, 14, 28),
          const Color(0xffcfb08b),
          radius: 1,
        );
        line(
          c,
          const Offset(282, 102),
          const Offset(282, 81),
          Colors.deepOrange,
          2,
        );
        text(c, 'Vcc', const Offset(270, 62), size: 10);
        text(c, 'Rc', const Offset(298, 108), size: 10);
      } else if (k == 3 || k == 4) {
        for (int i = 0; i < 4; i++) {
          for (int side = 0; side < 2; side++) {
            box(
              c,
              Rect.fromLTWH(126 + i * 25, side == 0 ? 98 : 167, 9, 18),
              Colors.grey.shade500,
              radius: 1,
            );
          }
        }
        box(c, const Rect.fromLTWH(116, 111, 121, 58), Colors.grey.shade900);
        text(
          c,
          k == 3 ? 'IDEAL OP AMP' : 'BOOLEAN',
          const Offset(128, 132),
          color: Colors.white,
          size: 11,
        );
        if (k == 4) {
          for (int i = 0; i < 3; i++) {
            final on = (s[['inputA', 'inputB', 'logicOutput'][i]] ?? 0) > 0;
            c.drawCircle(
              Offset(55 + i * 125, 45),
              10,
              Paint()..color = on ? Colors.green : Colors.grey.shade400,
            );
          }
          text(
            c,
            'A                  B                  Y',
            const Offset(50, 18),
          );
        } else {
          text(c, '+ / − inputs • dual rails', const Offset(102, 77));
          text(
            c,
            'Vin ${num(s['inputVoltage'])} V   Vout ${num(s['outputVoltage'])} V',
            const Offset(48, 32),
          );
          amplifierCircuit(c);
        }
      } else {
        box(c, const Rect.fromLTWH(95, 92, 170, 95), const Color(0xff31776e));
        c.drawCircle(
          const Offset(180, 132),
          24,
          Paint()..color = Colors.grey.shade300,
        );
        for (int i = 0; i < 3; i++) {
          line(
            c,
            Offset(150 + i * 30, 187),
            Offset(150 + i * 30, 211),
            Colors.grey.shade700,
            4,
          );
        }
        text(
          c,
          ['TMP36 transfer', 'LDR divider', 'Echo time-of-flight'][m],
          const Offset(105, 48),
        );
        text(c, 'Offline simulated module', const Offset(94, 216));
      }
    } else {
      if (k == 6) {
        final rect = const Rect.fromLTWH(80, 86, 160, 133);
        box(c, rect, const Color(0xffb6d5e6));
        box(c, const Rect.fromLTWH(85, 126, 150, 88), const Color(0xff71b1ce));
        c.drawOval(
          const Rect.fromLTWH(85, 117, 150, 20),
          Paint()..color = const Color(0xff98ccdf),
        );
        line(
          c,
          const Offset(206, 47),
          const Offset(206, 187),
          Colors.grey.shade700,
          7,
        );
        c.drawCircle(
          const Offset(206, 187),
          7,
          Paint()..color = Colors.grey.shade800,
        );
        text(
          c,
          'Sample ${num(s['sampleTemperature'])} K',
          const Offset(50, 21),
        );
        text(c, 'Probe ${num(s['probeTemperature'])} K', const Offset(50, 43));
      } else if (k == 7) {
        if (m == 0) {
          LabMaterials.metal(c, const Rect.fromLTWH(45, 111, 270, 45));
          if (overlays) {
            for (int i = 0; i < 27; i++) {
              box(
                c,
                Rect.fromLTWH(45 + i * 10, 111, 10, 45),
                thermalColor(
                  (p['leftT'] ?? 300) +
                      ((p['rightT'] ?? 300) - (p['leftT'] ?? 300)) * i / 26,
                ),
                radius: 0,
              );
            }
          }
          final x = 45 + 270 * (p['probe'] ?? .5);
          line(c, Offset(x, 89), Offset(x, 165), Colors.black, 2);
          text(
            c,
            'T colour scale 273–353 K • fixed reservoirs',
            const Offset(27, 44),
            size: 11,
          );
          text(c, '${num(p['leftT'])} K', const Offset(23, 178));
          text(c, '${num(p['rightT'])} K', const Offset(245, 178));
        } else {
          LabMaterials.metal(c, const Rect.fromLTWH(125, 95, 110, 105));
          if (overlays) {
            for (int i = 0; i < 5; i++) {
              final rate = s['heatRate'] ?? 0, x = 75.0 + i * 48;
              if (rate.abs() > 1e-12) {
                final start = Offset(x, rate > 0 ? 70 : 40),
                    end = Offset(x, rate > 0 ? 40 : 70);
                line(c, start, end, Colors.blueGrey, 2);
                line(
                  c,
                  end,
                  end + Offset(-3, rate > 0 ? 5 : -5),
                  Colors.blueGrey,
                  2,
                );
                line(
                  c,
                  end,
                  end + Offset(3, rate > 0 ? 5 : -5),
                  Colors.blueGrey,
                  2,
                );
              }
            }
          }
          text(
            c,
            '${m == 1 ? 'Convection' : 'Radiation'} • no visible glow',
            const Offset(50, 22),
          );
          text(c, 'Body ${num(s['temperature'])} K', const Offset(87, 65));
          text(c, 'Ambient ${num(p['ambientT'])} K', const Offset(88, 211));
        }
      } else if (k == 10 && m == 2) {
        box(
          c,
          const Rect.fromLTWH(32, 99, 130, 100),
          thermalColor(s['body1Temperature'] ?? 300),
        );
        box(
          c,
          const Rect.fromLTWH(198, 99, 130, 100),
          thermalColor(s['body2Temperature'] ?? 300),
        );
        line(c, const Offset(162, 148), const Offset(198, 148), Colors.grey, 9);
        text(c, '${num(s['body1Temperature'])} K', const Offset(45, 137));
        text(c, '${num(s['body2Temperature'])} K', const Offset(210, 137));
        text(c, 'Isolated pair • energy conserved', const Offset(55, 40));
      } else {
        final v = s['volume'] ?? p['initialVolume'] ?? .0025,
            base = p['initialVolume'] ?? .0025;
        final maxVolume = run.profile.fold<double>(
          base * math.max(1, p['volumeRatio'] ?? 1),
          (a, row) => math.max(a, row['volume'] ?? 0),
        );
        // Constant cross section within this configuration: height ∝ volume.
        // Camera framing adapts to the complete process, including both adiabats.
        final height = 150 * v / maxVolume, y = 218 - height;
        box(c, const Rect.fromLTWH(87, 56, 186, 166), const Color(0xffc3d6dc));
        box(c, Rect.fromLTWH(94, y, 172, 218 - y), const Color(0xffa8c9d6));
        LabMaterials.metal(c, Rect.fromLTWH(89, y - 9, 182, 13));
        line(
          c,
          Offset(180, y - 9),
          const Offset(180, 33),
          Colors.grey.shade700,
          10,
        );
        text(c, 'P ${num(s['pressure'])} Pa', const Offset(15, 13));
        text(c, 'V ${num(v)} m³', const Offset(15, 34));
        text(c, 'T ${num(s['temperature'])} K', const Offset(100, 234));
        if (k == 11) {
          text(
            c,
            [
              '1 Hot isotherm',
              '2 Adiabatic expansion',
              '3 Cold isotherm',
              '4 Adiabatic compression',
            ][(s['stage'] ?? 0).toInt().clamp(0, 3)],
            const Offset(90, 67),
            size: 11,
          );
        }
        if (overlays && s.containsKey('heat') && s.containsKey('work')) {
          text(
            c,
            'Q ${num(s['heat'])} J   W ${num(s['work'])} J',
            const Offset(72, 198),
            size: 11,
          );
        }
      }
    }
    text(
      c,
      run.invalid.isEmpty
          ? 'Calculated state • ${num(run.time)} s'
          : 'Outside model validity',
      const Offset(14, 250),
      size: 10,
    );
    c.restore();
  }

  @override
  bool shouldRepaint(covariant ETPainter old) =>
      old.run != run ||
      old.revision != revision ||
      old.labels != labels ||
      old.overlays != overlays;

  void amplifierCircuit(Canvas c) {
    // Functional ideal-op-amp schematic, deliberately not a named IC pinout.
    box(c, const Rect.fromLTWH(27, 65, 306, 148), const Color(0xfffaf7ed));
    text(
      c,
      'Ideal feedback • rails ±${num(run.p['rail'])} V',
      const Offset(60, 74),
      size: 10,
    );
    final body = Path()
      ..moveTo(154, 103)
      ..lineTo(154, 165)
      ..lineTo(210, 134)
      ..close();
    c.drawPath(body, Paint()..color = const Color(0xff17324d));
    text(c, '+', const Offset(158, 105), color: Colors.white, size: 13);
    text(c, '−', const Offset(158, 143), color: Colors.white, size: 13);
    line(
      c,
      const Offset(210, 134),
      const Offset(310, 134),
      Colors.deepOrange,
      2,
    );
    line(
      c,
      const Offset(300, 134),
      const Offset(300, 185),
      Colors.deepOrange,
      2,
    );
    line(
      c,
      const Offset(300, 185),
      const Offset(132, 185),
      Colors.deepOrange,
      2,
    );
    line(
      c,
      const Offset(132, 185),
      const Offset(132, 151),
      Colors.deepOrange,
      2,
    );
    line(
      c,
      const Offset(132, 151),
      const Offset(154, 151),
      Colors.deepOrange,
      2,
    );
    box(
      c,
      const Rect.fromLTWH(215, 177, 45, 16),
      const Color(0xffcfb08b),
      radius: 2,
    );
    text(
      c,
      'Rf ${num(run.p['feedback']! / 1000)} kΩ',
      const Offset(202, 197),
      size: 9,
    );
    c.drawCircle(
      const Offset(132, 151),
      2.5,
      Paint()..color = Colors.deepOrange,
    );
    text(c, 'out', const Offset(305, 116), size: 9);
    void ground(Offset p) {
      line(c, p, p + const Offset(0, 7), Colors.blueGrey, 2);
      for (int i = 0; i < 3; i++) {
        line(
          c,
          p + Offset(-9 + i * 3, 7 + i * 4),
          p + Offset(9 - i * 3, 7 + i * 4),
          Colors.blueGrey,
          1,
        );
      }
    }

    if (run.mode == 0) {
      line(c, const Offset(45, 115), const Offset(154, 115), Colors.blue, 2);
      text(c, 'Vin', const Offset(39, 96), size: 10);
      line(
        c,
        const Offset(132, 151),
        const Offset(75, 151),
        Colors.deepOrange,
        2,
      );
      line(
        c,
        const Offset(75, 151),
        const Offset(75, 190),
        Colors.deepOrange,
        2,
      );
      box(
        c,
        const Rect.fromLTWH(68, 162, 14, 23),
        const Color(0xffcfb08b),
        radius: 2,
      );
      ground(const Offset(75, 190));
      text(
        c,
        'Rg ${num(run.p['inputResistance']! / 1000)} kΩ',
        const Offset(31, 133),
        size: 9,
      );
    } else {
      line(c, const Offset(45, 151), const Offset(132, 151), Colors.blue, 2);
      box(
        c,
        const Rect.fromLTWH(75, 143, 40, 16),
        const Color(0xffcfb08b),
        radius: 2,
      );
      text(c, 'Vin', const Offset(34, 165), size: 10);
      text(
        c,
        'Rin ${num(run.p['inputResistance']! / 1000)} kΩ',
        const Offset(38, 124),
        size: 9,
      );
      line(
        c,
        const Offset(154, 115),
        const Offset(130, 115),
        Colors.blueGrey,
        2,
      );
      line(
        c,
        const Offset(130, 115),
        const Offset(130, 94),
        Colors.blueGrey,
        2,
      );
      text(c, '0 V', const Offset(108, 93), size: 9);
    }
  }

  Color thermalColor(double kelvin) => Color.lerp(
    Colors.blue.shade300,
    Colors.red.shade300,
    ((kelvin - 273.15) / 80).clamp(0, 1),
  )!;
}
