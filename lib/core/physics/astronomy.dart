import 'dart:math' as math;

import 'advanced.dart' show gravitationalConstant, keplerAt;
import 'waves_optics.dart' show lightSpeed;
import 'fluid_modern.dart' show planck, hydrogenTransition, julianYear;
import 'electronics_thermal.dart' show boltzmann, stefanBoltzmann, expm1;
import 'stochastic.dart';
export 'astronomy_data.dart';
export 'fluid_modern.dart' show julianYear;
import 'astronomy_data.dart';

const astroVersion = 'astronomy-8.0';
const astroDataset = 'jpl-j2000-frozen-mist1.2-sparc2016-2026-10';
const au = 149597870700.0,
    solarMu = 1.3271244e20,
    solarRadius = 6.957e8,
    solarLuminosity = 3.828e26,
    day = 86400.0;
const parsec = au * 648000 / math.pi,
    lightYear = lightSpeed * julianYear,
    solarMass = solarMu / gravitationalConstant,
    kpc = 1000 * parsec;
typedef AstroState = Map<String, double>;
void astroRequire(bool valid, String why) {
  if (!valid) throw ArgumentError(why);
}

/// Frozen JPL Table1 elements at J2000; deliberately no date-specific ephemeris claim.
class Planet {
  final String name;
  final double a, e, i, longitude, perihelion, node;
  const Planet(
    this.name,
    this.a,
    this.e,
    this.i,
    this.longitude,
    this.perihelion,
    this.node,
  );
  double get period => 2 * math.pi * math.sqrt(math.pow(a * au, 3) / solarMu);
  AstroState at(double elapsedSeconds) {
    astroRequire(
      elapsedSeconds.isFinite && elapsedSeconds.abs() <= 200 * julianYear,
      'Educational propagation limited to ±200 Julian years from J2000; elements frozen, not an ephemeris.',
    );
    final mean = (longitude - perihelion) * math.pi / 180;
    final q = keplerAt(
      solarMu,
      a * au,
      e,
      elapsedSeconds + mean / (2 * math.pi) * period,
    );
    final w = (perihelion - node) * math.pi / 180,
        o = node * math.pi / 180,
        inc = i * math.pi / 180;
    List<double> rotate(double x, double y) => [
      (math.cos(w) * math.cos(o) - math.sin(w) * math.sin(o) * math.cos(inc)) *
              x +
          (-math.sin(w) * math.cos(o) -
                  math.cos(w) * math.sin(o) * math.cos(inc)) *
              y,
      (math.cos(w) * math.sin(o) + math.sin(w) * math.cos(o) * math.cos(inc)) *
              x +
          (-math.sin(w) * math.sin(o) +
                  math.cos(w) * math.cos(o) * math.cos(inc)) *
              y,
      math.sin(w) * math.sin(inc) * x + math.cos(w) * math.sin(inc) * y,
    ];
    final r = rotate(q['x']!, q['y']!), v = rotate(q['vx']!, q['vy']!);
    final distance = math.sqrt(r.fold(0.0, (s, x) => s + x * x));
    return {
      'x': r[0],
      'y': r[1],
      'z': r[2],
      'distance': distance,
      'speed': math.sqrt(v.fold(0.0, (s, x) => s + x * x)),
      'semiMajorAxis': a * au,
      'period': period,
      'meanSpeed': 4 * a * au * ellipseE(e) / period,
      'daysFromJ2000': elapsedSeconds / day,
      'energy': -solarMu / (2 * a * au),
    };
  }
}

