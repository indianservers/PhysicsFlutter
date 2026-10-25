import 'dart:math' as math;

import 'electromagnetism.dart'
    show elementaryCharge, CircuitGraph, CircuitPart, solveCircuit, EMState;

const etVersion = 'electronics-thermal-6.0';
const boltzmann = 1.380649e-23, avogadro = 6.02214076e23;
const gasConstant = boltzmann * avogadro, stefanBoltzmann = 5.670374419e-8;
const monatomicCv = 1.5 * gasConstant, gamma = 5 / 3;
typedef ETState = EMState;
void positiveTemperature(double t) {
  if (!t.isFinite || t <= 0) {
    throw ArgumentError('Absolute temperature must be positive kelvin.');
  }
}

double celsius(double k) {
  if (!k.isFinite || k < 0) {
    throw ArgumentError('Temperature below absolute zero');
  }
  return k - 273.15;
}

double fahrenheit(double k) => celsius(k) * 9 / 5 + 32;
double fromCelsius(double c) {
  final k = c + 273.15;
  if (!k.isFinite || k < 0) {
    throw ArgumentError('Temperature below absolute zero');
  }
  return k;
}

double expm1(double x) {
  if (x.abs() < 1e-4) {
    return x +
        x * x / 2 +
        x * x * x / 6 +
        math.pow(x, 4) / 24 +
        math.pow(x, 5) / 120;
  }
  return math.exp(x) - 1;
}

ETState semiconductor(double temperature, double doping, int mode) {
  if (temperature < 250 ||
      temperature > 400 ||
      doping < 0 ||
      doping > 1e21 ||
      mode < 0 ||
      mode > 2) {
    throw ArgumentError(
      'Fully ionized nondegenerate model: 250–400 K, doping 0–1e21 m⁻³, intrinsic/n/p modes only.',
    );
  }
  final ni =
      1e16 *
      math.pow(temperature / 300, 1.5) *
      math.exp(
        -1.12 *
            elementaryCharge /
            (2 * boltzmann) *
            (1 / temperature - 1 / 300),
      );
  final donors = mode == 1 ? doping : 0.0,
      acceptors = mode == 2 ? doping : 0.0,
      delta = donors - acceptors,
      root = math.sqrt(delta * delta + 4 * ni * ni);
  final n = delta >= 0 ? (delta + root) / 2 : 2 * ni * ni / (-delta + root),
      p = ni * ni / n;
  final mn = .14 * math.pow(temperature / 300, -2.2),
      mp = .05 * math.pow(temperature / 300, -2.2);
  return {
    'ni': ni,
    'electrons': n,
    'holes': p,
    'donors': donors,
    'acceptors': acceptors,
    'neutrality': p - n + donors - acceptors,
    'massAction': n * p,
    'mobilityN': mn,
    'mobilityP': mp,
    'conductivity': elementaryCharge * (n * mn + p * mp),
    'fermiOffset': boltzmann * temperature * math.log(n / ni),
    'bandGap': 1.12 * elementaryCharge,
  };
}

double diodeSaturation(double temperature, double reference) {
  if (temperature < 250 ||
      temperature > 400 ||
      reference <= 0 ||
      !reference.isFinite) {
    throw ArgumentError('Diode requires 250–400 K and positive reference Is.');
  }
  return reference *
      math.pow(temperature / 300, 3) *
      math.exp(
        -1.12 * elementaryCharge / boltzmann * (1 / temperature - 1 / 300),
      );
}

double diodeCurrent(
  double voltage,
  double temperature,
  double ideality,
  double saturation,
) {
  if (ideality < 1 || ideality > 2 || saturation <= 0) {
    throw ArgumentError('Ideality 1–2 and positive Is required.');
  }
  final x = voltage / (ideality * boltzmann * temperature / elementaryCharge);
  if (x > 80) {
    return double
        .infinity; // Bracketing sentinel only, never a displayed solution.
  }
  return saturation * expm1(x);
}

