import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/core/physics/electronics_thermal.dart';
import 'package:physics_atelier/features/electronics_thermal/curriculum.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';

void main() {
  test(
    'Intrinsic and both doped limits satisfy neutrality and mass action',
    () {
      for (final t in [250.0, 300.0, 400.0]) {
        for (int m = 0; m < 3; m++) {
          for (final d in [0.0, 1e16, 1e21]) {
            final s = semiconductor(t, d, m);
            expect(
              s['electrons']! * s['holes']! / math.pow(s['ni']!, 2),
              closeTo(1, 1e-14),
            );
            expect(
              s['neutrality']!.abs(),
              lessThan(math.max(math.max(d, s['ni']!), 1e16) * 1e-14),
            );
            if (m == 0) {
              expect(s['electrons'], s['holes']);
            }
            if (m == 1) {
              expect(s['electrons']!, greaterThanOrEqualTo(s['holes']!));
            }
            if (m == 2) {
              expect(s['holes']!, greaterThanOrEqualTo(s['electrons']!));
            }
          }
        }
      }
    },
  );
  test('Semiconductor validity and intrinsic anchor', () {
    expect(
      semiconductor(300, 0, 0)['conductivity'],
      closeTo(.00030441356046, 1e-12),
    );
    expect(() => semiconductor(200, 0, 0), throwsArgumentError);
    expect(() => semiconductor(300, 1e22, 1), throwsArgumentError);
  });
  test('Diode operating points obey KVL and nonlinear current', () {
    for (final vs in [-5.0, 0.0, .2, 1.0, 12.0]) {
      for (final t in [250.0, 300.0, 400.0]) {
        final s = seriesDiode(vs, 1000, t, 1.5, 1e-12);
        expect(s['diodeVoltage']! + s['current']! * 1000, closeTo(vs, 1e-8));
        expect(s.values.every((x) => x.isFinite), isTrue);
      }
    }
  });
  test('Diode solver failure and overflow bracket are explicit', () {
    expect(
      () => seriesDiode(1, 1000, 300, 1.5, 1e-12, maxIterations: 0),
      throwsArgumentError,
    );
    expect(seriesDiode(12, 100, 250, 1, 1e-14)['current']!, lessThan(.12));
  });
  test('Diode forward voltage varies with load and temperature', () {
    final a = seriesDiode(1, 1000, 300, 1.5, 1e-12),
        b = seriesDiode(1, 10000, 300, 1.5, 1e-12),
        c = seriesDiode(1, 1000, 350, 1.5, 1e-12);
    expect(a['diodeVoltage'], isNot(b['diodeVoltage']));
    expect(a['diodeVoltage'], isNot(c['diodeVoltage']));
  });
  test('NPN cutoff active and saturation lie on load line', () {
    for (final drive in [.2, .8, 5.0]) {
      final s = npn(drive, 10000, 5, 1000, 100);
      expect(
        s['emitterCurrent'],
        closeTo(s['baseCurrent']! + s['collectorCurrent']!, 1e-15),
      );
      expect(s['vce']! + 1000 * s['collectorCurrent']!, closeTo(5, 1e-12));
      expect(
        s['collectorCurrent'],
        closeTo(
          transistorCharacteristic(s['vce']!, s['baseCurrent']!, 100),
          1e-12,
        ),
      );
    }
    expect(npn(.2, 10000, 5, 1000, 100)['region'], 0);
    expect(npn(.8, 10000, 5, 1000, 100)['region'], 1);
    expect(npn(5, 10000, 5, 1000, 100)['region'], 2);
  });
  test('Amplifier gain inversion and rail clipping', () {
    final a = amplifier(.125, .2, 0, 2, 10000, 2000, 5, .2, 0),
        b = amplifier(.125, .2, 0, 2, 10000, 2000, 5, .2, 1);
    expect(a['gain'], 6);
    expect(b['gain'], -5);
    expect(a['outputVoltage'], closeTo(1.2, 1e-12));
    expect(b['outputVoltage'], closeTo(-1, 1e-12));
    expect(
      amplifier(.125, 1, 0, 2, 100000, 1000, 5, .2, 0)['outputVoltage'],
      4.8,
    );
  });
  test('All seven truth tables independently enumerated', () {
    const truth = [
      [false, false, false, true],
      [false, true, true, true],
      [true, true, false, false],
      [true, true, true, false],
      [true, false, false, false],
      [false, true, true, false],
      [true, false, false, true],
    ];
    for (int g = 0; g < 7; g++) {
      for (int i = 0; i < 4; i++) {
        expect(logicGate(g, i >= 2, i.isOdd), truth[g][i]);
      }
    }
  });
  test('Sensor temperature calibration and strict range', () {
    expect(
      sensor(0, 298.15, 100, 1, 293.15)['sensorOutput'],
      closeTo(.75, 1e-12),
    );
    expect(() => sensor(0, 220, 100, 1, 293.15), throwsArgumentError);
    expect(sensor(0, 233.15, 0, 1, 293.15)['sensorOutput'], closeTo(.1, 1e-12));
  });
  test('LDR divider reuses circuit solution and flags saturation', () {
    expect(
      sensor(1, 300, 100, 1, 293.15)['sensorOutput'],
      closeTo(1.65, 1e-12),
    );
    expect(sensor(1, 300, 20000, 1, 293.15)['saturated'], 1);
    expect(
      sensor(1, 300, 10000, 1, 293.15)['sensorOutput']!,
      greaterThan(sensor(1, 300, 1, 1, 293.15)['sensorOutput']!),
    );
  });
  test('Ultrasonic time of flight and no echo limits', () {
    final s = sensor(2, 300, 0, 1, 293.15);
    expect(s['sensorOutput'], closeTo(2 / (331.3 + .606 * 20), 1e-12));
    expect(s['echoDistance'], closeTo(1, 1e-14));
    expect(() => sensor(2, 300, 0, .01, 293.15), throwsArgumentError);
    expect(() => sensor(2, 300, 0, 4.01, 293.15), throwsArgumentError);
  });
  test('Kelvin Celsius Fahrenheit and absolute zero', () {
    expect(fromCelsius(58.4), closeTo(331.55, 1e-10));
    expect(fahrenheit(331.55), closeTo(137.12, 1e-10));
    expect(celsius(0), -273.15);
    expect(() => fromCelsius(-274), throwsArgumentError);
  });
  test('Probe initial value, one tau and limiting value', () {
    expect(probeTemperature(333, 293, 4, 0), 293);
    expect(probeTemperature(333, 293, 4, 4), closeTo(333 - 40 / math.e, 1e-12));
    expect(probeTemperature(333, 293, 4, 1000), 333);
  });
  test('Finite sample probe degeneracy and energy conservation', () {
    final s = coolingProbe(333, 293, 293, 4, 4, 4, 1000);
    expect(s['sampleTemperature'], closeTo(293 + 40 / math.e, 1e-10));
    expect(s['probeTemperature'], closeTo(293 + 40 / math.e, 1e-10));
    expect(s['energyResidual'], 0);
  });
  test('Conduction sign and area length scaling', () {
    final q = conduction(205, .0002, 333, 293, .2);
    expect(q, closeTo(8.2, 1e-12));
    expect(conduction(205, .0004, 333, 293, .2), 2 * q);
    expect(conduction(205, .0002, 293, 333, .2), -q);
    expect(conduction(205, .0002, 333, 293, .4), q / 2);
  });
  test('Convection equilibrium and Biot rejection', () {
    final a = convection(333, 293, 12, .05, .25, 900, 205, 2700, 375);
    expect(a['temperature'], closeTo(293 + 40 / math.e, 1e-10));
    expect(a['deltaU']! + a['heatOut']!, 0);
    expect(
      () => convection(333, 293, 100, .01, 1, 900, .1, 1000, 1),
      throwsArgumentError,
    );
  });
  test('Radiation equilibrium sign and absolute temperature fourth power', () {
    expect(radiationRate(300, 300, .8, .1), 0);
    expect(
      radiationRate(333, 293, .8, .1),
      closeTo(
        .8 * stefanBoltzmann * .1 * (math.pow(333, 4) - math.pow(293, 4)),
        1e-10,
      ),
    );
    expect(radiationRate(293, 333, .8, .1), lessThan(0));
  });
  test('Radiation RK4 convergence and energy flux ledger', () {
    final coarse = radiationStep(350, 290, .8, .1, 225, 100),
        half = radiationStep(350, 290, .8, .1, 225, 50),
        fine = radiationStep(half.temperature, 290, .8, .1, 225, 50);
    expect(coarse.temperature, closeTo(fine.temperature, 1e-4));
    expect(coarse.heat, closeTo(225 * (350 - coarse.temperature), 1e-9));
    expect(coarse.temperature, greaterThan(290));
  });
  test('All ideal gas processes obey state equation and first law', () {
    for (int m = 0; m < 4; m++) {
      for (final ratio in [.8, 1.0, 2.0]) {
        final s = gasProcess(m, .1, 300, .0025, ratio, 1.2, 1);
        expect(
          s['pressure']! * s['volume']!,
          closeTo(.1 * gasConstant * s['temperature']!, 1e-10),
        );
        expect(s['energyResidual'], closeTo(0, 1e-10));
        if (m == 0) {
          expect(s['temperature'], 300);
        }
        if (m == 1) {
          expect(s['work'], 0);
        }
        if (m == 2) {
          expect(s['pressure'], closeTo(s['initialPressure']!, 1e-8));
        }
        if (m == 3) {
          expect(s['heat'], 0);
          expect(
            s['pressure']! * math.pow(s['volume']!, gamma),
            closeTo(s['initialPressure']! * math.pow(.0025, gamma), 1e-10),
          );
        }
      }
    }
  });
  test('Independent isothermal and isochoric references', () {
    expect(
      gasProcess(0, .1, 300, .0025, 2, 1, 1)['work'],
      closeTo(.1 * gasConstant * 300 * math.log(2), 1e-10),
    );
    expect(
      gasProcess(1, .1, 300, .0025, 2, 1.1, 1)['heat'],
      closeTo(.1 * monatomicCv * 30, 1e-10),
    );
  });
  test('Entropy free expansion and reversed state', () {
    final s = gasEntropy(.1, 300, .0025, 300, .005);
    expect(s, closeTo(.1 * gasConstant * math.log(2), 1e-12));
    expect(gasEntropy(.1, 300, .005, 300, .0025), closeTo(-s, 1e-12));
    expect(gasEntropy(.1, 300, .0025, 300, .0025), 0);
  });
  test('Two finite bodies conserve energy and increase total entropy', () {
    double last = -1;
    for (final t in [0.0, 1.0, 10.0, 100.0, 10000.0]) {
      final s = thermalContact(343, 293, 500, 700, 10, t);
      expect(s['energyResidual'], closeTo(0, 1e-7));
      expect(s['entropy']!, greaterThanOrEqualTo(last));
      last = s['entropy']!;
    }
    final s = thermalContact(343, 293, 500, 700, 10, 10000);
    expect(
      s['body1Temperature'],
      closeTo((500 * 343 + 700 * 293) / 1200, 1e-9),
    );
    expect(s['body1Temperature'], closeTo(s['body2Temperature']!, 1e-9));
  });
  test('Carnot stage continuity cycle closure and heat work balance', () {
    final initial = carnot(.1, 600, 300, .002, 2, 0);
    for (final phase in [1.0, 2.0, 3.0, 4.0]) {
      final s = carnot(.1, 600, 300, .002, 2, phase);
      expect(s['energyResidual'], closeTo(0, 1e-9));
      final before = carnot(.1, 600, 300, .002, 2, phase - 1e-8);
      expect(s['temperature'], closeTo(before['temperature']!, 1e-4));
      expect(s['volume'], closeTo(before['volume']!, 1e-9));
    }
    final end = carnot(.1, 600, 300, .002, 2, 4);
    expect(end['volume'], closeTo(initial['volume']!, 1e-12));
    expect(end['pressure'], closeTo(initial['pressure']!, 1e-7));
    expect(end['efficiency'], .5);
    expect(end['work'], closeTo(end['heat']!, 1e-9));
    expect(end['work'], closeTo(end['netWorkReference']!, 1e-9));
  });
  test('Carnot P–V integral converges to net work', () {
    double area(int steps) {
      double w = 0;
      var prev = carnot(.1, 600, 300, .002, 2, 0);
      for (int i = 1; i <= steps; i++) {
        final s = carnot(.1, 600, 300, .002, 2, 4 * i / steps);
        w +=
            (s['pressure']! + prev['pressure']!) /
            2 *
            (s['volume']! - prev['volume']!);
        prev = s;
      }
      return w;
    }

    final expected = carnot(.1, 600, 300, .002, 2, 4)['netWorkReference']!;
    expect(
      (area(1600) - expected).abs(),
      lessThan((area(160) - expected).abs()),
    );
    expect(area(1600), closeTo(expected, .002));
  });
  test(
    'Every model default and every mode are finite with coherent metrics',
    () {
      for (int k = 0; k < 12; k++) {
        for (int m = 0; m < etModes[k].length; m++) {
          final run = ETRun(k, etLessons[k].defaults, mode: m);
          expect(run.invalid, isEmpty, reason: '$k:$m');
          expect(run.state[etLessons[k].metric], isNotNull);
          expect(run.state.values.every((v) => v.isFinite), isTrue);
          expect(run.profile, isNotEmpty);
          if (run.dynamicLab) {
            run.seek(run.maxTime);
            expect(run.invalid, isEmpty);
            expect(
              run.finished,
              isTrue,
              reason: '$k:$m time=${run.time} max=${run.maxTime}',
            );
          }
        }
      }
    },
  );
  test('Numerical radiation and amplifier deterministic replay', () {
    for (final k in [3, 6, 7, 8, 9, 10, 11]) {
      final m = k == 7 ? 2 : 0, a = ETRun(k, etLessons[k].defaults, mode: m);
      for (int i = 0; i < 600; i++) {
        a.step();
      }
      a.refresh();
      final b = ETRun(k, etLessons[k].defaults, mode: m)..seek(a.time);
      expect(b.state, a.state, reason: 'kind $k');
    }
  });
  test('Logic event timing survives replay and bounded history', () {
    final a = ETRun(4, etLessons[4].defaults);
    for (int i = 0; i < 120; i++) {
      a.step();
    }
    a.setLogicInput('inputA', 1);
    for (int i = 0; i < 120; i++) {
      a.step();
    }
    a.setLogicInput('inputB', 0);
    a.refresh();
    final b = ETRun(4, a.initial)..seek(a.time, inputEvents: a.events);
    expect(b.state, a.state);
    expect(b.events, a.events);
    expect(b.p, a.p);
  });
  test('Logic changes between sample ticks are vertical timing edges', () {
    final run = ETRun(4, etLessons[4].defaults);
    for (int i = 0; i < 13; i++) {
      run.step();
    }
    run.setLogicInput('inputA', 1);
    expect(run.samples[run.samples.length - 2]['t'], run.time);
    expect(run.samples.last['t'], run.time);
  });
  test('New trial units round-trip without changing old model allowance', () {
    for (final data in [
      ('conductivity', 'S/m'),
      ('temperature', 'K'),
      ('gain', ''),
      ('logicState', ''),
      ('pressure', 'Pa'),
      ('entropy', 'J/K'),
    ]) {
      final t = Trial(
        id: data.$1,
        labId: 's12-e00',
        quantity: data.$1,
        unit: data.$2,
        value: 1,
        resolution: null,
        configuration: {},
        model: etVersion,
      );
      expect(Trial.fromJson(t.toJson()).unit, data.$2);
    }
  });
}
