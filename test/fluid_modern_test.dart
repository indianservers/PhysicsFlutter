import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/core/physics/fluid_modern_run.dart';
import 'package:physics_atelier/core/physics/electromagnetism.dart'
    show elementaryCharge;
import 'package:physics_atelier/features/fluid_modern/curriculum.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';

void main() {
  test(
    'Vertical hydrostatic depth, absolute/gauge reference and object density',
    () {
      final s = densityPressure(1000, .3, 101325, 101325, .2, .0002);
      expect(s['gaugePressure'], closeTo(2941.995, 1e-9));
      expect(s['absolutePressure'], closeTo(104266.995, 1e-8));
      expect(s['objectDensity'], 1000);
      expect(
        densityPressure(1000, 0, 95000, 101325, .2, .0002)['gaugePressure'],
        -6325,
      );
      expect(
        () => densityPressure(1000, -.1, 101325, 101325, 1, .001),
        throwsArgumentError,
      );
    },
  );
  test(
    'Manometer unequal areas conserve volume and pressure for both fluids',
    () {
      for (final mode in [0, 1]) {
        for (final pressure in [-980.665, 0.0, 980.665]) {
          final s = manometer(
            1000,
            850,
            .002,
            .001,
            .4,
            .00006,
            pressure,
            mode,
          );
          expect(s['volumeResidual'], closeTo(0, 1e-15));
          expect(s['pressureBalance'], closeTo(0, 1e-9));
          expect(s['baseVolume'], closeTo(.003 * .4, 1e-15));
          if (mode == 0 && pressure == 0) {
            expect(s['leftLevel'], s['rightLevel']);
          }
        }
      }
    },
  );
  test('Symmetric same-fluid pressure difference reference', () {
    final s = manometer(1000, 850, .002, .002, .4, .00006, 980.665, 0);
    expect(s['leftLevel'], closeTo(.35, 1e-12));
    expect(s['rightLevel'], closeTo(.45, 1e-12));
  });
  test(
    'Two-fluid interface pressure includes the finite upper-layer volume',
    () {
      final s = manometer(1000, 850, .002, .002, .4, .00006, 0, 1);
      expect(s['layerHeight'], .03);
      expect(
        s['rightLevel']! - s['interfaceLevel']!,
        closeTo(.85 * .03, 1e-12),
      );
      expect(s['leftLevel']! - s['interfaceLevel']!, closeTo(.03, 1e-12));
    },
  );
  test('Hydrostatic overflow and unstable density order are explicit', () {
    expect(
      () => manometer(1000, 850, .001, .001, .2, .0001, 15000, 0),
      throwsArgumentError,
    );
    expect(
      () => manometer(800, 850, .002, .002, .4, .00006, 0, 1),
      throwsArgumentError,
    );
  });
  test(
    'Rectangular displacement dry partial full and actual force balance',
    () {
      final dry = buoyancy(1000, 700, .08, .06, .12, 0, 1),
          half = buoyancy(1000, 700, .08, .06, .12, .06, 1),
          full = buoyancy(1000, 700, .08, .06, .12, .2, 1);
      expect(dry['displacedVolume'], 0);
      expect(half['displacedVolume'], closeTo(.08 * .06 * .06, 1e-15));
      expect(full['displacedVolume'], closeTo(.08 * .06 * .12, 1e-15));
      expect(
        half['supportForceUp'],
        closeTo(half['weight']! - half['buoyantForce']!, 1e-12),
      );
    },
  );
  test('Floating neutral and sinking static end states are distinct', () {
    final f = buoyancy(1000, 700, .08, .06, .12, .09, 0),
        n = buoyancy(1000, 1000, .08, .06, .12, .09, 0),
        s = buoyancy(1000, 2000, .08, .06, .12, .09, 0);
    expect(f['submergedFraction'], closeTo(.7, 1e-12));
    expect(f['buoyantForce'], closeTo(f['weight']!, 1e-12));
    expect(n['regime'], 1);
    expect(n['freeNetForceUp'], 0);
    expect(s['regime'], 2);
    expect(s['bottomDepth'], .22);
    expect(s['supportForceUp']!, greaterThan(0));
    expect(s['buoyantForce']!, lessThan(s['weight']!));
  });
  test('Continuity uses the same circular area at every station', () {
    final p = PipeModel(.015, .008, 2e-5);
    for (final s in p.profile) {
      expect(s['area'], closeTo(math.pi * s['radius']! * s['radius']!, 1e-15));
      expect(s['flowRate'], closeTo(2e-5, 1e-15));
    }
    expect(p.at(0)['speed'], closeTo(2e-5 / (math.pi * .008 * .008), 1e-12));
  });
  test('Volume-coordinate tracers have actual local Q/A speed', () {
    final p = PipeModel(.015, .008, 2e-5);
    final x = p.tracer(.5, 10), later = p.tracer(.50001, 10);
    expect((later - x) / .00001, closeTo(p.at(x)['speed']!, 2e-4));
  });
  test(
    'Elevated centreline tracer speed follows arclength, not projected x',
    () {
      final p = PipeModel(.015, .008, 2e-5, throatElevation: .04);
      final x = p.tracer(.2, 7),
          later = p.tracer(.20001, 7),
          dx = (later - x) / .00001,
          actual = dx * math.sqrt(1 + p.slope(x) * p.slope(x));
      expect(actual, closeTo(p.at(x)['speed']!, 2e-4));
    },
  );
  test('Bernoulli total energy and piezometer head are compatible', () {
    final p = PipeModel(
      .015,
      .008,
      2e-5,
      bernoulli: true,
      inletPressure: 101825,
      throatElevation: .03,
    );
    final first = p.profile.first;
    for (final row in p.profile) {
      expect(row['bernoulli'], closeTo(first['bernoulli']!, 1e-8));
      expect(
        row['head'],
        closeTo((row['pressure']! - 101325) / (1000 * 9.80665), 1e-12),
      );
      expect(
        row['columnTop'],
        closeTo(row['head']! + row['elevation']!, 1e-12),
      );
    }
  });
  test(
    'Potential cavitation and unmeasurable open-piezometer states reject',
    () {
      expect(
        () => PipeModel(
          .015,
          .003,
          .0005,
          bernoulli: true,
          inletPressure: 101825,
        ),
        throwsArgumentError,
      );
      expect(
        () =>
            PipeModel(.015, .008, 2e-5, bernoulli: true, inletPressure: 101325),
        throwsArgumentError,
      );
      expect(
        () =>
            PipeModel(.015, .008, 2e-5, bernoulli: true, inletPressure: 130000),
        throwsArgumentError,
      );
    },
  );
  test(
    'Stokes terminal speed includes buoyancy and has correct radius/μ scaling',
    () {
      final s = stokes(.0005, 2500, 1000, 1, .2, 0);
      expect(
        s['terminalSpeed'],
        closeTo(2 * math.pow(.0005, 2) * 1500 * 9.80665 / 9, 1e-14),
      );
      expect(
        stokes(.001, 2500, 1000, 1, .2, 0)['terminalSpeed'],
        closeTo(4 * s['terminalSpeed']!, 1e-12),
      );
      expect(
        stokes(.0005, 2500, 1000, 2, .2, 0)['terminalSpeed'],
        closeTo(.5 * s['terminalSpeed']!, 1e-12),
      );
      expect(s['drag'], 0);
      expect(
        s['netForceDown'],
        closeTo(s['weight']! - s['buoyantForce']!, 1e-12),
      );
    },
  );
  test(
    'Viscometer transient and bisection arrival are exact model predictions',
    () {
      final start = stokes(.0005, 2500, 1000, 1, .2, 0),
          tau = start['tau']!,
          s = stokes(.0005, 2500, 1000, 1, .2, tau);
      expect(
        s['speed'],
        closeTo(start['terminalSpeed']! * (1 - 1 / math.e), 1e-14),
      );
      final t = stokesArrival(.0005, 2500, 1000, 1, .2);
      expect(
        stokes(.0005, 2500, 1000, 1, .2, t)['position'],
        closeTo(.2, 1e-12),
      );
      expect(stokes(.0005, 2500, 1000, 1, .2, t)['reynolds']!, lessThan(.1));
    },
  );
  test('Stokes regime, falling direction and travel geometry are enforced', () {
    expect(() => stokes(.001, 8000, 1000, .001, .2, 0), throwsArgumentError);
    expect(() => stokes(.0005, 800, 1000, 1, .2, 0), throwsArgumentError);
    expect(() => stokes(.002, 2500, 1000, 1, .2, 0), throwsArgumentError);
  });
  test('Infinite well energy mass width and level scaling', () {
    final e = wellEnergy(1e-9, electronMass, 1);
    expect(e / elementaryCharge, closeTo(.37603, .00002));
    expect(wellEnergy(1e-9, electronMass, 2), 4 * e);
    expect(wellEnergy(2e-9, electronMass, 1), e / 4);
    expect(wellEnergy(1e-9, 2 * electronMass, 1), e / 2);
    expect(wellPsi(0, 1e-9, electronMass, 2), 0);
    expect(wellPsi(1e-9, 1e-9, electronMass, 2), 0);
  });
  test(
    'All six well densities normalize and stationary profiles do not slosh',
    () {
      for (int n = 1; n <= 6; n++) {
        final d = ProbabilityGrid(
          0,
          1e-9,
          (x) => math.pow(wellPsi(x, 1e-9, electronMass, n), 2).toDouble(),
        );
        expect(d.rawIntegral, closeTo(1, 1e-12));
      }
      final r = FMRun(6, fmLessons[6].defaults),
          profile = r.profile.map((s) => Map<String, double>.of(s)).toList();
      r.seek(3);
      expect(r.profile, profile);
      expect(r.measurementCount, 120);
    },
  );
  test(
    'Seeded well positions match the analytic CDF, not uniform randomness',
    () {
      final d = ProbabilityGrid(
            0,
            1,
            (x) => 2.0 * math.pow(math.sin(2 * math.pi * x), 2),
          ),
          rng = SeededRandom(741),
          xs = [for (int i = 0; i < 20000; i++) d.sample(rng)]..sort();
      double deviation = 0;
      for (int i = 0; i < xs.length; i++) {
        final f = xs[i] - math.sin(4 * math.pi * xs[i]) / (4 * math.pi);
        deviation = math.max(
          deviation,
          math.max((f - i / xs.length).abs(), (f - (i + 1) / xs.length).abs()),
        );
      }
      expect(deviation, lessThan(.02));
    },
  );
  test('Distribution cache reuse and histogram normalization preserve observations', () {
    final r = FMRun(6, fmLessons[6].defaults);
    r.seek(10);
    final total = r.histogram.reduce((a, b) => a + b);
    expect(total, 400);
    final width = 1e-9 / r.bins;
    expect(
      r.distributionData.fold<double>(
        0,
        (a, row) => a + row['observedDensity']! * width,
      ),
      closeTo(1, 1e-12),
    );
    expect(
      r.distributionData.fold<double>(
        0,
        (a, row) => a + row['expectedDensity']! * width,
      ),
      closeTo(1, 1e-12),
    );
    final next = FMRun(6, {
      ...r.p,
      'seed': 43,
      'mass': 2 * electronMass,
    }, geometryFrom: r);
    expect(identical(next.distribution, r.distribution), isTrue);
    expect(next.measurementCount, 0);
  });
  test('Photoelectric threshold cannot be overcome by intensity', () {
    final low = photoelectric(3e14, 100, .0001, 2 * elementaryCharge, .5, 5);
    expect(low['current'], 0);
    expect(low['maximumKineticEnergy'], 0);
    expect(low['emitting'], 0);
    final hi = photoelectric(6e14, 10, .0001, 2 * elementaryCharge, .1, 0);
    expect(
      hi['maximumKineticEnergy']! / elementaryCharge,
      closeTo(.481400618, .000001),
    );
    expect(
      hi['stoppingPotential'],
      closeTo(hi['maximumKineticEnergy']! / elementaryCharge, 1e-12),
    );
  });
  test(
    'Photocurrent follows stated flux QE and uniform-energy collection law',
    () {
      final a = photoelectric(8e14, 10, .0001, 2 * elementaryCharge, .2, 1),
          b = photoelectric(8e14, 20, .0001, 2 * elementaryCharge, .2, 1);
      expect(b['current'], 2 * a['current']!);
      expect(
        a['current'],
        closeTo(elementaryCharge * .2 * .001 / (planck * 8e14), 1e-15),
      );
      final stop = photoelectric(
        8e14,
        10,
        .0001,
        2 * elementaryCharge,
        .2,
        -a['stoppingPotential']!,
      );
      expect(stop['current'], 0);
      expect(
        photoelectric(8e14, 0, .0001, 2 * elementaryCharge, .2, 1)['emitting'],
        0,
      );
    },
  );
  test(
    'de Broglie wavelength and voltage obey the nonrelativistic relation',
    () {
      final p = electronMomentum(100);
      expect(planck / p, closeTo(.122643e-9, 1e-15));
      expect(
        p * p / (2 * electronMass),
        closeTo(100 * elementaryCharge, 1e-30),
      );
      expect(() => electronMomentum(201), throwsArgumentError);
      final d = MatterDistribution(
        electronMomentum(200),
        20e-9,
        100e-9,
        .3,
        .002,
      );
      expect(d.wavelength, greaterThan(0));
    },
  );
  test('Detector probability normalizes and grid CDF converges', () {
    final a = MatterDistribution(
          electronMomentum(100),
          20e-9,
          100e-9,
          .3,
          .002,
          intervals: 4096,
        ),
        b = MatterDistribution(
          electronMomentum(100),
          20e-9,
          100e-9,
          .3,
          .002,
          intervals: 8192,
        );
    double integral = 0;
    for (int i = 1; i < a.grid.density.length; i++) {
      integral += (a.grid.density[i - 1] + a.grid.density[i]) * a.grid.dx / 2;
    }
    expect(integral, closeTo(1, 1e-12));
    for (int i = 0; i <= 100; i++) {
      final x = -.002 + .004 * i / 100;
      expect(a.grid.cumulative(x), closeTo(b.grid.cumulative(x), 2e-5));
    }
  });
  test(
    'Unsupported slit resolution geometry and electron energy are rejected',
    () {
      expect(
        () => MatterDistribution(electronMomentum(200), 40e-9, 50e-9, .3, .002),
        throwsArgumentError,
      );
      expect(
        () =>
            MatterDistribution(electronMomentum(200), 20e-9, 200e-9, .1, .004),
        throwsArgumentError,
      );
      expect(
        () => MatterDistribution(8e-24, 20e-9, 100e-9, .3, .002),
        throwsArgumentError,
      );
    },
  );
  test('Hydrogen H-alpha uses vacuum, with ordered discrete levels', () {
    final s = hydrogenTransition(2, 3);
    expect(s['wavelength']! * 1e9, closeTo(656.47, .02));
    expect(
      s['photonEnergy'],
      closeTo(s['upperEnergy']! - s['lowerEnergy']!, 1e-30),
    );
    expect(s['frequency']! * s['wavelength']!, closeTo(299792458, 1e-6));
    expect(() => hydrogenTransition(3, 3), throwsArgumentError);
  });
  test('Lyman Balmer Paschen limits and spectral classifications', () {
    expect(hydrogenTransition(1, 2)['spectralRegion'], 0);
    expect(hydrogenTransition(2, 3)['spectralRegion'], 1);
    expect(hydrogenTransition(3, 4)['spectralRegion'], 2);
    expect(
      hydrogenTransition(2, 8)['seriesLimit'],
      4 * hydrogenTransition(1, 8)['seriesLimit']!,
    );
    expect(
      hydrogenTransition(3, 8)['seriesLimit'],
      closeTo(9 * hydrogenTransition(1, 8)['seriesLimit']!, 1e-18),
    );
  });
  test(
    'Nuclear counts neutral atomic masses and binding reference are consistent',
    () {
      for (int n = 0; n < isotopes.length; n++) {
        final s = nuclear(n), i = isotopes[n];
        expect(s['protons']! + s['neutrons']!, s['massNumber']);
        expect(s['nuclearCharge'], i.z * elementaryCharge);
        expect(s['atomicMass'], i.atomicMassU * atomicMass);
        expect(s['bindingEnergy']!, greaterThan(0));
      }
      expect(nuclear(3)['atomicMassU'], 12);
      expect(
        nuclear(3)['bindingEnergy']! / elementaryCharge / 1e6,
        closeTo(92.16, .02),
      );
      expect(
        nuclear(6)['bindingPerNucleon']! / elementaryCharge / 1e6,
        closeTo(8.79, .02),
      );
    },
  );
  test(
    'Half-life, exponential decay and activity have their defined SI units',
    () {
      for (int m = 0; m < 2; m++) {
        final initial = decayExpectation(m, 1e6, 0, .25, .01),
            half = decayExpectation(m, 1e6, halfLives[m], .25, .01);
        expect(half['expectedRemaining'], closeTo(5e5, 1e-8));
        expect(
          half['expectedActivity'],
          closeTo(initial['expectedActivity']! / 2, 1e-15),
        );
        expect(
          half['expectedDetectorRate'],
          closeTo(.25 * half['expectedActivity']! + .01, 1e-15),
        );
      }
    },
  );
  test('Versioned random stream has a fixed known xorshift vector', () {
    final r = SeededRandom(42);
    r.uniform();
    expect(r.state, 11355432);
    r.uniform();
    expect(r.state, 2836018348);
    r.uniform();
    expect(r.state, 476557059);
  });
  test(
    'Binomial endpoints and large population statistics (5 standard errors)',
    () {
      final r = SeededRandom(901);
      expect(r.binomial(1000000000, 0), 0);
      expect(r.binomial(1000000000, 1), 1000000000);
      double mean = 0, m2 = 0;
      const count = 3000;
      for (int i = 1; i <= count; i++) {
        final x = r.binomial(1000000000, 1e-6).toDouble(), delta = x - mean;
        mean += delta / i;
        m2 += delta * (x - mean);
      }
      const expected = 1000.0, variance = 999.999;
      expect(mean, closeTo(expected, 5 * math.sqrt(variance / count)));
      expect(
        m2 / (count - 1),
        closeTo(variance, 5 * variance * math.sqrt(2 / (count - 1))),
      );
    },
  );
  test(
    'Poisson small/large means match moments within justified tolerances',
    () {
      for (final lambda in [2.0, 1000.0]) {
        final r = SeededRandom(771);
        double mean = 0, m2 = 0;
        const count = 5000;
        for (int i = 1; i <= count; i++) {
          final x = r.poisson(lambda).toDouble(), delta = x - mean;
          mean += delta / i;
          m2 += delta * (x - mean);
        }
        expect(mean, closeTo(lambda, 5 * math.sqrt(lambda / count)));
        expect(
          m2 / (count - 1),
          closeTo(lambda, 6 * lambda * math.sqrt(2 / (count - 1))),
        );
      }
    },
  );
  test(
    'Source and detector streams remain independent when efficiency changes',
    () {
      final params = fmLessons[11].defaults,
          a = FMRun(11, {...params, 'efficiency': 0, 'background': 0}),
          b = FMRun(11, {...params, 'efficiency': 1, 'background': 0});
      for (int i = 0; i < 100; i++) {
        a.step();
        b.step();
      }
      a.refresh();
      b.refresh();
      expect(a.remaining, b.remaining);
      expect(a.decays, b.decays);
      expect(a.detected, 0);
      expect(a.background, 0);
      expect(b.detected, b.decays);
    },
  );
  test('Aggregate source population conserves initial nuclei and detector bookkeeping', () {
    final r = FMRun(11, {
      ...fmLessons[11].defaults,
      'initialN': 1e9,
      'background': 1,
    });
    r.seek(r.maxTime);
    expect(r.remaining + r.decays, 1000000000);
    expect(r.detected, lessThanOrEqualTo(r.decays));
    expect(r.state['detectorCounts'], (r.detected + r.background).toDouble());
    expect(r.samples.length, lessThanOrEqualTo(301));
    expect(r.ticks, 2400);
  });
  test('Every new model and reference choice has valid finite defaults', () {
    for (int k = 0; k < 12; k++) {
      for (int m = 0; m < fmModes[k].length; m++) {
        final r = FMRun(k, fmLessons[k].defaults, mode: m);
        expect(r.invalid, isEmpty, reason: '$k:$m');
        expect(r.state[fmLessons[k].metric], isNotNull, reason: '$k:$m');
        expect(r.state.values.every((v) => v.isFinite), isTrue);
        expect(r.profile, isNotEmpty, reason: '$k:$m');
      }
    }
  });
  test(
    'Dynamic endpoints and seeded replay are exact and histories bounded',
    () {
      for (final k in [3, 4, 5, 6, 8, 11]) {
        final a = FMRun(k, fmLessons[k].defaults);
        for (int i = 0; i < 377; i++) {
          a.step();
        }
        a.refresh();
        final b = FMRun(k, a.initial)..seek(a.time);
        expect(b.state, a.state, reason: 'kind $k');
        expect(b.histogram, a.histogram);
        expect(b.positions, a.positions);
        final end = FMRun(k, a.initial)..seek(a.maxTime);
        expect(end.finished, isTrue);
        expect(end.ticks, end.totalTicks);
        expect(end.samples.length, lessThanOrEqualTo(301));
        expect(end.positions.length, lessThanOrEqualTo(300));
      }
    },
  );
  test('New activity trial units round-trip while previous model types remain valid', () {
    final t = Trial(
      id: 'new-activity',
      labId: 's15-e05',
      quantity: 'activity',
      unit: 'Bq',
      value: .1,
      resolution: null,
      configuration: {'dataset': datasetVersion, 'seed': 42},
      model: fmVersion,
    );
    expect(Trial.fromJson(t.toJson()).toJson(), t.toJson());
  });
}
