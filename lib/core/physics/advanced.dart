import 'dart:math' as math;

import 'dynamics.dart';

const advancedVersion = 'energy-gravity-oscillation-3.0';
const gravitationalConstant = 6.67430e-11;
const earthMu = 3.98600435507e14;
const earthRadius = 6371000.0;
const earthMass = earthMu / gravitationalConstant;
const moonMass = 7.342e22;
typedef LabState = Map<String, double>;

double kinetic(double m, double v) => .5 * m * v * v;
double gravityPotential(double mu, double r) => -mu / r;
double escapeSpeed(double mu, double r) => math.sqrt(2 * mu / r);
double orbitalEnergy(double mu, Vec2 r, Vec2 v) =>
    .5 * v.magnitude * v.magnitude - mu / r.magnitude;

/// Exact homogeneous solution, including all three damping regimes.
({double x, double v}) freeOscillator(
  double m,
  double k,
  double b,
  double x0,
  double v0,
  double t,
) {
  final alpha = b / (2 * m), w2 = k / m, delta = w2 - alpha * alpha;
  if (delta.abs() < 1e-10 * w2) {
    final q = v0 + alpha * x0, decay = math.exp(-alpha * t);
    return (x: (x0 + q * t) * decay, v: (q - alpha * (x0 + q * t)) * decay);
  }
  if (delta > 0) {
    final w = math.sqrt(delta), q = (v0 + alpha * x0) / w;
    final c = math.cos(w * t), s = math.sin(w * t), e = math.exp(-alpha * t);
    final x = e * (x0 * c + q * s);
    return (x: x, v: e * w * (-x0 * s + q * c) - alpha * x);
  }
  final z = math.sqrt(-delta), r1 = -alpha + z, r2 = -alpha - z;
  final c1 = (v0 - r2 * x0) / (r1 - r2), c2 = x0 - c1;
  return (
    x: c1 * math.exp(r1 * t) + c2 * math.exp(r2 * t),
    v: c1 * r1 * math.exp(r1 * t) + c2 * r2 * math.exp(r2 * t),
  );
}

({double amplitude, double phase}) drivenResponse(
  double m,
  double k,
  double b,
  double force,
  double omega,
) {
  final real = k - m * omega * omega, imag = b * omega;
  final d = math.sqrt(real * real + imag * imag);
  return (
    amplitude: d < 1e-12 ? (force == 0 ? 0 : double.infinity) : force / d,
    phase: math.atan2(imag, real),
  );
}

({double x, double v}) drivenOscillator(
  double m,
  double k,
  double b,
  double force,
  double omega,
  double x0,
  double v0,
  double t,
) {
  final w0 = math.sqrt(k / m);
  if (b == 0 && (omega - w0).abs() < 1e-9 * w0) {
    final homogeneous = freeOscillator(m, k, 0, x0, v0, t);
    final c = force / (2 * m * w0);
    return (
      x: homogeneous.x + c * t * math.sin(w0 * t),
      v: homogeneous.v + c * (math.sin(w0 * t) + w0 * t * math.cos(w0 * t)),
    );
  }
  final response = drivenResponse(m, k, b, force, omega);
  final a = response.amplitude, phi = response.phase;
  final h = freeOscillator(
    m,
    k,
    b,
    x0 - a * math.cos(phi),
    v0 - a * omega * math.sin(phi),
    t,
  );
  return (
    x: h.x + a * math.cos(omega * t - phi),
    v: h.v - a * omega * math.sin(omega * t - phi),
  );
}