ETState seriesDiode(
  double supply,
  double resistance,
  double temperature,
  double ideality,
  double referenceIs, {
  int maxIterations = 96,
}) {
  if (!supply.isFinite ||
      supply < -5 ||
      supply > 12 ||
      resistance < 100 ||
      resistance > 100000 ||
      maxIterations < 1) {
    throw ArgumentError(
      'Series diode: supply −5…12 V, R 100…100000 Ω; positive iteration budget. Reverse breakdown is excluded.',
    );
  }
  final saturation = diodeSaturation(temperature, referenceIs);
  double low = math.min(0, supply),
      high = math.max(0, supply),
      vd = 0,
      current = 0,
      residual = 0;
  int count = 0;
  bool converged = false;
  for (; count < maxIterations; count++) {
    vd = (low + high) / 2;
    current = diodeCurrent(vd, temperature, ideality, saturation);
    residual = vd + resistance * current - supply;
    if (residual.isFinite &&
        residual.abs() <= 1e-11 * math.max(1, supply.abs())) {
      converged = true;
      break;
    }
    if (residual > 0) {
      high = vd;
    } else {
      low = vd;
    }
  }
  if (!converged || !current.isFinite) {
    throw ArgumentError(
      'Diode operating point did not converge; no reading assigned.',
    );
  }
  return {
    'current': current,
    'diodeVoltage': vd,
    'resistorVoltage': supply - vd,
    'saturationCurrent': saturation,
    'thermalVoltage': boltzmann * temperature / elementaryCharge,
    'kvlError': residual,
    'iterations': (count + 1).toDouble(),
    'diodePower': vd * current,
  };
}

double transistorCharacteristic(double vce, double ib, double beta) =>
    vce <= 0 ? 0 : beta * ib * math.min(1, vce / .15);
ETState npn(
  double drive,
  double baseResistance,
  double supply,
  double collectorResistance,
  double beta,
) {
  if (drive < 0 ||
      baseResistance <= 0 ||
      supply <= 0 ||
      collectorResistance <= 0 ||
      beta <= 0) {
    throw ArgumentError(
      'Positive bounded NPN supply, resistances and gain required.',
    );
  }
  final ib = math.max(0.0, (drive - .65) / baseResistance), demand = beta * ib;
  final active = demand <= (supply - .15) / collectorResistance;
  final vce = ib == 0
          ? supply
          : active
          ? supply - demand * collectorResistance
          : supply / (1 + collectorResistance * demand / .15),
      ic = (supply - vce) / collectorResistance;
  return {
    'baseCurrent': ib,
    'collectorCurrent': ic,
    'emitterCurrent': ib + ic,
    'baseVoltage': ib == 0 ? drive : .65,
    'collectorVoltage': vce,
    'emitterVoltage': 0,
    'vce': vce,
    'effectiveBeta': ib == 0 ? 0 : ic / ib,
    'region': ib == 0
        ? 0
        : active
        ? 1
        : 2,
    'collectorPower': vce * ic,
    'currentBalance': (ib + ic) - ib - ic,
  };
}

ETState amplifier(
  double time,
  double amplitude,
  double offset,
  double frequency,
  double feedback,
  double inputResistance,
  double rail,
  double margin,
  int mode,
) {
  if (frequency < .5 ||
      frequency > 20 ||
      amplitude < 0 ||
      feedback <= 0 ||
      inputResistance <= 0 ||
      rail <= margin ||
      margin < 0 ||
      mode < 0 ||
      mode > 1) {
    throw ArgumentError(
      'Ideal low-frequency closed-loop amplifier: .5–20 Hz, positive resistors and rail above swing margin.',
    );
  }
  final gain = mode == 0
          ? 1 + feedback / inputResistance
          : -feedback / inputResistance,
      vin = offset + amplitude * math.sin(2 * math.pi * frequency * time),
      raw = gain * vin,
      limit = rail - margin;
  return {
    'gain': gain,
    'inputVoltage': vin,
    'outputVoltage': raw.clamp(-limit, limit),
    'unclippedOutput': raw,
    'swingLimit': limit,
    'clipped': raw.abs() > limit ? 1 : 0,
  };
}

const gateNames = ['AND', 'OR', 'NOT', 'NAND', 'NOR', 'XOR', 'XNOR'];
bool logicGate(int gate, bool a, bool b) => switch (gate) {
  0 => a && b,
  1 => a || b,
  2 => !a,
  3 => !(a && b),
  4 => !(a || b),
  5 => a != b,
  6 => a == b,
  _ => throw ArgumentError('Unsupported ideal Boolean gate'),
};

double dividerVoltage(double supply, double upper, double lower) {
  final graph = CircuitGraph(
    [
      CircuitPart('V', 'source', value: supply),
      CircuitPart('Rtop', 'resistor', value: upper),
      CircuitPart('Rbottom', 'resistor', value: lower),
    ],
    [
      ['V:a', 'Rtop:a'],
      ['Rtop:b', 'Rbottom:a'],
      ['Rbottom:b', 'V:b'],
    ],
  );
  // The shared solver intentionally supports .1–10000 Ω. Scale both sensor
  // resistors by the same factor: node voltages are invariant; no fake clamp.
  final scale = math.max(1, math.max(upper, lower) / 10000);
  graph.parts[1].value = upper / scale;
  graph.parts[2].value = lower / scale;
  final result = solveCircuit(graph);
  if (!result.valid) throw ArgumentError(result.message);
  return result.nodes['Rbottom:a']!;
}