const planets = [
  Planet(
    'Mercury',
    .38709927,
    .20563593,
    7.00497902,
    252.25032350,
    77.45779628,
    48.33076593,
  ),
  Planet(
    'Venus',
    .72333566,
    .00677672,
    3.39467605,
    181.97909950,
    131.60246718,
    76.67984255,
  ),
  Planet(
    'Earth–Moon barycentre',
    1.00000261,
    .01671123,
    -.00001531,
    100.46457166,
    102.93768193,
    0,
  ),
  Planet(
    'Mars',
    1.52371034,
    .09339410,
    1.84969142,
    -4.55343205,
    -23.94362959,
    49.55953891,
  ),
  Planet(
    'Jupiter',
    5.20288700,
    .04838624,
    1.30439695,
    34.39644051,
    14.72847983,
    100.47390909,
  ),
  Planet(
    'Saturn',
    9.53667594,
    .05386179,
    2.48599187,
    49.95424423,
    92.59887831,
    113.66242448,
  ),
  Planet(
    'Uranus',
    19.18916464,
    .04725744,
    .77263783,
    313.23810451,
    170.95427630,
    74.01692503,
  ),
  Planet(
    'Neptune',
    30.06992276,
    .00859048,
    1.77004347,
    -55.12002969,
    44.96476227,
    131.78422574,
  ),
];
final _ellipseCache = <double, double>{};
double ellipseE(double e) {
  astroRequire(e >= 0 && e < 1, 'Elliptic eccentricity0…1');
  if (_ellipseCache.containsKey(e)) return _ellipseCache[e]!;
  if (_ellipseCache.length >= 32) {
    _ellipseCache.remove(_ellipseCache.keys.first);
  }
  return _ellipseCache[e] = integrate(
    (x) => math.sqrt(1 - e * e * math.sin(x) * math.sin(x)),
    0,
    math.pi / 2,
    256,
  );
}

double integrate(double Function(double) f, double a, double b, int n) {
  astroRequire(n >= 2 && n.isEven, 'Even Simpson interval count required');
  if (a == b) return 0;
  final h = (b - a) / n;
  double sum = f(a) + f(b);
  for (int i = 1; i < n; i++) {
    sum += (i.isEven ? 2 : 4) * f(a + i * h);
  }
  return sum * h / 3;
}

/// Track index, continuous age fraction. Never interpolate between masses or phases.
AstroState stellar(int track, double fraction) {
  astroRequire(
    track >= 0 &&
        track < stellarTracks.length &&
        fraction >= 0 &&
        fraction <= 1,
    'Select one supported MIST track and age fraction0…1.',
  );
  final rows = stellarTracks[track];
  final age = rows.first[0] + fraction * (rows.last[0] - rows.first[0]);
  int lo = 0, hi = rows.length - 1;
  while (hi - lo > 1) {
    final m = (lo + hi) ~/ 2;
    if (rows[m][0] <= age) {
      lo = m;
    } else {
      hi = m;
    }
  }
  final a = rows[lo], b = rows[hi];
  final f = a[3] == b[3]
      ? ((age - a[0]) / (b[0] - a[0])).clamp(0, 1).toDouble()
      : 0.0;
  final logL = a[1] + f * (b[1] - a[1]), logT = a[2] + f * (b[2] - a[2]);
  final luminosity = math.pow(10, logL) * solarLuminosity,
      temperature = math.pow(10, logT).toDouble();
  return {
    'age': age * julianYear,
    'luminosity': luminosity.toDouble(),
    'temperature': temperature,
    'radius': math.sqrt(
      luminosity / (4 * math.pi * stefanBoltzmann * math.pow(temperature, 4)),
    ),
    'phase': (fraction == 1 ? rows.last[3] : a[3]),
    'logL': logL,
    'logT': logT,
    'initialMass': stellarMasses[track] * solarMass,
  };
}

String stellarPhase(double code) => switch (code.round()) {
  -1 => 'Pre-main sequence',
  0 => 'Main sequence',
  2 => 'Subgiant / red giant',
  3 => 'Core helium burning',
  4 => 'Early AGB',
  5 => 'Late giant / advanced evolution (phase5)',
  6 => 'Post-AGB',
  9 => 'Wolf–Rayet',
  _ => 'Late evolution (track-defined)',
};

double blackbodyLambda(double wavelength, double temperature) {
  astroRequire(
    wavelength > 0 &&
        temperature > 0 &&
        wavelength.isFinite &&
        temperature.isFinite,
    'Positive wavelength/temperature',
  );
  final x = planck * lightSpeed / (wavelength * boltzmann * temperature);
  return x > 700
      ? 0
      : 2 *
            planck *
            lightSpeed *
            lightSpeed /
            (math.pow(wavelength, 5) * expm1(x));
}

double dopplerFactor(double velocity) {
  astroRequire(
    velocity.abs() <= .02 * lightSpeed,
    'Radial velocity bounded to0.02c. Positive is receding.',
  );
  final b = velocity / lightSpeed;
  return math.sqrt((1 + b) / (1 - b));
}

final balmerVacuum = [
  for (int n = 3; n <= 6; n++) hydrogenTransition(2, n)['wavelength']!,
];

