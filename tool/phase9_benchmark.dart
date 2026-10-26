import 'dart:io';
import 'dart:convert';

import 'package:physics_atelier/core/physics/advanced.dart';
import 'package:physics_atelier/core/physics/waves_optics.dart';
import 'package:physics_atelier/core/physics/electromagnetism.dart';
import 'package:physics_atelier/core/physics/electronics_thermal.dart';
import 'package:physics_atelier/core/physics/fluid_modern_run.dart';
import 'package:physics_atelier/core/physics/astronomy_run.dart';
import 'package:physics_atelier/features/advanced/curriculum.dart';
import 'package:physics_atelier/features/waves/curriculum.dart';
import 'package:physics_atelier/features/electromagnetism/curriculum.dart';
import 'package:physics_atelier/features/electronics_thermal/curriculum.dart';
import 'package:physics_atelier/features/fluid_modern/curriculum.dart';
import 'package:physics_atelier/features/astronomy/curriculum.dart';

void main() {
  final cases = <String, dynamic Function()>{
    'electricFieldPreparation': () => EMRun(1, emLessons[1].defaults),
    'circuitMNAPreparation': () => EMRun(4, emLessons[4].defaults),
    'coupledOscillator': () => AdvancedRun(17, advancedLessons[17].defaults),
    'waveInterferenceGrid': () => WaveOpticsRun(2, waveLessons[2].defaults),
    'generatedFFT': () => WaveOpticsRun(4, waveLessons[4].defaults),
    'diffractionProfile': () => WaveOpticsRun(11, waveLessons[11].defaults),
    'thermalConductionProfile': () => ETRun(7, etLessons[7].defaults),
    'liquidBernoulli': () => FMRun(4, fmLessons[4].defaults),
    'matterWaveDistribution': () => FMRun(8, fmLessons[8].defaults),
    'radioactiveDecay': () => FMRun(11, fmLessons[11].defaults),
    'orbitPropagation': () => AstronomyRun(0, astroLessons[0].defaults),
  };
  final results = <String, dynamic>{
    'qualification': 'Windows host warmed Dart JIT,7 repetitions, model construction plus120 fixed steps. Not mobile frame or solver-only timings; static models may do preparation only.',
  };
  for (final e in cases.entries) {
    void work() {
      final dynamic run = e.value();
      for (int i = 0; i < 120; i++) {
        run.step();
      }
    }

    work();
    final times = <double>[];
    for (int i = 0; i < 7; i++) {
      final watch = Stopwatch()..start();
      work();
      watch.stop();
      times.add(watch.elapsedMicroseconds / 1000);
    }
    times.sort();
    results[e.key] = {
      'medianMs': times[3],
      'maxMs': times.last,
      'repetitions': 7,
    };
  }
  File('screenshots/phase9-model-benchmarks.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(results));
  stdout.writeln('Eleven model scenarios measured.');
}
