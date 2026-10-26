import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/core/physics/measurement.dart';
import 'package:physics_atelier/core/physics/spherometer.dart';
import 'package:physics_atelier/core/physics/thermal_library.dart';
import 'package:physics_atelier/core/physics/optical_library.dart';
import 'package:physics_atelier/features/measurement/experiment.dart';

void main() {
  test('Every named lens has the correct paraxial power sign; coated penta and splitter reference paths', () {
    const positive = {
      'biconvex',
      'asymconvex',
      'planoconvex',
      'meniscusplus',
      'cylconvex',
    };
    for (final component in opticalComponents.where(
      (c) => c.category == 'Lens',
    )) {
      final b = OpticalBench()
        ..components = [PlacedOptic(component.id)]
        ..source = const OVec(-2, .1)
        ..direction = const OVec(1, 0);
      final out = b.trace().segments.firstWhere(
        (s) => s.event == 'exit' && s.depth == 2 && s.direction.x > 0,
      );
      expect(
        out.direction.y,
        positive.contains(component.id) ? lessThan(0) : greaterThan(0),
        reason: component.name,
      );
    }
    final penta = OpticalBench()
      ..components = [PlacedOptic('coatedpenta')]
      ..source = const OVec(-2, .1)
      ..direction = const OVec(1, 0);
    final exits =
        penta.trace().segments.where((s) => s.event == 'exit').toList()
          ..sort((a, b) => b.power.compareTo(a.power));
    expect(exits.first.direction.x, closeTo(0, 1e-8));
    expect(exits.first.direction.y, closeTo(-1, 1e-8));
    final splitter = OpticalBench()
      ..components = [PlacedOptic('splitter', reflectance: .3)]
      ..source = const OVec(-2, 0)
      ..direction = const OVec(1, 0);
    final front = splitter.trace().segments.firstWhere(
      (s) => s.event == 'exit' && s.depth == 1,
    );
    expect(front.power, closeTo(.3, 1e-12));
  });

  test('Three equilateral fixed tips, spherical cap contact and signed radius identities', () {
    final s = SpherometerSetup()..surface = 1;
    const r = .05;
    final legs = s.legs(r);
    for (final p in legs) {
      expect(math.sqrt(p.x * p.x + p.y * p.y), closeTo(r, 1e-12));
      expect(s.surfaceHeight(r, r), closeTo(0, 1e-12));
    }
    for (int i = 0; i < 3; i++) {
      final a = legs[i], b = legs[(i + 1) % 3];
      expect(
        math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2)),
        closeTo(math.sqrt(3) * r, 1e-12),
      );
    }
    expect(s.surfaceHeight(0, r), closeTo(.00044, 1e-12));
    // Published spherical-cap identity checked against a known 1 m sphere.
    final h = 1 - math.sqrt(1 - r * r);
    expect(curvatureRadius(r, h), closeTo(1, 1e-10));
    expect(curvatureFromLegSeparation(math.sqrt(3) * r, h), closeTo(1, 1e-10));
    expect(curvatureRadius(r, -h), closeTo(-1, 1e-10));
    expect(curvatureRadius(r, 0), isNull);
  });
  test('Plane reference, pitch, nonpenetrating contact, signed measured estimate and reopen', () {
    final e = Experiment(3), s = SpherometerSetup()..offset = .00007;
    e.spherometer = s;
    e.setA(-.003);
    expect(e.a, closeTo(.00007, 1e-12));
    s.reference = e.a;
    s.surface = 1;
    e.setA(-.003);
    expect(s.atContact(e.a), isTrue);
    s.contactReading = e.a;
    expect(s.measuredH, closeTo(.00044, 1e-12));
    expect(e.result, closeTo(2.84112909, 1e-7));
    e.setA(e.a + SpherometerSetup.pitch);
    expect(e.a - s.contactStop, closeTo(.0005, 1e-12));
    expect(s.measuredH, closeTo(.00044, 1e-12));
    s.surface = 2;
    e.setA(-.003);
    s.contactReading = e.a;
    expect(s.measuredH, closeTo(-.00044, 1e-12));
    expect(e.result, lessThan(0));
    final restored = Experiment(3);
    expect(restored.restore(e.toJson()), isTrue);
    expect(restored.result, e.result);
    expect(restored.spherometer!.offset, s.offset);
    s.surface = 0;
    e.setA(-.003);
    s.contactReading = e.a;
    expect(e.result, isNull);
    e.dispose();
    restored.dispose();
  });
  test('Spherometer quantization never penetrates; malformed/legacy sessions retained', () {
    final e = Experiment(3);
    e.spherometer!
      ..surface = 1
      ..truthSagitta = .000443;
    e.setA(-1);
    expect(e.a, closeTo(.00045, 1e-12));
    expect(
      e.a - e.spherometer!.offset,
      greaterThanOrEqualTo(e.spherometer!.target),
    );
    final old = e.toJson()..remove('spherometer');
    old['a'] = .00044;
    old['zero'] = 0.0;
    expect(e.restore(old), isTrue);
    expect(e.result, closeTo(curvatureRadius(.05, .00044)!, 1e-12));
    final bad = {
      ...old,
      'spherometer': {'version': 9},
    };
    expect(e.restore(bad), isFalse);
    expect(e.result, closeTo(curvatureRadius(.05, .00044)!, 1e-12));
    e.dispose();
  });
  test('36 named thermal records, unavailable properties never fabricated', () {
    expect(thermalMaterials.length, 36);
    expect(thermalMaterials.map((m) => m.id).toSet().length, 36);
    for (final m in thermalMaterials) {
      expect(m.source, startsWith('https://'));
      expect(m.toJson()['sourceVersion'], thermalDataVersion);
      expect(m.validity, isNotEmpty);
    }
    final b = ThermalBench()..materials = ['water', 'copper'];
    expect(b.error, contains('fluid'));
    expect(b.readings, isEmpty);
    b.materials = ['granite', 'copper'];
    expect(b.error, contains('unavailable'));
    expect(thermalMaterial('granite').kRange, [1.7, 4.3]);
  });
  test('Reference conduction, equal geometry, area/length scaling and validity guard', () {
    final b = ThermalBench();
    expect(b.error, isEmpty);
    expect(b.readings[0]['power'], closeTo(4.01, 1e-12));
    expect(b.readings[1]['power'], closeTo(2.37, 1e-12));
    expect(b.readings[2]['power'], closeTo(.149, 1e-12));
    b.area *= 2;
    expect(b.readings[0]['power'], closeTo(8.02, 1e-12));
    b.length *= 2;
    expect(b.readings[0]['power'], closeTo(4.01, 1e-12));
    b.hot = 400;
    expect(b.readings, isEmpty);
  });
  test('Composite hand calculation: 10 + 9 + 1 K/W, half watt and consistent boundary drops', () {
    final b = ThermalBench()
      ..mode = ThermalBench.modes[2]
      ..materials = ['ptfe', 'soda-lime']
      ..area = .01
      ..thicknesses = [.022, .01, .01]
      ..contact = 9;
    final rows = b.readings;
    expect(rows[0]['totalResistance'], closeTo(20, 1e-12));
    expect(rows[0]['power'], closeTo(.5, 1e-12));
    expect(rows[1]['power'], rows[0]['power']);
    expect(rows[0]['start'], 305);
    expect(rows[0]['end'], 300);
    expect(rows[0]['contactDrop'], 4.5);
    expect(rows[1]['start'], 295.5);
    expect(rows[1]['end'], 295);
  });
  test('Heating: mcΔT energy and equal mass versus volume are distinct; exact state roundtrip', () {
    final b = ThermalBench()..mode = ThermalBench.modes[1];
    expect(b.readings[0]['temperature'], closeTo(295 + 50 / 38.5, 1e-12));
    for (final row in b.readings) {
      expect(row['stored'], row['supplied']);
      expect(row['loss'], 0);
    }
    b.equalVolume = true;
    expect(b.readings[0]['mass'], closeTo(.08933, 1e-12));
    expect(b.readings[0]['temperature'], isNot(b.readings[1]['temperature']));
    final clone = ThermalBench.fromJson(b.toJson());
    expect(clone.toJson(), b.toJson());
    b.seconds = 1000;
    expect(b.readings, isEmpty);
  });
  test('Manufacturer reference indices and visible dispersion; monochromatic presets gated', () {
    expect(opticalMaterials.length, 8);
    expect(opticalMaterial('bk7').index(587.6), closeTo(1.51680, 0.00001));
    expect(opticalMaterial('f2').index(587.6), closeTo(1.62005, .00001));
    expect(opticalMaterial('silica').index(587.6), closeTo(1.45846, .00002));
    expect(
      opticalMaterial('bk7').index(450),
      greaterThan(opticalMaterial('bk7').index(650)),
    );
    expect(() => opticalMaterial('water').index(450), throwsArgumentError);
    final b = OpticalBench()..sourceMode = 'Visible spectrum';
    expect(b.traces.length, 3);
    b.components[0].material = 'pmma';
    expect(b.traces, isEmpty);
  });
  test('Analytic plane and sphere intersections, normal directions and grazing roots', () {
    final plane = OpticalSurface.plane(const OVec(1, 0), 2);
    expect(plane.intersections(const OVec(0, 0), const OVec(1, 0)), [2]);
    expect(plane.normal(const OVec(2, 0)).x, 1);
    final sphere = OpticalSurface(1, 1, 1, 0, 0, 0, -1);
    final roots = sphere.intersections(const OVec(-2, 0), const OVec(1, 0))
      ..sort();
    expect(roots, [1, 3]);
    expect(sphere.intersections(const OVec(-2, 1), const OVec(1, 0)), [2, 2]);
  });
  test('Normal-incidence Fresnel reference, reflection angle and slab emergent direction', () {
    final b = OpticalBench()
      ..source = const OVec(-2, 0)
      ..direction = const OVec(1, 0);
    final trace = b.trace(),
        n = opticalMaterial('bk7').index(587.6),
        r = math.pow((n - 1) / (n + 1), 2).toDouble();
    final frontExit = trace.segments.firstWhere(
      (s) => s.event == 'exit' && s.direction.x < 0 && s.depth == 1,
    );
    expect(frontExit.power, closeTo(r, 1e-10));
    expect(trace.accounted, closeTo(1, 1e-10));
    b.components = [PlacedOptic('frontmirror')];
    b.direction = const OVec(1, .2);
    final mirror = b.trace().segments.last;
    expect(mirror.direction.x, closeTo(-b.direction.unit.x, 1e-12));
    expect(mirror.direction.y, closeTo(b.direction.unit.y, 1e-12));
  });
  test('Oblique slab: vector Snell, parallel exit, lateral displacement from independent geometry', () {
    final b = OpticalBench(), trace = b.trace();
    final interfaces = trace.segments
        .where((s) => s.event == 'dielectric' && s.depth <= 1)
        .toList();
    expect(interfaces.length, 2);
    final inside = interfaces[1],
        i = math.atan(.22),
        n = opticalMaterial('bk7').index(587.6),
        refracted = math.asin(math.sin(i) / n);
    expect(
      inside.direction.y / inside.direction.x,
      closeTo(math.tan(refracted), 1e-9),
    );
    final exit = trace.segments.firstWhere(
      (s) => s.event == 'exit' && s.direction.x > 0 && s.depth == 2,
    );
    expect(exit.direction.x, closeTo(b.direction.unit.x, 1e-10));
    expect(exit.direction.y, closeTo(b.direction.unit.y, 1e-10));
    final freeAtExit = b.source.y + (exit.start.x - b.source.x) * .22;
    expect(
      freeAtExit - exit.start.y,
      closeTo(.4 * (math.tan(i) - math.tan(refracted)), 1e-6),
    );
  });
  test('Semicircular radial entry and critical-angle boundary', () {
    final b = OpticalBench()
      ..components = [PlacedOptic('semicircle')]
      ..source = const OVec(-1.3, .75)
      ..direction = const OVec(1.3, -.75);
    final first = b.trace().segments.first;
    expect(first.direction.dot(first.normal).abs(), closeTo(1, 1e-10));
    b.source = const OVec(0, .2);
    final n = opticalMaterial('bk7').index(587.6), critical = math.asin(1 / n);
    b.direction = OVec(math.sin(critical - .001), -math.cos(critical - .001));
    expect(b.trace().segments.first.event, isNot('TIR'));
    b.direction = OVec(math.sin(critical + .001), -math.cos(critical + .001));
    expect(b.trace().segments.first.event, 'TIR');
  });
  test('Prism minimum deviation reference and right-angle TIR', () {
    final b = OpticalBench()..components = [PlacedOptic('equilateral')];
    final n = opticalMaterial('bk7').index(587.6),
        inc = math.asin(n * .5),
        theta = inc - math.pi / 6;
    b.direction = OVec(math.cos(theta), math.sin(theta));
    b.source = const OVec(-.25, .1443375673) - b.direction * 2;
    final out = b.trace().segments.firstWhere(
      (s) => s.event == 'exit' && s.depth == 2,
    );
    final deviation = math.acos(
      b.direction.unit.dot(out.direction).clamp(-1, 1),
    );
    expect(deviation, closeTo(2 * inc - math.pi / 3, 1e-7));
    b.components = [PlacedOptic('right45')];
    b.source = const OVec(-2, 0);
    b.direction = const OVec(1, 0);
    expect(b.trace().segments.any((s) => s.event == 'TIR'), isTrue);
  });
  test('Lens convergence/divergence and parabolic parallel-ray focus', () {
    final b = OpticalBench()
      ..source = const OVec(-2, .15)
      ..direction = const OVec(1, 0)
      ..components = [PlacedOptic('biconvex')];
    RaySegment transmitted() => b.trace().segments.firstWhere(
      (s) => s.event == 'exit' && s.direction.x > 0 && s.depth == 2,
    );
    expect(transmitted().direction.y, lessThan(0));
    b.components = [PlacedOptic('biconcave')];
    expect(transmitted().direction.y, greaterThan(0));
    b.components = [PlacedOptic('parabolic')];
    final out = b.trace().segments.last;
    final focusX =
        out.start.x + (.0 - out.start.y) / out.direction.y * out.direction.x;
    expect(focusX, closeTo(-.4, 1e-6));
  });
  test(
    'True 3D corner return, ghost reflection and bounded power accounting',
    () {
      final b = OpticalBench()
        ..components = [PlacedOptic('corner')]
        ..source = const OVec(1.5, 1.4, 1.3)
        ..direction = const OVec(-1, -1, -1);
      final trace = b.trace();
      expect(
        trace.segments.where((s) => s.event == 'mirror').length,
        greaterThanOrEqualTo(3),
      );
      final exit = trace.segments.firstWhere(
        (s) => s.event == 'exit' && s.depth == 5,
      );
      expect(exit.direction.dot(b.direction.unit), closeTo(-1, 1e-8));
      expect(trace.accounted, closeTo(1, 1e-10));
      b.components = [PlacedOptic('backmirror')];
      b.source = const OVec(-2, -.2);
      b.direction = const OVec(1, .2);
      final ghost = b.trace();
      expect(
        ghost.segments
            .where((s) => s.event == 'exit' && s.direction.x < 0)
            .length,
        greaterThan(1),
      );
      b.components = [PlacedOptic('splitter', reflectance: .3)];
      b.maxRays = 16;
      b.minPower = .01;
      expect(b.trace().accounted, closeTo(1, 1e-10));
      expect(b.trace().processed, lessThanOrEqualTo(16));
    },
  );
  test('All forty component entries have working boundary interactions, bounded rays and serializable geometry', () {
    expect(opticalComponents.length, 40);
    expect(opticalComponents.map((c) => c.id).toSet().length, 40);
    for (final component in opticalComponents) {
      final b = OpticalBench()
        ..components = [
          PlacedOptic(
            component.id,
            material: component.category == 'Liquid-containing element'
                ? 'water'
                : 'bk7',
          ),
        ]
        ..wavelength = 589.3;
      if (component.id == 'corner') {
        b.source = const OVec(1.5, 1.4, 1.3);
        b.direction = const OVec(-1, -1, -1);
      } else {
        b.source = const OVec(-2, .1);
        b.direction = const OVec(1, 0);
      }
      final trace = b.trace();
      expect(
        trace.segments.any((s) => s.event != 'exit'),
        isTrue,
        reason: component.name,
      );
      expect(trace.accounted, closeTo(1, 1e-9), reason: component.name);
      expect(trace.processed, lessThanOrEqualTo(b.maxRays));
      expect(OpticalBench.fromJson(b.toJson()).toJson(), b.toJson());
    }
  });
  test('Geometry changes actual intersections; grazing paths terminate without self-hit loops', () {
    final b = OpticalBench();
    final first = b.trace().segments.first.end;
    b.components.first.rotation = .3;
    final second = b.trace().segments.first.end;
    expect((first - second).length, greaterThan(.01));
    b.components.first.size = 1.3;
    expect((second - b.trace().segments.first.end).length, greaterThan(.01));
    for (final y in [.599999, .6, .600001]) {
      b.components = [PlacedOptic('slab')];
      b.source = OVec(-2, y);
      b.direction = const OVec(1, 1e-9);
      final t = b.trace();
      expect(t.accounted, closeTo(1, 1e-8));
      expect(t.processed, lessThanOrEqualTo(256));
    }
  });
}