ETState sensor(
  int mode,
  double temperature,
  double lux,
  double distance,
  double airTemperature,
) {
  if (mode == 0) {
    if (temperature < 233.15 || temperature > 398.15) {
      throw ArgumentError(
        'TMP36 transfer-function simulation valid only −40…125 °C. No extrapolated reading.',
      );
    }
    return {
      'sensorOutput': .5 + .01 * celsius(temperature),
      'temperatureC': celsius(temperature),
      'saturated': 0,
    };
  }
  if (mode == 1) {
    if (lux < 0) throw ArgumentError('Illuminance must be nonnegative.');
    final bounded = lux.clamp(1, 10000).toDouble(),
        r = (10000 * math.pow(bounded / 100, -.7)).toDouble();
    return {
      'sensorOutput': dividerVoltage(3.3, r, 10000),
      'ldrResistance': r,
      'effectiveLux': bounded,
      'saturated': lux != bounded ? 1 : 0,
    };
  }
  if (mode == 2) {
    if (distance < .02 || distance > 4) {
      throw ArgumentError(
        'Simulated ultrasonic range .02…4 m; out of range means no valid echo.',
      );
    }
    if (airTemperature < 273.15 || airTemperature > 313.15) {
      throw ArgumentError(
        'Dry-air sound-speed approximation restricted to 0…40 °C.',
      );
    }
    final c = 331.3 + .606 * celsius(airTemperature), tof = 2 * distance / c;
    return {
      'sensorOutput': tof,
      'roundTripTime': tof,
      'soundSpeed': c,
      'echoDistance': c * tof / 2,
      'saturated': 0,
    };
  }
  throw ArgumentError('Select temperature, light or distance simulation.');
}

double probeTemperature(
  double sample,
  double initial,
  double tau,
  double time,
) {
  positiveTemperature(sample);
  positiveTemperature(initial);
  if (tau <= 0 || time < 0) {
    throw ArgumentError('Positive response τ and nonnegative time');
  }
  return sample + (initial - sample) * math.exp(-time / tau);
}

ETState coolingProbe(
  double sampleInitial,
  double ambient,
  double probeInitial,
  double sampleTau,
  double probeTau,
  double time,
  double capacity,
) {
  for (final t in [sampleInitial, ambient, probeInitial]) {
    positiveTemperature(t);
  }
  if (sampleTau <= 0 || probeTau <= 0 || capacity <= 0 || time < 0) {
    throw ArgumentError('Positive thermal capacities/time constants required.');
  }
  final a = 1 / sampleTau,
      b = 1 / probeTau,
      sample = ambient + (sampleInitial - ambient) * math.exp(-a * time);
  final response = (a - b).abs() < 1e-8 * math.max(a, b)
      ? b * time * math.exp(-b * time)
      : b * (math.exp(-a * time) - math.exp(-b * time)) / (b - a);
  final probe =
          ambient +
          (probeInitial - ambient) * math.exp(-b * time) +
          (sampleInitial - ambient) * response,
      du = capacity * (sample - sampleInitial),
      out = capacity * (sampleInitial - sample);
  return {
    'sampleTemperature': sample,
    'probeTemperature': probe,
    'heatOut': out,
    'deltaU': du,
    'energyResidual': du + out,
  };
}

double conduction(
  double k,
  double area,
  double left,
  double right,
  double length,
) {
  for (final t in [left, right]) {
    positiveTemperature(t);
  }
  if (k <= 0 || area <= 0 || length <= 0) {
    throw ArgumentError('Positive rod k, area and length');
  }
  return k * area * (left - right) / length;
}

ETState convection(
  double initial,
  double ambient,
  double h,
  double area,
  double mass,
  double cp,
  double conductivity,
  double density,
  double time,
) {
  positiveTemperature(initial);
  positiveTemperature(ambient);
  if ([h, area, mass, cp, conductivity, density].any((v) => v <= 0) ||
      time < 0) {
    throw ArgumentError('Positive convection geometry/material parameters');
  }
  final bi = h * mass / (density * area * conductivity);
  if (bi > .1) {
    throw ArgumentError(
      'Lumped convection requires Bi≤0.1; change h, geometry or conductivity.',
    );
  }
  final capacity = mass * cp,
      tau = capacity / (h * area),
      t = probeTemperature(ambient, initial, tau, time),
      q = capacity * (initial - t);
  return {
    'temperature': t,
    'heatRate': h * area * (t - ambient),
    'heatOut': q,
    'deltaU': -q,
    'energyResidual': 0,
    'biot': bi,
    'tau': tau,
  };
}

