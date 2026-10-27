import 'package:flutter/material.dart';

import '../../core/design_system/reading_presentation.dart';
import '../../core/design_system/theme.dart';
import '../../core/physics/electromagnetism.dart';

/// An alternate view of the same graph: terminal identity determines connections.
class CircuitSchematic extends StatelessWidget {
  final CircuitGraph circuit;
  final CircuitSolution? solution;
  const CircuitSchematic({super.key, required this.circuit, this.solution});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Circuit schematic', style: Theme.of(context).textTheme.titleMedium),
      const Text(
        'Same components and wires as the physical view. Dots indicate terminals; crossing wires are not joined unless their endpoint identities match.',
      ),
      Semantics(
        label:
            'Connected circuit schematic with ${circuit.parts.length} components and ${circuit.wires.length} wires. Each branch is described below.',
        child: SizedBox(
          height: ((circuit.parts.length + 1) ~/ 2) * 120.0 + 24,
          child: CustomPaint(painter: _Network(circuit)),
        ),
      ),
      for (final part in circuit.parts)
        ExpansionTile(
          title: Text('${part.id} · ${part.type}'),
          subtitle: Text('${part.a} ↔ ${part.b}'),
          children: [
            SizedBox(height: 100, child: CustomPaint(painter: _Symbol(part))),
            if (part.type == 'source')
              Text(
                'Source: ${conciseNumber(part.value)} V; terminal a is positive relative to b.',
              ),
            if (['resistor', 'lamp'].contains(part.type))
              Text('Resistance: ${conciseNumber(part.value)} Ω'),
            if (part.type == 'switch')
              Text(part.closed ? 'Switch closed' : 'Switch open'),
            if (solution?.valid ?? false) ...[
              Text(
                'I (a → b): ${conciseNumber(solution!.currents[part.id] ?? 0)} A',
              ),
              Text(
                'V (a − b): ${conciseNumber(solution!.voltages[part.id] ?? 0)} V',
              ),
              Text(
                'Absorbed power: ${conciseNumber(solution!.powers[part.id] ?? 0)} W',
              ),
            ],
          ],
        ),
      const SizedBox(height: 8),
      const Text('Actual wire connections'),
      for (final wire in circuit.wires) Text(wire.join(' ↔ ')),
      if (solution != null && !solution!.valid) Text(solution!.message),
    ],
  );
}

class _Network extends CustomPainter {
  final CircuitGraph graph;
  _Network(this.graph);
  @override
  void paint(Canvas c, Size s) {
    final width = s.width / 2 - 16;
    final terminals = <String, Offset>{};
    Offset origin(int index) =>
        Offset(8 + (index % 2) * s.width / 2, 12 + (index ~/ 2) * 120.0);
    for (final part in graph.parts.indexed) {
      final at = origin(part.$1);
      terminals[part.$2.a] = at + const Offset(20, 50);
      terminals[part.$2.b] = at + Offset(width - 20, 50);
    }
    for (final wire in graph.wires.indexed) {
      if (wire.$2.length != 2) continue;
      final a = terminals[wire.$2[0]], b = terminals[wire.$2[1]];
      if (a == null || b == null) continue;
      final gutter = s.width / 2 + (wire.$1 % 5 - 2) * 3;
      c.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(gutter, a.dy)
          ..lineTo(gutter, b.dy)
          ..lineTo(b.dx, b.dy),
        Paint()
          ..color = teal
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke,
      );
    }
    for (final part in graph.parts.indexed) {
      final at = origin(part.$1);
      c.save();
      c.translate(at.dx, at.dy);
      c.drawRect(
        Rect.fromLTWH(24, 26, width - 48, 48),
        Paint()..color = Colors.white,
      );
      _Symbol(part.$2).paint(c, Size(width, 100));
      final t = TextPainter(
        text: TextSpan(
          text: part.$2.id,
          style: const TextStyle(
            color: navy,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: width);
      t.paint(c, const Offset(8, 0));
      t.dispose();
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _Network old) => true;
}

class _Symbol extends CustomPainter {
  final CircuitPart part;
  _Symbol(this.part);
  @override
  void paint(Canvas c, Size s) {
    final y = s.height / 2,
        x = s.width / 2,
        p = Paint()
          ..color = navy
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
    c.drawLine(Offset(20, y), Offset(x - 30, y), p);
    c.drawLine(Offset(x + 30, y), Offset(s.width - 20, y), p);
    c.drawCircle(Offset(20, y), 3, p);
    c.drawCircle(Offset(s.width - 20, y), 3, p);
    switch (part.type) {
      case 'resistor':
        c.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: 60, height: 20),
          p,
        );
      case 'switch':
        c.drawLine(
          Offset(x - 30, y),
          Offset(x + 30, part.closed ? y : y - 20),
          p,
        );
      default:
        c.drawCircle(Offset(x, y), 22, p);
    }
    void label(String value, Offset at) {
      final t = TextPainter(
        text: TextSpan(
          text: value,
          style: const TextStyle(color: navy, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      t.paint(c, at);
      t.dispose();
    }

    label('a', Offset(16, y + 10));
    label('b', Offset(s.width - 24, y + 10));
    if (part.type == 'ammeter') label('A', Offset(x - 5, y - 10));
    if (part.type == 'voltmeter') label('V', Offset(x - 5, y - 10));
    if (part.type == 'source') {
      label('+', Offset(x - 16, y - 10));
      label('−', Offset(x + 4, y - 10));
    }
    if (part.type == 'lamp') {
      c.drawLine(Offset(x - 12, y - 12), Offset(x + 12, y + 12), p);
      c.drawLine(Offset(x - 12, y + 12), Offset(x + 12, y - 12), p);
    }
  }

  @override
  bool shouldRepaint(covariant _Symbol old) => true;
}
