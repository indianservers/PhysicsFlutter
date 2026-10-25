import 'dart:math' as math;

import 'fluid_modern.dart';
import 'electromagnetism.dart' show elementaryCharge;
import 'waves_optics.dart' show lightSpeed;
export 'fluid_modern.dart';

const fmModeCounts = [1, 2, 2, 1, 1, 1, 1, 2, 2, 6, 8, 2];

class FMRun {
  final int kind, mode;
  final FMState initial, p;
  FMState state = {};
  List<FMState> profile = [], samples = [];
  PipeModel? pipe;
  ProbabilityGrid? distribution;
  MatterDistribution? matter;
  double? arrival;
  late final SeededRandom sourceRandom, detectorRandom, backgroundRandom;
  final positions = <double>[];
  late final List<int> histogram;
  int ticks = 0,
      revision = 0,
      measurementCount = 0,
      remaining = 0,
      decays = 0,
      detected = 0,
      background = 0;
  double time = 0, positionSum = 0;
  String invalid = '';
  bool finished = false;
  static const dt = 1 / 120;
  int get totalTicks => [3, 4, 5].contains(kind) ? 1440 : 2400;
  double v(String key, [double fallback = 0]) => p[key] ?? fallback;
  bool get dynamicLab => [3, 4, 5, 6, 8, 11].contains(kind);
  bool get stochastic => [6, 8, 11].contains(kind);
  int get bins => kind == 6 ? 40 : 160;
  double get maxTime => kind == 5
      ? (arrival ?? 20)
      : kind == 11
      ? halfLives[mode] * v('halfLifeCount')
      : kind == 3 || kind == 4
      ? 12
      : 20;
  double get timeScale => kind == 5
      ? maxTime / 12
      : kind == 11
      ? maxTime / 20
      : 1;
  FMRun(
    this.kind,
    Map<String, double> parameters, {
    this.mode = 0,
    FMRun? geometryFrom,
  }) : initial = Map.of(parameters),
       p = Map.of(parameters) {
    if (kind < 0 ||
        kind > 11 ||
        mode < 0 ||
        mode >= fmModeCounts[kind] ||
        parameters.values.any((x) => !x.isFinite)) {
      throw ArgumentError('Supported finite model configuration required');
    }
    final seed = v('seed', 42).round();
    sourceRandom = SeededRandom(seed);
    detectorRandom = SeededRandom(seed ^ 0x9e3779b9);
    backgroundRandom = SeededRandom(seed ^ 0x85ebca6b);
    histogram = List.filled(bins, 0);
    remaining = v('initialN').round();
    try {
      bool reusable(List<String> keys) =>
          geometryFrom != null &&
          geometryFrom.kind == kind &&
          geometryFrom.mode == mode &&
          keys.every((key) => geometryFrom.v(key) == v(key));
      if (kind == 3 || kind == 4) {
        pipe =
            reusable([
              'radius1',
              'radius2',
              'flow',
              'density',
              'inletPressure',
              'elevation',
              'vapourPressure',
            ])
            ? geometryFrom!.pipe
            : null;
        pipe ??= PipeModel(
          v('radius1'),
          v('radius2'),
          v('flow'),
          bernoulli: kind == 4,
          rho: v('density', 1000),
          inletPressure: v('inletPressure', 110000),
          throatElevation: v('elevation'),
          vapourPressure: v('vapourPressure', 2340),
        );
      }
      if (kind == 5) {
        arrival = stokesArrival(
          v('radius'),
          v('sphereDensity'),
          v('density'),
          v('viscosity'),
          v('travel'),
        );
      }
      if (kind == 6) {
        distribution = reusable(['wellWidth', 'n'])
            ? geometryFrom!.distribution
            : null;
        distribution ??= ProbabilityGrid(0, v('wellWidth'), (x) {
          final psi = wellPsi(x, v('wellWidth'), v('mass'), v('n').round());
          return psi * psi;
        });
      }
      if (kind == 8) {
        matter =
            reusable([
              'voltage',
              'momentum',
              'slitWidth',
              'separation',
              'screenDistance',
              'window',
            ])
            ? geometryFrom!.matter
            : null;
        matter ??= MatterDistribution(
          mode == 0 ? electronMomentum(v('voltage')) : v('momentum'),
          v('slitWidth'),
          v('separation'),
          v('screenDistance'),
          v('window'),
        );
        distribution = matter!.grid;
      }
      if (kind == 11 &&
          (remaining < 1 ||
              remaining > 1000000000 ||
              v('halfLifeCount') <= 0 ||
              v('halfLifeCount') > 5)) {
        throw ArgumentError('Source1…1e9 nuclei; duration0…5 half-lives');
      }
      calculate();
      buildProfile();
      capture();
    } on ArgumentError catch (e) {
      invalid = e.message.toString();
      state = {'t': 0};
    }
  }
  void calculate() {
    if (invalid.isNotEmpty) return;
    state = {'t': time};
    try {
      switch (kind) {
        case 0:
          state.addAll(
            densityPressure(
              v('density'),
              v('depth'),
              v('surfacePressure'),
              v('referencePressure'),
              v('objectMass'),
              v('objectVolume'),
            ),
          );
        case 1:
          state.addAll(
            manometer(
              v('density'),
              v('layerDensity'),
              v('areaLeft'),
              v('areaRight'),
              v('initialLevel'),
              v('oilVolume'),
              v('deltaPressure'),
              mode,
            ),
          );
        case 2:
          state.addAll(
            buoyancy(
              v('density'),
              v('objectDensity'),
              v('width'),
              v('length'),
              v('height'),
              v('bottomDepth'),
              mode,
            ),
          );
        case 3 || 4:
          final a = pipe!.at(-PipeModel.halfLength),
              b = pipe!.at(0),
              probe = pipe!.at(v('probeX'));
          state.addAll({
            'speed': probe['speed']!,
            'area': probe['area']!,
            'inletSpeed': a['speed']!,
            'throatSpeed': b['speed']!,
            'inletArea': a['area']!,
            'throatArea': b['area']!,
            'flowRate': v('flow'),
            'continuityResidual': a['flowRate']! - b['flowRate']!,
            'probeX': v('probeX'),
          });
          if (kind == 4) {
            state.addAll({
              'pressure': probe['pressure']!,
              'inletPressure': a['pressure']!,
              'throatPressure': b['pressure']!,
              'inletHead': a['head']!,
              'throatHead': b['head']!,
              'probeHead': probe['head']!,
              'energyPerVolume': probe['bernoulli']!,
              'bernoulliResidual': a['bernoulli']! - b['bernoulli']!,
            });
          }
        case 5:
          state.addAll(
            stokes(
              v('radius'),
              v('sphereDensity'),
              v('density'),
              v('viscosity'),
              v('travel'),
              time,
            ),
          );
          state['arrivalTime'] = arrival!;
        case 6:
          state.addAll({
            'energy': wellEnergy(v('wellWidth'), v('mass'), v('n').round()),
            'energyEV':
                wellEnergy(v('wellWidth'), v('mass'), v('n').round()) /
                elementaryCharge,
            'normalization': distribution!.rawIntegral,
            'measurementCount': measurementCount.toDouble(),
            'histogramIntegral': measurementCount == 0
                ? 0
                : histogram.reduce((a, b) => a + b) / measurementCount,
          });
          if (measurementCount > 0) {
            state['observedMean'] = positionSum / measurementCount;
          }
        case 7:
          state.addAll(
            photoelectric(
              mode == 0 ? lightSpeed / v('wavelength') : v('frequency'),
              v('intensity'),
              v('illuminatedArea'),
              v('workFunction'),
              v('quantumEfficiency'),
              v('bias'),
            ),
          );
        case 8:
          state.addAll({
            'wavelength': matter!.wavelength,
            'momentum': matter!.momentum,
            'kineticEnergy':
                matter!.momentum * matter!.momentum / (2 * electronMass),
            'fringeSpacing': matter!.fringe,
            'fresnelNumber': matter!.fresnel,
            'conditionalNormalization': 1,
            'measurementCount': measurementCount.toDouble(),
            'histogramIntegral': measurementCount == 0
                ? 0
                : histogram.reduce((a, b) => a + b) / measurementCount,
          });
          if (measurementCount > 0) {
            state['observedMean'] = positionSum / measurementCount;
          }
        case 9:
          state.addAll(hydrogenTransition(1 + mode % 3, v('upper').round()));
          state['absorption'] = mode >= 3 ? 1 : 0;
        case 10:
          state.addAll(nuclear(mode));
        case 11:
          state.addAll(
            decayExpectation(
              mode,
              v('initialN'),
              time,
              v('efficiency'),
              v('background'),
            ),
          );
          state.addAll({
            'remaining': remaining.toDouble(),
            'simulatedDecays': decays.toDouble(),
            'detectedSourceCounts': detected.toDouble(),
            'backgroundCounts': background.toDouble(),
            'detectorCounts': (detected + background).toDouble(),
            'realizationActivity': state['decayConstant']! * remaining,
          });
      }
    } on ArgumentError catch (e) {
      invalid = e.message.toString();
      state = {'t': time};
    }
  }