/// Unit-peak Planck B_lambda times illustrative Gaussian line deficits, convolved
/// analytically with an instrumental Gaussian of FWHM lambda/R. No observed star.
AstroState spectrumAt(
  double wavelength,
  double temperature,
  double velocity,
  double resolution, {
  bool lines = true,
}) {
  astroRequire(
    wavelength >= 350e-9 &&
        wavelength <= 800e-9 &&
        temperature >= 3000 &&
        temperature <= 20000 &&
        resolution >= 500 &&
        resolution <= 10000,
    'Synthetic spectrum:350…800nm,3000…20000K,R500…10000',
  );
  final d = dopplerFactor(velocity),
      rest = wavelength / d,
      peak = 2.897771955e-3 / temperature;
  final continuum =
      blackbodyLambda(rest, temperature) / blackbodyLambda(peak, temperature);
  double deficit = 0, restDeficit = 0;
  for (int j = 0; j < balmerVacuum.length; j++) {
    final centre = balmerVacuum[j] * d,
        intrinsic = .12e-9 * d,
        instrument = centre / (resolution * 2.354820045),
        sigma = math.sqrt(intrinsic * intrinsic + instrument * instrument);
    final restSigma = math.sqrt(
      math.pow(.12e-9, 2) +
          math.pow(balmerVacuum[j] / (resolution * 2.354820045), 2),
    );
    restDeficit +=
        (.5 - .06 * j) *
        .12e-9 /
        restSigma *
        math.exp(-.5 * math.pow((wavelength - balmerVacuum[j]) / restSigma, 2));
    deficit +=
        (.5 - .06 * j) *
        intrinsic /
        sigma *
        math.exp(-.5 * math.pow((wavelength - centre) / sigma, 2));
  }
  return {
    't': wavelength,
    'continuum': continuum,
    'syntheticFlux': continuum * (1 - (lines ? deficit : 0)),
    'restReference':
        blackbodyLambda(wavelength, temperature) /
        blackbodyLambda(peak, temperature) *
        (1 - (lines ? restDeficit : 0)),
    'peakWavelength': peak * d,
  };
}

/// Hernquist spherical bulge + exact equatorial Miyamoto–Nagai disk + optional log halo.
AstroState galaxy(
  double radius,
  double bulgeMass,
  double diskMass,
  double diskScale,
  double haloSpeed, {
  bool halo = true,
}) {
  astroRequire(
    radius > 0 &&
        radius <= 40 * kpc &&
        bulgeMass >= 0 &&
        diskMass > 0 &&
        diskScale > 0 &&
        haloSpeed >= 0,
    'Positive bounded galactic radius/mass/scales',
  );
  const c = .6 * kpc, b = .3 * kpc, rc = 4 * kpc;
  final vb2 =
          gravitationalConstant * bulgeMass * radius / math.pow(radius + c, 2),
      vd2 =
          gravitationalConstant *
          diskMass *
          radius *
          radius /
          math.pow(radius * radius + math.pow(diskScale + b, 2), 1.5),
      vh2 = halo
          ? haloSpeed *
                haloSpeed *
                radius *
                radius /
                (radius * radius + rc * rc)
          : 0.0;
  final potential =
      -gravitationalConstant * bulgeMass / (radius + c) -
      gravitationalConstant *
          diskMass /
          math.sqrt(radius * radius + math.pow(diskScale + b, 2)) +
      (halo
          ? .5 *
                haloSpeed *
                haloSpeed *
                math.log((radius * radius + rc * rc) / (rc * rc))
          : 0);
  return {
    'radius': radius,
    'speed': math.sqrt(vb2 + vd2 + vh2),
    'bulgeSpeed': math.sqrt(vb2),
    'diskSpeed': math.sqrt(vd2),
    'haloSpeed': math.sqrt(vh2),
    'potential': potential,
    'sphericalEquivalentMass':
        (vb2 + vd2 + vh2) * radius / gravitationalConstant,
  };
}

AstroState cosmology(
  double z,
  double h0,
  double matter, {
  int intervals = 1024,
}) {
  astroRequire(
    z >= 0 && z <= 5 && h0 >= 50 && h0 <= 90 && matter >= .1 && matter <= .5,
    'Flat ΛCDM: z0…5,H0 50…90km/s/Mpc,Ωm0.1…0.5',
  );
  const radiation = 0.00009;
  final lambda = 1 - matter - radiation, H = h0 * 1000 / (1e6 * parsec);
  double e(double x) => math.sqrt(
    radiation * math.pow(1 + x, 4) + matter * math.pow(1 + x, 3) + lambda,
  );
  final dc = lightSpeed / H * integrate((x) => 1 / e(x), 0, z, intervals),
      lookback =
          1 / H * integrate((x) => 1 / ((1 + x) * e(x)), 0, z, intervals);
  return {
    'redshift': z,
    'scaleFactor': 1 / (1 + z),
    'lookback': lookback,
    'lightTravelDistance': lightSpeed * lookback,
    'comovingDistance': dc,
    'luminosityDistance': (1 + z) * dc,
    'angularDistance': dc / (1 + z),
    'recessionNow': H * dc,
    'hubbleAtEmission': H * e(z),
    'omegaLambda': lambda,
    'omegaRadiation': radiation,
    'hubbleSI': H,
  };
}

