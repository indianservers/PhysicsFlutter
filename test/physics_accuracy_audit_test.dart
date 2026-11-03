import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/core/physics/advanced.dart';
import 'package:physics_atelier/core/physics/astronomy_run.dart';
import 'package:physics_atelier/core/physics/dynamics.dart';
import 'package:physics_atelier/core/physics/electromagnetism.dart';
import 'package:physics_atelier/core/physics/electronics_thermal.dart';
import 'package:physics_atelier/core/physics/fluid_modern_run.dart';
import 'package:physics_atelier/core/physics/live_optics.dart';
import 'package:physics_atelier/core/physics/measurement.dart';
import 'package:physics_atelier/core/physics/optical_library.dart';
import 'package:physics_atelier/core/physics/supplemental_labs.dart';
import 'package:physics_atelier/core/physics/waves_optics.dart';
import 'package:physics_atelier/features/advanced/curriculum.dart';
import 'package:physics_atelier/features/astronomy/curriculum.dart';
import 'package:physics_atelier/features/dynamics/curriculum.dart';
import 'package:physics_atelier/features/electromagnetism/curriculum.dart';
import 'package:physics_atelier/features/electronics_thermal/curriculum.dart';
import 'package:physics_atelier/features/fluid_modern/curriculum.dart';
import 'package:physics_atelier/features/measurement/experiment.dart';
import 'package:physics_atelier/features/optics_live/scene.dart';
import 'package:physics_atelier/features/waves/curriculum.dart';

void finite(Map<String, double> values, String reason) {
  expect(values, isNotEmpty, reason: reason);
  for (final e in values.entries) {
    expect(e.value.isFinite, true, reason: '$reason ${e.key}=${e.value}');
  }
}