  void capture() {
    if (samples.isNotEmpty && samples.last['t'] == time) samples.removeLast();
    samples.add(Map.of(state));
    while (samples.length > 301) {
      samples.removeAt(0);
    }
  }

  void refresh() {
    calculate();
    capture();
    revision++;
  }

  void step({bool captureNow = false}) {
    if (!dynamicLab || finished || invalid.isNotEmpty) return;
    final before = time;
    ticks++;
    time = ticks >= totalTicks ? maxTime : ticks * dt * timeScale;
    try {
      if (kind == 6 || kind == 8) {
        final desired = (time * v('eventRate')).floor().clamp(0, 2000);
        while (measurementCount < desired) {
          final x = distribution!.sample(sourceRandom);
          positions.add(x);
          if (positions.length > 300) positions.removeAt(0);
          final bin =
              ((x - distribution!.min) /
                      (distribution!.max - distribution!.min) *
                      bins)
                  .floor()
                  .clamp(0, bins - 1);
          histogram[bin]++;
          measurementCount++;
          positionSum += x;
        }
      }
      if (kind == 11) {
        final probability =
                1 - math.exp(-math.ln2 / halfLives[mode] * (time - before)),
            lost = sourceRandom.binomial(remaining, probability);
        remaining -= lost;
        decays += lost;
        detected += detectorRandom.binomial(lost, v('efficiency'));
        background += backgroundRandom.poisson(
          v('background') * (time - before),
        );
      }
      if (ticks % 4 == 0 || captureNow) {
        calculate();
        if (ticks % 8 == 0 || captureNow) capture();
        revision++;
      }
      if (ticks >= totalTicks) {
        time = maxTime;
        finished = true;
        refresh();
      }
    } on StateError catch (e) {
      invalid = e.message;
      finished = true;
      revision++;
    }
  }