double overlapArea(double r, double p, double d) {
  astroRequire(
    r > 0 && p > 0 && d >= 0 && [r, p, d].every((x) => x.isFinite),
    'Positive finite circle radii and nonnegative separation',
  );
  if (d >= r + p) return 0;
  if (d <= (r - p).abs()) return math.pi * math.pow(math.min(r, p), 2);
  final a = math.acos(((d * d + r * r - p * p) / (2 * d * r)).clamp(-1, 1)),
      b = math.acos(((d * d + p * p - r * r) / (2 * d * p)).clamp(-1, 1));
  return r * r * a +
      p * p * b -
      .5 *
          math.sqrt(
            math.max(0, (-d + r + p) * (d + r - p) * (d - r + p) * (d + r + p)),
          );
}

AstroState transit(
  double stellarMassRatio,
  double stellarRadiusRatio,
  double planetRadiusRatio,
  double periodDays,
  double inclinationDeg,
  double time,
) {
  astroRequire(
    stellarMassRatio >= .5 &&
        stellarMassRatio <= 2 &&
        stellarRadiusRatio >= .5 &&
        stellarRadiusRatio <= 2 &&
        planetRadiusRatio >= .01 &&
        planetRadiusRatio <= .2 &&
        periodDays >= 1 &&
        periodDays <= 30 &&
        inclinationDeg >= 80 &&
        inclinationDeg <= 90,
    'Supported synthetic circular system: M/Rstar0.5…2 solar, Rp/Rs0.01…0.2,P1…30d,i80…90°',
  );
  final mu = solarMu * stellarMassRatio,
      period = periodDays * day,
      star = stellarRadiusRatio * solarRadius,
      planet = planetRadiusRatio * star,
      a = math.pow(mu * math.pow(period / (2 * math.pi), 2), 1 / 3).toDouble(),
      inc = inclinationDeg * math.pi / 180,
      phase = 2 * math.pi * time / period;
  astroRequire(
    a > star + planet,
    'Orbit intersects stellar surface; unsupported',
  );
  final x = a * math.sin(phase),
      y = a * math.cos(inc) * math.cos(phase),
      front = math.cos(phase) > 0,
      d = math.sqrt(x * x + y * y),
      b = a * math.cos(inc) / star,
      k = planet / star;
  final depth = front
      ? overlapArea(star, planet, d) / (math.pi * star * star)
      : 0.0;
  final transitPossible = b < 1 + k,
      term = transitPossible
          ? math.sqrt((1 + k) * (1 + k) - b * b) / (a / star * math.sin(inc))
          : 0.0;
  return {
    'x': x,
    'y': y,
    'projectedSeparation': d,
    'front': front ? 1 : 0,
    'impactParameter': b,
    'flux': 1 - depth,
    'instantDepth': depth,
    'midDepth': overlapArea(star, planet, b * star) / (math.pi * star * star),
    'smallPlanetFullDepth': k * k,
    'duration': transitPossible
        ? period / math.pi * math.asin(term.clamp(0, 1))
        : 0,
    'semiMajorAxis': a,
    'period': period,
    'starRadius': star,
    'planetRadius': planet,
  };
}

List<AstroState> noisyTransit(Map<String, double> p, int seed, double noise) {
  final rng = SeededRandom(seed),
      period = p['periodDays']! * day,
      window = period * .04;
  return [
    for (int i = 0; i <= 240; i++)
      (() {
        final t = -window + 2 * window * i / 240,
            s = transit(
              p['starMass']!,
              p['starRadius']!,
              p['radiusRatio']!,
              p['periodDays']!,
              p['inclination']!,
              t,
            );
        return {
          't': t,
          'flux': s['flux']!,
          'syntheticFlux': s['flux']! + noise * rng.normal(),
        };
      })(),
  ];
}