double radiationRate(
  double temperature,
  double surroundings,
  double emissivity,
  double area,
) {
  positiveTemperature(temperature);
  positiveTemperature(surroundings);
  if (emissivity < 0 || emissivity > 1 || area <= 0) {
    throw ArgumentError('Emissivity0…1 and positive area');
  }
  return emissivity *
      stefanBoltzmann *
      area *
      (math.pow(temperature, 4) - math.pow(surroundings, 4));
}

({double temperature, double heat}) radiationStep(
  double t,
  double ambient,
  double emissivity,
  double area,
  double capacity,
  double dt,
) {
  if (capacity <= 0 || dt < 0) {
    throw ArgumentError('Positive heat capacity and nonnegative timestep');
  }
  final slope =
      4 *
      math.max(emissivity, .000001) *
      stefanBoltzmann *
      area *
      math.pow(math.max(t, ambient), 3) /
      capacity;
  final n = math.max(1, (dt * slope / .2).ceil()), h = dt / n;
  double heat = 0;
  double rate(double v) =>
      -radiationRate(v, ambient, emissivity, area) / capacity;
  for (int i = 0; i < n; i++) {
    final k1 = rate(t),
        k2 = rate(t + k1 * h / 2),
        k3 = rate(t + k2 * h / 2),
        k4 = rate(t + k3 * h),
        change = h * (k1 + 2 * k2 + 2 * k3 + k4) / 6;
    t += change;
    heat -= capacity * change;
  }
  return (temperature: t, heat: heat);
}

/// Modes:0 isothermal,1 isochoric,2 isobaric,3 reversible adiabatic.
ETState gasProcess(
  int mode,
  double n,
  double t0,
  double v0,
  double volumeRatio,
  double temperatureRatio,
  double progress,
) {
  positiveTemperature(t0);
  if (n <= 0 ||
      v0 <= 0 ||
      volumeRatio <= 0 ||
      temperatureRatio <= 0 ||
      mode < 0 ||
      mode > 3) {
    throw ArgumentError(
      'Positive ideal-gas state/ratios and supported process required.',
    );
  }
  final f = progress.clamp(0, 1).toDouble(), p0 = n * gasConstant * t0 / v0;
  double v = mode == 1 ? v0 : v0 * (1 + (volumeRatio - 1) * f),
      t = mode == 1
          ? t0 * (1 + (temperatureRatio - 1) * f)
          : mode == 2
          ? t0 * v / v0
          : mode == 3
          ? t0 * math.pow(v0 / v, gamma - 1)
          : t0;
  final pressure = n * gasConstant * t / v,
      du = n * monatomicCv * (t - t0),
      work = mode == 1
          ? 0.0
          : mode == 0
          ? n * gasConstant * t0 * math.log(v / v0)
          : mode == 2
          ? p0 * (v - v0)
          : n * monatomicCv * (t0 - t),
      heat = mode == 3 ? 0.0 : du + work;
  return {
    'pressure': pressure,
    'volume': v,
    'temperature': t,
    'initialPressure': p0,
    'initialVolume': v0,
    'initialTemperature': t0,
    'deltaU': du,
    'work': work,
    'heat': heat,
    'energyResidual': du - heat + work,
    'progress': f,
  };
}

double gasEntropy(double n, double t0, double v0, double t1, double v1) {
  positiveTemperature(t0);
  positiveTemperature(t1);
  if (n <= 0 || v0 <= 0 || v1 <= 0) {
    throw ArgumentError('Positive gas amount/volume');
  }
  return n * monatomicCv * math.log(t1 / t0) +
      n * gasConstant * math.log(v1 / v0);
}

ETState thermalContact(
  double t1,
  double t2,
  double c1,
  double c2,
  double conductance,
  double time,
) {
  positiveTemperature(t1);
  positiveTemperature(t2);
  if (c1 <= 0 || c2 <= 0 || conductance <= 0 || time < 0) {
    throw ArgumentError('Positive finite heat capacities/conductance');
  }
  final tf = (c1 * t1 + c2 * t2) / (c1 + c2),
      tau = 1 / (conductance * (1 / c1 + 1 / c2)),
      difference = (t1 - t2) * math.exp(-time / tau),
      a = tf + c2 / (c1 + c2) * difference,
      b = tf - c1 / (c1 + c2) * difference;
  final s1 = c1 * math.log(a / t1), s2 = c2 * math.log(b / t2);
  return {
    'body1Temperature': a,
    'body2Temperature': b,
    'equilibriumTemperature': tf,
    'entropy1': s1,
    'entropy2': s2,
    'entropy': s1 + s2,
    'equilibriumEntropy': c1 * math.log(tf / t1) + c2 * math.log(tf / t2),
    'energyResidual': c1 * (a - t1) + c2 * (b - t2),
    'tau': tau,
  };
}