/// Symmetric eigenproblem in mass-weighted coordinates for wall-k1-m1-kc-m2-k2-wall.
class CoupledSolution {
  final double m1, m2, k1, k2, kc;
  late final double theta, low, high;
  CoupledSolution(this.m1, this.m2, this.k1, this.k2, this.kc) {
    final a = (k1 + kc) / m1, d = (k2 + kc) / m2, b = -kc / math.sqrt(m1 * m2);
    theta = .5 * math.atan2(2 * b, a - d);
    final gap = math.sqrt((a - d) * (a - d) + 4 * b * b);
    low = math.sqrt((a + d - gap) / 2);
    high = math.sqrt((a + d + gap) / 2);
  }
  LabState at(double x1, double x2, double v1, double v2, double t) {
    final c = math.cos(theta),
        s = math.sin(theta),
        a = math.sqrt(m1),
        b = math.sqrt(m2);
    final qh = c * a * x1 + s * b * x2, ql = -s * a * x1 + c * b * x2;
    final uh = c * a * v1 + s * b * v2, ul = -s * a * v1 + c * b * v2;
    final h = qh * math.cos(high * t) + uh / high * math.sin(high * t);
    final l = ql * math.cos(low * t) + ul / low * math.sin(low * t);
    final dh = -qh * high * math.sin(high * t) + uh * math.cos(high * t);
    final dl = -ql * low * math.sin(low * t) + ul * math.cos(low * t);
    return {
      'x': (c * h - s * l) / a,
      'x2': (s * h + c * l) / b,
      'vx': (c * dh - s * dl) / a,
      'v2': (s * dh + c * dl) / b,
    };
  }
}

List<double> rk4(
  List<double> y,
  double h,
  List<double> Function(List<double>) f,
) {
  List<double> add(List<double> a, List<double> b, double factor) => [
    for (int i = 0; i < a.length; i++) a[i] + factor * b[i],
  ];
  final a = f(y), b = f(add(y, f(y), h / 2));
  final c = f(add(y, b, h / 2)), d = f(add(y, c, h));
  return [
    for (int i = 0; i < y.length; i++)
      y[i] + h / 6 * (a[i] + 2 * b[i] + 2 * c[i] + d[i]),
  ];
}

double pendulumPeriod(double length, double g, double amplitude) {
  final k = math.sin(amplitude / 2);
  double f(double q) => 1 / math.sqrt(1 - k * k * math.sin(q) * math.sin(q));
  const n = 256;
  final h = math.pi / (2 * n);
  double sum = f(0) + f(math.pi / 2);
  for (int i = 1; i < n; i++) {
    sum += (i.isEven ? 2 : 4) * f(i * h);
  }
  return 4 * math.sqrt(length / g) * sum * h / 3;
}

/// Solves M=E-e sinE, advancing by mean anomaly (physical time), not angle.
LabState keplerAt(double mu, double a, double e, double t) {
  final n = math.sqrt(mu / (a * a * a)), mean = (n * t) % (2 * math.pi);
  double eccentric = mean;
  for (int i = 0; i < 16; i++) {
    eccentric -=
        (eccentric - e * math.sin(eccentric) - mean) /
        (1 - e * math.cos(eccentric));
  }
  final c = math.cos(eccentric),
      s = math.sin(eccentric),
      z = math.sqrt(1 - e * e),
      factor = n * a / (1 - e * c);
  return {
    'x': a * (c - e),
    'y': a * z * s,
    'vx': -factor * s,
    'vy': factor * z * c,
    'meanAnomaly': n * t,
    'eccentricAnomaly': eccentric,
    'area': .5 * a * a * z * n * t,
  };
}

