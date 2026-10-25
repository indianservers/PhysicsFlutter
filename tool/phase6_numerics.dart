import 'dart:convert';
import 'dart:io';

import 'package:physics_atelier/core/physics/electronics_thermal.dart';
import 'package:physics_atelier/features/electronics_thermal/curriculum.dart';

void main() {
  final out = <String, dynamic>{
    'model': etVersion,
    'qualification': 'Host pure-Dart elapsed cost including allocation; 10 warmups then 100 iterations. Not Android frame measurements.',
  };
  void measure(String name, void Function() f) {
    for (int i = 0; i < 10; i++) {
      f();
    }
    final values = <double>[];
    for (int i = 0; i < 100; i++) {
      final w = Stopwatch()..start();
      f();
      w.stop();
      values.add(w.elapsedMicroseconds / 1000);
    }
    values.sort();
    out[name] = {
      'medianMs': values[50],
      'p95Ms': values[94],
      'iterations': 100,
    };
  }

  measure(
    'Semiconductor full 161-point profile',
    () => ETRun(0, etLessons[0].defaults, mode: 1),
  );
  measure(
    'Diode 161 operating points and junction curve',
    () => ETRun(1, etLessons[1].defaults),
  );
  measure(
    'Light sensor 161 shared-MNA divider solutions',
    () => ETRun(5, etLessons[5].defaults, mode: 1),
  );
  measure('Radiation full deterministic replay', () {
    final r = ETRun(7, etLessons[7].defaults, mode: 2);
    r.seek(r.maxTime);
  });
  measure(
    'Carnot complete 161-point cycle',
    () => ETRun(11, etLessons[11].defaults),
  );
  final states = <String, dynamic>{};
  for (int k = 0; k < 12; k++) {
    for (int m = 0; m < etModes[k].length; m++) {
      final r = ETRun(k, etLessons[k].defaults, mode: m);
      if (r.invalid.isNotEmpty) throw StateError(r.invalid);
      if (r.dynamicLab) r.seek(r.maxTime);
      states['$k:$m'] = {
        'initial': r.initial,
        'finalState': r.state,
        'ticks': r.ticks,
        'samples': r.samples.length,
        'profilePoints': r.profile.length,
      };
    }
  }
  out['allModelEndpoints'] = states;
  File('screenshots/phase6-numerics.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(out));
}
