import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/core/physics/dynamics.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';
import 'package:physics_atelier/features/dynamics/curriculum.dart';
import 'package:physics_atelier/features/dynamics/scene.dart';
import 'package:flutter/material.dart';

DynamicsRun make(
  int kind, [
  Map<String, double> edits = const {},
  int mode = 0,
]) => DynamicsRun(kind, {...lessons[kind].defaults, ...edits}, mode: mode);
void advance(DynamicsRun r, double t) {
  for (int i = 0; i < (t / DynamicsRun.dt).round() && !r.finished; i++) {
    r.step();
  }
}

void main() {
  test('Recorded configuration is a detached deep snapshot', () {
    final configuration = <String, dynamic>{
      'parameters': {'m': 2.0},
      'samples': [
        {'x': 1.0},
      ],
    };
    final t = Trial(
      id: 'snapshot',
      labId: 's02-e00',
      quantity: 'force',
      unit: 'N',
      value: 1,
      resolution: null,
      configuration: configuration,
      model: dynamicsVersion,
    );
    (configuration['parameters'] as Map)['m'] = 9.0;
    (configuration['samples'] as List).clear();
    expect(t.configuration['parameters']['m'], 2);
    expect(t.configuration['samples'], hasLength(1));
  });
  test('Vectors, reference frames and view transforms invert consistently', () {
    final f = const Vec2(3, 4) + const Vec2(-1, 2);
    expect(f.x, 2);
    expect(f.y, 6);
    expect(const Vec2(3, 4).magnitude, 5);
    const frame = ReferenceFrame(Vec2(1, 0), Vec2(2, 0));
    expect(frame.position(const Vec2(8, 0), 3).x, 1);
    expect(frame.relativeVelocity(const Vec2(5, 0)).x, 3);
    const view = WorldViewport(Size(360, 270), 30, Vec2(2, 3));
    final w = view.world(view.screen(const Vec2(4, 5)));
    expect(w.x, closeTo(4, 1e-12));
    expect(w.y, closeTo(5, 1e-12));
  });
  test('Zero net force preserves rest and uniform motion after the push', () {
    final r = make(12, {'v0': 2, 'impulse': 0});
    advance(r, 3);
    expect(r.state['x'], closeTo(6, 1e-10));
    expect(r.state['vx'], 2);
    expect(r.state['fx'], 0);
    final rest = make(12, {'v0': 0, 'impulse': 0});
    advance(rest, 2);
    expect(rest.state['x'], 0);
  });
  test('Constant net force gives F/m and exact kinematics', () {
    final r = make(13, {'m': 2, 'force': 6, 'v0': 0});
    advance(r, 2);
    expect(r.state['ax'], 3);
    expect(r.state['vx'], closeTo(6, 1e-10));
    expect(r.state['x'], closeTo(6, 1e-10));
  });
  test('Static friction is the required value, not its maximum', () {
    final s = frictionStep(0, 0, 5, 2, 2 * standardGravity, .4, .25, .1);
    expect(s.friction, -5);
    expect(s.v, 0);
    final slip = frictionStep(0, 0, 10, 2, 2 * standardGravity, .4, .25, .1);
    expect(slip.v, greaterThan(0));
  });
  test('Ramp sticking thresholds and uphill friction direction', () {
    final stuck = make(1, {'angle': 10, 'v0': 0, 'mus': .4, 'muk': .25});
    advance(stuck, .5);
    expect(stuck.state['vx'], 0);
    expect(
      stuck.state['friction'],
      closeTo(-2 * standardGravity * math.sin(10 * math.pi / 180), 1e-10),
    );
    final downhill = make(1, {'angle': 30, 'mus': .1, 'muk': .05});
    advance(downhill, .2);
    expect(downhill.state['vx'], greaterThan(0));
    final uphill = make(1, {'angle': 30, 'v0': -1});
    expect(uphill.state['friction'], greaterThan(0));
    expect(uphill.state['ax'], greaterThan(standardGravity * .5));
  });
  test('Dry friction dissipates energy and re-sticks without jitter', () {
    var x = 0.0, u = 2.0;
    double previous = 4;
    for (int i = 0; i < 1000; i++) {
      final next = frictionStep(x, u, 0, 2, 2 * standardGravity, .4, .25, .01);
      x = next.x;
      u = next.v;
      final energy = u * u;
      expect(energy, lessThanOrEqualTo(previous + 1e-10));
      previous = energy;
    }
    expect(u, 0);
    final noLaunch = frictionStep(x, 0, 0, 2, 20, .4, .25, 1);
    expect(noLaunch.v, 0);
  });
  test('Equal-mass Atwood and movable-pulley topology', () {
    final a = atwood(2, 2);
    expect(a.a, 0);
    expect(a.tension, closeTo(2 * standardGravity, 1e-12));
    final moving = movablePulley(2, 1);
    expect(moving.a, 0);
    expect(moving.tension, closeTo(standardGravity, 1e-12));
    final r = make(2, {'m': 3, 'm2': 2}, 1);
    advance(r, .3);
    expect(r.state['x2'], closeTo(2 * r.state['x']!, 1e-12));
    expect(r.state['v2'], closeTo(2 * r.state['vx']!, 1e-12));
    expect(r.state['tension'], greaterThan(0));
    expect(
      2 * r.state['tension']! - 3 * standardGravity,
      closeTo(3 * r.state['ax']!, 1e-10),
    );
  });
  test('Torque uses the perpendicular arm and balances', () {
    expect(
      torque(const Vec2(-.5, 0), const Vec2(0, -20), const Vec2(0, 0)),
      10,
    );
    expect(torque(const Vec2(2, 0), const Vec2(10, 0), const Vec2(0, 0)), 0);
    final r = make(3);
    expect(r.state['netTorque'], closeTo(0, 1e-10));
    expect(r.state['arm1'], closeTo(.5, 1e-10));
  });
  test('COM derives from masses; suspension rotates COM onto plumb line', () {
    final c = centreOfMass([1, 2], [const Vec2(-1, 0), const Vec2(2, 3)]);
    expect(c.x, 1);
    expect(c.y, 2);
    final r = make(4, {}, 1);
    final dx = r.state['x']! - r.p['hangX']!,
        dy = r.state['y']! - r.p['hangY']!,
        phi = r.state['suspensionAngle']!;
    expect(dx * math.cos(phi) - dy * math.sin(phi), closeTo(0, 1e-10));
    expect(dx * math.sin(phi) + dy * math.cos(phi), lessThan(0));
  });
  test('Momentum, restitution and elastic energy across supported impacts', () {
    for (final e in [0.0, .4, 1.0]) {
      final c = collision(2, 3, 4, -1, e);
      expect(2 * c.v1 + 3 * c.v2, closeTo(5, 1e-10));
      expect(c.v2 - c.v1, closeTo(e * 5, 1e-10));
      if (e == 1) {
        expect(
          .5 * 2 * c.v1 * c.v1 + .5 * 3 * c.v2 * c.v2,
          closeTo(17.5, 1e-10),
        );
      }
      if (e == 0) {
        expect(c.v1, closeTo(c.v2, 1e-10));
      }
    }
    expect(collision(2, 3, -1, 1, 1).impulse, 0);
  });
  test('Collision event occurs once at contact without penetration', () {
    final r = make(5, {'v0': 5, 'v2': -4, 'e': .5});
    advance(r, 2);
    expect(r.impacts.length, 1);
    expect(r.state['x2']! - r.state['x']!, greaterThanOrEqualTo(.8 - 1e-10));
    expect(r.impacts.first['t'], closeTo(2.2 / 9, 1e-10));
    expect(r.state['momentum'], closeTo(r.state['initialMomentum']!, 1e-10));
  });
  test('Signed velocity area differs from distance after reversal', () {
    final r = make(7, {'x0': 0, 'v0': -2, 'a': 1});
    advance(r, 4);
    expect(r.state['displacement'], closeTo(0, 1e-10));
    expect(r.state['distance'], closeTo(4, 1e-10));
    expect(r.state['vx'], closeTo(2, 1e-10));
  });
  test(
    'Piecewise schedule splits exactly, retaining x/v continuity and areas',
    () {
      final r = make(8, {'x0': 0, 'v0': 0, 'a': 2, 'a2': -1, 'switch': 2}, 1);
      advance(r, 4);
      expect(r.state['vx'], closeTo(2, 1e-9));
      expect(r.state['x'], closeTo(10, 1e-9));
      expect(r.state['distance'], closeTo(10, 1e-9));
    },
  );
  test('Projectile valid roots handle unequal heights, downward, vertical and zero launches', () {
    final t = landingTime(5, 0, standardGravity);
    expect(5 - .5 * standardGravity * t * t, closeTo(0, 1e-10));
    expect(landingTime(0, -2, standardGravity), 0);
    expect(landingTime(0, 0, standardGravity), 0);
    final r = make(9, {'speed': 10, 'angle': 0, 'height': 5});
    advance(r, 2);
    expect(r.state['y'], 0);
    expect(r.state['x'], closeTo(10 * t, 1e-10));
    final vertical = make(9, {'speed': 0, 'height': 3});
    advance(vertical, 2);
    expect(vertical.state['x'], 0);
    expect(vertical.finished, true);
  });
  test('Relative-frame differences preserve the same event', () {
    const worldA = Vec2(10, 0), worldB = Vec2(4, 0);
    for (final observer in [0.0, 3.0, -2.0]) {
      final f = ReferenceFrame(const Vec2(0, 0), Vec2(observer, 0));
      expect((f.position(worldA, 2) - f.position(worldB, 2)).x, 6);
      expect(
        (f.relativeVelocity(const Vec2(3, 0)) -
                f.relativeVelocity(const Vec2(-2, 0)))
            .x,
        5,
      );
    }
  });
  test('Circular tangent and centripetal acceleration are consistent, zero speed safe', () {
    final r = make(11, {'m': 2, 'radius': 1, 'speed': 2});
    advance(r, 1);
    final position = Vec2(r.state['x']!, r.state['y']!),
        vel = Vec2(r.state['vx']!, r.state['vy']!);
    expect(position.magnitude, closeTo(1, 1e-10));
    expect(position.x * vel.x + position.y * vel.y, closeTo(0, 1e-10));
    expect(r.state['radialForce'], 8);
    expect(r.state['period'], closeTo(math.pi, 1e-10));
    expect(make(11, {'speed': 0}).state['period'], 0);
    expect(() => make(11, {'radius': 0}), throwsArgumentError);
  });
  test(
    'Third-law forces act on separate bodies and preserve system momentum',
    () {
      final r = make(14, {'m': 2, 'm2': 3, 'force': 6, 'pushTime': 1, 'v0': 1});
      expect(r.state['fx']! + r.state['force2']!, 0);
      expect(r.state['ax'], -3);
      expect(r.state['a2'], 2);
      advance(r, 2);
      expect(r.state['fx'], 0);
      expect(2 * r.state['vx']! + 3 * r.state['v2']!, closeTo(5, 1e-10));
    },
  );
  test('Tension and normal reactions respect unilateral constraints', () {
    final hanging = make(16, {'m': 2, 'a': 2});
    expect(hanging.state['tension'], closeTo(2 * (standardGravity + 2), 1e-10));
    final table = make(16, {'m': 2, 'force': 5, 'angle': 30}, 1);
    expect(table.state['normal'], closeTo(2 * standardGravity - 2.5, 1e-10));
    expect(() => make(16, {'a': -20}), throwsArgumentError);
    expect(
      () => make(16, {'m': .2, 'force': 60, 'angle': 60}, 1),
      throwsArgumentError,
    );
  });
  test('Multi-force vector sum is in-plane and not counted twice', () {
    final r = make(17);
    expect(r.state['fx'], closeTo(4, 1e-10));
    expect(r.state['fy'], closeTo(3, 1e-10));
    expect(r.state['ax'], closeTo(2, 1e-10));
    expect(r.state['ay'], closeTo(1.5, 1e-10));
  });
  test(
    'Deterministic replay, bounded clock catch-up and bounded histories',
    () {
      for (int kind = 0; kind < 18; kind++) {
        final a = make(kind), b = make(kind);
        advance(a, 1);
        b.seek(1);
        expect(b.state, a.state, reason: 'kind $kind');
        for (int i = 0; i < 3000; i++) {
          a.step();
        }
        expect(a.samples.length, lessThanOrEqualTo(301));
      }
      final clock = FixedClock();
      var steps = 0;
      clock.advance(10, () => steps++);
      expect(steps, 12);
      expect(clock.droppedWallTime, greaterThan(9));
      clock.pause();
      expect(clock.accumulator, 0);
    },
  );
  test('Friction event solution is insensitive to a split timestep', () {
    final a = frictionStep(0, -1, 5, 2, 20, .4, .25, 1);
    var x = 0.0, u = -1.0;
    for (int i = 0; i < 100; i++) {
      final b = frictionStep(x, u, 5, 2, 20, .4, .25, .01);
      x = b.x;
      u = b.v;
    }
    expect(a.x, closeTo(x, 1e-9));
    expect(a.v, closeTo(u, 1e-9));
  });
  test('Phase 1 records and dynamics model metadata both round-trip', () {
    final old = Trial(
      id: 'old',
      labId: 's01-e00',
      quantity: 'length',
      unit: 'm',
      value: .05,
      resolution: .001,
      configuration: {'model': 'measurement-1.0'},
    );
    final newTrial = Trial(
      id: 'new',
      labId: 's02-e00',
      quantity: 'acceleration',
      unit: 'm/s²',
      value: 2,
      resolution: null,
      configuration: {'model': dynamicsVersion},
      model: dynamicsVersion,
    );
    expect(Trial.fromJson(old.toJson()).model, 'measurement-1.0');
    expect(Trial.fromJson(newTrial.toJson()).model, dynamicsVersion);
    expect(csvEncode([old, newTrial]), contains(dynamicsVersion));
  });
}
