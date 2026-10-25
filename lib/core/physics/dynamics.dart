import 'dart:math' as math;

const standardGravity = 9.80665;
const dynamicsVersion = 'dynamics-2.0';

class Vec2 {
  final double x, y;
  const Vec2(this.x, this.y);
  Vec2 operator +(Vec2 b) => Vec2(x + b.x, y + b.y);
  Vec2 operator -(Vec2 b) => Vec2(x - b.x, y - b.y);
  Vec2 operator *(double s) => Vec2(x * s, y * s);
  double get magnitude => math.sqrt(x * x + y * y);
  double cross(Vec2 b) => x * b.y - y * b.x;
  static Vec2 polar(double magnitude, double radians) =>
      Vec2(magnitude * math.cos(radians), magnitude * math.sin(radians));
}

class ReferenceFrame {
  final Vec2 origin, velocity;
  const ReferenceFrame(this.origin, this.velocity);
  Vec2 position(Vec2 world, double t) => world - origin - velocity * t;
  Vec2 relativeVelocity(Vec2 world) => world - velocity;
}

double torque(Vec2 position, Vec2 force, Vec2 pivot) =>
    (position - pivot).cross(force);
Vec2 centreOfMass(List<double> masses, List<Vec2> points) {
  final total = masses.fold<double>(0, (a, b) => a + b);
  if (total <= 0 || masses.length != points.length) {
    throw ArgumentError('Positive total mass and matching points required');
  }
  var sum = const Vec2(0, 0);
  for (int i = 0; i < masses.length; i++) {
    if (masses[i] <= 0) {
      throw ArgumentError('Positive masses required');
    }
    sum = sum + points[i] * masses[i];
  }
  return sum * (1 / total);
}

({double a, double tension}) atwood(double m1, double m2) {
  final a = (m2 - m1) * standardGravity / (m1 + m2);
  return (a: a, tension: m1 * (standardGravity + a));
}

/// One movable sheave: two segments support load M, effort mass m falls twice as far.
({double a, double tension}) movablePulley(double load, double effort) {
  final a = (2 * effort - load) * standardGravity / (load + 4 * effort);
  return (a: a, tension: effort * (standardGravity - 2 * a));
}

({double v1, double v2, double impulse}) collision(
  double m1,
  double m2,
  double u1,
  double u2,
  double e,
) {
  if (m1 <= 0 || m2 <= 0 || e < 0 || e > 1) {
    throw ArgumentError('Invalid collision parameters');
  }
  if (u1 <= u2) {
    return (v1: u1, v2: u2, impulse: 0);
  }
  final j = (1 + e) * (u1 - u2) / (1 / m1 + 1 / m2);
  return (v1: u1 - j / m1, v2: u2 + j / m2, impulse: j);
}

({double x, double v, double a, double friction}) frictionStep(
  double x,
  double v,
  double drive,
  double mass,
  double normal,
  double mus,
  double muk,
  double dt,
) {
  if (dt < 0 || mass <= 0 || normal < 0 || mus < 0 || muk < 0 || muk > mus) {
    throw ArgumentError('Invalid contact model');
  }
  if (v.abs() < 1e-10) {
    v = 0;
    if (drive.abs() <= mus * normal + 1e-10) {
      return (x: x, v: 0, a: 0, friction: -drive);
    }
  }
  final direction = v == 0 ? drive.sign : v.sign;
  final f = -direction * muk * normal;
  final a = (drive + f) / mass;
  if (v * a < 0) {
    final stop = -v / a;
    if (stop < dt) {
      final atStop = x + v * stop + .5 * a * stop * stop;
      final tail = frictionStep(
        atStop,
        0,
        drive,
        mass,
        normal,
        mus,
        muk,
        dt - stop,
      );
      return tail;
    }
  }
  return (x: x + v * dt + .5 * a * dt * dt, v: v + a * dt, a: a, friction: f);
}

double absoluteDistance(double v, double a, double t) {
  if (a == 0) {
    return (v * t).abs();
  }
  final turn = -v / a;
  final displacement = v * t + .5 * a * t * t;
  if (turn > 0 && turn < t) {
    final first = v * turn + .5 * a * turn * turn;
    return first.abs() + (displacement - first).abs();
  }
  return displacement.abs();
}

double landingTime(double height, double vy, double g) {
  if (height < 0 || g <= 0) {
    throw ArgumentError('Invalid projectile');
  }
  return (vy + math.sqrt(vy * vy + 2 * g * height)) / g;
}