/// One fixed display tick is 1/120 s. Orbit ticks represent 4 physical seconds (480×).
class AdvancedRun {
  static const dt = 1 / 120;
  final int kind;
  final Map<String, double> p;
  final double stepSize;
  int ticks = 0;
  double time = 0, _loss = 0, _lastCross = -1;
  bool finished = false, impacted = false;
  LabState state = {};
  final List<LabState> samples = [];
  late final double initialEnergy;
  late final CoupledSolution coupled;
  double v(String name, [double fallback = 0]) => p[name] ?? fallback;
  double get timeScale => kind >= 9 && kind <= 11 ? 480 : 1;
  bool get staticLab => kind >= 6 && kind <= 8;
  AdvancedRun(this.kind, Map<String, double> parameters, {this.stepSize = dt})
    : p = Map.of(parameters) {
    if (kind < 0 ||
        kind >= 18 ||
        p.values.any((x) => !x.isFinite) ||
        stepSize <= 0) {
      throw ArgumentError('Invalid model');
    }
    for (final key in [
      'm',
      'm2',
      'k',
      'k2',
      'g',
      'length',
      'duration',
      'source',
      'r',
      'a',
    ]) {
      if (p.containsKey(key) && p[key]! <= 0) {
        throw ArgumentError('Positive $key required');
      }
    }
    if (kind == 0 &&
        v('force') * math.sin(v('angle') * math.pi / 180) >
            v('m') * standardGravity + 1e-9) {
      throw ArgumentError('Contact would be lost');
    }
    if (kind >= 6 && kind <= 10 && v('r') <= (kind == 6 ? 1.273 : 1)) {
      throw ArgumentError('Exterior non-overlap required');
    }
    if (kind == 11 &&
        (v('e') < 0 || v('e') > .8 || v('a') * (1 - v('e')) <= 1)) {
      throw ArgumentError('Intersecting ellipse');
    }
    if (kind == 13 &&
        1 -
                math.cos(v('angle') * math.pi / 180) +
                .5 * v('length') / v('g') * v('v0') * v('v0') >
            1 - math.cos(75 * math.pi / 180) + 1e-10) {
      throw ArgumentError('Pendulum energy exceeds taut core range');
    }
    if (kind == 17) {
      coupled = CoupledSolution(v('m'), v('m2'), v('k'), v('k2'), v('kc'));
    }
    state = {'x': v('x0'), 'vx': v('v0'), 'y': 0, 'vy': 0, 'loss': 0};
    if (kind == 3) {
      state['x'] = v('x0');
    }
    if (kind == 13) {
      state['x'] = v('angle') * math.pi / 180;
    }
    if (kind == 9 || kind == 10) {
      state = {
        'x': v('r') * earthRadius,
        'y': 0,
        'vx': v('vr') * 1000,
        'vy': v('vt') * 1000,
      };
    }
    _calculate();
    initialEnergy = state['total'] ?? state['specificEnergy'] ?? 0;
    _capture();
  }
  void _capture() {
    if (samples.isNotEmpty && samples.last['t'] == time) {
      samples.removeLast();
    }
    samples.add(Map.of(state));
    if (samples.length > 301) {
      samples.removeAt(0);
    }
  }

  void seek(double seconds) {
    if (staticLab) {
      _capture();
      return;
    }
    final count = (seconds / (stepSize * timeScale)).round().clamp(
      0,
      (120 / stepSize).round(),
    );
    while (ticks < count && !finished) {
      step();
    }
    _capture();
  }

