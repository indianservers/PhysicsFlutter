import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/content/learning.dart';
import 'package:physics_atelier/core/physics/supplemental_labs.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';

void main() {
  SupplementalLab lab(int k) => supplementalLabs.firstWhere((l) => l.kind == k);
  Map<String, double> value(
    int k, [
    Map<String, double> overrides = const {},
    double t = 0,
  ]) => lab(k).evaluate({...lab(k).defaults, ...overrides}, t);
  test('Twenty appended labs keep all original catalog identities and path progress', () {
    expect(supplementalLabs.length, 20);
    expect(allEntries.length, 122);
    expect(labInventory.length, 116);
    for (int studio = 0; studio < 17; studio++) {
      for (int i = 0; i < 6; i++) {
        final e = entryById('s${studio.toString().padLeft(2, '0')}-e0$i');
        expect(e.studioIndex, studio);
        expect(e.index, i);
        expect(e.supplemental, false);
      }
    }
    for (final l in supplementalLabs) {
      final e = entryById(l.id);
      expect(e.supplemental, true);
      expect(e.interactive, true);
      expect(
        e.dynamics ||
            e.advanced ||
            e.wavesOptics ||
            e.electromagnetism ||
            e.electronicsThermal ||
            e.fluidModern ||
            e.astronomy,
        false,
      );
      expect(stageFor(e), l.stage);
      expect(filterLabs(query: l.title).map((e) => e.id), contains(l.id));
    }
    for (final path in learningPaths) {
      final originalRequired = path.activities
          .where((e) => e.index < 5)
          .map((e) => e.id)
          .toSet();
      expect(path.progress(originalRequired), 1);
      expect(path.requiredActivities.every((e) => !e.supplemental), true);
    }
  });
  for (final l in supplementalLabs) {
    test(
      '${l.title}: finite defaults, boundaries, curves and durable trial',
      () {
        final p = l.defaults;
        expect(l.invalid(p), isEmpty);
        expect(l.duration(p), greaterThan(0));
        for (final fraction in [0.0, .25, .5, .75, 1.0]) {
          final s = l.evaluate(p, l.duration(p) * fraction);
          expect(s[l.quantity], isNotNull);
          expect(s.values.every((v) => v.isFinite), true);
        }
        expect(l.curve(p).length, 241);
        expect(
          l.curve(p).every((s) => s.values.every((v) => v.isFinite)),
          true,
        );
        for (final c in l.inputs) {
          for (final x in [c.min, c.max]) {
            final changed = {...p, c.key: x};
            final s = l.evaluate(changed, 0);
            expect(
              l.invalid(changed).isNotEmpty ||
                  s.values.every((v) => v.isFinite),
              true,
            );
          }
        }
        expect(l.evaluate({...p, l.inputs.first.key: double.nan}, 0), isEmpty);
        expect(l.evaluate(p, double.nan), isEmpty);
        expect(l.evaluate(p, -1), isEmpty);
        final t = Trial(
          id: 'test',
          labId: l.id,
          quantity: l.quantity,
          unit: l.unit,
          value: l.evaluate(p, 0)[l.quantity]!,
          resolution: null,
          configuration: {'model': supplementalVersion, 'parameters': p},
          model: supplementalVersion,
        );
        expect(Trial.fromJson(t.toJson()).toJson(), t.toJson());
      },
    );
  }
  test(
    'Rotational work equals kinetic energy; inertia scales with radius squared',
    () {
      final s = value(0, {}, 3);
      expect(
        s['energy'],
        closeTo(lab(0).defaults['torque']! * s['angle']!, 1e-12),
      );
      expect(
        value(0, {'radius': .6})['inertia'],
        closeTo(4 * value(0)['inertia']!, 1e-12),
      );
    },
  );
  test('Rolling sphere conserves gravitational energy and rejects slipping conditions', () {
    final p = lab(1).defaults, s = value(1, {}, lab(1).duration(p));
    expect(s['distance'], closeTo(p['length']!, 1e-10));
    expect(
      s['energy'],
      closeTo(
        p['mass']! *
            9.80665 *
            p['length']! *
            math.sin(p['incline']! * math.pi / 180),
        1e-10,
      ),
    );
    expect(value(1, {'friction': 0}), isEmpty);
  });
  test('Hooke and Young scaling follow independent analytic expectations', () {
    expect(value(2, {'extension': .16})['force'], 2 * value(2)['force']!);
    expect(value(2, {'extension': .16})['energy'], 4 * value(2)['energy']!);
    expect(
      value(3, {'radius': .001})['length'],
      closeTo(value(3)['length']! / 4, 1e-15),
    );
    expect(value(3, {'force': 150, 'radius': .0002, 'modulus': 1e10}), isEmpty);
  });
  test('Free fall stops at ground with the analytic impact speed', () {
    final p = lab(4).defaults, s = value(4, {}, 100);
    expect(s['height'], closeTo(0, 1e-12));
    expect(
      s['speed'],
      closeTo(math.sqrt(2 * p['gravity']! * p['height']!), 1e-10),
    );
  });
  test('Torsion returns after one period and preserves energy', () {
    final p = lab(5).defaults, s = value(5), end = value(5, {}, s['period']!);
    expect(end['angle'], closeTo(s['angle']!, 1e-12));
    expect(
      value(5, {'inertia': p['inertia']! * 4})['period'],
      closeTo(s['period']! * 2, 1e-12),
    );
    final q = value(5, {}, .731);
    expect(
      .5 * p['inertia']! * q['angularSpeed']! * q['angularSpeed']! +
          .5 * p['torsion']! * q['angle']! * q['angle']!,
      closeTo(q['energy']!, 1e-12),
    );
  });
  test('Beats envelope and crossed polarizers have correct nulls', () {
    expect(value(6, {'difference': 0}, 1)['envelope'], .4);
    expect(value(6, {}, 1 / 6)['envelope'], closeTo(0, 1e-12));
    expect(value(7, {'angle': 90})['intensity'], closeTo(0, 1e-25));
    expect(value(7, {'angle': 0})['intensity'], 30);
  });
  test('Resistivity and Wheatstone balance use correct circuit topology', () {
    expect(
      value(8, {'radius': .001})['resistance'],
      closeTo(value(8)['resistance']! / 4, 1e-12),
    );
    expect(value(9)['voltage'], 0);
    expect(value(9)['balancedResistance'], 300);
    expect(value(9, {'unknown': 600})['voltage'], lessThan(0));
  });
  test('RLC resonance has unity power factor and RMS power I squared R', () {
    final p = lab(10).defaults,
        f = 1 / (2 * math.pi * math.sqrt(p['inductance']! * p['capacitance']!)),
        s = value(10, {'frequency': f});
    expect(s['impedance'], closeTo(p['resistance']!, 1e-10));
    expect(s['phase'], closeTo(0, 1e-12));
    expect(s['power'], closeTo(p['supply']! * s['rmsCurrent']!, 1e-10));
  });
  test(
    'Transformer conserves power and rectifier doubles ripple frequency',
    () {
      final p = lab(11).defaults, s = value(11);
      expect(s['rmsVoltage'], 24);
      expect(s['power'], closeTo(p['supply']! * s['primaryCurrent']!, 1e-12));
      expect(value(12)['rippleFrequency'], 100);
      expect(value(12)['rippleFactor'], closeTo(.4834258476, 1e-9));
      expect(value(12, {}, .015)['voltage'], closeTo(12 * math.sqrt2, 1e-10));
    },
  );
  test('Calorimetry closes the energy ledger including calorimeter', () {
    final s = value(13);
    expect(
      s['hotHeat']! + s['coldHeat']! + s['calorimeterHeat']!,
      closeTo(0, 1e-8),
    );
    expect(s['temperature'], inInclusiveRange(293.15, 353.15));
  });
  test(
    'Heating curve has both latent heat plateaus and correct terminal state',
    () {
      final p = lab(14).defaults,
          m = p['mass']!,
          power = p['power']!,
          q1 = -m * 2100 * p['initial']!;
      expect(
        value(14, {}, (q1 + m * 334000 * .5) / power)['temperature'],
        273.15,
      );
      final q3 = q1 + m * 334000 + m * 418600;
      expect(
        value(14, {}, (q3 + m * 2256000 * .5) / power)['temperature'],
        373.15,
      );
      final end = value(14, {}, lab(14).duration(p));
      expect(end['vapourFraction'], closeTo(1, 1e-12));
      expect(end['temperature'], 373.15);
    },
  );
  test('Capillarity sign, scattering limits, Lorentz factor and parallax convention', () {
    expect(value(15, {'angle': 90})['length'], closeTo(0, 1e-15));
    expect(value(15, {'angle': 120})['length'], lessThan(0));
    expect(value(16, {'impact': 0})['angle'], 180);
    expect(
      value(16, {'impact': 100})['angle'],
      lessThan(value(16, {'impact': 20})['angle']!),
    );
    expect(value(17, {'beta': .6})['gamma'], 1.25);
    expect(value(17, {'beta': 0})['length'], 4);
    expect(value(18)['parallax'], closeTo(100, 1e-7));
    expect(value(18)['fullShift'], 2 * value(18)['parallax']!);
    expect(value(18, {'distance': 20})['parallax'], closeTo(50, 1e-7));
    expect(value(19)['length'], closeTo(.0012, 1e-15));
  });
}