typedef Observation = Map<String, double>;

class DynamicsRun {
  final int kind;
  final Map<String, double> p;
  int ticks = 0, mode;
  Observation state = {};
  final List<Observation> samples = [];
  final List<Observation> impacts = [];
  bool impacted = false, finished = false;
  static const dt = 1 / 120;
  DynamicsRun(this.kind, Map<String, double> parameters, {this.mode = 0})
    : p = Map.from(parameters) {
    if (kind < 0 ||
        kind > 17 ||
        !p.values.every((x) => x.isFinite) ||
        (p['m'] ?? 1) <= 0 ||
        (p['m2'] ?? 1) <= 0 ||
        (p['radius'] ?? 1) <= 1e-6 ||
        (p['g'] ?? standardGravity) <= 0 ||
        (p['height'] ?? 0) < 0 ||
        (p['muk'] ?? 0) > (p['mus'] ?? 1)) {
      throw ArgumentError('Invalid dynamics parameters');
    }
    if (kind == 0 || (kind == 16 && mode == 1)) {
      final upward =
          (p['force'] ?? 0) * math.sin((p['angle'] ?? 0) * math.pi / 180);
      if (upward > (p['m'] ?? 2) * standardGravity + 1e-8) {
        throw ArgumentError('This contact model requires N ≥ 0');
      }
    }
    if (kind == 16 && mode == 0 && (p['a'] ?? 0) < -standardGravity) {
      throw ArgumentError('A taut rope cannot supply negative tension');
    }
    reset();
  }
  double get time => ticks * dt;
  double v(String key, [double fallback = 0]) => p[key] ?? fallback;
  void reset() {
    ticks = 0;
    impacted = false;
    finished = false;
    impacts.clear();
    samples.clear();
    state = {
      't': 0,
      'x': v('x0'),
      'y': 0,
      'vx': v('v0'),
      'vy': 0,
      'ax': 0,
      'ay': 0,
      'x2': v('x2', 3),
      'v2': v('v2'),
      'distance': 0,
      'impulse': 0,
    };
    _advance(0);
    samples.add(Map.from(state));
  }

  void step({bool capture = false}) {
    if (finished) {
      return;
    }
    ticks++;
    _advance(dt);
    state['t'] = finished ? math.min(time, state['eventTime'] ?? time) : time;
    if (ticks % 8 == 0 || finished || capture) {
      samples.add(Map.from(state));
    }
    while (samples.length > 301) {
      samples.removeAt(0);
    }
    if (ticks >= 2400) {
      finished = true;
    }
  }

  void seek(double time) {
    reset();
    final target = (time / dt).round().clamp(0, 2400);
    for (int i = 0; i < target && !finished; i++) {
      step();
    }
    if (samples.last['t'] != state['t']) {
      samples.add(Map.from(state));
      if (samples.length > 301) {
        samples.removeAt(0);
      }
    }
  }