void main() {
  test(
    'Every catalog lab resolves to a finite physical model and observation',
    () {
      final covered = <String>{};
      for (final entry in allEntries.where((e) => e.interactive)) {
        final id = entry.id;
        if (entry.studioIndex == 9) {
          final model = LiveOpticsModel(opticsById(id));
          finite(model.state, id);
          expect(model.observation, isNotNull, reason: id);
        } else if (entry.supplemental) {
          final lab = supplementalById(id);
          finite(
            lab.evaluate(
              lab.defaults,
              lab.dynamicModel ? lab.duration(lab.defaults) / 3 : 0,
            ),
            id,
          );
        } else if (entry.dynamics) {
          final k = (entry.studioIndex - 2) * 6 + entry.index;
          final run = DynamicsRun(k, lessons[k].defaults)..seek(.25);
          finite(run.state, id);
        } else if (entry.advanced) {
          final k = (entry.studioIndex - 5) * 6 + entry.index;
          final run = AdvancedRun(k, advancedLessons[k].defaults)..seek(.25);
          finite(run.state, id);
        } else if (entry.wavesOptics) {
          final k = (entry.studioIndex - 8) * 6 + entry.index;
          final run = WaveOpticsRun(k, waveLessons[k].defaults)..seek(.025);
          finite(run.state, id);
        } else if (entry.electromagnetism) {
          final k = (entry.studioIndex - 10) * 6 + entry.index;
          final run = EMRun(k, emLessons[k].defaults);
          expect(run.invalid, isEmpty, reason: id);
          finite(run.state, id);
        } else if (entry.electronicsThermal) {
          final k = (entry.studioIndex - 12) * 6 + entry.index;
          final run = ETRun(k, etLessons[k].defaults);
          expect(run.invalid, isEmpty, reason: id);
          finite(run.state, id);
        } else if (entry.fluidModern) {
          final k = (entry.studioIndex - 14) * 6 + entry.index;
          final run = FMRun(k, fmLessons[k].defaults);
          expect(run.invalid, isEmpty, reason: id);
          finite(run.state, id);
        } else if (entry.astronomy) {
          final run = AstronomyRun(
            entry.index,
            astroLessons[entry.index].defaults,
          );
          expect(run.invalid, isEmpty, reason: id);
          finite(run.state, id);
        } else {
          expect(entry.studioIndex, 1);
          final e = Experiment(entry.index);
          finite({'duration': e.duration, 'leastCount': e.leastCount}, id);
          e.dispose();
        }
        covered.add(id);
      }
      expect(covered.length, 119);
    },
  );

  test(
    'Arrival roots remain stable at tiny acceleration and unreachable targets',
    () {
      expect(finishTime(.5, .2, 1e-20), closeTo(2.5, 1e-12));
      expect(finishTime(0, 0, 0), 0);
      expect(finishTime(1, 0, 0), double.infinity);
      expect(finishTime(1, -1, 0), double.infinity);
      expect(finishTime(1, 1, -1), double.infinity);
      expect(finishTime(.5, 1, -1), 1);
      expect(finishTime(1, -1, 1), closeTo(1 + math.sqrt(3), 1e-12));
    },
  );

  test('Timing resolution affects measured readings; zero launch restores', () {
    final e = Experiment(4)..v0 = 0;
    final config = e.toJson()..['elapsed'] = .1234;
    expect(e.restore(config), true);
    e.resolution = .01;
    expect(e.timerReading, closeTo(.12, 1e-12));
    expect(e.result, closeTo(trackPosition(.1234, 0, .3) / .12, 1e-12));
    final restored = Experiment(4);
    expect(restored.restore(e.toJson()), true);
    expect(restored.v0, 0);
    expect(restored.timerReading, e.timerReading);
    e.dispose();
    restored.dispose();
  });

  test(
    'Damped period follows zero crossings and disappears without oscillation',
    () {
      final p = {
        ...advancedLessons[15].defaults,
        'm': 1.0,
        'k': 4.0,
        'b': 2.0,
        'x0': 1.0,
        'v0': 0.0,
      };
      final s = AdvancedRun(15, p).state;
      final period = 2 * math.pi / math.sqrt(3);
      expect(s['period'], closeTo(period, 1e-12));
      expect(s['naturalPeriod'], closeTo(math.pi, 1e-12));
      final a = freeOscillator(1, 4, 2, 1, 0, .4);
      final b = freeOscillator(1, 4, 2, 1, 0, .4 + period);
      expect(b.x / a.x, closeTo(math.exp(-period), 1e-12));
      for (final damping in [4.0, 7.0]) {
        final state = AdvancedRun(15, {...p, 'b': damping}).state;
        expect(state.containsKey('period'), false);
        expect(state.containsKey('frequency'), false);
        finite(state, 'damping $damping');
      }
    },
  );

  test(
    'Telescope defocus is a finite image, not afocal angular magnification',
    () {
      final m = LiveOpticsModel(opticsById('s09-e09'));
      expect(m.observation!.quantity, 'magnification');
      expect(m.observation!.value, -4);
      m.set('separation', .32);
      expect(m.state.containsKey('Angular magnification'), false);
      expect(m.observation, isNull);
      expect(m.state['Final image distance (m)'], closeTo(3 / 35, 1e-12));
      m.set('separation', .2);
      expect(m.state.containsKey('Output vergence (1/m)'), false);
      m.mode = 1;
      expect(m.state['Valid microscope'], 0);
      expect(m.state.containsKey('Magnification'), false);
      expect(m.observation, isNull);
    },
  );

  test(
    'All optics records use the measured response and physical dimension',
    () {
      final refract = LiveOpticsModel(opticsById('s09-e01'));
      expect(refract.observation!.value, closeTo(35.26438968, 1e-7));
      refract.set('n1', 1.5);
      refract.set('n2', 1);
      expect(refract.observation, isNull);
      final film = LiveOpticsModel(opticsById('s09-e08'))..mode = 1;
      expect(film.observation!.value, film.state['Transmittance']);
      final prism = LiveOpticsModel(opticsById('s09-e07'));
      expect(prism.observation!.value, prism.state['Deviation (°)']);
      expect(prism.observation!.value, isNot(prism.v('angle')));
      final legacy = prism.toJson()..['model'] = legacyLiveOpticsVersion;
      expect(prism.restore(legacy), true);
      expect(prism.toJson()['model'], liveOpticsVersion);
    },
  );

  test('Far-field model refuses unsupported near-field configurations', () {
    final m = LiveOpticsModel(opticsById('s09-e04'));
    m.set('wavelength', 400e-9);
    m.set('aperture', .25e-3);
    expect(m.invalid, isNotEmpty);
    expect(m.curve(), isEmpty);
    expect(m.observation, isNull);
    expect(OpticalGeometry(m, 520).rays.length, 1);
    m.set('screen', 3);
    expect(m.invalid, isEmpty);
    expect(m.observation, isNotNull);
  });

  test(
    'Finite glass block uses actual exit face, Snell law and energy balance',
    () {
      final path = traceRectangularSlab(
        width: 2,
        height: 1,
        entry: const OVec(.4, 0),
        direction: const OVec(.98, .2),
        insideIndex: 1.5,
        outsideIndex: 1,
      );
      final inside = path.segments.first;
      expect(inside.end.x, closeTo(2, 1e-12));
      expect(inside.end.y, lessThan(1));
      final exit = path.segments.firstWhere((r) => !r.inside);
      final out = (exit.end - exit.start).unit;
      expect(out.y, closeTo(1.5 * const OVec(.98, .2).unit.y, 1e-12));
      expect(path.escaped + path.remaining, closeTo(1, 1e-12));
      final tir = traceRectangularSlab(
        width: .1,
        height: 1,
        entry: const OVec(.05, 0),
        direction: const OVec(.5, .866025403784),
        insideIndex: 1.5,
        outsideIndex: 1,
      );
      expect(
        tir.segments[1].inside,
        true,
        reason: 'side-wall TIR retains the ray in glass',
      );
      expect(tir.escaped + tir.remaining, closeTo(1, 1e-12));
      expect(fresnelPower(1, 1, math.pi / 2, math.pi / 2), 0);
    },
  );

  test('Polarizer brightness obeys one common incident intensity scale', () {
    final m = LiveOpticsModel(opticsById('s09-e06'));
    for (final intensity in [0.0, 20.0, 100.0]) {
      m.set('intensity', intensity);
      m.set('angle', 0);
      final rays = OpticalGeometry(m, 520).rays;
      expect(rays[0].power, closeTo(intensity / 60, 1e-12));
      expect(rays[1].power, closeTo(rays[0].power / 2, 1e-12));
      expect(rays[2].power, closeTo(rays[1].power, 1e-12));
    }
  });

  test(
    'Prism rendered directions agree with the independent analytic deviation',
    () {
      final m = LiveOpticsModel(opticsById('s09-e07'));
      for (int mode = 0; mode < 3; mode++) {
        m.mode = mode;
        for (final angle in [45.0, 55.0, 65.0]) {
          m.set('angle', angle);
          if (m.state['Exit TIR'] == 1) continue;
          final trace = m.prismTraces(spectrum: false).single;
          final outgoing = trace.segments
              .where((s) => s.event == 'exit')
              .reduce((a, b) => a.power > b.power ? a : b);
          final deviation =
              math.atan2(outgoing.direction.y, outgoing.direction.x).abs() *
              180 /
              math.pi;
          expect(
            deviation,
            closeTo(m.state['Deviation (°)']!, 1e-7),
            reason: 'material $mode incidence $angle',
          );
          expect(trace.accounted, closeTo(1, 1e-10));
        }
      }
    },
  );
}
