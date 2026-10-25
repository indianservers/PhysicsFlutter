import 'dart:convert';
import 'dart:io';

import 'package:physics_atelier/features/waves/curriculum.dart';
import 'package:physics_atelier/core/physics/waves_optics.dart';

// Reproducible documentation of actual curriculum ranges and numerical cost.
void main() {
  const titles = [
    'Wave Properties',
    'Superposition',
    'Interference — mechanical',
    'Standing Waves',
    'Sound Spectrum',
    'Doppler Effect',
    'Reflection',
    'Refraction',
    'Lenses',
    'Mirrors',
    'Interference — optical',
    'Diffraction',
  ];
  final b = StringBuffer(
    '# Phase 4 per-lab scientific specification\n\nGenerated from the shipped curriculum by `dart run tool/phase4_evidence.dart`. Model `$waveOpticsVersion`. Companion numerical/sampling notes: [PHASE4_SCIENCE.md](PHASE4_SCIENCE.md). These are ideal teaching models with the explicit limits below. All stored physical inputs use SI units.\n\n',
  );
  for (int i = 0; i < 12; i++) {
    final l = waveLessons[i];
    b.writeln(
      '## ${i + 1}. ${titles[i]}\n\nStable ID: `s0${i < 6 ? 8 : 9}-e0${i % 6}`.\n\n${l.apparatus}\n\n${l.principle}\n\nEquation: `${l.formula}`\n\nSymbols/convention: ${l.symbols}\n\nSupported assumptions and limitations: ${l.limits}\n\nProcedure: ${l.procedure}\n\nMisconception: ${l.mistake}\n\nWorked example: ${l.example}\n\nRecorded primary quantity: `${l.metric}` (${l.unit.isEmpty ? 'dimensionless' : l.unit}).\n\nIndependent control bounds (dependent validity clamps may narrow them):\n',
    );
    for (final p in l.controls) {
      b.writeln(
        '- ${p.label} (`${p.key}`): ${p.min} to ${p.max} ${p.unit}; documented default ${p.initial}.',
      );
    }
    b.writeln();
  }
  File('docs/PHASE4_LAB_SPECIFICATIONS.md')
      .writeAsStringSync('${b.toString().trimRight()}\n');
  final measurements = <String, dynamic>{
    'qualification': 'Host pure-Dart elapsed numerical cost, not device frame times; includes allocations; 10 warmups then 100 calls.',
    'model': waveOpticsVersion,
  };
  for (final k in [2, 4, 11]) {
    final p = waveLessons[k].defaults;
    for (int i = 0; i < 10; i++) {
      WaveOpticsRun(k, p);
    }
    final times = <double>[];
    for (int i = 0; i < 100; i++) {
      final watch = Stopwatch()..start();
      WaveOpticsRun(k, p);
      watch.stop();
      times.add(watch.elapsedMicroseconds / 1000);
    }
    times.sort();
    measurements[titles[k]] = {
      'medianMs': times[50],
      'p95Ms': times[94],
      'iterations': 100,
    };
  }
  File(
    'screenshots/phase4-numerics.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(measurements));
}
