import 'dart:convert';
import 'dart:io';

import 'package:physics_atelier/features/electromagnetism/curriculum.dart';
import 'package:physics_atelier/core/physics/electromagnetism.dart';

void main() {
  const titles = [
    'Coulomb Force',
    'Electric Field',
    'Electric Potential',
    'Current',
    'Circuits',
    'Capacitors',
    'Field Lines',
    'Lorentz Force',
    'Current-Carrying Wire',
    'Solenoids',
    'Induction',
    'Electromagnets',
  ];
  final b = StringBuffer(
    '# Phase 5 per-lab scientific specification\n\nGenerated from the shipped curriculum by `dart run tool/phase5_evidence.dart`. Model `$emVersion`. Companion [science and references](PHASE5_SCIENCE.md). Every stored physical input uses the listed SI unit.\n\n',
  );
  for (int i = 0; i < 12; i++) {
    final l = emLessons[i];
    b.writeln(
      '## ${i + 1}. ${titles[i]}\n\nStable ID `s${i < 6 ? 10 : 11}-e0${i % 6}`.\n\n${l.apparatus}\n\nPrinciple: ${l.principle}\n\nEquation: `${l.formula}`\n\nUnits and convention: ${l.symbols}\n\nAssumptions, method and limitations: ${l.limits}\n\nInvestigation: ${l.procedure}\n\nMisconception: ${l.mistake}\n\nWorked example: ${l.example}\n\nRecorded primary quantity `${l.metric}`, unit ${l.unit}.\n\nSupported control bounds (dependent geometry validity still applies):\n',
    );
    if (l.controls.isEmpty) {
      b.writeln(
        '- Real graph editor: 1–12 components, ≤24 wires; terminal topology and per-component values saved. Resistors/lamps .1–10000 Ω; ideal sources −24…24 V; ideal series ammeters/across-node voltmeters/switches.',
      );
    }
    for (final p in l.controls) {
      b.writeln(
        '- ${p.label} (`${p.key}`): ${p.min}…${p.max} ${p.unit}; default ${p.initial}.',
      );
    }
    b.writeln();
  }
  File('docs/PHASE5_LAB_SPECIFICATIONS.md')
      .writeAsStringSync('${b.toString().trimRight()}\n');
  final results = <String, dynamic>{
    'model': emVersion,
    'qualification': 'Host pure-Dart elapsed numerical cost, includes allocation; 10 warmups, 100 iterations. Not device frame measurements.',
  };
  void measure(String label, void Function() callback) {
    for (int i = 0; i < 10; i++) {
      callback();
    }
    final times = <double>[];
    for (int i = 0; i < 100; i++) {
      final watch = Stopwatch()..start();
      callback();
      watch.stop();
      times.add(watch.elapsedMicroseconds / 1000);
    }
    times.sort();
    results[label] = {
      'medianMs': times[50],
      'p95Ms': times[94],
      'iterations': 100,
    };
  }

  measure(
    'Two-source field/contour rebuild',
    () => EMRun(2, emLessons[2].defaults),
  );
  final geometry = EMRun(2, emLessons[2].defaults);
  measure(
    'Cached-geometry probe update',
    () => EMRun(2, {...geometry.p, 'probeX': .22}, geometryFrom: geometry),
  );
  final graph = CircuitGraph.example(2);
  for (int i = 0; i < 5; i++) {
    final p = CircuitPart('Stress$i', 'resistor', value: 10.0 + 5 * i);
    graph.parts.add(p);
    graph.wires.addAll([
      [p.a, 'B1:a'],
      [p.b, 'B1:b'],
    ]);
  }
  measure('Twelve-part MNA solve', () => solveCircuit(graph));
  measure(
    '256-sample finite-loop flux and derivative',
    () => loopFlux(.04, .015, .05, .15),
  );
  measure(
    'Boris tick, worst supported gyrofrequency',
    () => borisStep(
      V3.zero,
      const V3(2e6, 1e6, 1e6),
      3.2e-19,
      1e-27,
      const V3(0, 0, .1),
      EMRun.dt * 1e-6,
    ),
  );
  File('screenshots/phase5-numerics.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(results));
}
