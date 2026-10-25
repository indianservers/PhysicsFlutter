import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/core/physics/advanced.dart';
import 'package:physics_atelier/core/physics/dynamics.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';
import 'package:physics_atelier/features/advanced/curriculum.dart';

AdvancedRun run(
  int kind, {
  Map<String, double> edit = const {},
  double time = 0,
  double dt = AdvancedRun.dt,
}) => AdvancedRun(kind, {
  ...advancedLessons[kind].defaults,
  ...edit,
}, stepSize: dt)..seek(time);
void main() {
  test('Contact boundary has a finite nonnegative normal reaction', () {
    for (final angle in [17.0, 43.0, 80.0, 90.0]) {
      final force = .2 * standardGravity / math.sin(angle * math.pi / 180);
      final r = run(
        0,
        edit: {'m': .2, 'angle': angle, 'force': force, 'mu': .8},
        time: .2,
      );
      expect(r.state['normal'], greaterThanOrEqualTo(0));
      expect(r.state.values.every((x) => x.isFinite), isTrue);
    }
  });
  test('Signed applied work, contact reaction and work-energy theorem', () {
    for (final angle in [0.0, 60.0, 180.0]) {
      final r = run(
            0,
            edit: {
              'm': 2,
              'force': 10,
              'mu': .2,
              'angle': angle,
              'distance': 10,
            },
            time: .8,
          ),
          s = r.state;
      expect(
        s['normal'],
        closeTo(
          2 * standardGravity - 10 * math.sin(angle * math.pi / 180),
          1e-9,
        ),
      );
      expect(s['netWork'], closeTo(s['deltaK']!, 1e-9));
      expect(s['frictionWork'], lessThanOrEqualTo(0));
      expect(s['gravityWork'], 0);
      expect(s['normalWork'], 0);
    }
    final opposed = run(
      0,
      edit: {'v0': 3, 'force': 4, 'angle': 180, 'mu': 0, 'distance': 10},
      time: .5,
    );
    expect(opposed.state['appliedWork'], lessThan(0));
    expect(
      () => run(0, edit: {'m': .2, 'force': 40, 'angle': 90}),
      throwsArgumentError,
    );
  });
  test('Travel includes reversal; differs from signed displacement', () {
    final r = run(
      0,
      edit: {'v0': 1, 'force': 2, 'angle': 180, 'mu': 0, 'distance': 10},
      time: 1,
    );
    expect(r.state['x'], closeTo(0, 1e-10));
    expect(r.state['distance'], closeTo(.5, 1e-5));
    expect(r.state['netWork'], closeTo(r.state['deltaK']!, 1e-9));
  });
  test('Translational energy scaling does not include rolling rotation', () {
    expect(kinetic(2, 5), 25);
    expect(kinetic(2, -5), 25);
    expect(kinetic(2, 10), 100);
    expect(kinetic(4, 5), 50);
    expect(kinetic(2, 5) + .5 * (.4 * 2) * 25, greaterThan(kinetic(2, 5)));
  });
  test('Height-zero shifts U but not lift delta U', () {
    final a = run(2, time: 4), b = run(2, edit: {'zero': 3}, time: 4);
    expect(a.state['deltaU'], b.state['deltaU']);
    expect(a.state['U']! - b.state['U']!, closeTo(3 * standardGravity, 1e-10));
  });
  test('Captive track maintains geometry and ideal energy', () {
    final r = run(3, time: 30);
    expect(r.state['y'], closeTo(r.state['x']! * r.state['x']! / 4, 1e-12));
    expect(r.state['total'], closeTo(r.initialEnergy, 2e-6));
    expect(r.state['loss'], 0);
  });
  test(
    'Generalized track drag removes mechanical energy with consistent budget',
    () {
      final r = run(3, edit: {'drag': 1}, time: 10);
      expect(r.state['mechanical'], lessThan(r.initialEnergy));
      expect(r.state['loss'], greaterThan(0));
      expect(r.state['total'], closeTo(r.initialEnergy, 2e-6));
    },
  );
  test('Steady lifting power and endpoint instant power', () {
    final a = run(4, time: 1), b = run(4, edit: {'duration': 8}, time: 1);
    expect(a.state['power'], closeTo(10 * standardGravity * 2 / 4, 1e-9));
    expect(b.state['power'], closeTo(a.state['power']! / 2, 1e-9));
    expect(a.state['instantPower'], a.state['power']);
    expect(run(4, time: 4).state['instantPower'], 0);
  });
  test('Passive efficiency including zero input and end limits', () {
    for (final eta in [0.0, .8, 1.0]) {
      final r = run(5, edit: {'eta': eta}, time: 5);
      expect(
        r.state['useful']! + r.state['loss']!,
        closeTo(r.state['input']!, 1e-10),
      );
      expect(r.state['loss'], greaterThanOrEqualTo(0));
    }
    expect(
      run(5, edit: {'input': 0}, time: 5).state.values.every((x) => x.isFinite),
      isTrue,
    );
  });
  test('Gravitation inverse-square law and equal/opposite forces', () {
    final a = run(6, edit: {'r': 10}), b = run(6, edit: {'r': 20});
    expect(a.state['force']! / b.state['force']!, closeTo(4, 1e-12));
    expect(a.state['force'], -a.state['force2']!);
    expect(() => run(6, edit: {'r': 1}), throwsArgumentError);
  });
  test('Exterior field and potential gradient agree; no test-mass field dependence', () {
    final a = run(7, edit: {'r': 2, 'angle': 90}),
        h = 10.0,
        r = 2 * earthRadius;
    final derivative =
        (gravityPotential(earthMu, r + h) - gravityPotential(earthMu, r - h)) /
        (2 * h);
    expect(derivative, closeTo(a.state['field']!, 1e-8));
    expect(a.state['gy'], closeTo(-a.state['field']!, 1e-10));
    expect(a.state['gx'], closeTo(0, 1e-10));
    final v = run(8, edit: {'m': 2});
    expect(v.state['U'], closeTo(2 * v.state['potential']!, 1e-8));
    expect(v.state['potential'], lessThan(0));
  });
  test(
    'Circular orbit reference and conservation over multiple revolutions',
    () {
      final radius = 2 * earthRadius,
          vt = math.sqrt(earthMu / radius) / 1000,
          r = run(9, edit: {'vt': vt}, time: 24000);
      expect((r.state['radius']! / radius - 1).abs(), lessThan(5e-6));
      expect(
        (r.state['specificEnergy']! / r.initialEnergy - 1).abs(),
        lessThan(1e-8),
      );
      expect(r.state['angularMomentum'], closeTo(radius * vt * 1000, 2));
      expect(
        r.state['period'],
        closeTo(2 * math.pi * math.sqrt(math.pow(radius, 3) / earthMu), .01),
      );
    },
  );
  test(
    'Verlet orbital timestep convergence for an eccentric initial state',
    () {
      final edits = {'vt': 4.0, 'r': 3.0};
      final a = run(9, edit: edits, time: 8000),
          b = run(9, edit: edits, time: 8000, dt: AdvancedRun.dt / 2),
          ref = run(9, edit: edits, time: 8000, dt: AdvancedRun.dt / 4);
      double error(AdvancedRun r) => Vec2(
        r.state['x']! - ref.state['x']!,
        r.state['y']! - ref.state['y']!,
      ).magnitude;
      expect(error(b), lessThan(error(a) * .3));
    },
  );
  test('Escape energy boundary and collision are independent', () {
    final speed = escapeSpeed(earthMu, 1.2 * earthRadius) / 1000;
    expect(
      run(10, edit: {'vr': speed, 'vt': 0}).state['specificEnergy'],
      closeTo(0, 1e-7),
    );
    expect(run(10, edit: {'vr': speed * .99, 'vt': 0}).state['bound'], 1);
    expect(run(10, edit: {'vr': speed * 1.01, 'vt': 0}).state['bound'], 0);
    final impact = run(10, edit: {'vr': -4, 'vt': 0}, time: 2000);
    expect(impact.impacted, isTrue);
    expect(impact.state['radius'], closeTo(earthRadius, .001));
    expect(impact.state['period'], isNull);
  });
  test('Kepler circular limit and equal-area equal-time sectors', () {
    final a = 4 * earthRadius,
        period = 2 * math.pi * math.sqrt(a * a * a / earthMu),
        s = keplerAt(earthMu, a, 0, period / 4);
    expect(s['x'], closeTo(0, .001));
    expect(s['y'], closeTo(a, .001));
    for (final e in [0.0, .4, .8]) {
      final a0 = keplerAt(earthMu, a, e, 0)['area']!,
          a1 = keplerAt(earthMu, a, e, 100)['area']!,
          a2 = keplerAt(earthMu, a, e, 200)['area']!;
      expect((a1 - a0) / (a2 - a1), closeTo(1, 1e-12));
    }
    expect(() => run(11, edit: {'a': 2, 'e': .8}), throwsArgumentError);
  });
  test('Kepler period cubed-axis law, eccentric speed and focus geometry', () {
    final a = run(11), b = run(11, edit: {'a': 8});
    expect(
      math.pow(b.state['period']! / a.state['period']!, 2),
      closeTo(8, 1e-10),
    );
    final r = 4 * earthRadius,
        e = .4,
        t = a.state['period']!,
        peri = keplerAt(earthMu, r, e, 0),
        apo = keplerAt(earthMu, r, e, t / 2);
    expect(peri['x'], closeTo(r * (1 - e), 1e-6));
    expect(apo['x'], closeTo(-r * (1 + e), 1e-6));
    expect(
      Vec2(peri['vx']!, peri['vy']!).magnitude,
      greaterThan(Vec2(apo['vx']!, apo['vy']!).magnitude),
    );
  });
  test('Exact SHM initial conditions, quarter period and energy', () {
    final r = run(12, edit: {'x0': .2, 'v0': 0}),
        quarter = r.state['period']! / 4,
        s = freeOscillator(1, 20, 0, .2, 0, quarter);
    expect(s.x, closeTo(0, 1e-12));
    expect(s.v, closeTo(-.2 * math.sqrt(20), 1e-12));
    expect(run(14, time: 80).state['total'], closeTo(.225, 1e-12));
  });
  test(
    'Nonlinear pendulum small-angle limit and amplitude-dependent period',
    () {
      final small = pendulumPeriod(1, standardGravity, .001),
          large = pendulumPeriod(1, standardGravity, 70 * math.pi / 180),
          linear = 2 * math.pi / math.sqrt(standardGravity);
      expect(small, closeTo(linear, 2e-7));
      expect(large, greaterThan(linear * 1.09));
    },
  );
  test('Pendulum conserved energy, taut tension and measured period', () {
    final r = run(13, time: 12);
    expect(r.state['total'], closeTo(r.initialEnergy, 2e-8));
    expect(r.samples.every((s) => s['tension']! > 0), isTrue);
    expect(r.state['measuredPeriod'], closeTo(r.state['period']!, .0001));
    expect(
      () => run(13, edit: {'g': 1, 'length': 2, 'angle': 70, 'v0': 2}),
      throwsArgumentError,
    );
  });
  test('Pendulum RK4 convergence', () {
    final a = run(13, time: 8),
        b = run(13, time: 8, dt: AdvancedRun.dt / 2),
        c = run(13, time: 8, dt: AdvancedRun.dt / 4);
    expect(
      (b.state['x']! - c.state['x']!).abs(),
      lessThan((a.state['x']! - c.state['x']!).abs() * .2),
    );
  });
  test('Energy exchange has twice displacement frequency', () {
    final r = run(14),
        period = r.state['period']!,
        a = run(14, time: period / 2),
        b = run(14);
    expect(a.state['U'], closeTo(b.state['U']!, 1e-4));
    expect(a.state['x'], lessThan(0));
  });
  test('Damping regimes match critical threshold; energy never increases', () {
    final critical = 2 * math.sqrt(20);
    for (final b in [1.0, critical, 20.0]) {
      double old = .225;
      for (int i = 0; i < 200; i++) {
        final s = freeOscillator(1, 20, b, .15, 0, i * .05),
            energy = kinetic(1, s.v) + 10 * s.x * s.x;
        expect(energy, lessThanOrEqualTo(old + 1e-12));
        old = energy;
      }
      final s = freeOscillator(1, 20, b, .15, 0, 1);
      expect(s.x.isFinite, isTrue);
    }
    expect(run(15, edit: {'b': critical}).state['regime'], 0);
    expect(run(15, edit: {'b': 20}).state['regime'], 1);
  });
  test('Driven steady amplitude/phase and differential equation', () {
    final w = math.sqrt(20), r = drivenResponse(1, 20, 1, 2, w);
    expect(r.amplitude, closeTo(2 / w, 1e-12));
    expect(r.phase, closeTo(math.pi / 2, 1e-12));
    const h = 1e-4, t = 2.3;
    final a = drivenOscillator(1, 20, 1, 2, 4, .1, .2, t),
        before = drivenOscillator(1, 20, 1, 2, 4, .1, .2, t - h),
        after = drivenOscillator(1, 20, 1, 2, 4, .1, .2, t + h);
    expect(
      (after.v - before.v) / (2 * h) + a.v + 20 * a.x,
      closeTo(2 * math.cos(4 * t), 1e-6),
    );
  });
  test('Undamped resonance grows without silently clipping; initial conditions exact', () {
    final w = math.sqrt(20), a = drivenOscillator(1, 20, 0, 1, w, .15, .2, 0);
    expect(a.x, closeTo(.15, 1e-12));
    expect(a.v, closeTo(.2, 1e-12));
    expect(drivenResponse(1, 20, 0, 1, w).amplitude.isInfinite, isTrue);
    final late = drivenOscillator(1, 20, 0, 1, w, 0, 0, 100);
    expect(late.x.abs(), greaterThan(1));
  });
  test('Natural, damped-free and displacement-peak frequencies differ', () {
    final s = run(16, edit: {'b': 2}).state;
    expect(s['naturalOmega'], greaterThan(s['dampedOmega']!));
    expect(s['dampedOmega'], greaterThan(s['peakOmega']!));
  });
  test('Coupled normal modes match actual spring topology', () {
    final c = CoupledSolution(1, 1, 20, 20, 2);
    expect(c.low, closeTo(math.sqrt(20), 1e-12));
    expect(c.high, closeTo(math.sqrt(24), 1e-12));
    final same = c.at(.1, .1, 0, 0, .7), opposite = c.at(.1, -.1, 0, 0, .7);
    expect(same['x'], closeTo(same['x2']!, 1e-12));
    expect(opposite['x'], closeTo(-opposite['x2']!, 1e-12));
  });
  test('Unequal-mass coupled system energy and equations', () {
    final edits = {
      'm': 2.0,
      'm2': 1.3,
      'k': 30.0,
      'k2': 12.0,
      'kc': 7.0,
      'v0': .2,
      'v2': -.1,
    };
    final r = run(17, edit: edits, time: 35);
    expect(r.state['total'], closeTo(r.initialEnergy, 1e-12));
    final p = r.p,
        c = CoupledSolution(p['m']!, p['m2']!, p['k']!, p['k2']!, p['kc']!),
        t = .7,
        h = 1e-5,
        a = c.at(p['x0']!, p['x2']!, p['v0']!, p['v2']!, t),
        l = c.at(p['x0']!, p['x2']!, p['v0']!, p['v2']!, t - h),
        u = c.at(p['x0']!, p['x2']!, p['v0']!, p['v2']!, t + h);
    expect(
      p['m']! * (u['vx']! - l['vx']!) / (2 * h),
      closeTo(-(p['k']! + p['kc']!) * a['x']! + p['kc']! * a['x2']!, 1e-8),
    );
  });
  test('Coupled energy exchange after a one-mass release', () {
    final a = run(17), b = run(17, time: 8);
    expect(b.state['energy2'], greaterThan(a.state['energy2']! + .03));
    expect(
      b.state['energy1']! + b.state['energy2']!,
      closeTo(b.state['total']!, 1e-12),
    );
  });
  test('All eighteen models have finite state, deterministic replay, bounded samples and valid records', () {
    for (int kind = 0; kind < 18; kind++) {
      final a = run(kind, time: kind >= 9 && kind <= 11 ? 12000 : 35),
          b = run(kind, time: kind >= 9 && kind <= 11 ? 12000 : 35);
      expect(a.state, b.state, reason: 'kind $kind');
      expect(
        a.state.values.every((n) => n.isFinite),
        isTrue,
        reason: 'kind $kind',
      );
      expect(a.samples.length, lessThanOrEqualTo(301));
      expect(a.state[advancedLessons[kind].metric], isNotNull);
      final lesson = advancedLessons[kind],
          quantity = switch (lesson.unit) {
            'J' => 'energy',
            'W' => 'power',
            'N' => 'force',
            'm/s²' => 'acceleration',
            'J/kg' => 'specificEnergy',
            'm/s' => 'speed',
            's' => 'time',
            'kg/s' => 'damping',
            'rad/s' => 'angularFrequency',
            _ => 'efficiency',
          };
      final trial = Trial(
        id: '$kind',
        labId: 's0${5 + kind ~/ 6}-e0${kind % 6}',
        quantity: quantity,
        unit: lesson.unit,
        value: a.state[lesson.metric]!,
        resolution: null,
        configuration: {'parameters': a.p},
        model: advancedVersion,
      );
      expect(Trial.fromJson(trial.toJson()).model, advancedVersion);
    }
  });
}
