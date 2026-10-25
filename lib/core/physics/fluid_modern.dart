import 'dart:math' as math;

import 'dynamics.dart' show standardGravity;
import 'electromagnetism.dart' show elementaryCharge;
import 'waves_optics.dart' show lightSpeed;
import 'electronics_thermal.dart' show expm1;
import 'stochastic.dart';
export 'stochastic.dart';

const fmVersion = 'fluid-modern-7.0',
    datasetVersion = 'nist-isotope-central-ptb-half-life-2026-10';
const planck = 6.62607015e-34,
    electronMass = 9.1093837139e-31,
    protonMass = 1.67262192595e-27,
    neutronMassU = 1.00866491606,
    hydrogenMassU = 1.00782503223,
    atomicMass = 1.66053906892e-27,
    rydbergInfinity = 10973731.568157;
const hbar = planck / (2 * math.pi),
    rydbergHydrogen = rydbergInfinity / (1 + electronMass / protonMass),
    julianYear = 365.25 * 86400;
typedef FMState = Map<String, double>;
void finitePositive(Iterable<double> values) {
  if (values.any((x) => !x.isFinite || x <= 0)) {
    throw ArgumentError('Finite positive model inputs required');
  }
}

FMState densityPressure(
  double rho,
  double depth,
  double surface,
  double reference,
  double objectMass,
  double volume,
) {
  finitePositive([rho, surface, reference, objectMass, volume]);
  if (!depth.isFinite || depth < 0 || depth > .8) {
    throw ArgumentError('Probe depth0…0.8 m below the free surface');
  }
  final absolute = surface + rho * standardGravity * depth;
  return {
    'absolutePressure': absolute,
    'gaugePressure': absolute - reference,
    'fluidDensity': rho,
    'objectDensity': objectMass / volume,
    'depth': depth,
    'gradient': rho * standardGravity,
  };
}

FMState manometer(
  double rho,
  double oilRho,
  double leftArea,
  double rightArea,
  double initialLevel,
  double oilVolume,
  double deltaPressure,
  int mode,
) {
  finitePositive([rho, oilRho, leftArea, rightArea, initialLevel]);
  if (mode < 0 || mode > 1 || oilVolume < 0 || !deltaPressure.isFinite) {
    throw ArgumentError('Supported one-fluid / two-fluid equilibrium required');
  }
  if (mode == 1 && oilRho >= rho) {
    throw ArgumentError(
      'Supported stable upper layer requires oil density below the connected base-fluid density',
    );
  }
  final layer = mode == 1 ? oilVolume / leftArea : 0.0,
      dh =
          (deltaPressure + oilRho * standardGravity * layer) /
          (rho * standardGravity),
      interface = initialLevel - rightArea / (leftArea + rightArea) * dh,
      right = initialLevel + leftArea / (leftArea + rightArea) * dh,
      left = interface + layer;
  if (interface < .03 || right < .03 || left > .55 || right > .55) {
    throw ArgumentError(
      'Column/interface leaves the 0.03…0.55 m vessel capacity. Overflow/empty branches are unsupported; reduce applied pressure or layer volume.',
    );
  }
  return {
    'leftLevel': left,
    'rightLevel': right,
    'interfaceLevel': interface,
    'layerHeight': layer,
    'heightDifference': dh,
    'baseVolume': leftArea * interface + rightArea * right,
    'initialBaseVolume': (leftArea + rightArea) * initialLevel,
    'volumeResidual':
        leftArea * interface +
        rightArea * right -
        (leftArea + rightArea) * initialLevel,
    'pressureBalance':
        deltaPressure +
        oilRho * standardGravity * layer +
        rho * standardGravity * interface -
        rho * standardGravity * right,
    'datumPressureRightGauge': rho * standardGravity * right,
    'deltaPressure': deltaPressure,
  };
}

FMState buoyancy(
  double rho,
  double objectRho,
  double width,
  double length,
  double height,
  double bottomDepth,
  int mode,
) {
  finitePositive([rho, objectRho, width, length, height]);
  if (height > .22 ||
      bottomDepth < -.02 ||
      bottomDepth > .22 ||
      mode < 0 ||
      mode > 1) {
    throw ArgumentError(
      'Rectangular body fits tank; bottom depth −0.02…0.22 m',
    );
  }
  final volume = width * length * height,
      mass = volume * objectRho,
      regime = objectRho < rho
          ? 0
          : objectRho == rho
          ? 1
          : 2;
  final bottom = mode == 0
      ? (regime == 0
            ? height * objectRho / rho
            : regime == 1
            ? math.min(.22, height + .05)
            : .22)
      : bottomDepth;
  final submergedHeight = bottom.clamp(0, height).toDouble(),
      displaced = width * length * submergedHeight,
      fb = rho * standardGravity * displaced,
      weight = mass * standardGravity;
  return {
    'volume': volume,
    'mass': mass,
    'bottomDepth': bottom,
    'submergedHeight': submergedHeight,
    'displacedVolume': displaced,
    'submergedFraction': displaced / volume,
    'buoyantForce': fb,
    'weight': weight,
    'freeNetForceUp': fb - weight,
    'supportForceUp': weight - fb,
    'equilibriumFraction': objectRho <= rho ? objectRho / rho : 1,
    'regime': regime.toDouble(),
  };
}

