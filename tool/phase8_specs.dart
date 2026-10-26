import 'dart:io';

import 'package:physics_atelier/features/astronomy/curriculum.dart';
import 'package:physics_atelier/content/catalog.dart';

void main() {
  final out = StringBuffer(
    '# Phase 8 lab specifications\n\nGenerated from the same curriculum and control definitions used by the app. SI units internally. Model plots use calculated data; the SPARC option retains observed points and uncertainties. Model astronomy-8.0.\n\n',
  );
  for (int k = 0; k < 6; k++) {
    final e = studios[16].entries[k], l = astroLessons[k];
    out.writeln(
      '## ${e.id} — ${e.title}\n\n${l.apparatus}\n\n${l.principle}\n\nEquation: `${l.formula}`\n\n${l.symbols}\n\n${l.limits}\n\nReference example: ${l.example}\n\nPrimary observation: ${l.metric} (${l.unit}).\n\nModes: ${astroModes[k].join(', ')}.\n\nSupported controls (only model-relevant controls are exposed):\n',
    );
    for (final p in l.controls) {
      out.writeln(
        '- ${p.label} (`${p.key}`): ${p.min}…${p.max} ${p.unit}; default ${p.initial}.',
      );
    }
    out.writeln('\n');
  }
  File('docs/PHASE8_LAB_SPECIFICATIONS.md')
      .writeAsStringSync('${out.toString().trimRight()}\n');
}