  void step({bool capture = false}) {
    if (finished || staticLab) {
      return;
    }
    final h = stepSize * timeScale, old = Map<String, double>.of(state);
    if (kind == 0) {
      final f = v('force') * math.cos(v('angle') * math.pi / 180);
      final normal = math.max(
        0.0,
        v('m') * standardGravity -
            v('force') * math.sin(v('angle') * math.pi / 180),
      );
      final next = frictionStep(
        state['x']!,
        state['vx']!,
        f,
        v('m'),
        normal,
        v('mu'),
        v('mu'),
        h,
      );
      final oldX = state['x']!, oldV = state['vx']!;
      final accel =
          (f - (oldV == 0 ? f.sign : oldV.sign) * v('mu') * normal) / v('m');
      final stop = accel == 0 ? -1.0 : -oldV / accel;
      final turning = oldX + oldV * stop + .5 * accel * stop * stop;
      final travel = stop > 0 && stop < h
          ? (turning - oldX).abs() + (next.x - turning).abs()
          : (next.x - oldX).abs();
      _loss += math.max(
        0,
        f * (next.x - state['x']!) -
            (kinetic(v('m'), next.v) - kinetic(v('m'), state['vx']!)),
      );
      state.addAll({
        'x': next.x,
        'vx': next.v,
        'ax': next.a,
        'friction': next.friction,
        'distance': (state['distance'] ?? 0) + travel,
      });
    } else if (kind == 3) {
      final r = v('radius'), m = v('m'), drag = v('drag');
      final y = rk4(
        [state['x']!, state['vx']!, _loss],
        h,
        (s) => [
          s[1],
          -(s[0] / (r * r) * s[1] * s[1] +
                  standardGravity * s[0] / r +
                  drag / m * s[1]) /
              (1 + s[0] * s[0] / (r * r)),
          drag * s[1] * s[1],
        ],
      );
      state['x'] = y[0];
      state['vx'] = y[1];
      _loss = y[2];
    } else if (kind == 9 || kind == 10) {
      final mu = earthMu * v('source');
      List<double> integrate(double duration) {
        final r = Vec2(old['x']!, old['y']!),
            velocity = Vec2(old['vx']!, old['vy']!);
        final acc = r * (-mu / math.pow(r.magnitude, 3));
        final pos = r + velocity * duration + acc * (.5 * duration * duration);
        final acc2 = pos * (-mu / math.pow(pos.magnitude, 3));
        final vel = velocity + (acc + acc2) * (.5 * duration);
        return [pos.x, pos.y, vel.x, vel.y];
      }

      var y = integrate(h);
      if (Vec2(y[0], y[1]).magnitude <= earthRadius) {
        double lo = 0, hi = h;
        for (int i = 0; i < 40; i++) {
          final mid = (lo + hi) / 2, s = integrate(mid);
          if (Vec2(s[0], s[1]).magnitude > earthRadius) {
            lo = mid;
          } else {
            hi = mid;
          }
        }
        y = integrate(hi);
        time += hi;
        impacted = true;
        finished = true;
      }
      state.addAll({'x': y[0], 'y': y[1], 'vx': y[2], 'vy': y[3]});
    } else if (kind == 13) {
      var y = [state['x']!, state['vx']!];
      for (int i = 0; i < 4; i++) {
        y = rk4(
          y,
          h / 4,
          (s) => [s[1], -v('g') / v('length') * math.sin(s[0])],
        );
      }
      if (old['x']! < 0 && y[0] >= 0 && y[1] > 0) {
        final crossing = time + h * (-old['x']! / (y[0] - old['x']!));
        if (_lastCross >= 0) {
          state['measuredPeriod'] = crossing - _lastCross;
        }
        _lastCross = crossing;
      }
      state['x'] = y[0];
      state['vx'] = y[1];
    }
    ticks++;
    if (!impacted) {
      time = ticks * h;
    }
    _calculate();
    if (ticks * stepSize >= 120 ||
        (kind == 0 && state['distance']! >= v('distance'))) {
      finished = true;
    }
    if (capture || ticks % 8 == 0 || finished) {
      _capture();
    }
  }

