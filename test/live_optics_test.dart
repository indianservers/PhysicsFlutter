import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/core/physics/live_optics.dart';
import 'package:physics_atelier/features/optics_live/scene.dart';

void main() {
  test('Snell, TIR and Fresnel powers agree and conserve energy', () {
    final m = LiveOpticsModel(opticsById('s09-e01'));
    expect(m.state['Transmitted angle (°)'], closeTo(35.26438968, 1e-7));
    expect(
      m.state['Reflected power']! + m.state['Transmitted power']!,
      closeTo(1, 1e-12),
    );
    m.set('n1', 1.5);
    m.set('n2', 1);
    m.set('angle', 60);
    expect(m.state['TIR'], 1);
    expect(m.state['Transmitted power'], 0);
    final g = OpticalGeometry(m, 520);
    expect(g.rays.length, 2);
    expect(g.rays.last.power, 1);
  });
  test('Thin lens handles real, virtual, diverging and focal limit', () {
    final m = LiveOpticsModel(opticsById('s09-e02'));
    expect(m.state['Image distance (m)'], closeTo(.3, 1e-12));
    expect(m.state['Magnification'], closeTo(-2, 1e-12));
    m.set('u', .1);
    expect(m.state['At infinity'], 1);
    expect(m.state.containsKey('Image distance (m)'), false);
    expect(
      OpticalGeometry(
        m,
        520,
      ).rays.every((r) => r.a.dx.isFinite && r.b.dy.isFinite),
      true,
    );
    m.set('u', .08);
    expect(m.state['Image type'], -1);
    expect(OpticalGeometry(m, 520).rays.where((r) => r.dashed), isNotEmpty);
    m.mode = 1;
    expect(m.state['Image distance (m)']!, lessThan(0));
    expect(m.state['Magnification']!, inExclusiveRange(0, 1));
  });
  test('Fraunhofer profiles and widths respond to aperture and wavelength', () {
    final interference = LiveOpticsModel(opticsById('s09-e04'));
    expect(interference.state['Fringe spacing (m)'], closeTo(.00325, 1e-12));
    expect(interference.profile(0), 1);
    final slit = LiveOpticsModel(opticsById('s09-e05'));
    expect(slit.state['Central width (m)'], closeTo(.013000274634, 1e-9));
    expect(slit.profile(0), 1);
    slit.set('aperture', .05e-3);
    expect(slit.state['Central width (m)']!, greaterThan(.025));
  });
  test('Malus law extinguishes the output at crossed axes', () {
    final m = LiveOpticsModel(opticsById('s09-e06'));
    expect(m.state['Transmitted intensity (W/m²)'], closeTo(15, 1e-12));
    m.set('angle', 90);
    expect(m.state['Transmitted intensity (W/m²)']!, lessThan(1e-20));
    expect(OpticalGeometry(m, 520).rays.last.power, lessThan(1e-20));
    m.set('angle', 0);
    expect(m.state['Transmitted intensity (W/m²)'], 30);
  });
  test('Prism traces conserve power and disperse independently at every wavelength', () {
    final m = LiveOpticsModel(opticsById('s09-e07')), traces = m.prismTraces();
    expect(traces.length, 9);
    for (final t in traces) {
      expect(t.segments, isNotEmpty);
      expect(t.accounted, closeTo(1, 1e-8));
    }
    final red = traces.last.segments.where((s) => s.event == 'exit').toList();
    final violet = traces.first.segments
        .where((s) => s.event == 'exit')
        .toList();
    expect(red, isNotEmpty);
    expect(violet, isNotEmpty);
    final a = red.reduce((a, b) => a.power > b.power ? a : b),
        b = violet.reduce((a, b) => a.power > b.power ? a : b);
    expect((a.direction.y - b.direction.y).abs(), greaterThan(.001));
  });
  test(
    'Thin film cancels at zero thickness and peaks at quarter-wave thickness',
    () {
      const lambda = 550e-9, n = 1.33;
      expect(filmReflectance(lambda, 0, n, 0), 0);
      final peak = filmReflectance(lambda, lambda / (4 * n), n, 0);
      expect(peak, greaterThan(.07));
      expect(
        filmReflectance(lambda, lambda / (2 * n), n, 0),
        closeTo(0, 1e-12),
      );
      final m = LiveOpticsModel(opticsById('s09-e08'));
      expect(
        m.state['Reflectance']! + m.state['Transmittance']!,
        closeTo(1, 1e-12),
      );
    },
  );
  test(
    'Telescope transfer rays are parallel exactly at the afocal separation',
    () {
      final m = LiveOpticsModel(opticsById('s09-e09'));
      expect(m.state['Angular magnification'], -4);
      expect(m.state['Defocus (m)'], closeTo(0, 1e-12));
      final rays = OpticalGeometry(m, 520).rays;
      for (final ray in rays.where((r) => r.b.dx == 730)) {
        expect((ray.b.dy - ray.a.dy).abs(), lessThan(1e-8));
      }
      m.set('separation', .32);
      expect(m.state['Defocus (m)']!.abs(), greaterThan(.06));
      m.mode = 1;
      m.set('f1', .05);
      m.set('f2', .05);
      m.set('separation', .3);
      expect(m.state['Magnification'], closeTo(-20, 1e-10));
    },
  );
  test('Every lab rejects invalid restores atomically and all geometry stays finite', () {
    for (final def in opticsDefinitions) {
      final m = LiveOpticsModel(def), saved = m.toJson();
      expect(m.restore(saved), true);
      expect(
        m.restore({
          ...saved,
          'p': {...m.p, def.primary.key: double.nan},
        }),
        false,
      );
      expect(m.toJson(), saved);
      for (final value in [def.primary.min, def.primary.max]) {
        m.set(def.primary.key, value);
        final geometry = OpticalGeometry(m, 520);
        expect(
          geometry.rays.every(
            (r) => [
              r.a.dx,
              r.a.dy,
              r.b.dx,
              r.b.dy,
              r.power,
            ].every((v) => v.isFinite),
          ),
          true,
          reason: def.title,
        );
        expect(
          m.state.values.every((v) => v.isFinite),
          true,
          reason: def.title,
        );
      }
    }
  });
}
