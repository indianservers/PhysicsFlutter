import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/core/physics/electromagnetism.dart';
import 'package:physics_atelier/core/physics/plot_range.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';
import 'package:physics_atelier/features/electromagnetism/curriculum.dart';

EMRun model(
  int kind, {
  EMState edit = const {},
  int mode = 0,
  double time = 0,
  double? held,
}) => EMRun(
  kind,
  {...emLessons[kind].defaults, ...edit},
  mode: mode,
  heldCharge: held,
)..seek(time);
void main() {
  test('Potential readout checks numerical gradient including a cancellation point', () {
    for (final edit in [
      <String, double>{},
      <String, double>{'q2': 5e-9, 'probeX': 0, 'probeY': 0},
      <String, double>{'q1': 0, 'q2': 0},
    ]) {
      final state = model(2, edit: edit).state;
      expect(state['gradientEx'], isNotNull);
      expect(state['gradientEy'], isNotNull);
      expect(
        state['gradientError']!,
        lessThanOrEqualTo(state['gradientTolerance']!),
      );
    }
  });

  test('CODATA constants and right-handed vectors', () {
    expect(coulombK, closeTo(8.9875517862e9, 1));
    expect(const V3(1, 0).cross(const V3(0, 1)).z, 1);
    expect(const V3(1, 2, 3).dot(const V3(-2, 1, 0)), 0);
  });
  test('Signed Coulomb force, inverse square and zero charge', () {
    const a = ChargeSource(V3(0, 0), 2e-6), b = ChargeSource(V3(.2, 0), -2e-6);
    final f = coulombForce(a, b), back = coulombForce(b, a);
    expect(f.x, closeTo(-.89875517862, 1e-9));
    expect((f + back).norm, 0);
    expect(
      coulombForce(a, const ChargeSource(V3(.4, 0), -2e-6)).x,
      closeTo(f.x / 4, 1e-12),
    );
    expect(
      coulombForce(a, const ChargeSource(V3(.2, 0), 2e-6)).x,
      greaterThan(0),
    );
    expect(coulombForce(a, const ChargeSource(V3(.2, 0), 0)).norm, 0);
    expect(() => coulombForce(a, a), throwsArgumentError);
  });
  test('Superposition has zero potential but nonzero dipole-midpoint E', () {
    final e = Electrostatic([
      const ChargeSource(V3(-.12, 0), 5e-9),
      const ChargeSource(V3(.12, 0), -5e-9),
    ]);
    expect(e.potential(V3.zero), closeTo(0, 1e-12));
    expect(
      e.field(V3.zero).x,
      closeTo(2 * coulombK * 5e-9 / (.12 * .12), 1e-10),
    );
    expect(e.field(V3.zero).y, 0);
  });
  test(
    'Like charges cancel E, potential adds, zero test charge changes no E',
    () {
      final a = model(1, edit: {'q2': 5e-9, 'probeX': 0, 'probeY': 0}),
          b = model(
            1,
            edit: {'q2': 5e-9, 'probeX': 0, 'probeY': 0, 'testCharge': 0},
          );
      expect(a.state['field'], closeTo(0, 1e-10));
      expect(a.state['potential'], greaterThan(0));
      expect(a.state['field'], b.state['field']);
      expect(b.state['fx'], 0);
    },
  );
  test('E equals minus central gradient of V away from sources', () {
    final e = Electrostatic([
      const ChargeSource(V3(-.1, 0), 3e-9),
      const ChargeSource(V3(.1, .04), -2e-9),
    ]);
    for (final r in [
      const V3(.23, .12),
      const V3(-.27, -.2),
      const V3(0, .18),
    ]) {
      const h = 1e-6;
      final ex =
              -(e.potential(r + const V3(h, 0)) -
                  e.potential(r - const V3(h, 0))) /
              (2 * h),
          ey =
              -(e.potential(r + const V3(0, h)) -
                  e.potential(r - const V3(0, h))) /
              (2 * h);
      expect(ex, closeTo(e.field(r).x, e.field(r).norm * 1e-8));
      expect(ey, closeTo(e.field(r).y, e.field(r).norm * 1e-8));
    }
  });
  test(
    'Exclusion holes and overlapping sources never use softened readouts',
    () {
      final e = Electrostatic([const ChargeSource(V3.zero, 0)]);
      expect(() => e.field(V3.zero), throwsArgumentError);
      expect(() => e.potential(const V3(.01, 0)), throwsArgumentError);
      expect(
        () => Electrostatic([
          const ChargeSource(V3.zero, 1),
          const ChargeSource(V3(.02, 0), 1),
        ]),
        throwsArgumentError,
      );
      final r = model(1, edit: {'probeX': -.12, 'probeY': 0});
      expect(r.invalid, isNotEmpty);
      expect(r.state.containsKey('field'), false);
    },
  );
  test('Field tracing stops, arrows follow positive-to-negative, geometry caching exact', () {
    final r = model(1);
    expect(r.lines.length, 12);
    expect(r.lines.every((l) => l.length <= 401), true);
    final e = Electrostatic(r.sources);
    for (final path in r.lines) {
      for (int i = 1; i < path.length; i++) {
        final d = path[i] - path[i - 1];
        expect(d.dot(e.field(path[i - 1])), greaterThanOrEqualTo(-1e-9));
      }
    }
    final moved = EMRun(1, {
      ...r.p,
      'probeX': .2,
      'testCharge': -1e-9,
    }, geometryFrom: r);
    expect(identical(moved.lines, r.lines), true);
    expect(identical(moved.contours, r.contours), true);
    expect(moved.state['field'], isNot(r.state['field']));
    expect(moved.state['fx']! * moved.state['ex']!, lessThan(0));
  });
  test('Ohm law, signed charge transfer, conserved drift and open switch', () {
    final r = model(3, time: 2);
    expect(r.state['current'], closeTo(.4, 1e-14));
    expect(r.state['charge'], closeTo(.8, 1e-12));
    expect(r.state['power'], closeTo(2.4, 1e-14));
    expect(
      -r.state['drift']! * 8.5e28 * elementaryCharge * 1e-6,
      closeTo(.4, 1e-12),
    );
    final open = model(3, edit: {'closed': 0}, time: 2);
    expect(open.state['current'], 0);
    expect(open.state['charge'], 0);
    expect(open.state['power'], 0);
  });
  for (final (example, expected) in [(0, .2), (1, .9), (2, 6 / (5 + 20 / 3))]) {
    test(
      'MNA example $example independently agrees with equivalent resistance and KCL/power',
      () {
        final g = CircuitGraph.example(example), s = solveCircuit(g);
        expect(s.valid, true, reason: s.message);
        expect(-s.currents['B1']!, closeTo(expected, 1e-11));
        expect(s.kclResidual, lessThan(1e-12));
        expect(s.powerResidual, lessThan(1e-10));
        for (final p in g.parts.where(
          (p) => p.type == 'resistor' || p.type == 'lamp',
        )) {
          expect(s.voltages[p.id], closeTo(s.currents[p.id]! * p.value, 1e-12));
          expect(s.powers[p.id], greaterThanOrEqualTo(0));
        }
        expect(s.currents['V1'], 0);
        expect(s.voltages['V1'], closeTo(s.voltages['L1']!, 1e-12));
      },
    );
  }
  test('Actual graph wiring changes series into a bypass, not visual-template switching', () {
    final g = CircuitGraph.example(0), s = solveCircuit(g);
    g.wires.add(['R1:a', 'R1:b']);
    final b = solveCircuit(g);
    expect(b.valid, true, reason: b.message);
    expect(-b.currents['B1']!, closeTo(.3, 1e-12));
    expect(b.currents['R1'], closeTo(0, 1e-12));
    expect(s.currents['B1'], isNot(b.currents['B1']));
  });
  test('Open series switch gives zero conduction and source voltage across opening', () {
    final g = CircuitGraph.example(0);
    g.parts.firstWhere((p) => p.id == 'S1').closed = false;
    final s = solveCircuit(g);
    expect(s.valid, true, reason: s.message);
    expect(s.currents['B1'], closeTo(0, 1e-12));
    expect(s.voltages['S1'], closeTo(6, 1e-12));
  });
  test(
    'Floating nodes and disconnected voltmeters produce useful invalid states',
    () {
      final g = CircuitGraph.example(0);
      g.parts.add(CircuitPart('floating', 'resistor'));
      final s = solveCircuit(g);
      expect(s.valid, false);
      expect(s.message, contains('Floating'));
      expect(s.currents, isEmpty);
    },
  );
  test(
    'Ideal wire/source and ammeter shorts never show plausible finite readings',
    () {
      for (final viaMeter in [false, true]) {
        final g = CircuitGraph.example(0);
        if (viaMeter) {
          g.parts.add(CircuitPart('A2', 'ammeter'));
          g.wires.addAll([
            ['B1:a', 'A2:a'],
            ['B1:b', 'A2:b'],
          ]);
        } else {
          g.wires.add(['B1:a', 'B1:b']);
        }
        final s = solveCircuit(g);
        expect(s.valid, false);
        expect(s.currents, isEmpty);
        expect(s.message, contains(viaMeter ? 'ideal' : 'short'));
      }
    },
  );
  test(
    'Inconsistent parallel sources and redundant ideal constraints detected',
    () {
      for (final value in [6.0, 7.0]) {
        final g = CircuitGraph.example(0);
        g.parts.add(CircuitPart('B2', 'source', value: value));
        g.wires.addAll([
          ['B1:a', 'B2:a'],
          ['B1:b', 'B2:b'],
        ]);
        expect(solveCircuit(g).valid, false);
      }
    },
  );
  test('Invalid resistors, unsupported types, dangling terminals and bounds handled', () {
    final g = CircuitGraph.example(0);
    g.parts[1].value = 0;
    expect(solveCircuit(g).message, contains('require'));
    final h = CircuitGraph.example(0);
    h.wires.add(['missing:a', 'B1:b']);
    expect(solveCircuit(h).message, contains('missing'));
    expect(solveCircuit(CircuitGraph([], [])).valid, false);
  });
  test(
    'Plate capacitance scaling, connected voltage and isolated charge/work',
    () {
      final a = plateCapacitor(.005, .001, 1, 6),
          b = plateCapacitor(.01, .001, 1, 6),
          c = plateCapacitor(.005, .002, 1, 6, heldCharge: a.q);
      expect(a.c, closeTo(44.270939094e-12, 1e-22));
      expect(b.c, closeTo(2 * a.c, 1e-22));
      expect(b.v, a.v);
      expect(c.q, a.q);
      expect(c.v, closeTo(12, 1e-12));
      expect(c.energy, closeTo(2 * a.energy, 1e-20));
      expect(() => plateCapacitor(.001, .01, 1, 6), throwsArgumentError);
    },
  );
  test(
    'RC initial/final values, time constant, sign and continuous switch state',
    () {
      final start = rcState(1e4, 1e-4, 6, 0, 0),
          one = rcState(1e4, 1e-4, 6, 0, 1),
          end = rcState(1e4, 1e-4, 6, 0, 50),
          switched = rcState(1e4, 1e-4, 0, one.voltage, 0);
      expect(start.voltage, 0);
      expect(start.current, .0006);
      expect(one.voltage, closeTo(6 * (1 - math.exp(-1)), 1e-12));
      expect(end.voltage, closeTo(6, 1e-12));
      expect(switched.voltage, one.voltage);
      expect(switched.current, lessThan(0));
    },
  );
  test(
    'Dipole axial/equatorial reference and inverse cube with exclusions',
    () {
      const m = V3(.15, 0);
      final axis = dipoleField(const V3(.1, 0), m),
          equator = dipoleField(const V3(0, .1), m);
      expect(axis.x, closeTo(mu0 * .15 / (2 * math.pi * .001), 1e-15));
      expect(equator.x, closeTo(-axis.x / 2, 1e-15));
      expect(dipoleField(const V3(.2, 0), m).x, closeTo(axis.x / 8, 1e-15));
      expect(() => dipoleField(V3.zero, m), throwsArgumentError);
    },
  );
  test('Zero magnetic source has no fabricated compass direction', () {
    expect(model(6, edit: {'moment': 0}).state.containsKey('compass'), false);
    expect(model(8, edit: {'current': 0}).state.containsKey('compass'), false);
  });
  test('Lorentz signs, parallel motion and zero magnetic work', () {
    for (final charge in [-elementaryCharge, elementaryCharge]) {
      final r = model(7, edit: {'charge': charge});
      expect(r.state['fy']! * charge, lessThan(0));
      expect(
        V3(r.state['fx']!, r.state['fy']!, r.state['fz']!).dot(r.velocity),
        closeTo(0, 1e-20),
      );
    }
    final parallel = model(7, edit: {'vx': 0, 'vy': 0, 'vz': 1e5}, time: 2e-6);
    expect(parallel.state['force'], 0);
    expect(parallel.position.z, closeTo(.2, 1e-12));
  });
  test(
    'Boris speed/energy preservation, physical circle radius and period',
    () {
      const m = 1.6726e-27, q = elementaryCharge, b = .02, v = 1e5;
      final period = 2 * math.pi * m / (q * b), radius = m * v / (q * b);
      var p = V3.zero, velocity = const V3(v, 0);
      for (int i = 0; i < 2000; i++) {
        final s = borisStep(
          p,
          velocity,
          q,
          m,
          const V3(0, 0, b),
          period / 2000,
        );
        p = s.position;
        velocity = s.velocity;
        expect(velocity.norm, closeTo(v, 1e-7));
        expect((p - V3(0, -radius)).norm, closeTo(radius, 1e-12));
      }
      expect(p.norm, lessThan(radius * 1e-5));
    },
  );
  test('Boris trajectory converges quadratically with time refinement', () {
    double error(int n) {
      const m = 1.6726e-27, q = elementaryCharge, b = .02, v = 1e5;
      final period = 2 * math.pi * m / (q * b);
      var p = V3.zero, velocity = const V3(v, 0);
      for (int i = 0; i < n; i++) {
        final s = borisStep(
          p,
          velocity,
          q,
          m,
          const V3(0, 0, b),
          period / n,
          substeps: 1,
        );
        p = s.position;
        velocity = s.velocity;
      }
      return p.norm;
    }

    expect(error(100) / error(200), closeTo(4, .01));
  });
  test('Nonrelativistic restriction is explicit before playback', () {
    final r = model(7, edit: {'vx': 2e6, 'vy': 2e6, 'vz': 1e6});
    expect(r.invalid, contains('Nonrelativistic'));
    expect(
      () => borisStep(V3.zero, const V3(3e6, 0), 1, 1, const V3(0, 0, 1), .1),
      throwsArgumentError,
    );
  });
  test('Long wire sign, inverse distance, tangent direction and no interior formula', () {
    final a = wireField(const V3(.03, 0), 5),
        b = wireField(const V3(.06, 0), 5);
    expect(a.x, 0);
    expect(a.y, closeTo(33.3333333289e-6, 1e-12));
    expect(b.norm, closeTo(a.norm / 2, 1e-15));
    expect(wireField(const V3(.03, 0), -5).y, -a.y);
    expect(() => wireField(V3.zero, 5), throwsArgumentError);
  });
  test('Finite solenoid centre, symmetry, exterior decay and long limit', () {
    final a = solenoidField(0, 500, .1, .02, 2);
    expect(
      a,
      closeTo(mu0 * 500 * 2 / (2 * math.sqrt(.02 * .02 + .05 * .05)), 1e-14),
    );
    expect(
      solenoidField(.2, 500, .1, .02, 2),
      closeTo(solenoidField(-.2, 500, .1, .02, 2), 1e-14),
    );
    expect(solenoidField(2, 500, .1, .02, 2), lessThan(a / 1e4));
    expect(
      solenoidField(0, 500, 1, .001, 2),
      closeTo(mu0 * 1000, mu0 * 1000 * 3e-6),
    );
    expect(model(9).state.containsKey('longField'), false);
  });
  test('Finite-loop flux derivative agrees with geometry difference; polarity reversals', () {
    const z = -.06, a = .015, r = .05, m = .15, h = 1e-6;
    final s = loopFlux(z, a, r, m),
        derivative =
            (loopFlux(z + h, a, r, m).flux - loopFlux(z - h, a, r, m).flux) /
            (2 * h);
    expect(s.derivative, closeTo(derivative, s.derivative.abs() * 1e-8));
    expect(s.derivative, greaterThan(0));
    expect(loopFlux(-z, a, r, m).derivative, closeTo(-s.derivative, 1e-15));
    expect(loopFlux(z, a, r, -m).flux, closeTo(-s.flux, 1e-15));
    expect(model(10, edit: {'velocity': 0}).state['emf'], 0);
    expect(
      model(10, edit: {'velocity': -.12}).state['emf'],
      closeTo(-model(10).state['emf']!, 1e-15),
    );
  });
  test('Finite source passes coil plane nonsingular; quadrature converges and far limit matches dipole', () {
    final coarse = loopFlux(0, .025, .04, .15, samples: 32),
        medium = loopFlux(0, .025, .04, .15, samples: 64),
        reference = loopFlux(0, .025, .04, .15, samples: 512);
    expect(
      (medium.flux - reference.flux).abs(),
      lessThan((coarse.flux - reference.flux).abs() + 1e-25),
    );
    expect(reference.derivative, 0);
    expect(reference.flux.isFinite, true);
    final far = loopFlux(1, .005, .05, .15),
        dipole = mu0 * .15 * .05 * .05 / (2 * math.pow(1 + .05 * .05, 1.5));
    expect(far.flux, closeTo(dipole, dipole * 4e-5));
    expect(() => loopFlux(0, .05, .05, .15), throwsArgumentError);
  });
  test('Open EMF is separate from closed resistive current', () {
    final open = model(10),
        closed = model(10, edit: {'closed': 1, 'resistance': 50});
    expect(open.state['current'], 0);
    expect(closed.state['emf'], open.state['emf']);
    expect(closed.state['current'], closeTo(closed.state['emf']! / 50, 1e-15));
  });
  test(
    'Magnetic circuit polarity, NI-square force, area and air gap scaling',
    () {
      final a = magneticCircuit(400, .5, .15, .003, .0005, 200),
          b = magneticCircuit(400, 1, .15, .003, .0005, 200),
          reverse = magneticCircuit(400, -.5, .15, .003, .0005, 200);
      expect(b.force, closeTo(a.force * 4, 1e-12));
      expect(reverse.field, -a.field);
      expect(reverse.force, a.force);
      expect(a.field, greaterThan(a.airField));
      expect(
        magneticCircuit(400, .5, .15, .006, .0005, 200).force,
        lessThan(a.force),
      );
      expect(
        magneticCircuit(400, .5, .15, .003, .001, 200).force,
        closeTo(a.force * 2, 1e-12),
      );
      expect(
        () => magneticCircuit(1000, 2, .1, .001, .001, 1000),
        throwsArgumentError,
      );
    },
  );
  test('Every lab valid by default and saved observations finite, bounded, replay deterministic', () {
    for (int kind = 0; kind < 12; kind++) {
      final a = model(
            kind,
            time: kind == 7
                ? 3e-6
                : kind == 10
                ? .8
                : kind == 3
                ? 2
                : 0,
          ),
          b = model(kind, time: a.time);
      expect(a.invalid, isEmpty, reason: 'lab $kind');
      expect(a.state, b.state);
      expect(a.state.values.every((v) => v.isFinite), true);
      expect(a.samples.length, lessThanOrEqualTo(301));
      expect(a.trail.length, lessThanOrEqualTo(601));
      expect(a.state.containsKey(emLessons[kind].metric), true);
    }
  });
  test('Trial JSON round-trip keeps model/units/topology and is detached from edits', () {
    final r = model(4);
    final t = Trial(
      id: 'em',
      labId: 's10-e04',
      quantity: 'current',
      unit: 'A',
      value: r.state['current']!,
      resolution: null,
      configuration: {'model': emVersion, 'circuit': r.circuit.toJson()},
      model: emVersion,
    );
    r.circuit.wires.clear();
    final restored = Trial.fromJson(t.toJson());
    expect(restored.model, emVersion);
    expect((restored.configuration['circuit']['wires'] as List), isNotEmpty);
  });
  test('Plot ranges retain femtonewton amplitude and sub-microsecond span', () {
    final tiny = plotRange([1e-18, 2e-18, 3e-18], includeZero: true),
        ordinary = plotRange([1, 2, 3], includeZero: true);
    expect(tiny.max, 3e-18);
    expect(
      (2e-18 - tiny.min) / (tiny.max - tiny.min),
      closeTo((2 - ordinary.min) / (ordinary.max - ordinary.min), 1e-15),
    );
    final time = plotRange([0, 1e-9, 2e-9]);
    expect(time.max, 2e-9);
    expect(plotRange([0, 0]).max, greaterThan(0));
  });
}