ETState carnot(
  double n,
  double hot,
  double cold,
  double initialVolume,
  double ratio,
  double phase,
) {
  positiveTemperature(hot);
  positiveTemperature(cold);
  if (hot <= cold ||
      n <= 0 ||
      initialVolume <= 0 ||
      ratio <= 1 ||
      phase < 0 ||
      phase > 4) {
    throw ArgumentError(
      'Carnot requires Th>Tc>0, n/V>0, expansion ratio>1 and phase0…4.',
    );
  }
  final a = math.pow(hot / cold, 1 / (gamma - 1)),
      v1 = initialVolume,
      v2 = v1 * ratio,
      v3 = v2 * a,
      v4 = v1 * a;
  final stage = math.min(3, phase.floor()), u = phase - stage;
  late double v, t, stageW, stageQ;
  switch (stage) {
    case 0:
      v = v1 * math.pow(ratio, u);
      t = hot;
      stageW = n * gasConstant * hot * math.log(v / v1);
      stageQ = stageW;
    case 1:
      v = v2 * math.pow(a, u);
      t = hot * math.pow(v2 / v, gamma - 1);
      stageW = n * monatomicCv * (hot - t);
      stageQ = 0;
    case 2:
      v = v3 / math.pow(ratio, u);
      t = cold;
      stageW = n * gasConstant * cold * math.log(v / v3);
      stageQ = stageW;
    default:
      v = v4 / math.pow(a, u);
      t = cold * math.pow(v4 / v, gamma - 1);
      stageW = n * monatomicCv * (cold - t);
      stageQ = 0;
  }
  final qh = n * gasConstant * hot * math.log(ratio),
      qc = n * gasConstant * cold * math.log(ratio),
      adiabaticW = n * monatomicCv * (hot - cold);
  final cumulativeW =
          stageW +
          (stage >= 1 ? qh : 0) +
          (stage >= 2 ? adiabaticW : 0) +
          (stage >= 3 ? -qc : 0),
      cumulativeQ = stageQ + (stage >= 1 ? qh : 0) + (stage >= 3 ? -qc : 0),
      du = n * monatomicCv * (t - hot);
  return {
    'volume': v,
    'temperature': t,
    'pressure': n * gasConstant * t / v,
    'stage': stage.toDouble(),
    'stageFraction': u,
    'stageWork': stageW,
    'stageHeat': stageQ,
    'work': cumulativeW,
    'heat': cumulativeQ,
    'deltaU': du,
    'energyResidual': du - cumulativeQ + cumulativeW,
    'hotHeatReference': qh,
    'coldHeatReference': qc,
    'netWorkReference': qh - qc,
    'efficiency': 1 - cold / hot,
    'phase': phase,
    'v1': v1,
    'v2': v2,
    'v3': v3,
    'v4': v4,
  };
}

