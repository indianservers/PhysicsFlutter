import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/core/physics/advanced.dart';
import 'package:physics_atelier/core/physics/astronomy.dart';
import 'package:physics_atelier/core/physics/dynamics.dart';
import 'package:physics_atelier/core/physics/electromagnetism.dart';
import 'package:physics_atelier/core/physics/electronics_thermal.dart';
import 'package:physics_atelier/core/physics/fluid_modern.dart';
import 'package:physics_atelier/core/physics/supplemental_labs.dart';
import 'package:physics_atelier/core/physics/waves_optics.dart';
import 'package:physics_atelier/features/advanced/curriculum.dart' as advanced;
import 'package:physics_atelier/features/dynamics/curriculum.dart' as dynamics;

void main() {
  test('Stellar endpoint uses one consistent final data row, including phase transitions', () {
    for (int track = 0; track < stellarTracks.length; track++) {
      for (final fraction in [0.0, 1.0]) {
        final row = fraction == 0
            ? stellarTracks[track].first
            : stellarTracks[track].last;
        final s = stellar(track, fraction);
        expect(s['age'], closeTo(row[0] * julianYear, 1));
        expect(s['logL'], closeTo(row[1], 1e-12));
        expect(s['logT'], closeTo(row[2], 1e-12));
        expect(s['phase'], row[3]);
        final luminosity =
            4 *
            math.pi *
            math.pow(s['radius']!, 2) *
            stefanBoltzmann *
            math.pow(s['temperature']!, 4);
        expect(luminosity / s['luminosity']!, closeTo(1, 1e-12));
      }
    }
  });

  test(
    'PCM analysis retains Nyquist peaks, their one-sided scaling, and silence',
    () {
      for (final windowed in [false, true]) {
        final signal = [for (int i = 0; i < 2048; i++) (i.isEven ? .7 : -.7)];
        final spectrum = Spectrum.analyze(signal, 16384, hann: windowed);
        expect(spectrum.peakFrequency, 8192);
        expect(spectrum.peakAmplitude, closeTo(.7, 1e-12));
        expect(spectrum.rms, closeTo(.7, 1e-12));
        final quiet = Spectrum.analyze(
          List.filled(2048, .2),
          16384,
          hann: windowed,
        );
        expect(quiet.peakFrequency, 0);
        expect(quiet.peakAmplitude, lessThan(1e-12));
      }
    },
  );

  test('Forced oscillator distinguishes drive period from natural and transient motion', () {
    final s = AdvancedRun(16, {
      ...advanced.advancedLessons[16].defaults,
      'omega': 2.0,
    }).state;
    expect(s['drivePeriod'], closeTo(math.pi, 1e-12));
    expect(s['driveFrequency'], closeTo(1 / math.pi, 1e-12));
    expect(
      s['period'],
      isNull,
      reason: 'a transient has no unique repeating period',
    );
    expect(s['naturalPeriod'], isNot(closeTo(s['drivePeriod']!, 1e-3)));
  });

  test(
    'Pulley accelerations and both force equations use the selected gravity',
    () {
      for (final g in [1.62, standardGravity, 20.0]) {
        for (int mode = 0; mode < 2; mode++) {
          final run = DynamicsRun(2, {
            ...dynamics.lessons[2].defaults,
            'm': 3.0,
            'm2': 2.0,
            'g': g,
          }, mode: mode);
          final s = run.state, a = s['ax']!, tension = s['tension']!;
          expect(
            (mode == 0 ? tension : 2 * tension) - 3 * g,
            closeTo(3 * a, 1e-12),
          );
          expect(2 * g - tension, closeTo(2 * (mode == 0 ? a : 2 * a), 1e-12));
          run.seek(.1);
          expect(run.state['vx'], closeTo(a * .1, 1e-12));
        }
      }
      expect(() => atwood(0, 1), throwsArgumentError);
      expect(
        () => movablePulley(1, 1, gravity: double.nan),
        throwsArgumentError,
      );
      expect(
        () => DynamicsRun(0, {
          ...dynamics.lessons[0].defaults,
          'm': 1.0,
          'g': 1.62,
          'force': 2.0,
          'angle': 90.0,
        }),
        throwsArgumentError,
      );
      expect(
        () => DynamicsRun(16, {
          ...dynamics.lessons[16].defaults,
          'g': 1.62,
          'a': -2.0,
        }),
        throwsArgumentError,
      );
    },
  );

  test(
    'RC capacitor power ledger closes throughout charging and discharging',
    () {
      for (final source in [-5.0, 0.0, 5.0]) {
        for (final initial in [-2.0, 0.0, 3.0]) {
          const r = 4700.0, c = 220e-6;
          for (final f in [.0, .1, 1.0, 4.0]) {
            final t = f * r * c, s = rcState(r, c, source, initial, t);
            final storedRate = s.voltage * s.current;
            expect(
              source * s.current - r * s.current * s.current,
              closeTo(storedRate, 1e-14),
            );
            const h = 1e-5;
            final after = rcState(r, c, source, initial, t + h);
            final before = rcState(r, c, source, initial, t - (t == 0 ? 0 : h));
            final derivative = t == 0
                ? (-3 * s.energy +
                          4 * after.energy -
                          rcState(r, c, source, initial, 2 * h).energy) /
                      (2 * h)
                : (after.energy - before.energy) / (2 * h);
            expect(derivative, closeTo(storedRate, 3e-8));
          }
        }
      }
    },
  );

  test('All gas constraints obey first law; adiabatic entropy is constant', () {
    for (int mode = 0; mode < 4; mode++) {
      for (final ratio in [.75, 1.0, 3.0]) {
        for (final f in [0.0, .3, 1.0]) {
          final s = gasProcess(mode, .1, 300, .002, ratio, 1.5, f);
          expect(
            s['pressure']! *
                s['volume']! /
                (.1 * gasConstant * s['temperature']!),
            closeTo(1, 1e-12),
          );
          expect(s['deltaU']! - s['heat']! + s['work']!, closeTo(0, 1e-10));
          if (mode == 3) {
            expect(
              gasEntropy(.1, 300, .002, s['temperature']!, s['volume']!),
              closeTo(0, 1e-12),
            );
          }
        }
      }
    }
  });

  test(
    'Thermal contact and radiation preserve energy and move heat hot to cold',
    () {
      for (final t1 in [280.0, 350.0]) {
        for (final t2 in [280.0, 350.0]) {
          final state = thermalContact(t1, t2, 100, 300, 4, 20);
          expect(state['energyResidual'], closeTo(0, 1e-10));
          expect(state['entropy']!, greaterThanOrEqualTo(-1e-12));
          final step = radiationStep(t1, t2, .8, .1, 100, 10);
          expect(step.heat + 100 * (step.temperature - t1), closeTo(0, 1e-10));
          expect(
            step.temperature,
            inInclusiveRange(math.min(t1, t2), math.max(t1, t2)),
          );
        }
      }
    },
  );

  test(
    'Fluid pressure, Stokes drag and buoyancy satisfy their force balances',
    () {
      for (final rho in [800.0, 1000.0, 1400.0]) {
        final a = densityPressure(rho, .2, 101325, 101325, .2, .0002);
        final b = densityPressure(rho, .4, 101325, 101325, .2, .0002);
        expect(
          (b['absolutePressure']! - a['absolutePressure']!) / .2,
          closeTo(rho * standardGravity, 1e-9),
        );
        final s = stokes(.0005, 2500, rho, 1, .1, .0001);
        final next = stokes(.0005, 2500, rho, 1, .1, .00010001);
        final mass = 2500 * 4 / 3 * math.pi * math.pow(.0005, 3);
        expect(
          mass * (next['speed']! - s['speed']!) / 1e-8,
          closeTo(s['netForceDown']!, 1e-9),
        );
        final float = buoyancy(rho, rho * .6, .08, .06, .12, .09, 0);
        expect(float['submergedFraction'], closeTo(.6, 1e-12));
        expect(float['freeNetForceUp'], closeTo(0, 1e-12));
      }
    },
  );

  test('Coupled oscillators conserve energy with unequal masses and spring constants', () {
    final p = {
      ...advanced.advancedLessons[17].defaults,
      'm': .2,
      'm2': 4.0,
      'k': 80.0,
      'k2': 5.0,
      'kc': 3.0,
      'x0': .2,
      'x2': -.1,
      'v0': .3,
      'v2': -.2,
    };
    final initial = AdvancedRun(17, p).state['total']!;
    for (final t in [.5, 3.0, 15.0]) {
      final run = AdvancedRun(17, p)..seek(t);
      expect(run.state['total'], closeTo(initial, 1e-11));
    }
  });

  test('RLC AC waveforms satisfy instantaneous Kirchhoff voltage law', () {
    final lab = supplementalLabs.firstWhere((l) => l.kind == 10),
        p = lab.defaults;
    final w = 2 * math.pi * p['frequency']!;
    for (final f in [.1, .3, .8]) {
      final t = f / p['frequency']!, s = lab.evaluate(p, t);
      final peak = math.sqrt2 * s['rmsCurrent']!, phase = s['phase']!;
      final theta = w * t - phase;
      final vr = p['resistance']! * s['current']!;
      final vl = p['inductance']! * peak * w * math.cos(theta);
      final vc = -peak / (w * p['capacitance']!) * math.cos(theta);
      expect(
        vr + vl + vc,
        closeTo(math.sqrt2 * p['supply']! * math.sin(w * t), 1e-10),
      );
    }
  });

  test('Quantum eigenstates, photons and isotope composition have consistent limits', () {
    for (int n = 1; n <= 6; n++) {
      expect(
        wellEnergy(1e-9, electronMass, n) / wellEnergy(1e-9, electronMass, 1),
        closeTo(n * n, 1e-12),
      );
      expect(wellPsi(0, 1e-9, electronMass, n), 0);
      expect(wellPsi(1e-9, 1e-9, electronMass, n), 0);
    }
    final transition = hydrogenTransition(2, 3);
    expect(
      transition['upperEnergy']! - transition['lowerEnergy']!,
      closeTo(transition['photonEnergy']!, 1e-30),
    );
    for (int i = 0; i < isotopes.length; i++) {
      final s = nuclear(i);
      expect(s['protons']! + s['neutrons']!, s['massNumber']);
      expect(s['bindingEnergy']!, greaterThan(0));
    }
  });
}