  void _advance(double h) {
    final t = time, m = v('m', 2), m2 = v('m2', 3), g = v('g', standardGravity);
    final x = state['x']!, u = state['vx']!;
    state.addAll({
      'ax': 0,
      'ay': 0,
      'fx': 0,
      'fy': 0,
      'normal': 0,
      'friction': 0,
    });
    if ([0, 1, 15].contains(kind)) {
      final theta = kind == 1 ? v('angle') * math.pi / 180 : 0.0;
      final applied = kind == 1
          ? const Vec2(0, 0)
          : Vec2.polar(v('force'), v('angle') * math.pi / 180);
      final normal = kind == 1
          ? m * g * math.cos(theta)
          : math.max(0.0, m * g - applied.y);
      final drive = kind == 1 ? m * g * math.sin(theta) : applied.x;
      final result = frictionStep(
        x,
        u,
        drive,
        m,
        normal,
        v('mus'),
        v('muk'),
        h,
      );
      state.addAll({
        'x': result.x,
        'vx': result.v,
        'ax': result.a,
        'friction': result.friction,
        'normal': normal,
        'appliedX': applied.x,
        'appliedY': applied.y,
        'drive': drive,
        'weight': m * g,
        'fx': m * result.a,
      });
      if (kind == 1 && (result.x < 0 || result.x > 5)) {
        state['x'] = result.x.clamp(0, 5);
        state['vx'] = 0;
        state['ax'] = 0;
        state['boundaryReaction'] = -drive - result.friction;
        state['fx'] = 0;
        finished = true;
      }
    } else if (kind == 2) {
      final r = mode == 0 ? atwood(m, m2) : movablePulley(m, m2);
      final a = r.a;
      var displacement = v('v0') * t + .5 * a * t * t;
      var speed = v('v0') + a * t;
      final travel = mode == 0 ? 1.5 : .75;
      if (displacement.abs() > travel) {
        // Exact first boundary root; no bounce or artificial continued travel.
        final target = displacement.sign * travel;
        final roots = <double>[];
        if (a.abs() < 1e-12) {
          if (v('v0') != 0) {
            roots.add(target / v('v0'));
          }
        } else {
          final d = v('v0') * v('v0') + 2 * a * target;
          if (d >= 0) {
            roots.addAll([
              (-v('v0') + math.sqrt(d)) / a,
              (-v('v0') - math.sqrt(d)) / a,
            ]);
          }
        }
        final hit = roots
            .where((x) => x >= 0 && x <= t)
            .fold<double>(t, math.min);
        displacement = target;
        speed = 0;
        state['eventTime'] = hit;
        finished = true;
      }
      state.addAll({
        'x': displacement,
        'vx': speed,
        'ax': finished ? 0 : a,
        'x2': mode == 0 ? -displacement : 2 * displacement,
        'v2': mode == 0 ? -speed : 2 * speed,
        'tension': r.tension,
        'normal': 0,
        'fx': m * (finished ? 0 : a),
        'ropeInvariant': mode == 0 ? 0 : 2 * displacement - 2 * displacement,
      });
    } else if (kind == 3) {
      final f1 = Vec2.polar(v('force'), v('angle') * math.pi / 180),
          f2 = Vec2.polar(v('force2'), v('angle2') * math.pi / 180);
      final t1 = torque(Vec2(v('r1'), 0), f1, Vec2(v('pivot'), 0)),
          t2 = torque(Vec2(v('r2'), 0), f2, Vec2(v('pivot'), 0));
      final beamTorque = -v('beamMass') * g * (0 - v('pivot'));
      state.addAll({
        'torque1': t1,
        'torque2': t2,
        'netTorque': t1 + t2 + beamTorque,
        'support': -(f1.y + f2.y) + v('beamMass') * g,
        'supportX': -f1.x - f2.x,
        'x': v('r1'),
        'x2': v('r2'),
        'arm1':
            (v('r1') - v('pivot')).abs() *
            math.sin(v('angle') * math.pi / 180).abs(),
        'arm2':
            (v('r2') - v('pivot')).abs() *
            math.sin(v('angle2') * math.pi / 180).abs(),
      });
    } else if (kind == 4) {
      final c = centreOfMass(
        [m, m2, v('m3')],
        [
          Vec2(v('x0'), v('y1')),
          Vec2(v('x2'), v('y2')),
          Vec2(v('x3'), v('y3')),
        ],
      );
      final support = v('support'), half = v('base') / 2;
      final inside = (c.x - support).abs() < half;
      final phi = -math.pi / 2 - math.atan2(c.y - v('hangY'), c.x - v('hangX'));
      state.addAll({
        'x': c.x,
        'y': c.y,
        'mass': m + m2 + v('m3'),
        'stable': inside
            ? 1
            : ((c.x - support).abs() - half).abs() < 1e-8
            ? 0
            : -1,
        'netTorque': mode == 1
            ? 0.0
            : -(m + m2 + v('m3')) *
                  g *
                  (c.x - c.x.clamp(support - half, support + half)),
        'normal': (m + m2 + v('m3')) * g,
        'suspensionAngle': phi,
        'plumbX': v('hangX'),
      });
    } else if (kind == 5) {
      var xa = x, xb = state['x2']!, ua = u, ub = state['v2']!;
      final gap = xb - xa - .8, relative = ua - ub;
      var remaining = h;
      if (!impacted && relative > 0 && gap <= relative * h + 1e-10) {
        final hit = (gap / relative).clamp(0, h);
        xa += ua * hit;
        xb += ub * hit;
        remaining -= hit;
        final impact = collision(m, m2, ua, ub, v('e'));
        final eventTime = time - h + hit;
        samples.add({
          ...state,
          't': eventTime,
          'x': xa,
          'x2': xb,
          'vx': ua,
          'v2': ub,
          'momentum': m * ua + m2 * ub,
          'energy': .5 * m * ua * ua + .5 * m2 * ub * ub,
        });
        state.addAll({
          'beforeV1': ua,
          'beforeV2': ub,
          'impulse': impact.impulse,
        });
        ua = impact.v1;
        ub = impact.v2;
        samples.add({
          ...state,
          't': eventTime,
          'x': xa,
          'x2': xb,
          'vx': ua,
          'v2': ub,
          'momentum': m * ua + m2 * ub,
          'energy': .5 * m * ua * ua + .5 * m2 * ub * ub,
          'impulse': impact.impulse,
        });
        impacted = true;
        impacts.add({
          't': time - h + hit,
          'v1': ua,
          'v2': ub,
          'impulse': impact.impulse,
        });
      }
      xa += ua * remaining;
      xb += ub * remaining;
      state.addAll({
        'x': xa,
        'x2': xb,
        'vx': ua,
        'v2': ub,
        'momentum': m * ua + m2 * ub,
        'energy': .5 * m * ua * ua + .5 * m2 * ub * ub,
        'initialMomentum': m * v('v0') + m2 * v('v2'),
        'initialEnergy':
            .5 * m * v('v0') * v('v0') + .5 * m2 * v('v2') * v('v2'),
      });
    } else if (kind >= 6 && kind <= 8) {
      if (kind == 8 && mode == 1) {
        final from = time - h;
        final split = v('switch', 2);
        if (h > 0 && from < split && time >= split) {
          final xx = v('x0') + v('v0') * split + .5 * v('a') * split * split,
              vv = v('v0') + v('a') * split;
          for (final acceleration in [v('a'), v('a2')]) {
            samples.add({
              ...state,
              't': split,
              'x': xx,
              'vx': vv,
              'ax': acceleration,
              'distance': absoluteDistance(v('v0'), v('a'), split),
              'displacement': xx - v('x0'),
            });
          }
        }
        var remaining = h;
        var xx = x, vv = u;
        for (final segment in [
          (end: split, a: v('a')),
          (end: 20.0, a: v('a2')),
        ]) {
          final start = time - remaining;
          if (start >= segment.end) {
            continue;
          }
          final duration = math.min(remaining, segment.end - start);
          xx += vv * duration + .5 * segment.a * duration * duration;
          vv += segment.a * duration;
          remaining -= duration;
          if (remaining <= 1e-12) {
            break;
          }
        }
        state['distance'] =
            state['distance']! +
            _pieceDistance(from, h, u, split, v('a'), v('a2'));
        state.addAll({'x': xx, 'vx': vv, 'ax': t < split ? v('a') : v('a2')});
      } else {
        final a = v('a');
        state.addAll({
          'x': v('x0') + v('v0') * t + .5 * a * t * t,
          'vx': v('v0') + a * t,
          'ax': a,
          'distance': absoluteDistance(v('v0'), a, t),
        });
      }
      state['displacement'] = state['x']! - v('x0');
      state['averageVelocity'] = t == 0 ? v('v0') : state['displacement']! / t;
    } else if (kind == 9) {
      final velocity = Vec2.polar(v('speed'), v('angle') * math.pi / 180),
          flight = landingTime(v('height'), velocity.y, g),
          tt = math.min(t, flight);
      state.addAll({
        'x': velocity.x * tt,
        'y': tt >= flight
            ? 0.0
            : math.max(0.0, v('height') + velocity.y * tt - .5 * g * tt * tt),
        'vx': velocity.x,
        'vy': velocity.y - g * tt,
        'ay': -g,
        'flight': flight,
        'range': velocity.x * flight,
        'maxHeight':
            v('height') + math.pow(math.max(0.0, velocity.y), 2) / (2 * g),
        'eventTime': flight,
      });
      if (t >= flight && h > 0) {
        finished = true;
      }
    } else if (kind == 10) {
      final xa = v('x0') + v('v0') * t, xb = v('x2') + v('v2') * t;
      state.addAll({
        'x': xa,
        'x2': xb,
        'vx': v('v0'),
        'v2': v('v2'),
        'relativePosition': xa - xb,
        'relativeVelocity': v('v0') - v('v2'),
      });
    } else if (kind == 11) {
      final r = v('radius'),
          speed = v('speed'),
          omega = speed / r,
          angle = v('phase') + omega * t;
      state.addAll({
        'x': r * math.cos(angle),
        'y': r * math.sin(angle),
        'vx': -speed * math.sin(angle),
        'vy': speed * math.cos(angle),
        'ax': -speed * speed / r * math.cos(angle),
        'ay': -speed * speed / r * math.sin(angle),
        'omega': omega,
        'angle': angle,
        'period': speed == 0 ? 0 : 2 * math.pi * r / speed,
        'radialForce': m * speed * speed / r,
      });
    } else if (kind == 12) {
      final initial = v('v0') + v('impulse') / m;
      state.addAll({
        'x': v('x0') + initial * t,
        'vx': initial,
        'fx': 0,
        'impulse': v('impulse'),
        'distance': initial.abs() * t,
      });
    } else if (kind == 13) {
      final a = v('force') / m;
      state.addAll({
        'x': v('x0') + v('v0') * t + .5 * a * t * t,
        'vx': v('v0') + a * t,
        'ax': a,
        'fx': v('force'),
      });
    } else if (kind == 14) {
      final duration = v('pushTime'),
          active = math.min(t, duration),
          j = v('force') * active;
      final d1 = -.5 * v('force') / m * active * active - j / m * (t - active),
          d2 = .5 * v('force') / m2 * active * active + j / m2 * (t - active);
      state.addAll({
        'x': v('x0') + v('v0') * t + d1,
        'x2': v('x2') + v('v0') * t + d2,
        'vx': v('v0') - j / m,
        'v2': v('v0') + j / m2,
        'fx': t < duration ? -v('force') : 0,
        'force2': t < duration ? v('force') : 0,
        'ax': t < duration ? -v('force') / m : 0,
        'a2': t < duration ? v('force') / m2 : 0,
        'momentum': (m + m2) * v('v0'),
        'impulse': j,
      });
    } else if (kind == 16) {
      if (mode == 0) {
        final a = v('a');
        state.addAll({
          'supportForce': m * (g + a),
          'tension': m * (g + a),
          'weight': m * g,
          'fy': m * a,
          'ay': a,
          'y': v('v0') * t + .5 * a * t * t,
          'vy': v('v0') + a * t,
        });
      } else {
        final f = Vec2.polar(v('force'), v('angle') * math.pi / 180);
        final normal = math.max(0.0, m * g - f.y);
        state.addAll({
          'supportForce': normal,
          'normal': normal,
          'weight': m * g,
          'appliedX': f.x,
          'appliedY': f.y,
          'x': v('x0') + v('v0') * t + .5 * f.x / m * t * t,
          'vx': v('v0') + f.x / m * t,
          'ax': f.x / m,
          'fx': f.x,
        });
      }
    } else if (kind == 17) {
      var force = const Vec2(0, 0);
      for (int i = 1; i <= 3; i++) {
        force = force + Vec2.polar(v('f$i'), v('d$i') * math.pi / 180);
      }
      final acc = force * (1 / m);
      state.addAll({
        'fx': force.x,
        'fy': force.y,
        'ax': acc.x,
        'ay': acc.y,
        'x': v('x0') + v('v0') * t + .5 * acc.x * t * t,
        'y': .5 * acc.y * t * t,
        'vx': v('v0') + acc.x * t,
        'vy': acc.y * t,
        'resultant': force.magnitude,
        'direction': math.atan2(force.y, force.x) * 180 / math.pi,
      });
    }
    state['t'] = t;
  }

  double _pieceDistance(
    double from,
    double h,
    double u,
    double split,
    double a,
    double b,
  ) {
    final first = (split - from).clamp(0.0, h);
    return absoluteDistance(u, a, first) +
        absoluteDistance(u + a * first, b, h - first);
  }
}

/// Wall-time adapter: 120 Hz fixed steps; <=0.1 s catch-up / render call.
class FixedClock {
  double accumulator = 0, speed = 1, droppedWallTime = 0;
  void advance(double wallSeconds, void Function() step) {
    if (wallSeconds < 0 || !wallSeconds.isFinite) {
      return;
    }
    final work = math.min(.1, wallSeconds * speed);
    droppedWallTime += math.max(0, wallSeconds * speed - work);
    accumulator += work;
    int count = 0;
    while (accumulator >= DynamicsRun.dt - 1e-12 && count < 12) {
      step();
      accumulator -= DynamicsRun.dt;
      count++;
    }
  }

  void pause() {
    accumulator = 0;
  }
}
