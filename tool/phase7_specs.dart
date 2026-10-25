import 'dart:io';

import 'package:physics_atelier/features/fluid_modern/curriculum.dart';
import 'package:physics_atelier/content/catalog.dart';

void main() {
  final out = StringBuffer(
    '# Phase 7 lab specifications\n\nGenerated from the same curriculum and control definitions used by the app. SI units internally. All plots use calculated data. Model fluid-modern-7.0.\n\n',
  );
  for (int k = 0; k < 12; k++) {
    final e = studios[14 + k ~/ 6].entries[k % 6], l = fmLessons[k];
    out.writeln(
      '## ${e.id} — ${e.title}\n\n${l.apparatus}\n\n${l.principle}\n\nEquation: `${l.formula}`\n\n${l.symbols}\n\n${l.limits}\n\nReference example: ${l.example}\n\nPrimary observation: ${l.metric} (${l.unit}).\n\nModes: ${fmModes[k].join(', ')}.\n\nSupported controls (only model-relevant controls are exposed):\n',
    );
    for (final p in l.controls) {
      out.writeln(
        '- ${p.label} (`${p.key}`): ${p.min}…${p.max} ${p.unit}; default ${p.initial}.',
      );
    }
    out.writeln('\n');
  }
  File('docs/PHASE7_LAB_SPECIFICATIONS.md')
      .writeAsStringSync(out.toString().trimRight() + '\n');
}