class PipeModel {
  final double inletRadius,
      throatRadius,
      flow,
      rho,
      inletPressure,
      throatElevation,
      vapourPressure;
  final bool bernoulli;
  late final List<FMState> profile;
  late final List<double> volumeGrid;
  static const halfLength = .12, intervals = 2048;
  PipeModel(
    this.inletRadius,
    this.throatRadius,
    this.flow, {
    this.bernoulli = false,
    this.rho = 1000,
    this.inletPressure = 110000,
    this.throatElevation = 0,
    this.vapourPressure = 2340,
  }) {
    finitePositive([inletRadius, throatRadius, flow, rho, inletPressure]);
    if (inletRadius < .003 ||
        inletRadius > .03 ||
        throatRadius < .003 ||
        throatRadius > .03 ||
        throatElevation.abs() > .05 ||
        vapourPressure < 0) {
      throw ArgumentError(
        'Supported circular pipe radii3…30 mm; elevation±.05 m',
      );
    }
    profile = [
      for (int i = 0; i <= 160; i++) at(-halfLength + 2 * halfLength * i / 160),
    ];
    if (bernoulli) {
      if (profile.any((s) => s['pressure']! <= vapourPressure)) {
        throw ArgumentError(
          'Potential cavitation / invalid absolute pressure: below the model vapour pressure',
        );
      }
      for (final s in profile) {
        if (s['pressure']! <= vapourPressure) {
          throw ArgumentError(
            'Potential cavitation / invalid absolute pressure: pressure must exceed the stated model vapour pressure',
          );
        }
        if (s['head']! < 0 || s['columnTop']! > .14) {
          throw ArgumentError(
            'Open piezometer requires nonnegative gauge head and a column within 0.14 m capacity; use lower flow or a supported inlet pressure',
          );
        }
      }
    }
    volumeGrid = List.filled(intervals + 1, 0);
    final dx = 2 * halfLength / intervals;
    for (int i = 1; i <= intervals; i++) {
      volumeGrid[i] =
          volumeGrid[i - 1] +
          dx *
              (area(-halfLength + (i - 1) * dx) *
                      metric(-halfLength + (i - 1) * dx) +
                  area(-halfLength + i * dx) * metric(-halfLength + i * dx)) /
              2;
    }
  }
  double shape(double x) => (1 + math.cos(math.pi * x / halfLength)) / 2;
  double slope(double x) =>
      -throatElevation *
      math.pi /
      (2 * halfLength) *
      math.sin(math.pi * x / halfLength);
  double metric(double x) => math.sqrt(1 + slope(x) * slope(x));
  double radius(double x) =>
      inletRadius + (throatRadius - inletRadius) * shape(x);
  double area(double x) => math.pi * math.pow(radius(x), 2);
  FMState at(double x) {
    final a = area(x),
        v = flow / a,
        v1 = flow / (math.pi * inletRadius * inletRadius),
        z = throatElevation * shape(x),
        p =
            inletPressure +
            .5 * rho * (v1 * v1 - v * v) -
            rho * standardGravity * z,
        head = (p - 101325) / (rho * standardGravity);
    return {
      't': x,
      'area': a,
      'radius': radius(x),
      'speed': v,
      'flowRate': a * v,
      'elevation': z,
      if (bernoulli) 'pressure': p,
      if (bernoulli) 'head': head,
      if (bernoulli) 'columnTop': z + head,
      if (bernoulli)
        'bernoulli': p + .5 * rho * v * v + rho * standardGravity * z,
    };
  }

