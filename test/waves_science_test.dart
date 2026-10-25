import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/core/physics/waves_optics.dart';
import 'package:physics_atelier/core/physics/dynamics.dart' show Vec2;
import 'package:physics_atelier/core/persistence/notebook.dart';
import 'package:physics_atelier/features/waves/curriculum.dart';

WaveOpticsRun model(
  int kind, {
  Map<String, double> edit = const {},
  int mode = 0,
  double time = 0,
}) =>
    WaveOpticsRun(kind, {...waveLessons[kind].defaults, ...edit}, mode: mode)
      ..seek(time);
void main() {
  test('Detector movement preserves the common physical profile and exact intensity', () {
    final r = model(11), profile = r.profile;
    for (final y in [-.02, 0.0, .012]) {
      r.setDetector(y);
      expect(
        r.state['intensity'],
        closeTo(opticalIntensity(false, 650e-9, 100e-6, 1, y), 1e-14),
      );
      expect(identical(r.profile, profile), isTrue);
    }
    expect(
      () => model(2, edit: {'speed': .5, 'frequency': 5}),
      throwsArgumentError,
    );
  });
  test('Refresh aligns recorded state with the exact replay tick', () {
    final r = model(0);
    for (int i = 0; i < 7; i++) {
      r.step();
    }
    r.refresh();
    final b = model(0, time: r.time);
    expect(r.state, b.state);
    expect(r.state['t'], r.time);
  });
  test('Wave speed, direction and local phase advance', () {
    const a = .02, f = 2.0, l = .4, t = .1;
    expect(model(0).state['waveSpeed'], .8);
    expect(harmonic(l / 4 + f * l * t, t, a, f, l, 0, 1), closeTo(a, 1e-12));
    expect(harmonic(l / 4 - f * l * t, t, a, f, l, 0, -1), closeTo(a, 1e-12));
    expect(harmonic(0, .125, a, f, l, 0, 1), closeTo(-a, 1e-12));
  });
  test('Gaussian superposition and exact opposite cancellation', () {
    for (final x in [-1.0, 0.0, .2, 1.0]) {
      final a = gaussianPulse(x, 1.25, .025, .1, -.5, .4, 1),
          b = gaussianPulse(x, 1.25, -.025, .1, .5, .4, -1);
      expect(a + b, closeTo(0, 1e-12));
    }
    final after = model(1, time: 2);
    expect(after.profile.any((s) => s['first']!.abs() > .02), isTrue);
    for (final s in after.profile) {
      expect(s['sum'], closeTo(s['first']! + s['second']!, 1e-15));
    }
  });
  test('Independent Gaussian widths and direction matter', () {
    final a = model(1, edit: {'width1': .04}, time: .5),
        b = model(1, edit: {'width1': .2, 'd1': -1}, time: .5);
    expect(a.profile, isNot(equals(b.profile)));
  });
  test('Finite-geometry phasor interference distinguishes phase, amplitude, intensity', () {
    final inPhase = model(2, edit: {'probe': 0, 'phase': 0}),
        opposite = model(2, edit: {'probe': 0, 'phase': math.pi});
    expect(inPhase.state['intensity'], closeTo(1, 1e-12));
    expect(opposite.state['intensity'], closeTo(0, 1e-12));
    expect(opposite.state['probeAmplitude'], closeTo(0, 1e-10));
    expect(inPhase.field(0, .25).pathDifference, 0);
  });
  test('Source coincidence stays finite; no hidden singular attenuation', () {
    final r = model(2);
    for (final x in [-.25, .25]) {
      final s = r.field(x, 0);
      expect(s.displacement.isFinite, isTrue);
      expect(s.amplitude.isFinite, isTrue);
    }
  });
  test('Intensity proxy bounds and time-average agree', () {
    final r = model(2, edit: {'ratio': .4, 'phase': .7}), f = r.field(.3, .1);
    double sum = 0;
    for (int i = 0; i < 1000; i++) {
      r.time = i / (1000 * r.frequency);
      final y = r.field(.3, .1).displacement;
      sum += y * y;
    }
    final normalization =
        .5 * math.pow(r.p['amplitude']! * (1 + r.p['ratio']!), 2);
    expect(sum / 1000 / normalization, closeTo(f.intensity, 1e-12));
    expect(r.intensityGrid.every((x) => x >= 0 && x <= 1), isTrue);
  });
  test('Standing endpoints, harmonic frequency and node locations', () {
    for (int n = 1; n <= 6; n++) {
      final r = model(3, edit: {'harmonic': n.toDouble()}, time: .0012);
      expect(r.frequency, closeTo(n * 25, 1e-10));
      expect(r.wavelength, closeTo(2 / n, 1e-12));
      for (int j = 0; j <= n; j++) {
        expect(r.point(j / n)['sum'], closeTo(0, 1e-14));
      }
      expect(r.state['nodeCount'], n + 1);
      expect(() => model(3, edit: {'harmonic': 2.5}), throwsArgumentError);
    }
  });
  test('Standing traveling-wave decomposition is exact', () {
    final r = model(3, time: .0007);
    for (final point in r.profile) {
      expect(point['first']! + point['second']!, closeTo(point['sum']!, 1e-15));
      final x = point['t']!,
          expected =
              r.p['amplitude']! *
              math.sin(math.pi * 2 * x) *
              math.cos(2 * math.pi * 50 * r.time);
      expect(point['sum'], closeTo(expected, 1e-14));
    }
  });
  test(
    'Hann FFT detects known bin-centred sine with coherent-gain normalization',
    () {
      final signal = educationalSignal(2048, 16384, 440, .6, 880, .5, 0),
          s = Spectrum.analyze(signal, 16384);
      expect(s.peakFrequency, 440);
      expect(s.peakAmplitude, closeTo(.6, 1e-5));
      expect(s.binWidth, 8);
      expect(s.rms, closeTo(.6 / math.sqrt(2), 1e-10));
      expect(s.peaks.first, 440);
    },
  );
  test('Two-tone FFT preserves relative amplitudes and known peaks', () {
    final s = Spectrum.analyze(
      educationalSignal(2048, 16384, 440, .6, 880, .5, 1),
      16384,
    );
    expect(s.peaks, containsAll([440.0, 880.0]));
    expect(s.amplitudes[55], closeTo(.4, 1e-5));
    expect(s.amplitudes[110], closeTo(.2, 1e-5));
  });
  test('Band-limited odd harmonic source omits above-Nyquist terms', () {
    final signal = educationalSignal(2048, 16384, 2000, .6, 880, .5, 2),
        s = Spectrum.analyze(signal, 16384);
    expect(s.peaks, containsAll([2000.0, 6000.0]));
    expect(s.peaks.any((x) => x > 8192), isFalse);
    expect(signal.every((x) => x.abs() <= .6 + 1e-12), isTrue);
  });
  test('Hann suppresses distant spectral leakage for off-bin tone', () {
    final input = [
          for (int i = 0; i < 2048; i++)
            math.sin(2 * math.pi * 443 * i / 16384),
        ],
        h = Spectrum.analyze(input, 16384),
        rect = Spectrum.analyze(input, 16384, hann: false);
    double tail(Spectrum s) => s.amplitudes
        .asMap()
        .entries
        .where((e) => (e.key - 55).abs() > 5)
        .fold(0.0, (sum, e) => sum + e.value * e.value);
    expect(tail(h), lessThan(tail(rect) * .01));
  });
  test(
    'Nyquist boundary is explicit; aliased input cannot be magically repaired',
    () {
      expect(
        () => educationalSignal(2048, 16384, 8192, .5, 880, .5, 0),
        throwsArgumentError,
      );
      expect(
        () => educationalSignal(2048, 16384, 9000, .5, 880, .5, 0),
        throwsArgumentError,
      );
      final aliased = Spectrum.analyze([
        for (int i = 0; i < 1024; i++) math.sin(2 * math.pi * 1000 * i / 1024),
      ], 1024);
      expect(aliased.peakFrequency, 24);
    },
  );
  test('Silence has no fake FFT peak and DC removal is documented', () {
    final s = Spectrum.analyze(List.filled(2048, 0.0), 48000),
        dc = Spectrum.analyze(List.filled(2048, .3), 48000);
    expect(s.peakFrequency, 0);
    expect(s.peaks, isEmpty);
    expect(dc.peakAmplitude, closeTo(0, 1e-12));
    expect(dc.rms, closeTo(.3, 1e-12));
    expect(() => Spectrum.analyze([1, 2, 3], 48000), throwsArgumentError);
  });
  test('PCM16 little-endian signed values and split-byte carry', () {
    final window = PcmWindow();
    window.add([0, 128, 0]);
    window.add([0, 255, 127]);
    expect(window.values[0], -1);
    expect(window.values[1], 0);
    expect(window.values[2], 32767 / 32768);
    expect(window.receivedFrames, 3);
  });
  test('PCM stereo is downmixed and raw ring is bounded', () {
    final w = PcmWindow(channels: 2, capacity: 4);
    w.add([0, 64, 0, 192]);
    expect(w.values.single, 0);
    w.add(List.filled(100, 0));
    expect(w.values.length, 4);
    expect(w.receivedFrames, 26);
  });
  test('Doppler stationary, approach and recession use retarded time', () {
    expect(doppler(0, -60, 0, 70, 343, 600).frequency, 600);
    expect(
      doppler(0, -60, 30, 70, 343, 600).frequency,
      closeTo(600 * 343 / 313, 1e-10),
    );
    expect(
      doppler(0, -60, -30, 70, 343, 600).frequency,
      closeTo(600 * 343 / 373, 1e-10),
    );
    for (final vs in [-150.0, 0.0, 150.0]) {
      for (final t in [0.0, 1.0, 3.0]) {
        final r = doppler(t, -60, vs, 70, 343, 600);
        expect(r.emission + (70 - r.source).abs() / 343, closeTo(t, 1e-12));
      }
    }
    expect(() => doppler(0, 0, 343, 70, 343, 600), throwsArgumentError);
  });
  test('Emission-origin fronts use past positions, not current source', () {
    final r = model(5, time: 1);
    expect(r.fronts.length, 32);
    for (final front in r.fronts) {
      expect(
        front['x'],
        closeTo(
          r.p['x0']! + r.state['sourceSpeed']! * front['emission']!,
          1e-10,
        ),
      );
      expect(
        front['radius'],
        closeTo(r.p['c']! * (r.time - front['emission']!), 1e-10),
      );
    }
    expect(r.fronts.last['x'], isNot(closeTo(r.state['sourceX']!, 1e-6)));
  });
  test(
    'Reflection vectors preserve length and equality relative to normal',
    () {
      for (final deg in [0.0, 30.0, 85.0]) {
        final theta = deg * math.pi / 180,
            d = Vec2(math.sin(theta), -math.cos(theta)),
            r = reflected(d, const Vec2(0, 1));
        expect(r.magnitude, closeTo(1, 1e-12));
        expect(r.x, d.x);
        expect(r.y, -d.y);
        expect(math.acos(dot(r, const Vec2(0, 1))), closeTo(theta, 1e-12));
      }
    },
  );
  test('Ray-plane intersection and parallel/behind cases', () {
    final p = rayPlane(
      const Vec2(-1, 1),
      const Vec2(1, -1),
      const Vec2(0, 0),
      const Vec2(0, 1),
    );
    expect(p!.x, 0);
    expect(p.y, 0);
    expect(
      rayPlane(
        const Vec2(0, 1),
        const Vec2(1, 0),
        const Vec2(0, 0),
        const Vec2(0, 1),
      ),
      isNull,
    );
    expect(
      rayPlane(
        const Vec2(0, 1),
        const Vec2(0, 1),
        const Vec2(0, 0),
        const Vec2(0, 1),
      ),
      isNull,
    );
  });
  test('Snell equal-index, normal incidence and numerical law', () {
    for (final a in [0.0, .3, 1.0]) {
      expect(snell(1, 1, a).angle, closeTo(a, 1e-12));
      final s = snell(1, 1.5, a);
      expect(math.sin(a), closeTo(1.5 * math.sin(s.angle!), 1e-12));
    }
    expect(snell(1.5, 1, 0).angle, 0);
  });
  test('Critical boundary and total internal reflection', () {
    final critical = math.asin(1 / 1.5),
        at = snell(1.5, 1, critical),
        above = snell(1.5, 1, critical + 1e-5);
    expect(at.tir, isFalse);
    expect(at.angle, closeTo(math.pi / 2, 1e-7));
    expect(above.tir, isTrue);
    expect(above.transmission, isNull);
    expect(
      model(7, edit: {'n1': 1.5, 'n2': 1, 'angle': 60}).state.containsKey('tx'),
      isFalse,
    );
  });
  test('Frequency is continuous while speed and wavelength change', () {
    final s = model(7).state;
    expect(s['speed1']! / s['lambda1']!, closeTo(s['frequency']!, 1));
    expect(s['speed2']! / s['lambda2']!, closeTo(s['frequency']!, 1));
    expect(s['lambda2']! / s['lambda1']!, closeTo(1 / 1.5, 1e-12));
  });
  test('Thin-lens known real, virtual, focal and diverging cases', () {
    for (final u in [.3, .2, .15]) {
      final s = ImageSolution(.1, u, .004);
      expect(1 / s.distance! + 1 / u, closeTo(10, 1e-12));
      expect(s.classification, 1);
      expect(s.magnification, lessThan(0));
    }
    expect(const ImageSolution(.1, .2, .004).distance, closeTo(.2, 1e-12));
    expect(const ImageSolution(.1, .05, .004).classification, -1);
    final at = const ImageSolution(.1, .1, .004);
    expect(at.atInfinity, isTrue);
    expect(at.distance, isNull);
    expect(at.state['imageVergence'], 0);
    final diverging = const ImageSolution(-.1, .3, .004);
    expect(diverging.distance, lessThan(0));
    expect(diverging.magnification, greaterThan(0));
  });
  test('Paraxial mirrors share real-positive convention and centre case', () {
    final c = const ImageSolution(.15, .3, .004);
    expect(c.distance, closeTo(.3, 1e-12));
    expect(c.magnification, closeTo(-1, 1e-12));
    final convex = const ImageSolution(-.15, .3, .004);
    expect(convex.classification, -1);
    expect(convex.magnification, closeTo(1 / 3, 1e-12));
  });
  test('Double-slit spacing matches bright minima within small-angle approximation', () {
    const l = 650e-9, L = 1.0, d = 200e-6;
    final spacing = l * L / d;
    expect(opticalIntensity(true, l, d, L, spacing), greaterThan(.999999));
    expect(opticalIntensity(true, l, d, L, spacing / 2), lessThan(1e-9));
    expect(opticalIntensity(true, l, d, L, 0), 1);
  });
  test('Single-slit central limit, minima and exact central width', () {
    const l = 650e-9, L = 1.0, a = 100e-6;
    expect(sinc(0), 1);
    expect(opticalIntensity(false, l, a, L, 0), 1);
    for (int m = 1; m <= 4; m++) {
      final y = diffractionMinimum(l, a, L, m)!;
      expect(opticalIntensity(false, l, a, L, y), lessThan(1e-25));
    }
    expect(2 * diffractionMinimum(l, a, L, 1)!, closeTo(.0130002746, 1e-9));
    expect(diffractionMinimum(l, a, L, 0), isNull);
  });
  test(
    'Optical intensities symmetric/bounded, narrower slit broadens lobe',
    () {
      for (final twice in [true, false]) {
        for (int i = -100; i <= 100; i++) {
          final y = i * .0003,
              a = opticalIntensity(twice, 650e-9, 100e-6, 1, y),
              b = opticalIntensity(twice, 650e-9, 100e-6, 1, -y);
          expect(a, b);
          expect(a, inInclusiveRange(0, 1));
        }
      }
      expect(
        diffractionMinimum(650e-9, 50e-6, 1, 1),
        greaterThan(diffractionMinimum(650e-9, 100e-6, 1, 1)!),
      );
      expect(() => model(10, edit: {'aperture': .001}), throwsArgumentError);
    },
  );
  test('Twelve models replay deterministically, finite snapshots, bounded sampling', () {
    for (int k = 0; k < 12; k++) {
      final a = model(k, time: .001), b = model(k, time: .001);
      expect(a.state, b.state, reason: 'kind $k');
      expect(a.state.values.every((v) => v.isFinite), isTrue);
      expect(a.profile.length, lessThanOrEqualTo(801));
      expect(a.grid.length, lessThanOrEqualTo(2048));
      expect(a.state[waveLessons[k].metric], isNotNull);
      final unit = waveLessons[k].unit,
          quantity = switch (unit) {
            'm' => 'length',
            'm/s' => 'speed',
            'Hz' => 'frequency',
            '°' => 'angle',
            'm⁻¹' => 'vergence',
            _ => 'relativeIntensity',
          };
      final t = Trial(
        id: '$k',
        labId: 's0${8 + k ~/ 6}-e0${k % 6}',
        quantity: quantity,
        unit: unit,
        value: a.state[waveLessons[k].metric]!,
        resolution: null,
        configuration: {'parameters': a.p},
        model: waveOpticsVersion,
      );
      expect(Trial.fromJson(t.toJson()).model, waveOpticsVersion);
    }
    final r = model(0, time: 12);
    expect(r.samples.length, 301);
  });
}