  /// Call on a fresh run. Physical initial state and all three random streams
  /// are recreated by the saved seed; no replay depends on rendering cadence.
  void seek(double seconds) {
    if (!dynamicLab) {
      refresh();
      return;
    }
    final target =
        (seconds >= maxTime ? totalTicks : (seconds / (dt * timeScale)).round())
            .clamp(0, totalTicks);
    while (ticks < target && !finished && invalid.isEmpty) {
      step();
    }
    refresh();
  }

  List<FMState> get distributionData {
    if (distribution == null) return [];
    final d = distribution!, width = (d.max - d.min) / bins;
    return [
      for (int i = 0; i < bins; i++)
        {
          't': d.min + (i + .5) * width,
          'expectedDensity':
              (d.cumulative(d.min + (i + 1) * width) -
                  d.cumulative(d.min + i * width)) /
              width,
          if (measurementCount > 0)
            'observedDensity': histogram[i] / (measurementCount * width),
          'count': histogram[i].toDouble(),
        },
    ];
  }

  void buildProfile() {
    if (invalid.isNotEmpty) return;
    if (kind == 3 || kind == 4) {
      profile = pipe!.profile;
      return;
    }
    if (kind == 10) {
      profile = [
        for (int i = 0; i < isotopes.length; i++)
          {
            't': isotopes[i].a.toDouble(),
            'bindingPerNucleon': isotopes[i].binding / isotopes[i].a,
          },
      ];
      return;
    }
    for (int i = 0; i <= 160; i++) {
      final f = i / 160;
      FMState row = {};
      switch (kind) {
        case 0:
          row = {
            't': .8 * f,
            ...densityPressure(
              v('density'),
              .8 * f,
              v('surfacePressure'),
              v('referencePressure'),
              v('objectMass'),
              v('objectVolume'),
            ),
          };
        case 1:
          final dh = v('initialLevel') * 2 * f;
          row = {'t': dh, 'pressure': v('density') * 9.80665 * dh};
        case 2:
          final depth = v('height') * f;
          row = {
            't': depth,
            ...buoyancy(
              v('density'),
              v('objectDensity'),
              v('width'),
              v('length'),
              v('height'),
              depth,
              1,
            ),
          };
        case 5:
          final t = maxTime * f;
          row = {
            't': t,
            ...stokes(
              v('radius'),
              v('sphereDensity'),
              v('density'),
              v('viscosity'),
              v('travel'),
              t,
            ),
          };
        case 6:
          final x = v('wellWidth') * f,
              psi = wellPsi(x, v('wellWidth'), v('mass'), v('n').round());
          row = {'t': x, 'wavefunction': psi, 'probabilityDensity': psi * psi};
        case 7:
          final bias = -5 + 10 * f;
          row = {
            't': bias,
            ...photoelectric(
              mode == 0 ? lightSpeed / v('wavelength') : v('frequency'),
              v('intensity'),
              v('illuminatedArea'),
              v('workFunction'),
              v('quantumEfficiency'),
              bias,
            ),
          };
        case 8:
          final x = -v('window') + 2 * v('window') * f;
          row = {
            't': x,
            'expectedDensity': distribution!.probabilityDensity(x),
          };
        case 9:
          if (i > 7) continue;
          final n = i + 1;
          row = {
            't': n.toDouble(),
            'energy': -planck * lightSpeed * rydbergHydrogen / (n * n),
          };
        case 11:
          row = {
            't': maxTime * f,
            ...decayExpectation(
              mode,
              v('initialN'),
              maxTime * f,
              v('efficiency'),
              v('background'),
            ),
          };
      }
      if (row.isNotEmpty) profile.add(row);
    }
  }
}