  /// Passive volume-coordinate markers. The inverse integral makes axial
  /// arclength speed Q/A(x), with no invented molecular/turbulent trajectory.
  double tracer(double time, int index, {int count = 24}) {
    final target =
        ((index + .5) * volumeGrid.last / count + flow * time) %
        volumeGrid.last;
    int lo = 0, hi = intervals;
    while (hi - lo > 1) {
      final mid = (lo + hi) ~/ 2;
      if (volumeGrid[mid] < target) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final f = (target - volumeGrid[lo]) / (volumeGrid[hi] - volumeGrid[lo]);
    return -halfLength + 2 * halfLength * (lo + f) / intervals;
  }
}

FMState stokes(
  double radius,
  double sphereRho,
  double fluidRho,
  double viscosity,
  double travel,
  double time,
) {
  finitePositive([radius, sphereRho, fluidRho, viscosity, travel]);
  if (radius > .001 || sphereRho <= fluidRho || travel > .2 || time < 0) {
    throw ArgumentError(
      'Falling sphere: radius≤1 mm, sphere density above liquid, travel≤0.2 m; large vessel radius0.05 m',
    );
  }
  final volume = 4 * math.pi * radius * radius * radius / 3,
      mass = sphereRho * volume,
      b = 6 * math.pi * viscosity * radius,
      vt = (sphereRho - fluidRho) * volume * standardGravity / b,
      re = 2 * fluidRho * radius * vt / viscosity,
      tau = mass / b;
  if (re > .1) {
    throw ArgumentError(
      'Stokes approximation requires terminal Re≤0.1; increase viscosity or reduce sphere radius/density contrast',
    );
  }
  final u = time / tau,
      relax = -expm1(-u),
      distance =
          vt *
          (u < 1e-3
              ? tau * (u * u / 2 - u * u * u / 6 + u * u * u * u / 24)
              : time - tau * relax),
      speed = vt * relax;
  return {
    'position': distance,
    'speed': speed,
    'terminalSpeed': vt,
    'terminalReynolds': re,
    'reynolds': 2 * fluidRho * radius * speed / viscosity,
    'tau': tau,
    'weight': mass * standardGravity,
    'buoyantForce': fluidRho * volume * standardGravity,
    'drag': b * speed,
    'netForceDown':
        (sphereRho - fluidRho) * volume * standardGravity - b * speed,
  };
}

double stokesArrival(
  double radius,
  double sphereRho,
  double rho,
  double mu,
  double travel,
) {
  final s = stokes(radius, sphereRho, rho, mu, travel, 0);
  double lo = 0, hi = travel / s['terminalSpeed']! + s['tau']!;
  for (int i = 0; i < 80; i++) {
    final mid = (lo + hi) / 2;
    if (stokes(radius, sphereRho, rho, mu, travel, mid)['position']! < travel) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return (lo + hi) / 2;
}

double wellPsi(double x, double width, double mass, int n) {
  finitePositive([width, mass]);
  if (n < 1 || n > 6) throw ArgumentError('Eigenstate n1…6');
  return x <= 0 || x >= width
      ? 0
      : math.sqrt(2 / width) * math.sin(n * math.pi * x / width);
}

double wellEnergy(double width, double mass, int n) {
  finitePositive([width, mass]);
  if (n < 1 || n > 6) throw ArgumentError('Eigenstate n1…6');
  return n * n * math.pi * math.pi * hbar * hbar / (2 * mass * width * width);
}

FMState photoelectric(
  double frequency,
  double intensity,
  double area,
  double workFunction,
  double efficiency,
  double bias,
) {
  finitePositive([frequency, area, workFunction]);
  if (intensity < 0 || efficiency < 0 || efficiency > 1 || !bias.isFinite) {
    throw ArgumentError('Nonnegative intensity and efficiency0…1');
  }
  final photon = planck * frequency,
      k = math.max(0.0, photon - workFunction),
      emits = photon >= workFunction,
      flux = intensity * area / photon,
      sat = emits ? elementaryCharge * efficiency * flux : 0.0,
      collection = !emits
          ? 0.0
          : k == 0
          ? (bias > 0 ? 1.0 : 0.0)
          : (1 + elementaryCharge * bias / k).clamp(0, 1).toDouble();
  return {
    'frequency': frequency,
    'wavelength': lightSpeed / frequency,
    'photonEnergy': photon,
    'maximumKineticEnergy': k,
    'thresholdFrequency': workFunction / planck,
    'stoppingPotential': k / elementaryCharge,
    'photonFlux': flux,
    'saturationCurrent': sat,
    'collectionFraction': collection,
    'current': sat * collection,
    'emitting': emits && intensity > 0 && efficiency > 0 ? 1 : 0,
  };
}

double electronMomentum(double voltage) {
  if (voltage <= 0 || voltage > 200) {
    throw ArgumentError('Nonrelativistic electron source supports0<V≤200 V');
  }
  return math.sqrt(2 * electronMass * elementaryCharge * voltage);
}

class MatterDistribution {
  final double momentum, slitWidth, separation, distance, window;
  late final double wavelength, fresnel, fringe;
  late final ProbabilityGrid grid;
  MatterDistribution(
    this.momentum,
    this.slitWidth,
    this.separation,
    this.distance,
    this.window, {
    int intervals = 4096,
  }) {
    finitePositive([momentum, slitWidth, separation, distance, window]);
    final energy = momentum * momentum / (2 * electronMass);
    if (energy > 200 * elementaryCharge * (1 + 1e-12) ||
        slitWidth > separation / 2 ||
        window / distance > .05) {
      throw ArgumentError(
        'Far-field electron model: KE≤200 eV, slit width≤d/2, screen half-window / distance≤0.05',
      );
    }
    wavelength = planck / momentum;
    fresnel = separation * separation / (wavelength * distance);
    fringe = wavelength * distance / separation;
    if (fresnel > .01 || fringe < 8 * window / 160) {
      throw ArgumentError(
        'Far-field/grid validity: d²/(λD)≤0.01 and at least four histogram bins per fringe. Increase D, reduce d/V, or narrow the window',
      );
    }
    grid = ProbabilityGrid(-window, window, (y) {
      final a = math.pi * slitWidth * y / (wavelength * distance),
          b = math.pi * separation * y / (wavelength * distance),
          sinc = a.abs() < 1e-8 ? 1.0 : math.sin(a) / a;
      return sinc * sinc * math.pow(math.cos(b), 2);
    }, intervals: intervals);
  }
}

FMState hydrogenTransition(int lower, int upper) {
  if (lower < 1 || lower > 3 || upper <= lower || upper > 8) {
    throw ArgumentError('Hydrogen core: lower1…3 and upper>lower≤8');
  }
  final w = 1 / (rydbergHydrogen * (1 / (lower * lower) - 1 / (upper * upper))),
      f = lightSpeed / w,
      e = planck * f;
  return {
    'wavelength': w,
    'frequency': f,
    'photonEnergy': e,
    'lowerEnergy': -planck * lightSpeed * rydbergHydrogen / (lower * lower),
    'upperEnergy': -planck * lightSpeed * rydbergHydrogen / (upper * upper),
    'seriesLimit': lower * lower / rydbergHydrogen,
    'spectralRegion': w < 380e-9
        ? 0
        : w > 780e-9
        ? 2
        : 1,
  };
}

class Isotope {
  final String symbol;
  final int z, a;
  final double atomicMassU;
  const Isotope(this.symbol, this.z, this.a, this.atomicMassU);
  int get neutrons => a - z;
  double get binding =>
      (z * hydrogenMassU + neutrons * neutronMassU - atomicMassU) *
      atomicMass *
      lightSpeed *
      lightSpeed;
  String get label => '$symbol-$a';
}

// NIST Atomic Weights and Isotopic Compositions central masses (u). No natural
// abundance average is substituted for an isotope. No stability inferred.
const isotopes = [
  Isotope('H', 1, 2, 2.01410177812),
  Isotope('He', 2, 3, 3.0160293201),
  Isotope('He', 2, 4, 4.00260325413),
  Isotope('C', 6, 12, 12),
  Isotope('C', 6, 13, 13.00335483507),
  Isotope('Fe', 26, 54, 53.93960899),
  Isotope('Fe', 26, 56, 55.93493633),
  Isotope('Fe', 26, 58, 57.93327443),
];
FMState nuclear(int index) {
  if (index < 0 || index >= isotopes.length) {
    throw ArgumentError('Sourced isotope selection required');
  }
  final i = isotopes[index];
  return {
    'protons': i.z.toDouble(),
    'neutrons': i.neutrons.toDouble(),
    'massNumber': i.a.toDouble(),
    'atomicMass': i.atomicMassU * atomicMass,
    'atomicMassU': i.atomicMassU,
    'nuclearCharge': i.z * elementaryCharge,
    'bindingEnergy': i.binding,
    'bindingPerNucleon': i.binding / i.a,
  };
}

const decayNames = ['Cs-137', 'Co-60'];
// PTB representative rounded half-lives, not a new evaluated-data release.
const halfLives = [30.05 * julianYear, 5.27 * julianYear];
FMState decayExpectation(
  int mode,
  double n0,
  double time,
  double efficiency,
  double background,
) {
  if (mode < 0 ||
      mode >= halfLives.length ||
      n0 < 0 ||
      time < 0 ||
      efficiency < 0 ||
      efficiency > 1 ||
      background < 0) {
    throw ArgumentError('Supported parent decay and detector inputs');
  }
  final lambda = math.ln2 / halfLives[mode], n = n0 * math.exp(-lambda * time);
  return {
    'expectedRemaining': n,
    'expectedActivity': lambda * n,
    'decayConstant': lambda,
    'halfLife': halfLives[mode],
    'expectedDetectorRate': efficiency * lambda * n + background,
    'expectedDecays': n0 - n,
    'expectedDetected': efficiency * (n0 - n),
    'expectedBackground': background * time,
  };
}
