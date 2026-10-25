import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:physics_atelier/core/physics/advanced.dart';
import 'package:physics_atelier/features/advanced/curriculum.dart';

void main() {
  AdvancedRun run(
    int kind,
    double t, {
    Map<String, double> edit = const {},
    double dt = AdvancedRun.dt,
  }) => AdvancedRun(kind, {
    ...advancedLessons[kind].defaults,
    ...edit,
  }, stepSize: dt)..seek(t);
  final radius = 2 * earthRadius, speed = math.sqrt(earthMu / radius) / 1000;
  final orbit = run(9, 24000, edit: {'vt': speed});
  final pendulum = run(13, 12),
      track = run(3, 30),
      drag = run(3, 10, edit: {'drag': 1}),
      coupled = run(
        17,
        35,
        edit: {
          'm': 2,
          'm2': 1.3,
          'k': 30,
          'k2': 12,
          'kc': 7,
          'v0': .2,
          'v2': -.1,
        },
      );
  final report = {
    'model': advancedVersion,
    'circularOrbitPhysicalDurationS': orbit.time,
    'circularOrbitRelativeEnergyError':
        (orbit.state['specificEnergy']! / orbit.initialEnergy - 1).abs(),
    'circularOrbitRelativeRadiusError': (orbit.state['radius']! / radius - 1)
        .abs(),
    'trackAbsoluteBudgetErrorJ': (track.state['total']! - track.initialEnergy)
        .abs(),
    'dragTrackAbsoluteBudgetErrorJ': (drag.state['total']! - drag.initialEnergy)
        .abs(),
    'pendulumAbsoluteEnergyErrorJ':
        (pendulum.state['total']! - pendulum.initialEnergy).abs(),
    'pendulumMeasuredMinusPredictedPeriodS':
        pendulum.state['measuredPeriod']! - pendulum.state['period']!,
    'unequalCoupledAbsoluteEnergyErrorJ':
        (coupled.state['total']! - coupled.initialEnergy).abs(),
    'note': 'Actual deterministic computed reference cases, not physical sensor measurements. Timestep convergence assertions are in advanced_science_test.dart.',
  };
  final output = File('screenshots/phase3-numerics.json');
  output.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
}
