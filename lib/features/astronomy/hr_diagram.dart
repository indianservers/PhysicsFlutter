import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design_system/reading_presentation.dart';
import '../../core/design_system/theme.dart';
import '../../core/physics/astronomy_data.dart';

class HRDiagram extends StatelessWidget {
  final int track;
  final double logTemperature, logLuminosity, ageFraction;
  final ValueChanged<double> changeAge;
  const HRDiagram({
    super.key,
    required this.track,
    required this.logTemperature,
    required this.logLuminosity,
    required this.ageFraction,
    required this.changeAge,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Hertzsprung–Russell diagram',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      Text(
        'Bundled MIST model · ${stellarMasses[track]} solar masses · dot = current star',
      ),
      Semantics(
        label:
            'Stellar evolutionary track. Temperature decreases toward the right. Current log10 effective temperature $logTemperature K; log10 luminosity relative to the Sun $logLuminosity.',
        child: SizedBox(
          height: 280,
          child: CustomPaint(
            painter: _HRPainter(
              stellarTracks[track],
              logTemperature,
              logLuminosity,
            ),
          ),
        ),
      ),
      Text('Track age: ${(ageFraction * 100).toStringAsFixed(1)}%'),
      Slider(
        value: ageFraction.clamp(0, 1),
        label: '${(ageFraction * 100).round()}%',
        semanticFormatterCallback: (v) =>
            '${(v * 100).round()} percent of this track',
        onChanged: changeAge,
      ),
      const Text(
        'The slider changes the model age. Curves show the selected evolutionary model, not an observed population of stars. Temperature increases to the left; both axes use base-10 logarithms.',
      ),
    ],
  );
}

class _HRPainter extends CustomPainter {
  final List<List<double>> rows;
  final double currentT, currentL;
  _HRPainter(this.rows, this.currentT, this.currentL);
  @override
  void paint(Canvas c, Size s) {
    final minT = rows.map((r) => r[2]).reduce(math.min) - .08,
        maxT = rows.map((r) => r[2]).reduce(math.max) + .08;
    final minL = rows.map((r) => r[1]).reduce(math.min) - .15,
        maxL = rows.map((r) => r[1]).reduce(math.max) + .15;
    final area = Rect.fromLTRB(48, 30, s.width - 12, s.height - 46);
    Offset point(double t, double l) => Offset(
      area.left + (maxT - t) / (maxT - minT) * area.width,
      area.bottom - (l - minL) / (maxL - minL) * area.height,
    );
    void text(String value, Offset p) {
      final t = TextPainter(
        text: TextSpan(
          text: value,
          style: const TextStyle(color: navy, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: s.width);
      t.paint(c, p);
      t.dispose();
    }

    for (var i = 0; i <= 4; i++) {
      final y = area.top + i * area.height / 4;
      c.drawLine(
        Offset(area.left, y),
        Offset(area.right, y),
        Paint()..color = const Color(0xffdce5ee),
      );
      text(
        conciseNumber(maxL - (maxL - minL) * i / 4, precision: 3),
        Offset(0, y - 6),
      );
    }
    final path = Path();
    for (final r in rows.indexed) {
      final p = point(r.$2[2], r.$2[1]);
      if (r.$1 == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    c.drawPath(
      path,
      Paint()
        ..color = navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    c.drawCircle(point(currentT, currentL), 5, Paint()..color = cobalt);
    text('log₁₀(L / L☉)', const Offset(0, 6));
    text(conciseNumber(maxT, precision: 3), Offset(area.left, area.bottom + 6));
    text(
      conciseNumber(minT, precision: 3),
      Offset(area.right - 26, area.bottom + 6),
    );
    text('log₁₀(Tₑff / K) · hotter ←', Offset(area.left, s.height - 18));
  }

  @override
  bool shouldRepaint(covariant _HRPainter old) =>
      rows != old.rows || currentT != old.currentT || currentL != old.currentL;
}
