import 'dart:math' as math;

import 'advanced.dart';
import 'dynamics.dart' show standardGravity;
import 'measurement.dart' show trackPosition;
import 'waves_optics.dart';
import 'electromagnetism.dart';
import 'electronics_thermal.dart' show probeTemperature;
import 'fluid_modern.dart';

const comparisonVersion = 'comparisons-8.0';
const comparisonNames = [
  'Spring SHM / small-angle pendulum',
  'Electric / gravitational inverse-square fields',
  'Wave superposition / optical interference',
  'Capacitor charging / thermal response',
  'Classical motion / matter-wave detections',
];
const comparisonLabs = [
  ['s07-e00', 's07-e01'],
  ['s10-e01', 's06-e01'],
  ['s08-e02', 's09-e05'],
  ['s10-e03', 's13-e00'],
  ['s03-e00', 's15-e02'],
];
const comparisonConventions = [
  'Common physical time in seconds. Spring displacement m and pendulum angle rad are separate. Pendulum small-angle≤0.1rad; no claim of equal frequencies.',
  'Common radial coordinate in meters outside source exclusions. Electric field N/C and gravitational acceleration m/s² have separate graphs. Positive charge repels a positive test charge; gravity attracts positive mass.',
  'Common controlled phase difference φ, not one physical clock. Classical amplitude envelope m and coherent optical intensity fraction use separate axes. Optical phase is mapped through exact far-field sinθ geometry.',
  'Common normalized response time u=t/τ. Physical RC seconds=uRC; thermal seconds=uτthermal are shown separately. Normalized responses dimensionless; actual V and K remain separate.',
  'Common observation time in seconds. Classical position m is deterministic motion; independent identically prepared matter-wave detector events sample a conditional position probability. No quantum trajectory is drawn.',
];
const comparisonLimits = [
  'Linear undamped spring and small-angle pendulum only. Large-angle pendula differ; damping/nonlinear forces are omitted.',
  'Exterior point/spherical sources only. Gravity does not have negative mass or electrostatic cancellation analogues here.',
  'Equal coherent classical amplitudes and ideal coherent optical slits; no literal mapping of sound energy to photons or particles.',
  'Constant RC and constant-sample first-order thermal probe, not every thermal process or nonlinear diode/capacitance.',
  'One free classical particle versus a statistical ensemble of nonrelativistic electrons. Detection probability is not a classical spatial path or a distribution of classical balls.',
];

class ComparisonModel {
  final int pair;
  final Map<String, double> p;
  final MatterDistribution? matter;
  final List<Map<String, double>> left = [], right = [];
  Map<String, double> values = {};
  ComparisonModel(this.pair, Map<String, double> params)
    : p = Map.of(params),
      matter = pair == 4
          ? MatterDistribution(electronMomentum(100), 20e-9, 100e-9, .3, .002)
          : null {
    if (pair < 0 || pair > 4 || p.values.any((v) => !v.isFinite)) {
      throw ArgumentError('Bounded valid comparison required');
    }
    build();
    at(0);
  }
  double v(String k, double fallback) => p[k] ?? fallback;
  Map<String, double> at(double u) {
    if (u < 0 || u > 20) throw ArgumentError('Comparison coordinate0…20');
    switch (pair) {
      case 0:
        final mass = v('mass', 1),
            k = v('spring', 4),
            length = v('length', 1),
            amplitude = v('amplitude', .1);
        final x = freeOscillator(mass, k, 0, amplitude, 0, u),
            theta = freeOscillator(1, standardGravity / length, 0, .08, 0, u);
        values = {
          'coordinate': u,
          'springPosition': x.x,
          'pendulumAngle': theta.x,
          'springPeriod': 2 * math.pi * math.sqrt(mass / k),
          'pendulumPeriod': 2 * math.pi * math.sqrt(length / standardGravity),
          'springTime': u,
          'pendulumTime': u,
        };
      case 1:
        final r = 1 + u / 20 * 9,
            q = v('charge', 1e-6),
            mass = v('sourceMass', 1e10),
            e = Electrostatic([ChargeSource(V3.zero, q)]).field(V3(r, 0)).x,
            g = -gravitationalConstant * mass / (r * r);
        values = {
          'coordinate': r,
          'electricField': e,
          'gravityField': g,
          'fieldRadius': r,
        };
      case 2:
        final phase = (u / 20 * 4 - 2) * math.pi,
            amp = v('amplitude', .1),
            lambda = 550e-9,
            d = .0002,
            D = 1.0,
            sinTheta = phase * lambda / (2 * math.pi * d),
            y = D * sinTheta / math.sqrt(1 - sinTheta * sinTheta),
            a =
                harmonic(0, 0, amp, 1, 1, 0, 1) +
                harmonic(0, 0, amp, 1, 1, phase, 1),
            b =
                harmonic(0, .25, amp, 1, 1, 0, 1) +
                harmonic(0, .25, amp, 1, 1, phase, 1);
        values = {
          'coordinate': phase,
          'waveEnvelope': math.sqrt(a * a + b * b),
          'opticalIntensity': opticalIntensity(true, lambda, d, D, y),
          'detectorPosition': y,
          'phase': phase,
        };
      case 3:
        final normalized = u / 4,
            r = v('resistance', 10000),
            c = v('capacitance', .0001),
            tau = v('thermalTau', 10),
            voltage = rcState(r, c, 5, 0, normalized * r * c).voltage,
            temp = probeTemperature(350, 300, tau, normalized * tau);
        values = {
          'coordinate': normalized,
          'voltage': voltage,
          'temperature': temp,
          'normalizedCharge': voltage / 5,
          'normalizedThermal': (temp - 300) / 50,
          'rcTime': normalized * r * c,
          'thermalTime': normalized * tau,
        };
      case 4:
        final random = SeededRandom(v('seed', 42).round()),
            count = (u * 50).floor(),
            hist = List.filled(80, 0),
            width = .004 / 80;
        for (int i = 0; i < count; i++) {
          final x = matter!.grid.sample(random),
              bin = ((x + .002) / width).floor().clamp(0, 79);
          hist[bin]++;
        }
        right.clear();
        for (int i = 0; i < 80; i++) {
          final x = -.002 + (i + .5) * width;
          right.add({
            't': x,
            'expected':
                (matter!.grid.cumulative(x + width / 2) -
                    matter!.grid.cumulative(x - width / 2)) /
                width,
            if (count > 0) 'observed': hist[i] / (count * width),
          });
        }
        values = {
          'coordinate': u,
          'classicalPosition': trackPosition(u, v('velocity', 1), 0),
          'detections': count.toDouble(),
          'conditionalIntegral': 1,
        };
    }
    return values;
  }