  void _calculate() {
    final t = time, m = v('m', 1);
    state['t'] = time;
    if (kind == 0) {
      final x = state['x']!,
          speed = state['vx']!,
          f = v('force') * math.cos(v('angle') * math.pi / 180);
      final applied = f * (x - v('x0'));
      state.addAll({
        'appliedWork': applied,
        'gravityWork': 0,
        'normalWork': 0,
        'frictionWork': -_loss,
        'netWork': applied - _loss,
        'deltaK': kinetic(m, speed) - kinetic(m, v('v0')),
        'normal': math.max(
          0.0,
          m * standardGravity -
              v('force') * math.sin(v('angle') * math.pi / 180),
        ),
        'distance': (state['distance'] ?? 0),
        'K': kinetic(m, speed),
      });
    } else if (kind == 1) {
      state.addAll({
        'x': v('speed') * t,
        'vx': v('speed'),
        'K': kinetic(m, v('speed')),
        'total': kinetic(m, v('speed')),
      });
    } else if (kind == 2) {
      final height = v('height') * (t / 4).clamp(0, 1);
      state.addAll({
        'x': 0,
        'y': height,
        'U': m * v('g') * (height - v('zero')),
        'deltaU': m * v('g') * height,
        'targetDeltaU': m * v('g') * v('height'),
        'referenceU': -m * v('g') * v('zero'),
      });
      if (t >= 4) {
        finished = true;
      }
    } else if (kind == 3) {
      final x = state['x']!,
          speed = state['vx']!,
          r = v('radius'),
          y = x * x / (2 * r);
      final k = .5 * m * (1 + x * x / (r * r)) * speed * speed,
          u = m * standardGravity * y;
      state.addAll({
        'y': y,
        'K': k,
        'U': u,
        'loss': _loss,
        'total': k + u + _loss,
        'mechanical': k + u,
      });
    } else if (kind == 4) {
      final progress = (t / v('duration')).clamp(0, 1),
          speed = v('height') / v('duration');
      state.addAll({
        'y': v('height') * progress,
        'work': m * standardGravity * v('height') * progress,
        'power': m * standardGravity * speed,
        'instantPower': progress < 1 ? m * standardGravity * speed : 0,
        'liftForce': m * standardGravity,
        'vx': 0,
        'vy': progress < 1 ? speed : 0,
      });
      if (progress >= 1) {
        finished = true;
      }
    } else if (kind == 5) {
      final input = v('input') * (t / 5).clamp(0, 1), eta = v('eta');
      state.addAll({
        'input': input,
        'useful': input * eta,
        'loss': input * (1 - eta),
        'efficiency': eta,
        'conversionPower': v('input') / 5,
        'y': input * eta / (m * standardGravity),
      });
      if (t >= 5) {
        finished = true;
      }
    } else if (kind >= 6 && kind <= 8) {
      final mu = earthMu * v('source'),
          r = v('r') * earthRadius,
          angle = v('angle') * math.pi / 180;
      final field = mu / (r * r),
          potential = -mu / r,
          test = kind == 6 ? v('second') * moonMass : m;
      state.addAll({
        'x': r * math.cos(angle),
        'y': r * math.sin(angle),
        'radius': r,
        'altitude': r - earthRadius,
        'field': field,
        'gx': -field * math.cos(angle),
        'gy': -field * math.sin(angle),
        'potential': potential,
        'U': test * potential,
        'force': test * field,
        'force2': -test * field,
      });
    } else if (kind >= 9 && kind <= 11) {
      final mu = earthMu * v('source');
      if (kind == 11) {
        state.addAll(keplerAt(mu, v('a') * earthRadius, v('e'), t));
      }
      final r = Vec2(state['x']!, state['y']!),
          vel = Vec2(state['vx']!, state['vy']!),
          e = orbitalEnergy(mu, r, vel),
          angular = r.cross(vel);
      final eccentricity = math.sqrt(
        math.max(0, 1 + 2 * e * angular * angular / (mu * mu)),
      );
      final a = e < 0 ? -mu / (2 * e) : 0,
          peri = angular * angular / (mu * (1 + eccentricity));
      state.addAll({
        'radius': r.magnitude,
        'altitude': r.magnitude - earthRadius,
        'speed': vel.magnitude,
        'specificEnergy': e,
        'angularMomentum': angular,
        'eccentricity': eccentricity,
        'periapsis': peri,
        'escape': escapeSpeed(mu, r.magnitude),
        'bound': e < -1e-6 ? 1 : 0,
        'collision': impacted ? 1 : 0,
      });
      if (e < 0 && peri > earthRadius) {
        state['period'] = 2 * math.pi * math.sqrt(a * a * a / mu);
        state['apoapsis'] = a * (1 + eccentricity);
      }
    } else if (kind == 13) {
      final theta = state['x']!,
          omega = state['vx']!,
          length = v('length'),
          g = v('g');
      final energy =
          .5 * m * length * length * omega * omega +
          m * g * length * (1 - math.cos(theta));
      final amplitude = math.acos((1 - energy / (m * g * length)).clamp(-1, 1));
      state.addAll({
        'angle': theta * 180 / math.pi,
        'angularVelocity': omega,
        'K': .5 * m * length * length * omega * omega,
        'U': m * g * length * (1 - math.cos(theta)),
        'total': energy,
        'tension': m * (g * math.cos(theta) + length * omega * omega),
        'smallPeriod': 2 * math.pi * math.sqrt(length / g),
        'period': pendulumPeriod(length, g, amplitude),
      });
    } else if (kind == 17) {
      state.addAll(coupled.at(v('x0'), v('x2'), v('v0'), v('v2'), t));
      final x = state['x']!,
          x2 = state['x2']!,
          k =
              .5 * m * state['vx']! * state['vx']! +
              .5 * v('m2') * state['v2']! * state['v2']!,
          u1 = .5 * v('k') * x * x,
          u2 = .5 * v('k2') * x2 * x2,
          uc = .5 * v('kc') * (x2 - x) * (x2 - x);
      state.addAll({
        'K': k,
        'U': u1 + u2 + uc,
        'total': k + u1 + u2 + uc,
        'energy1': kinetic(m, state['vx']!) + u1 + uc / 2,
        'energy2': kinetic(v('m2'), state['v2']!) + u2 + uc / 2,
        'lowFrequency': coupled.low / (2 * math.pi),
        'highFrequency': coupled.high / (2 * math.pi),
      });
    } else {
      final b = kind >= 15 ? v('b') : 0.0, k = v('k'), w0 = math.sqrt(k / m);
      final solution = kind == 16
          ? drivenOscillator(
              m,
              k,
              b,
              v('force'),
              v('omega'),
              v('x0'),
              v('v0'),
              t,
            )
          : freeOscillator(m, k, b, v('x0'), v('v0'), t);
      final force = kind == 16 ? v('force') * math.cos(v('omega') * t) : 0.0;
      final energy = kinetic(m, solution.v) + .5 * k * solution.x * solution.x;
      state.addAll({
        'x': solution.x,
        'vx': solution.v,
        'ax': (force - b * solution.v - k * solution.x) / m,
        'K': kinetic(m, solution.v),
        'U': .5 * k * solution.x * solution.x,
        'total': energy,
        'force': force,
        'period': 2 * math.pi / w0,
        'frequency': w0 / (2 * math.pi),
        'critical': 2 * math.sqrt(k * m),
        'regime': b < 2 * math.sqrt(k * m) - 1e-8
            ? -1
            : b > 2 * math.sqrt(k * m) + 1e-8
            ? 1
            : 0,
        'naturalOmega': w0,
        'dampedOmega': math.sqrt(math.max(0, w0 * w0 - b * b / (4 * m * m))),
        'peakOmega': math.sqrt(math.max(0, w0 * w0 - b * b / (2 * m * m))),
      });
      if (kind == 15) {
        state['loss'] =
            kinetic(m, v('v0')) + .5 * k * v('x0') * v('x0') - energy;
        final alpha = b / (2 * m), wd = state['dampedOmega']!;
        if (wd > 0) {
          state['envelope'] =
              math.sqrt(
                v('x0') * v('x0') +
                    math.pow((v('v0') + alpha * v('x0')) / wd, 2),
              ) *
              math.exp(-alpha * t);
        }
      }
      if (kind == 16) {
        final response = drivenResponse(m, k, b, v('force'), v('omega'));
        if (response.amplitude.isFinite) {
          state['steadyAmplitude'] = response.amplitude;
        }
        state['phase'] = response.phase;
      }
    }
  }
}