class ETRun {
  final int kind, mode;
  final ETState initial, p;
  static const dt = 1 / 120;
  ETState state = {};
  List<ETState> samples = [], profile = [], alternate = [];
  final events = <Map<String, dynamic>>[];
  int ticks = 0, revision = 0;
  double time = 0, radiationTemperature = 0, radiationHeat = 0;
  bool finished = false;
  String invalid = '';
  double v(String key, [double fallback = 0]) => p[key] ?? fallback;
  bool get dynamicLab =>
      kind == 3 ||
      kind == 4 ||
      kind == 6 ||
      kind == 7 && mode > 0 ||
      kind == 8 ||
      kind == 9 ||
      kind == 10 && mode != 1 ||
      kind == 11;
  double get characteristic => kind == 6
      ? (mode == 0
            ? v('probeTau')
            : math.max(
                v('mass') * v('cp') / (v('h') * v('surface')),
                v('probeTau'),
              ))
      : kind == 7
      ? (mode == 1
            ? v('mass') * v('cp') / (v('h') * v('surface'))
            : v('mass') *
                  v('cp') /
                  (4 *
                      math.max(v('emissivity'), .001) *
                      stefanBoltzmann *
                      v('surface') *
                      math.pow(math.max(v('initialT'), v('ambientT')), 3)))
      : kind == 10 && mode == 2
      ? 1 / (v('conductance') * (1 / v('capacity1') + 1 / v('capacity2')))
      : 1;
  double get timeScale => kind == 3
      ? .2 / v('frequency')
      : kind == 6 || kind == 7 && mode > 0 || kind == 10 && mode == 2
      ? characteristic / 5
      : 1;
  double get maxTime => kind == 3
      ? 2 / v('frequency')
      : kind == 4
      ? 30
      : kind == 6 || kind == 7 && mode > 0 || kind == 10 && mode == 2
      ? 5 * characteristic
      : kind >= 8
      ? v('duration', 10)
      : 30;
  ETRun(this.kind, Map<String, double> parameters, {this.mode = 0})
    : initial = Map.of(parameters),
      p = Map.of(parameters) {
    if (kind < 0 ||
        kind > 11 ||
        mode < 0 ||
        mode >= [3, 1, 1, 2, 7, 3, 2, 3, 3, 4, 3, 1][kind] ||
        parameters.values.any((x) => !x.isFinite)) {
      throw ArgumentError('Supported model and finite inputs required');
    }
    radiationTemperature = v('initialT');
    calculate();
    buildProfile();
    capture();
  }
  void calculate() {
    invalid = '';
    state = {'t': time};
    try {
      switch (kind) {
        case 0:
          state.addAll(semiconductor(v('temperature'), v('doping'), mode));
        case 1:
          state.addAll(
            seriesDiode(
              v('supply'),
              v('resistance'),
              v('temperature'),
              v('ideality'),
              v('referenceIs'),
            ),
          );
        case 2:
          state.addAll(
            npn(
              v('drive'),
              v('baseResistance'),
              v('supply'),
              v('collectorResistance'),
              v('beta'),
            ),
          );
        case 3:
          state.addAll(
            amplifier(
              time,
              v('amplitude'),
              v('offset'),
              v('frequency'),
              v('feedback'),
              v('inputResistance'),
              v('rail'),
              v('margin'),
              mode,
            ),
          );
        case 4:
          state.addAll({
            'inputA': v('inputA'),
            'inputB': v('inputB'),
            'logicOutput': logicGate(mode, v('inputA') > 0, v('inputB') > 0)
                ? 1
                : 0,
          });
        case 5:
          state.addAll(
            sensor(
              mode,
              v('temperature'),
              v('lux'),
              v('distance'),
              v('airTemperature'),
            ),
          );
        case 6:
          if (mode == 0) {
            state.addAll({
              'sampleTemperature': v('sampleT'),
              'probeTemperature': probeTemperature(
                v('sampleT'),
                v('probeT'),
                v('probeTau'),
                time,
              ),
            });
          } else {
            state.addAll(
              coolingProbe(
                v('sampleT'),
                v('ambientT'),
                v('probeT'),
                v('mass') * v('cp') / (v('h') * v('surface')),
                v('probeTau'),
                time,
                v('mass') * v('cp'),
              ),
            );
          }
          state.addAll({
            'celsius': celsius(state['probeTemperature']!),
            'fahrenheit': fahrenheit(state['probeTemperature']!),
          });
        case 7:
          if (mode == 0) {
            final rate = conduction(
              v('conductivity'),
              v('area'),
              v('leftT'),
              v('rightT'),
              v('length'),
            );
            state.addAll({
              'heatRate': rate,
              'probeTemperature':
                  v('leftT') + (v('rightT') - v('leftT')) * v('probe'),
              'gradient': (v('rightT') - v('leftT')) / v('length'),
            });
          } else if (mode == 1) {
            state.addAll(
              convection(
                v('initialT'),
                v('ambientT'),
                v('h'),
                v('surface'),
                v('mass'),
                v('cp'),
                v('conductivity'),
                v('density'),
                time,
              ),
            );
          } else if (mode == 2) {
            state.addAll({
              'temperature': radiationTemperature,
              'heatRate': radiationRate(
                radiationTemperature,
                v('ambientT'),
                v('emissivity'),
                v('surface'),
              ),
              'heatOut': radiationHeat,
              'deltaU':
                  v('mass') * v('cp') * (radiationTemperature - v('initialT')),
              'energyResidual':
                  radiationHeat +
                  v('mass') * v('cp') * (radiationTemperature - v('initialT')),
            });
          } else {
            throw ArgumentError('Choose conduction, convection or radiation.');
          }
        case 8 || 9:
          final process = kind == 8 ? mode : [1, 2, 0, 3][mode];
          state.addAll(
            gasProcess(
              process,
              v('amount'),
              v('initialT'),
              v('initialVolume'),
              v('volumeRatio'),
              v('temperatureRatio'),
              time / v('duration'),
            ),
          );
        case 10:
          if (mode == 2) {
            state.addAll(
              thermalContact(
                v('body1T'),
                v('body2T'),
                v('capacity1'),
                v('capacity2'),
                v('conductance'),
                time,
              ),
            );
          } else {
            if (mode == 1 && v('volumeRatio') < 1) {
              throw ArgumentError('Free expansion into vacuum requires V₂≥V₁.');
            }
            final f = mode == 1
                    ? v('expanded')
                    : (time / v('duration')).clamp(0, 1).toDouble(),
                t = mode == 1
                    ? v('initialT')
                    : v('initialT') + (v('finalT') - v('initialT')) * f,
                volume = v('initialVolume') * math.pow(v('volumeRatio'), f);
            state.addAll({
              'temperature': t,
              'volume': volume,
              'pressure': v('amount') * gasConstant * t / volume,
              'entropy': gasEntropy(
                v('amount'),
                v('initialT'),
                v('initialVolume'),
                t,
                volume,
              ),
              'deltaU': v('amount') * monatomicCv * (t - v('initialT')),
            });
            if (mode == 1) {
              state.addAll({'heat': 0, 'work': 0, 'energyResidual': 0});
            }
          }
        case 11:
          state.addAll(
            carnot(
              v('amount'),
              v('hotT'),
              v('coldT'),
              v('initialVolume'),
              v('volumeRatio'),
              4 * (time / v('duration')).clamp(0, 1),
            ),
          );
      }
    } on ArgumentError catch (e) {
      invalid = e.message.toString();
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

  void setLogicInput(String key, double value, {bool recordEvent = true}) {
    if (kind != 4 ||
        !['inputA', 'inputB'].contains(key) ||
        value != 0 && value != 1) {
      throw ArgumentError('Binary gate input required');
    }
    if (recordEvent && events.length >= 200) {
      throw ArgumentError(
        'Timing sequence limited to 200 input events. Save/reset before adding more.',
      );
    }
    calculate(); // Both sides of an input edge have the same physical timestamp.
    samples.add(Map.of(state));
    p[key] = value;
    calculate();
    samples.add(Map.of(state));
    while (samples.length > 301) {
      samples.removeAt(0);
    }
    if (recordEvent) events.add({'tick': ticks, 'key': key, 'value': value});
    revision++;
  }

  void step({bool captureNow = false}) {
    if (!dynamicLab || finished || invalid.isNotEmpty) return;
    final previousTime = time;
    ticks++;
    time = math.min(ticks * dt * timeScale, maxTime);
    if (kind == 7 && mode == 2) {
      final next = radiationStep(
        radiationTemperature,
        v('ambientT'),
        v('emissivity'),
        v('surface'),
        v('mass') * v('cp'),
        time - previousTime,
      );
      radiationTemperature = next.temperature;
      radiationHeat += next.heat;
    }
    if (ticks % 4 == 0 || captureNow) {
      calculate();
      if (ticks % 8 == 0 || captureNow) capture();
      revision++;
    }
    if (ticks >= (maxTime / (dt * timeScale)).ceil()) {
      time = maxTime;
      finished = true;
      refresh();
    }
  }

  void seek(
    double seconds, {
    List<Map<String, dynamic>> inputEvents = const [],
  }) {
    if (!dynamicLab) {
      refresh();
      return;
    }
    final target =
        (seconds >= maxTime
                ? (maxTime / (dt * timeScale)).ceil()
                : (seconds / (dt * timeScale)).round())
            .clamp(0, (maxTime / (dt * timeScale)).ceil());
    int index = 0;
    void apply() {
      while (index < inputEvents.length &&
          (inputEvents[index]['tick'] as int) <= ticks) {
        final e = inputEvents[index++];
        setLogicInput(e['key'], (e['value'] as num).toDouble());
      }
    }

    while (ticks < target && !finished && invalid.isEmpty) {
      if (kind == 4) apply();
      step();
    }
    if (kind == 4) apply();
    refresh();
  }

  void buildProfile() {
    profile = [];
    alternate = [];
    for (int i = 0; i <= 160; i++) {
      final f = i / 160;
      ETState row = {};
      try {
        switch (kind) {
          case 0:
            final t = 250 + 150 * f;
            row = {'t': t, ...semiconductor(t, v('doping'), mode)};
          case 1:
            final supply = -5 + 17 * f;
            row = {
              't': supply,
              ...seriesDiode(
                supply,
                v('resistance'),
                v('temperature'),
                v('ideality'),
                v('referenceIs'),
              ),
            };
            final vd = -.2 + 1 * f;
            final current = diodeCurrent(
              vd,
              v('temperature'),
              v('ideality'),
              diodeSaturation(v('temperature'), v('referenceIs')),
            );
            if (current.isFinite) {
              alternate.add({
                't': vd,
                'current': current,
                'loadLine': (v('supply') - vd) / v('resistance'),
              });
            }
          case 2:
            final vc = v('supply') * f,
                ib = math.max(0.0, (v('drive') - .65) / v('baseResistance'));
            row = {
              't': vc,
              'characteristic': transistorCharacteristic(vc, ib, v('beta')),
              'loadLine': (v('supply') - vc) / v('collectorResistance'),
            };
          case 3:
            final t = 2 / v('frequency') * f;
            row = {
              't': t,
              ...amplifier(
                t,
                v('amplitude'),
                v('offset'),
                v('frequency'),
                v('feedback'),
                v('inputResistance'),
                v('rail'),
                v('margin'),
                mode,
              ),
            };
          case 4:
            if (i > 3) continue;
            final a = i ~/ 2, b = i % 2;
            row = {
              't': i.toDouble(),
              'inputA': a.toDouble(),
              'inputB': b.toDouble(),
              'logicOutput': logicGate(mode, a == 1, b == 1) ? 1 : 0,
            };
          case 5:
            if (mode == 0) {
              final t = 220 + 210 * f;
              row = {
                't': t,
                ...sensor(
                  mode,
                  t,
                  v('lux'),
                  v('distance'),
                  v('airTemperature'),
                ),
              };
            } else if (mode == 1) {
              final lux = 10000 * f;
              row = {
                't': lux,
                ...sensor(
                  mode,
                  v('temperature'),
                  lux,
                  v('distance'),
                  v('airTemperature'),
                ),
              };
            } else {
              final d = 5 * f;
              row = {
                't': d,
                ...sensor(
                  mode,
                  v('temperature'),
                  v('lux'),
                  d,
                  v('airTemperature'),
                ),
              };
            }
          case 6:
            final t = maxTime * f;
            row = mode == 0
                ? {
                    't': t,
                    'sampleTemperature': v('sampleT'),
                    'probeTemperature': probeTemperature(
                      v('sampleT'),
                      v('probeT'),
                      v('probeTau'),
                      t,
                    ),
                  }
                : {
                    't': t,
                    ...coolingProbe(
                      v('sampleT'),
                      v('ambientT'),
                      v('probeT'),
                      v('mass') * v('cp') / (v('h') * v('surface')),
                      v('probeTau'),
                      t,
                      v('mass') * v('cp'),
                    ),
                  };
          case 7:
            if (mode == 0) {
              row = {
                't': f * v('length'),
                'probeTemperature': v('leftT') + (v('rightT') - v('leftT')) * f,
              };
            } else if (mode == 1) {
              row = {
                't': maxTime * f,
                ...convection(
                  v('initialT'),
                  v('ambientT'),
                  v('h'),
                  v('surface'),
                  v('mass'),
                  v('cp'),
                  v('conductivity'),
                  v('density'),
                  maxTime * f,
                ),
              };
            } else {
              final t = 273.15 + 80 * f;
              row = {
                't': t,
                'heatRate': radiationRate(
                  t,
                  v('ambientT'),
                  v('emissivity'),
                  v('surface'),
                ),
              };
            }
          case 8 || 9:
            final process = kind == 8 ? mode : [1, 2, 0, 3][mode],
                s = gasProcess(
                  process,
                  v('amount'),
                  v('initialT'),
                  v('initialVolume'),
                  v('volumeRatio'),
                  v('temperatureRatio'),
                  f,
                );
            row = {'t': s['volume']!, ...s};
          case 10:
            if (mode == 2) {
              row = {
                't': maxTime * f,
                ...thermalContact(
                  v('body1T'),
                  v('body2T'),
                  v('capacity1'),
                  v('capacity2'),
                  v('conductance'),
                  maxTime * f,
                ),
              };
            } else if (mode == 1) {
              final ratio = 1 + 2 * f;
              row = {
                't': ratio,
                'entropy': v('amount') * gasConstant * math.log(ratio),
              };
            } else {
              final t = v('initialT') + (v('finalT') - v('initialT')) * f,
                  vol = v('initialVolume') * math.pow(v('volumeRatio'), f);
              row = {
                't': f,
                'entropy': gasEntropy(
                  v('amount'),
                  v('initialT'),
                  v('initialVolume'),
                  t,
                  vol,
                ),
                'temperature': t,
                'volume': vol,
              };
            }
          case 11:
            final s = carnot(
              v('amount'),
              v('hotT'),
              v('coldT'),
              v('initialVolume'),
              v('volumeRatio'),
              4 * f,
            );
            row = {'t': s['volume']!, ...s};
        }
      } on ArgumentError {
        row = {
          't': switch (kind) {
            5 =>
              mode == 0
                  ? 220 + 210 * f
                  : mode == 1
                  ? 10000 * f
                  : 5 * f,
            _ => f,
          },
        };
      }
      if (row.isNotEmpty) profile.add(row);
    }
  }
}