  void build() {
    for (int i = 0; i <= 240; i++) {
      final s = pair == 4
              ? <String, double>{
                  'coordinate': 20 * i / 240,
                  'classicalPosition': trackPosition(
                    20 * i / 240,
                    v('velocity', 1),
                    0,
                  ),
                }
              : at(20 * i / 240),
          x = s['coordinate']!;
      switch (pair) {
        case 0:
          left.add({'t': x, 'spring': s['springPosition']!});
          right.add({'t': x, 'pendulum': s['pendulumAngle']!});
        case 1:
          left.add({'t': x, 'electric': s['electricField']!});
          right.add({'t': x, 'gravity': s['gravityField']!});
        case 2:
          left.add({'t': x, 'waveEnvelope': s['waveEnvelope']!});
          right.add({'t': x, 'opticalIntensity': s['opticalIntensity']!});
        case 3:
          left.add({'t': x, 'chargeFraction': s['normalizedCharge']!});
          right.add({'t': x, 'thermalFraction': s['normalizedThermal']!});
        case 4:
          left.add({'t': x, 'classicalPosition': s['classicalPosition']!});
      }
    }
  }

  String valueUnit(String key) => switch (key) {
    'springPosition' ||
    'classicalPosition' ||
    'waveEnvelope' ||
    'detectorPosition' ||
    'fieldRadius' => 'm',
    'pendulumAngle' || 'phase' => 'rad',
    'springPeriod' ||
    'pendulumPeriod' ||
    'springTime' ||
    'pendulumTime' ||
    'rcTime' ||
    'thermalTime' => 's',
    'electricField' => 'N/C',
    'gravityField' => 'm/s²',
    'voltage' => 'V',
    'temperature' => 'K',
    'coordinate' =>
      pair == 1
          ? 'm'
          : pair == 2
          ? 'rad'
          : pair == 3
          ? 'normalized t/τ'
          : 's',
    _ => '1',
  };
  List<String> get xLabels => switch (pair) {
    0 => ['Physical time (s)', 'Physical time (s)'],
    1 => ['Radius (m)', 'Radius (m)'],
    2 => ['Phase difference (rad)', 'Phase difference (rad)'],
    3 => ['u=tRC/τRC', 'u=tthermal/τthermal'],
    _ => ['Observation time (s)', 'Detector position (m)'],
  };
  List<String> get units => switch (pair) {
    0 => ['m', 'rad'],
    1 => ['N/C', 'm/s²'],
    2 => ['m', 'relative intensity'],
    3 => ['V/5V', '(T−300K)/50K'],
    _ => ['m', 'm⁻¹'],
  };
}
