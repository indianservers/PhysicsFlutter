import 'dart:convert';
import 'dart:io';

import 'package:physics_atelier/core/physics/astronomy_run.dart';
import 'package:physics_atelier/core/physics/comparisons.dart';
import 'package:physics_atelier/features/astronomy/curriculum.dart';
import 'package:physics_atelier/features/overview/comparison_curriculum.dart';

void main() {
  final result = <String, dynamic>{
    'qualification': 'Warmed host Dart JIT,7 repeats; not mobile frame timing',
    'model': astroVersion,
    'dataset': astroDataset,
  };
  void measure(String key, void Function() work) {
    work();
    final times = <double>[];
    for (int i = 0; i < 7; i++) {
      final timer = Stopwatch()..start();
      work();
      timer.stop();
      times.add(timer.elapsedMicroseconds / 1000);
    }
    times.sort();
    result[key] = {'medianMs': times[3], 'maxMs': times.last, 'repeats': 7};
  }

  measure('cosmologyFull121PointProfile1024Simpson', () {
    final r = AstronomyRun(4, astroLessons[4].defaults);
    if (r.invalid.isNotEmpty) throw StateError(r.invalid);
  });
  measure('adaptiveSyntheticSpectrumProfile', () {
    AstronomyRun(2, {
      ...astroLessons[2].defaults,
      'velocity': 600000,
      'resolution': 10000,
    });
  });
  final orbit = AstronomyRun(0, astroLessons[0].defaults);
  measure('100CachedOrbitTimeChanges', () {
    for (int i = 0; i < 100; i++) {
      final r = AstronomyRun(0, {
        ...astroLessons[0].defaults,
        'elapsedDays': i.toDouble(),
      }, cached: orbit);
      if (!identical(r.profile, orbit.profile)) throw StateError('cache');
    }
  });
  final inputs = <String, double>{
    for (final list in comparisonControls)
      for (final p in list) p.key: p.initial,
  };
  final comparison = ComparisonModel(4, inputs);
  measure('1000MatterDetectionsAt20s', () {
    comparison.at(20);
  });
  final endpoints = <String, dynamic>{};
  for (int kind = 0; kind < 6; kind++) {
    final run = AstronomyRun(kind, astroLessons[kind].defaults);
    if (run.dynamicLab) run.seek(20);
    endpoints['$kind'] = {
      'ticks': run.ticks,
      'state': run.state,
      'profilePoints': run.profile.length,
      'invalid': run.invalid,
    };
  }
  result['defaultEndpoints'] = endpoints;
  File('screenshots/phase8-model-benchmark.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(result));
  stdout.writeln(
    const JsonEncoder.withIndent('  ')
        .convert(Map.of(result)..remove('defaultEndpoints')),
  );
}
