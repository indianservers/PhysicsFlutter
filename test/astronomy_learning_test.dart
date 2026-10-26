import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/core/physics/astronomy_run.dart';
import 'package:physics_atelier/core/physics/advanced.dart';
import 'package:physics_atelier/core/physics/waves_optics.dart';
import 'package:physics_atelier/core/physics/electromagnetism.dart';
import 'package:physics_atelier/core/physics/electronics_thermal.dart';
import 'package:physics_atelier/core/physics/comparisons.dart';
import 'package:physics_atelier/core/physics/galaxy_observations.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/content/learning.dart';
import 'package:physics_atelier/features/astronomy/curriculum.dart';
import 'package:physics_atelier/features/overview/compare_workspace.dart'
    show comparisonControls;
import 'package:physics_atelier/core/persistence/notebook.dart';

Map<String, double> defaults(int kind) => astroLessons[kind].defaults;
Map<String, double> comparisonDefaults() => {
  for (final list in comparisonControls)
    for (final p in list) p.key: p.initial,
};
void main() {
  test(
    'Curated challenge configurations agree with independent reference answers',
    () {
      final references = [
        .0236,
        1.0,
        40.7886485,
        2.0,
        9.0,
        11186.14,
        -.1,
        3.0,
        2.0,
        2500.0,
        .000002,
        1.0,
        331.60602794,
        2941.995,
        656.47,
        .01,
      ];
      for (int i = 0; i < masteryQuestions.length; i++) {
        final q = masteryQuestions[i];
        expect(q.configuration, isNotEmpty);
        expect(q.sourceModel, isNotEmpty);
        expect(
          q.answer(),
          closeTo(
            references[i],
            i == 5
                ? .02
                : i == 14
                ? .02
                : 1e-6,
          ),
        );
      }
      final source = CircuitPart('V', 'source', value: 5, x: 0, y: 0),
          r = CircuitPart(
            'R',
            'resistor',
            value: masteryQuestions[9].answer(),
            x: 1,
            y: 0,
          );
      expect(
        solveCircuit(
          CircuitGraph(
            [source, r],
            [
              [source.a, r.a],
              [source.b, r.b],
            ],
          ),
        ).currents['R'],
        closeTo(.002, 1e-15),
      );
    },
  );

  test('Central astronomical conversions and nominal mass parameter', () {
    expect(au, 149597870700);
    expect(parsec / au, closeTo(206264.80624709636, 1e-9));
    expect(lightYear, lightSpeed * julianYear);
    expect(solarMass * gravitationalConstant, closeTo(solarMu, 1e5));
    expect(solarRadius, 6.957e8);
  });
  test('JPL J2000 Earth–Moon barycentre reference position', () {
    final e = planets[2].at(0);
    expect(e['x']! / au, closeTo(-.17717125, 2e-7));
    expect(e['y']! / au, closeTo(.96721448, 2e-7));
    expect(e['z']!.abs() / au, lessThan(1e-6));
    expect(e['daysFromJ2000'], 0);
  });
  test(
    'All eight frozen ellipses conserve two-body energy and repeat at period',
    () {
      for (final p in planets) {
        final first = p.at(0), last = p.at(p.period);
        for (final axis in ['x', 'y', 'z']) {
          expect(last[axis], closeTo(first[axis]!, p.a * au * 2e-12));
        }
        for (final t in [-p.period * .1, p.period * .25, p.period * .9]) {
          final s = p.at(t);
          expect(
            s['speed']! * s['speed']!,
            closeTo(solarMu * (2 / s['distance']! - 1 / (p.a * au)), 1e-5),
          );
          expect(
            s['distance'],
            inInclusiveRange(
              p.a * au * (1 - p.e) - 1,
              p.a * au * (1 + p.e) + 1,
            ),
          );
        }
        expect(
          p.period * p.period / (math.pow(p.a * au, 3)),
          closeTo(4 * math.pi * math.pi / solarMu, 1e-32),
        );
      }
    },
  );
  test('Circular shared Kepler solution and bounded epoch', () {
    const p = Planet('Test', 1, 0, 0, 0, 0, 0);
    final s = p.at(p.period / 4);
    expect(s['x']!.abs(), lessThan(.001));
    expect(s['y'], closeTo(au, .001));
    expect(s['speed'], closeTo(s['meanSpeed']!, 1e-8));
    expect(() => p.at(201 * julianYear), throwsArgumentError);
  });
  test('MIST tracks retain ordered physical ages and supported phases', () {
    expect(stellarMasses, [1, 3, 15]);
    expect(stellarTracks.map((t) => t.length), [1710, 1710, 808]);
    for (final track in stellarTracks) {
      for (int i = 1; i < track.length; i++) {
        expect(track[i][0], greaterThan(track[i - 1][0]));
        expect(track[i].length, 4);
        expect(track[i].every((x) => x.isFinite), true);
      }
    }
    expect(() => stellar(3, .5), throwsArgumentError);
    expect(() => stellar(0, 1.01), throwsArgumentError);
  });
  test('Within-phase interpolation matches reference logarithms', () {
    final rows = stellarTracks[0],
        i = 300,
        a = rows[i],
        b = rows[i + 1],
        age = (a[0] + b[0]) / 2,
        f = (age - rows.first[0]) / (rows.last[0] - rows.first[0]),
        s = stellar(0, f);
    expect(a[3], b[3]);
    expect(s['logL'], closeTo((a[1] + b[1]) / 2, 1e-12));
    expect(s['logT'], closeTo((a[2] + b[2]) / 2, 1e-12));
  });
  test('No interpolation crosses a stellar phase boundary', () {
    final rows = stellarTracks[0],
        index = List.generate(
          rows.length - 1,
          (i) => i,
        ).firstWhere((i) => rows[i][3] != rows[i + 1][3]),
        a = rows[index],
        b = rows[index + 1],
        age = (a[0] + b[0]) / 2,
        s = stellar(0, (age - rows.first[0]) / (rows.last[0] - rows.first[0]));
    expect(s['phase'], a[3]);
    expect(s['logL'], a[1]);
  });
  test(
    'Stellar radius is Stefan–Boltzmann consistent and mass lifetimes ordered',
    () {
      final lifetimes = <double>[];
      for (int m = 0; m < 3; m++) {
        final rows = stellarTracks[m].where((r) => r[3] == 0).toList();
        lifetimes.add(rows.last[0] - rows.first[0]);
        for (final f in [0.0, .4, 1.0]) {
          final s = stellar(m, f);
          expect(
            4 *
                math.pi *
                s['radius']! *
                s['radius']! *
                stefanBoltzmann *
                math.pow(s['temperature']!, 4) /
                s['luminosity']!,
            closeTo(1, 1e-12),
          );
        }
      }
      expect(lifetimes[0], greaterThan(lifetimes[1]));
      expect(lifetimes[1], greaterThan(lifetimes[2]));
    },
  );
  test('B-lambda Wien peak and Rayleigh–Jeans limiting convention', () {
    const t = 5800.0;
    final peak = 2.897771955e-3 / t, b = blackbodyLambda(peak, t);
    expect(b, greaterThan(blackbodyLambda(peak * .99, t)));
    expect(b, greaterThan(blackbodyLambda(peak * 1.01, t)));
    expect(
      blackbodyLambda(1, t) / (2 * lightSpeed * boltzmann * t),
      closeTo(1, 2e-6),
    );
  });
  test('Relativistic spectral shifts are signed and invertible', () {
    expect(dopplerFactor(0), 1);
    expect(dopplerFactor(300000), greaterThan(1));
    expect(dopplerFactor(-300000) * dopplerFactor(300000), closeTo(1, 1e-14));
    expect(() => dopplerFactor(.03 * lightSpeed), throwsArgumentError);
  });
  test('Resolving power changes actual line width and depth', () {
    final w = balmerVacuum.first,
        low = spectrumAt(w, 5800, 0, 500),
        high = spectrumAt(w, 5800, 0, 10000);
    expect(high['syntheticFlux']!, lessThan(low['syntheticFlux']!));
    expect(
      spectrumAt(w + 1e-9, 5800, 0, 500)['syntheticFlux']! /
          spectrumAt(w + 1e-9, 5800, 0, 500)['continuum']!,
      lessThan(
        spectrumAt(w + 1e-9, 5800, 0, 10000)['syntheticFlux']! /
            spectrumAt(w + 1e-9, 5800, 0, 10000)['continuum']!,
      ),
    );
    expect(
      spectrumAt(w, 5800, 300000, 2000)['restReference'],
      spectrumAt(w, 5800, 0, 2000)['syntheticFlux'],
    );
  });
  test(
    'Gaussian instrumental convolution preserves local line deficit area',
    () {
      final w = balmerVacuum.first;
      double area(double r) => integrate(
        (x) {
          final s = spectrumAt(x, 5800, 0, r);
          return 1 - s['syntheticFlux']! / s['continuum']!;
        },
        w - 5e-9,
        w + 5e-9,
        4096,
      );
      expect(area(500) / area(10000), closeTo(1, 1e-5));
    },
  );
  test('Galaxy v² equals R dPhi/dR for the axisymmetric potential', () {
    const r = 8 * kpc, h = .00001 * kpc;
    AstroState f(double x) =>
        galaxy(x, 1e9 * solarMass, 4e10 * solarMass, 3 * kpc, 130000);
    final s = f(r),
        derivative =
            (f(r + h)['potential']! - f(r - h)['potential']!) / (2 * h);
    expect(r * derivative / (s['speed']! * s['speed']!), closeTo(1, 1e-9));
  });
  test('Disk contribution uses exact equatorial Miyamoto–Nagai geometry', () {
    final r = 3 * kpc,
        s = galaxy(r, 0, 4e10 * solarMass, 3 * kpc, 0, halo: false),
        expected =
            gravitationalConstant *
            4e10 *
            solarMass *
            r *
            r /
            math.pow(r * r + math.pow(3.3 * kpc, 2), 1.5);
    expect(s['speed']! * s['speed']!, closeTo(expected, 1e-5));
    expect(s['haloSpeed'], 0);
    expect(s['bulgeSpeed'], 0);
  });
  test('Observed SPARC data retain source velocities and uncertainties', () {
    expect(ngc2403.length, 73);
    expect(ngc2403.first, [.16, 24.5, 2.83]);
    expect(ngc2403.every((r) => r[0] > 0 && r[1] > 0 && r[2] > 0), true);
  });
  test('Flat cosmology matches independent Gauss–Legendre reference', () {
    final data =
        jsonDecode(
              File('screenshots/phase8-independent-cosmology.json')
                  .readAsStringSync(),
            )['references']
            as Map;
    for (final e in data.entries) {
      final z = double.parse(e.key), s = cosmology(z, 70, .3);
      expect(s['comovingDistance']! / e.value['DC'], closeTo(1, 3e-10));
      expect(s['lookback']! / e.value['lookback'], closeTo(1, 3e-10));
    }
  });
  test('Cosmological distance duality and explicit radiation closure', () {
    for (final z in [0.0, .1, 1.0, 5.0]) {
      final s = cosmology(z, 70, .3);
      expect(
        z == 0
            ? 0
            : s['luminosityDistance']! /
                  (s['angularDistance']! * (1 + z) * (1 + z)),
        closeTo(z == 0 ? 0 : 1, 2e-15),
      );
      expect(s['scaleFactor'], 1 / (1 + z));
      expect(s['omegaLambda']! + s['omegaRadiation']! + .3, closeTo(1, 1e-14));
      expect(s['lightTravelDistance'], lightSpeed * s['lookback']!);
    }
    expect(cosmology(0, 70, .3)['lookback'], 0);
  });
  test('Low-redshift limit and cosmological numerical convergence', () {
    final s = cosmology(1e-7, 70, .3);
    expect(
      s['comovingDistance']! / (lightSpeed * 1e-7 / s['hubbleSI']!),
      closeTo(1, 1e-7),
    );
    final a = cosmology(5, 50, .1, intervals: 64),
        b = cosmology(5, 50, .1, intervals: 128),
        c = cosmology(5, 50, .1, intervals: 2048);
    expect(
      (b['lookback']! - c['lookback']!).abs(),
      lessThan((a['lookback']! - c['lookback']!).abs() / 10),
    );
    expect(() => cosmology(6, 70, .3), throwsArgumentError);
    expect(() => cosmology(1, 70, .9), throwsArgumentError);
  });
  test('Exact overlap geometry at tangency containment and partial lens', () {
    expect(overlapArea(1, .1, 1.1), 0);
    expect(overlapArea(1, .1, 0), closeTo(math.pi * .01, 1e-15));
    expect(
      overlapArea(1, 1, 1),
      closeTo(2 * math.pi / 3 - math.sqrt(3) / 2, 1e-14),
    );
    expect(
      overlapArea(1e9, 1e8, 1e9) / 1e18,
      closeTo(overlapArea(1, .1, 1), 1e-13),
    );
  });
  test(
    'Transit Kepler consistency symmetry and superior-conjunction visibility',
    () {
      final s = transit(1, 1, .1, 5, 90, 0);
      expect(s['midDepth'], closeTo(.01, 1e-14));
      expect(
        math.pow(s['semiMajorAxis']!, 3) /
            (solarMu * math.pow(5 * day / (2 * math.pi), 2)),
        closeTo(1, 1e-14),
      );
      for (final time in [.0, 500.0, 3000.0, 10000.0]) {
        expect(
          transit(1, 1, .1, 5, 89, time)['flux'],
          closeTo(transit(1, 1, .1, 5, 89, -time)['flux']!, 1e-14),
        );
      }
      expect(transit(1, 1, .1, 5, 90, 2.5 * day)['flux'], 1);
    },
  );
  test('Transit grazing no-transit and contact duration', () {
    final base = transit(1, 1, .1, 5, 90, 0),
        a = base['semiMajorAxis']! / solarRadius;
    double inc(double b) => math.acos(b / a) * 180 / math.pi;
    final grazing = transit(1, 1, .1, 5, inc(1.05), 0),
        none = transit(1, 1, .1, 5, inc(1.2), 0);
    expect(grazing['midDepth'], inExclusiveRange(0, .01));
    expect(none['duration'], 0);
    expect(none['midDepth'], 0);
    expect(
      transit(1, 1, .1, 5, 90, base['duration']! / 2)['flux'],
      closeTo(1, 1e-12),
    );
  });
  test('Seeded synthetic transit noise reproduces and has honest statistical scale', () {
    final p = defaults(5),
        a = noisyTransit(p, 42, .001),
        b = noisyTransit(p, 42, .001),
        other = noisyTransit(p, 43, .001);
    expect(a, b);
    expect(a, isNot(other));
    final residuals = a.map((r) => r['syntheticFlux']! - r['flux']!).toList(),
        mean = residuals.reduce((a, b) => a + b) / residuals.length;
    expect(mean.abs(), lessThan(5 * .001 / math.sqrt(residuals.length)));
    expect(
      noisyTransit(p, 42, 0).every((r) => r['flux'] == r['syntheticFlux']),
      true,
    );
  });
  test(
    'All seventeen astronomy selections support complete calculated states',
    () {
      int count = 0;
      for (int k = 0; k < 6; k++) {
        for (int m = 0; m < astroModes[k].length; m++) {
          final r = AstronomyRun(k, defaults(k), mode: m);
          expect(r.invalid, isEmpty, reason: '$k:$m');
          expect(r.state.values.every((x) => x.isFinite), true);
          expect(r.profile, isNotEmpty);
          count++;
        }
      }
      expect(count, 17);
    },
  );
  test(
    'Replay finite endpoints and bounded histories are independent of frames',
    () {
      for (final k in [0, 1, 5]) {
        final a = AstronomyRun(k, defaults(k)),
            b = AstronomyRun(k, defaults(k));
        a.seek(20);
        b.seek(a.ticks / 120);
        expect(a.state, b.state);
        expect(a.ticks, b.ticks);
        expect(a.finished, true);
        expect(a.samples.length, lessThanOrEqualTo(301));
        final ticks = a.ticks;
        a.step();
        expect(a.ticks, ticks);
      }
    },
  );
  test('Reference profiles cache for probe edits but not scientific geometry edits', () {
    final a = AstronomyRun(4, defaults(4)),
        b = AstronomyRun(4, {...defaults(4), 'redshift': 2}, cached: a),
        c = AstronomyRun(4, {...defaults(4), 'h0': 80}, cached: a);
    expect(identical(a.profile, b.profile), true);
    expect(identical(a.profile, c.profile), false);
    final s = AstronomyRun(2, defaults(2));
    expect(s.profile.length, greaterThan(900));
  });
  test('Stable inventory includes exactly96 labs and six tools with all links valid', () {
    expect(studios.length, 17);
    expect(allEntries.length, 102);
    expect(allEntries.map((e) => e.id).toSet().length, 102);
    expect(labInventory.length, 96);
    expect(allEntries.where((e) => e.tool).length, 6);
    for (final edge in conceptEdges) {
      expect(edge.explanation, isNotEmpty);
      expect(edge.assumptions, isNotEmpty);
      for (final id in edge.labs) {
        expect(entryById(id).interactive, true);
      }
    }
    for (final targets in relatedDestinations.values) {
      for (final id in targets) {
        expect(entryById(id).interactive, true);
      }
    }
  });
  test('Eight guided paths cover every lab exactly once without cyclic prerequisites', () {
    expect(learningPaths.length, 8);
    expect(
      learningPaths.expand((p) => p.activities).map((e) => e.id).toSet(),
      labInventory.map((e) => e.id).toSet(),
    );
    void visit(String id, Set<String> stack) {
      expect(stack.contains(id), false);
      for (final pre
          in learningPaths.firstWhere((p) => p.id == id).prerequisites) {
        visit(pre, {...stack, id});
      }
    }

    for (final p in learningPaths) {
      visit(p.id, {});
      expect(p.progress({}), 0);
      expect(p.resume({}), p.requiredActivities.first);
      expect(p.progress(p.requiredActivities.map((e) => e.id).toSet()), 1);
      expect(
        p.progress(
          p.activities.where((e) => !p.required(e)).map((e) => e.id).toSet(),
        ),
        0,
      );
    }
  });
  test('Launcher metadata filters and search use the same96 identities', () {
    expect(filterLabs().length, 96);
    expect(
      filterLabs(studio: 16).map((e) => e.id).toList(),
      studios[16].entries.map((e) => e.id).toList(),
    );
    expect(filterLabs(query: 'spectroscopy').single.id, 's16-e02');
    for (final apparatus in labInventory.map(apparatusFor).toSet()) {
      expect(
        filterLabs(apparatus: apparatus)
            .every((e) => apparatusFor(e) == apparatus),
        true,
      );
    }
    expect(filterLabs(stage: 'Foundation').length, 32);
  });
  test(
    'Every mastery answer evaluates with documented units and tolerance',
    () {
      expect(masteryQuestions.map((q) => q.id).toSet().length, 16);
      expect(masteryQuestions.map((q) => q.studio).toSet().length, 16);
      expect(masteryQuestions.map((q) => q.type).toSet().length, 6);
      for (final q in masteryQuestions) {
        final value = q.answer();
        expect(value.isFinite, true);
        expect(q.evaluate(value), true);
        expect(q.evaluate(value + math.max(1, q.tolerance * 2)), false);
        expect(q.evaluate(double.nan), false);
        if (q.options.isNotEmpty) {
          expect(value.toInt(), inInclusiveRange(0, q.options.length - 1));
        }
      }
      expect(masteryQuestions.first.answer(), closeTo(.0236, 1e-12));
    },
  );
  test(
    'Comparison SHM and RC/thermal responses match source models exactly',
    () {
      final p = comparisonDefaults(), a = ComparisonModel(0, p), s = a.at(1.2);
      expect(
        s['springPosition'],
        freeOscillator(p['mass']!, p['spring']!, 0, p['amplitude']!, 0, 1.2).x,
      );
      final c = ComparisonModel(3, p).at(8);
      expect(
        c['voltage'],
        rcState(
          p['resistance']!,
          p['capacitance']!,
          5,
          0,
          c['rcTime']!,
        ).voltage,
      );
      expect(
        c['temperature'],
        probeTemperature(350, 300, p['thermalTau']!, c['thermalTime']!),
      );
      expect(c['normalizedCharge'], closeTo(c['normalizedThermal']!, 1e-14));
    },
  );
  test('Inverse-square and interference comparisons preserve physics and separate units', () {
    final p = comparisonDefaults(),
        e = ComparisonModel(1, p),
        near = e.at(0),
        far = e.at(20 / 9);
    expect(near['electricField']! / far['electricField']!, closeTo(4, 1e-12));
    expect(near['gravityField']! / far['gravityField']!, closeTo(4, 1e-12));
    final w = ComparisonModel(2, p);
    for (final u in [0.0, 3.0, 10.0, 14.0, 20.0]) {
      final s = w.at(u);
      expect(
        math.pow(s['waveEnvelope']! / (2 * p['amplitude']!), 2),
        closeTo(s['opticalIntensity']!, 1e-12),
      );
    }
    expect(w.units, ['m', 'relative intensity']);
  });
  test(
    'Classical/matter comparison is seeded density rather than particle paths',
    () {
      final p = comparisonDefaults(),
          a = ComparisonModel(4, p),
          b = ComparisonModel(4, p);
      a.at(8);
      b.at(8);
      expect(a.right, b.right);
      expect(a.values['classicalPosition'], 8);
      expect(a.values['detections'], 400);
      expect(
        a.right.fold(0.0, (s, r) => s + (r['observed'] ?? 0) * .004 / 80),
        closeTo(1, 1e-12),
      );
      expect(a.xLabels[0], isNot(a.xLabels[1]));
    },
  );
  test('Astronomy quantities round-trip through existing trial schema', () {
    for (int k = 0; k < 6; k++) {
      final r = AstronomyRun(k, defaults(k)),
          trial = Trial(
            id: 'astro$k',
            labId: 's16-e0$k',
            quantity: [
              'length',
              'power',
              'length',
              'speed',
              'length',
              'relativeIntensity',
            ][k],
            unit: astroLessons[k].unit,
            value: r.state[astroLessons[k].metric]!,
            resolution: null,
            model: astroVersion,
            configuration: {'dataset': astroDataset},
          );
      expect(Trial.fromJson(trial.toJson()).value, trial.value);
    }
  });
}
