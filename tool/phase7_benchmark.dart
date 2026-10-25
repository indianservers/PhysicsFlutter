import 'dart:convert';
import 'dart:io';

import 'package:physics_atelier/core/physics/fluid_modern_run.dart';
import 'package:physics_atelier/features/fluid_modern/curriculum.dart';

void main() {
  final result = <String, dynamic>{
    'qualification': 'Host Dart JIT microbenchmarks, warmed once; not frame timings or physical-device performance.',
    'model': fmVersion,
    'dataset': datasetVersion,
    'sampler': stochasticVersion,
  };
  Map<String, double> inputs(int k) => {
    for (final p in fmLessons[k].controls) p.key: p.initial,
  };
  void measure(String name, void Function() work) {
    work();
    final values = <double>[];
    for (int i = 0; i < 7; i++) {
      final watch = Stopwatch()..start();
      work();
      watch.stop();
      values.add(watch.elapsedMicroseconds / 1000);
    }
    values.sort();
    result[name] = {'medianMs': values[3], 'maxMs': values.last, 'runs': 7};
  }

  measure('matter4096CdfBuild', () {
    final r = FMRun(8, inputs(8));
    if (r.invalid.isNotEmpty) throw StateError(r.invalid);
  });
  final pipe = FMRun(4, inputs(4));
  measure('100CachedPipeProbeChanges', () {
    for (int i = 0; i < 100; i++) {
      final r = FMRun(4, {
        ...pipe.p,
        'probeX': -.12 + .24 * i / 99,
      }, geometryFrom: pipe);
      if (!identical(r.pipe, pipe.pipe)) throw StateError('cache');
    }
  });
  measure('billionAtomsFull2400TickReplay', () {
    final r = FMRun(11, {...inputs(11), 'initialN': 1e9, 'background': 1});
    r.seek(r.maxTime);
    if (r.remaining + r.decays != 1000000000 || r.invalid.isNotEmpty) {
      throw StateError('conservation');
    }
  });
  final endpoints = <String, dynamic>{};
  for (int k = 0; k < 12; k++) {
    final r = FMRun(k, inputs(k));
    if (r.dynamicLab) r.seek(r.maxTime);
    endpoints['$k'] = {
      'invalid': r.invalid,
      'ticks': r.ticks,
      'state': r.state,
      'detections': r.measurementCount,
    };
    if (r.invalid.isNotEmpty) throw StateError(r.invalid);
  }
  result['defaultEndpoints'] = endpoints;
  File('screenshots/phase7-model-benchmark.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(result));
  stdout.writeln(
    const JsonEncoder.withIndent('  ')
        .convert(Map.of(result)..remove('defaultEndpoints')),
  );
}
