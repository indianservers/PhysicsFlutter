import 'dart:math' as math;
import 'dart:typed_data';

import 'dynamics.dart' show Vec2;

const waveOpticsVersion = 'waves-optics-4.0';
const lightSpeed = 299792458.0;
typedef WaveState = Map<String, double>;
double harmonic(
  double x,
  double t,
  double amplitude,
  double frequency,
  double wavelength,
  double phase,
  int direction,
) =>
    amplitude *
    math.sin(
      2 * math.pi * (x / wavelength - direction * frequency * t) + phase,
    );
double gaussianPulse(
  double x,
  double t,
  double amplitude,
  double width,
  double initial,
  double speed,
  int direction,
) =>
    amplitude *
    math.exp(-math.pow((x - initial - direction * speed * t) / width, 2) / 2);
Vec2 unit(Vec2 v) => v * (1 / v.magnitude);
double dot(Vec2 a, Vec2 b) => a.x * b.x + a.y * b.y;
Vec2 reflected(Vec2 direction, Vec2 normal) {
  final d = unit(direction), n = unit(normal);
  return d - n * (2 * dot(d, n));
}

Vec2? rayPlane(Vec2 origin, Vec2 direction, Vec2 point, Vec2 normal) {
  final denominator = dot(direction, normal);
  if (denominator.abs() < 1e-12) return null;
  final t = dot(point - origin, normal) / denominator;
  return t < 0 ? null : origin + direction * t;
}

({
  Vec2 reflection,
  Vec2? transmission,
  double? angle,
  double? critical,
  bool tir,
})
snell(double n1, double n2, double angle) {
  if (n1 <= 0 || n2 <= 0 || angle.abs() > math.pi / 2) {
    throw ArgumentError('Invalid media or angle');
  }
  final d = Vec2(math.sin(angle), -math.cos(angle)),
      eta = n1 / n2,
      radicand = 1 - eta * eta * math.sin(angle) * math.sin(angle);
  final transmitted = radicand < -1e-12
      ? null
      : Vec2(eta * d.x, -math.sqrt(math.max(0, radicand)));
  return (
    reflection: reflected(d, const Vec2(0, 1)),
    transmission: transmitted,
    angle: transmitted == null ? null : math.asin(transmitted.x.clamp(-1, 1)),
    critical: n1 > n2 ? math.asin(n2 / n1) : null,
    tir: transmitted == null,
  );
}

class ImageSolution {
  final double focal, object, height;
  const ImageSolution(this.focal, this.object, this.height);
  double get vergence => 1 / focal - 1 / object;
  bool get atInfinity =>
      (object - focal).abs() <= 1e-10 * math.max(1.0, object.abs());
  double? get distance => atInfinity ? null : 1 / vergence;
  double? get magnification => distance == null ? null : -distance! / object;
  int get classification => atInfinity
      ? 0
      : distance! > 0
      ? 1
      : -1;
  WaveState get state => {
    'imageVergence': atInfinity ? 0 : vergence,
    'imageType': classification.toDouble(),
    'infinity': atInfinity ? 1 : 0,
    'imageDistance': ?distance,
    'magnification': ?magnification,
    if (magnification != null) 'imageHeight': magnification! * height,
  };
}

double sinc(double beta) =>
    beta.abs() < 1e-8 ? 1 - beta * beta / 6 : math.sin(beta) / beta;
double opticalIntensity(
  bool doubleSlit,
  double wavelength,
  double aperture,
  double screen,
  double y,
) {
  final sinTheta = y / math.sqrt(screen * screen + y * y),
      beta = math.pi * aperture * sinTheta / wavelength;
  return (doubleSlit ? math.pow(math.cos(beta), 2) : math.pow(sinc(beta), 2))
      .toDouble()
      .clamp(0, 1);
}

double? diffractionMinimum(
  double wavelength,
  double aperture,
  double screen,
  int order,
) {
  final ratio = order * wavelength / aperture;
  return order == 0 || ratio.abs() >= 1
      ? null
      : screen * ratio / math.sqrt(1 - ratio * ratio);
}

/// Exact retarded time for an eternally emitting subsonic collinear point source.
({double emission, double source, double? frequency}) doppler(
  double t,
  double x0,
  double speed,
  double observer,
  double c,
  double frequency,
) {
  if (c <= 0 || speed.abs() >= c) {
    throw ArgumentError('Subsonic source required');
  }
  final delta = observer - x0,
      approach = (c * t - delta) / (c - speed),
      retreat = (c * t + delta) / (c + speed);
  final tau = x0 + speed * approach <= observer + 1e-9 ? approach : retreat,
      source = x0 + speed * tau,
      distance = observer - source;
  return (
    emission: tau,
    source: source,
    frequency: distance.abs() < 1e-8
        ? null
        : frequency * c / (c - speed * distance.sign),
  );
}

class Spectrum {
  final List<double> amplitudes;
  final int sampleRate, size;
  final double rms, peakFrequency, peakAmplitude;
  final List<double> peaks;
  const Spectrum(
    this.amplitudes,
    this.sampleRate,
    this.size,
    this.rms,
    this.peakFrequency,
    this.peakAmplitude,
    this.peaks,
  );
  double get binWidth => sampleRate / size;

  /// One-sided peak-amplitude Hann spectrum. DC removed; no peak interpolation.
  static Spectrum analyze(
    List<double> samples,
    int sampleRate, {
    bool hann = true,
  }) {
    final n = samples.length;
    if (n < 8 ||
        (n & (n - 1)) != 0 ||
        sampleRate <= 0 ||
        samples.any((v) => !v.isFinite)) {
      throw ArgumentError(
        'Power-of-two finite samples and positive rate required',
      );
    }
    final real = Float64List(n),
        imag = Float64List(n),
        mean = samples.reduce((a, b) => a + b) / n;
    double windowSum = 0, squares = 0;
    for (int i = 0; i < n; i++) {
      final w = hann ? .5 - .5 * math.cos(2 * math.pi * i / (n - 1)) : 1.0;
      real[i] = (samples[i] - mean) * w;
      windowSum += w;
      squares += samples[i] * samples[i];
    }
    for (int i = 1, j = 0; i < n; i++) {
      int bit = n >> 1;
      for (; j & bit != 0; bit >>= 1) {
        j ^= bit;
      }
      j ^= bit;
      if (i < j) {
        final v = real[i];
        real[i] = real[j];
        real[j] = v;
      }
    }
    for (int length = 2; length <= n; length <<= 1) {
      final angle = -2 * math.pi / length,
          wr = math.cos(angle),
          wi = math.sin(angle);
      for (int i = 0; i < n; i += length) {
        double ur = 1, ui = 0;
        for (int j = 0; j < length ~/ 2; j++) {
          final a = i + j,
              b = a + length ~/ 2,
              tr = ur * real[b] - ui * imag[b],
              ti = ur * imag[b] + ui * real[b];
          real[b] = real[a] - tr;
          imag[b] = imag[a] - ti;
          real[a] += tr;
          imag[a] += ti;
          final next = ur * wr - ui * wi;
          ui = ur * wi + ui * wr;
          ur = next;
        }
      }
    }
    final amplitudes = [
      for (int i = 0; i <= n ~/ 2; i++)
        math.sqrt(real[i] * real[i] + imag[i] * imag[i]) *
            (i == 0 || i == n ~/ 2 ? 1 : 2) /
            windowSum,
    ];
    final local = <int>[];
    for (int i = 1; i < amplitudes.length - 1; i++) {
      if (amplitudes[i] > amplitudes[i - 1] &&
          amplitudes[i] >= amplitudes[i + 1]) {
        local.add(i);
      }
    }
    local.sort((a, b) => amplitudes[b].compareTo(amplitudes[a]));
    final index = local.isEmpty ? 0 : local.first,
        maxAmplitude = amplitudes[index];
    final peaks = local
        .where((i) => amplitudes[i] > math.max(1e-5, maxAmplitude * .08))
        .take(8)
        .map((i) => i * sampleRate / n)
        .toList();
    return Spectrum(
      amplitudes,
      sampleRate,
      n,
      math.sqrt(squares / n),
      maxAmplitude < 1e-5 ? 0 : index * sampleRate / n,
      maxAmplitude,
      peaks,
    );
  }
}

/// Interleaved little-endian PCM16 decoder with byte/frame carry and bounded mono ring.
class PcmWindow {
  final int capacity;
  int channels;
  final List<int> _carry = [];
  final List<double> values = [];
  int receivedFrames = 0;
  PcmWindow({this.channels = 1, this.capacity = 4096});
  void clear() {
    _carry.clear();
    values.clear();
    receivedFrames = 0;
  }

  void add(List<int> chunk) {
    final bytes = [..._carry, ...chunk],
        stride = channels * 2,
        count = bytes.length ~/ stride;
    receivedFrames += count;
    _carry
      ..clear()
      ..addAll(bytes.skip(count * stride));
    for (int frame = 0; frame < count; frame++) {
      double value = 0;
      for (int ch = 0; ch < channels; ch++) {
        final index = frame * stride + 2 * ch,
            raw = bytes[index] | bytes[index + 1] << 8;
        value += (raw >= 32768 ? raw - 65536 : raw) / 32768;
      }
      values.add(value / channels);
    }
    if (values.length > capacity) {
      values.removeRange(0, values.length - capacity);
    }
  }
}

List<double> educationalSignal(
  int size,
  int rate,
  double f,
  double amplitude,
  double f2,
  double ratio,
  int mode, {
  double start = 0,
}) {
  if (f <= 0 || f >= rate / 2 || f2 <= 0 || f2 >= rate / 2) {
    throw ArgumentError('Tones must lie strictly below Nyquist');
  }
  final harmonics = [
    for (final h in [1, 3, 5, 7])
      if (h * f < rate / 2) h,
  ];
  final normalization = mode == 1
      ? 1 + ratio
      : mode == 2
      ? harmonics.fold<double>(0, (s, h) => s + 1 / h)
      : 1.0;
  return [
    for (int i = 0; i < size; i++)
      amplitude /
          normalization *
          (mode == 0
              ? math.sin(2 * math.pi * f * (start + i / rate))
              : mode == 1
              ? math.sin(2 * math.pi * f * (start + i / rate)) +
                    ratio * math.sin(2 * math.pi * f2 * (start + i / rate))
              : harmonics.fold<double>(
                  0,
                  (s, h) =>
                      s +
                      math.sin(2 * math.pi * h * f * (start + i / rate)) / h,
                )),
  ];
}

/// Models cache spatial curves, phasors and FFTs outside widget builds.
class WaveOpticsRun {
  static const dt = 1 / 120;
  final int kind, mode;
  final WaveState p;
  int ticks = 0, revision = 0;
  double time = 0;
  bool finished = false;
  WaveState state = {};
  final List<WaveState> samples = [];
  List<WaveState> profile = [], frequencyCurve = [];
  final List<double> grid = [],
      fieldReal = [],
      fieldImag = [],
      intensityGrid = [];
  List<double> signal = [];
  List<WaveState> fronts = [];
  Spectrum? spectrum;
  double v(String key, [double fallback = 0]) => p[key] ?? fallback;
  bool get staticLab => kind >= 6;
  double get timeScale => switch (kind) {
    3 => .001,
    4 => .0001,
    5 => .5,
    _ => .1,
  };
  double get maxTime => kind == 5 ? 4 : 120 * timeScale;
  WaveOpticsRun(this.kind, Map<String, double> parameters, {this.mode = 0})
    : p = Map.of(parameters) {
    if (kind < 0 || kind > 11 || p.values.any((x) => !x.isFinite)) {
      throw ArgumentError('Invalid model');
    }
    for (final key in [
      'frequency',
      'wavelength',
      'width1',
      'width2',
      'speed',
      'length',
      'tension',
      'density',
      'c',
      'n1',
      'n2',
      'u',
      'focal',
      'screen',
      'aperture',
    ]) {
      if (p.containsKey(key) && p[key]! <= 0) {
        throw ArgumentError('Positive $key required');
      }
    }
    if (kind == 3 &&
        (v('harmonic') != v('harmonic').roundToDouble() ||
            v('harmonic') < 1 ||
            v('harmonic') > 6)) {
      throw ArgumentError('Integer harmonic 1–6 required');
    }
    if (kind >= 10 &&
        v('aperture') * v('aperture') / (v('wavelength') * v('screen')) >
            .100000001) {
      throw ArgumentError('Far-field aperture constraint exceeded');
    }
    if (kind == 2 && v('speed') / v('frequency') < 16 / 63 - 1e-10) {
      throw ArgumentError('Field grid requires eight samples per wavelength');
    }
    if (kind == 2) _phasors();
    _calculate();
    _capture();
  }
  void _capture() {
    if (samples.isNotEmpty && samples.last['t'] == time) samples.removeLast();
    samples.add(Map.of(state));
    if (samples.length > 301) samples.removeAt(0);
  }

  void step({bool capture = false}) {
    if (finished || staticLab) return;
    ticks++;
    time = ticks * dt * timeScale;
    if (ticks % (kind == 4 ? 12 : 4) == 0 || capture) {
      _calculate();
      if (ticks % 8 == 0 || capture) _capture();
    }
    if (time >= maxTime) {
      finished = true;
      _calculate();
      _capture();
    }
  }

  void seek(double seconds) {
    if (staticLab) return;
    final count = (seconds / (dt * timeScale)).round().clamp(
      0,
      (maxTime / (dt * timeScale)).round(),
    );
    while (ticks < count && !finished) {
      step();
    }
    _calculate();
    _capture();
  }

  void refresh() {
    _calculate();
    _capture();
  }

  void setDetector(double position) {
    if (kind < 10 || !position.isFinite || position.abs() > .03) {
      throw ArgumentError('Optical detector outside screen');
    }
    p['probe'] = position;
    state['intensity'] = opticalIntensity(
      kind == 10,
      v('wavelength'),
      v('aperture'),
      v('screen'),
      position,
    );
    state['angle'] = math.atan(position / v('screen')) * 180 / math.pi;
    revision++;
    _capture();
  }

  double get frequency => kind == 3
      ? v('harmonic') *
            math.sqrt(v('tension') / v('density')) /
            (2 * v('length'))
      : v('frequency');
  double get wavelength => kind == 3
      ? 2 * v('length') / v('harmonic')
      : kind == 2
      ? v('speed') / v('frequency')
      : v('wavelength');
  WaveState point(double x) {
    if (kind == 0) {
      return {
        't': x,
        'sum': harmonic(
          x,
          time,
          v('amplitude'),
          frequency,
          wavelength,
          v('phase'),
          mode == 0 ? 1 : -1,
        ),
      };
    }
    if (kind == 1) {
      final a = gaussianPulse(
            x,
            time,
            v('a1'),
            v('width1'),
            v('x1'),
            v('speed'),
            v('d1').toInt(),
          ),
          b = gaussianPulse(
            x,
            time,
            v('a2'),
            v('width2'),
            v('x2'),
            v('speed'),
            v('d2').toInt(),
          );
      return {'t': x, 'first': a, 'second': b, 'sum': a + b};
    }
    final k = math.pi * v('harmonic') / v('length'),
        w = 2 * math.pi * frequency,
        a = .5 * v('amplitude');
    final first = a * math.sin(k * x - w * time),
        second = a * math.sin(k * x + w * time);
    return {'t': x, 'first': first, 'second': second, 'sum': first + second};
  }

  ({
    double displacement,
    double amplitude,
    double intensity,
    double pathDifference,
    double phase,
  })
  field(double x, double z) {
    final r1 = math.sqrt(math.pow(x + v('spacing') / 2, 2) + z * z),
        r2 = math.sqrt(math.pow(x - v('spacing') / 2, 2) + z * z),
        k = 2 * math.pi / wavelength,
        phi = v('phase');
    final re = math.cos(k * r1) + v('ratio') * math.cos(k * r2 + phi),
        im = math.sin(k * r1) + v('ratio') * math.sin(k * r2 + phi),
        a = v('amplitude');
    return (
      displacement:
          a *
          (im * math.cos(2 * math.pi * frequency * time) -
              re * math.sin(2 * math.pi * frequency * time)),
      amplitude: a * math.sqrt(re * re + im * im),
      intensity: ((re * re + im * im) / math.pow(1 + v('ratio'), 2)).clamp(
        0,
        1,
      ),
      pathDifference: r2 - r1,
      phase: k * (r2 - r1) + phi,
    );
  }

  void _phasors() {
    for (int j = 0; j < 32; j++) {
      for (int i = 0; i < 64; i++) {
        final x = -1 + 2 * i / 63,
            z = .5 - j / 31,
            r1 = math.sqrt(math.pow(x + v('spacing') / 2, 2) + z * z),
            r2 = math.sqrt(math.pow(x - v('spacing') / 2, 2) + z * z),
            k = 2 * math.pi / wavelength;
        final re =
                math.cos(k * r1) + v('ratio') * math.cos(k * r2 + v('phase')),
            im = math.sin(k * r1) + v('ratio') * math.sin(k * r2 + v('phase'));
        fieldReal.add(re);
        fieldImag.add(im);
        intensityGrid.add(
          ((re * re + im * im) / math.pow(1 + v('ratio'), 2)).clamp(0, 1),
        );
      }
    }
  }

  void acceptSignal(List<double> pcm, int rate) {
    signal = List.of(pcm);
    spectrum = Spectrum.analyze(signal, rate);
    _spectrumState();
    _capture();
    revision++;
  }

  void acceptAnalyzedSignal(List<double> pcm, Spectrum analysis) {
    signal = List.of(pcm);
    spectrum = analysis;
    _spectrumState();
    _capture();
    revision++;
  }

  void _spectrumState() {
    final s = spectrum!;
    state = {
      't': time,
      'peakFrequency': s.peakFrequency,
      'peakAmplitude': s.peakAmplitude,
      'rms': s.rms,
      'sampleRate': s.sampleRate.toDouble(),
      'windowSize': s.size.toDouble(),
      'binWidth': s.binWidth,
      'nyquist': s.sampleRate / 2,
    };
    profile = [
      for (int i = 0; i < math.min(256, signal.length); i++)
        {'t': i / s.sampleRate, 'signal': signal[i]},
    ];
    frequencyCurve = [
      for (int i = 0; i < s.amplitudes.length; i++)
        {'t': i * s.binWidth, 'amplitude': s.amplitudes[i]},
    ];
  }

  void _calculate() {
    state = {'t': time};
    if (kind == 0 || kind == 1 || kind == 3) {
      final extent = kind == 3 ? v('length') : 2.0;
      profile = [
        for (int i = 0; i <= 512; i++)
          point((kind == 1 ? -1 : 0) + extent * i / 512),
      ];
      final probe = point(v('probe'));
      state.addAll(probe..['t'] = time);
      if (kind != 1) {
        state.addAll({
          'frequency': frequency,
          'wavelength': wavelength,
          'waveSpeed': frequency * wavelength,
          'phase':
              2 *
                  math.pi *
                  (v('probe') / wavelength -
                      (mode == 0 ? 1 : -1) * frequency * time) +
              v('phase'),
          if (kind == 3) 'nodeCount': v('harmonic') + 1,
        });
      }
    } else if (kind == 2) {
      final f = field(v('probe'), v('z'));
      state.addAll({
        'sum': f.displacement,
        'probeAmplitude': f.amplitude,
        'intensity': f.intensity,
        'pathDifference': f.pathDifference,
        'phaseDifference': f.phase,
        'wavelength': wavelength,
      });
      final co = math.cos(2 * math.pi * frequency * time),
          si = math.sin(2 * math.pi * frequency * time);
      grid.clear();
      for (int i = 0; i < fieldReal.length; i++) {
        grid.add(v('amplitude') * (fieldImag[i] * co - fieldReal[i] * si));
      }
      profile = [
        for (int i = 0; i <= 256; i++)
          {
            't': -1 + 2 * i / 256,
            'sum': field(-1 + 2 * i / 256, v('z')).displacement,
            'intensity': field(-1 + 2 * i / 256, v('z')).intensity,
          },
      ];
    } else if (kind == 4) {
      signal = educationalSignal(
        2048,
        16384,
        v('frequency'),
        v('amplitude'),
        v('frequency2'),
        v('ratio'),
        mode,
        start: time,
      );
      spectrum = Spectrum.analyze(signal, 16384);
      _spectrumState();
    } else if (kind == 5) {
      final speed = v('mach') * v('c'),
          d = doppler(
            time,
            v('x0'),
            speed,
            v('observer'),
            v('c'),
            v('frequency'),
          );
      state.addAll({
        'sourceX': v('x0') + speed * time,
        'emissionTime': d.emission,
        'retardedSourceX': d.source,
        'sourceSpeed': speed,
        if (d.frequency != null) 'observedFrequency': d.frequency!,
        'frontStride': math.max(1, (v('frequency') * .03).ceil()).toDouble(),
      });
      final stride = state['frontStride']!,
          interval = stride / v('frequency'),
          last = (time / interval).floor() * interval;
      fronts = [
        for (int i = 0; i < 32; i++)
          {
            'emission': last - i * interval,
            'x': v('x0') + speed * (last - i * interval),
            'radius': v('c') * (time - last + i * interval),
          },
      ];
      profile = [
        for (int i = 0; i <= 512; i++)
          {
            't': -.02 + .04 * i / 512,
            'signal': math.sin(
              2 *
                  math.pi *
                  v('frequency') *
                  doppler(
                    time - .02 + .04 * i / 512,
                    v('x0'),
                    speed,
                    v('observer'),
                    v('c'),
                    v('frequency'),
                  ).emission,
            ),
          },
      ];
    } else if (kind == 6 || kind == 7) {
      final theta = v('angle') * math.pi / 180,
          d = Vec2(math.sin(theta), -math.cos(theta)),
          origin = Vec2(v('hit'), 0) - d * .5,
          intersection = rayPlane(
            origin,
            d,
            const Vec2(0, 0),
            const Vec2(0, 1),
          )!;
      state.addAll({
        'hitX': intersection.x,
        'incidentAngle': v('angle'),
        'reflectedAngle': v('angle'),
        'ix': d.x,
        'iy': d.y,
        'rx': d.x,
        'ry': -d.y,
      });
      if (kind == 7) {
        final s = snell(v('n1'), v('n2'), theta);
        state.addAll({
          'tir': s.tir ? 1 : 0,
          if (s.angle != null) 'transmittedAngle': s.angle! * 180 / math.pi,
          if (s.transmission != null) 'tx': s.transmission!.x,
          if (s.transmission != null) 'ty': s.transmission!.y,
          if (s.critical != null) 'criticalAngle': s.critical! * 180 / math.pi,
          'speed1': lightSpeed / v('n1'),
          'speed2': lightSpeed / v('n2'),
          'lambda1': v('wavelength') / v('n1'),
          'lambda2': v('wavelength') / v('n2'),
          'frequency': lightSpeed / v('wavelength'),
        });
      }
      profile = [
        for (int i = 0; i <= 170; i++)
          {
            't': i / 2,
            'reflection': i / 2,
            if (kind == 7 &&
                snell(v('n1'), v('n2'), i * math.pi / 360).angle != null)
              'refraction':
                  snell(v('n1'), v('n2'), i * math.pi / 360).angle! *
                  180 /
                  math.pi,
          },
      ];
    } else if (kind == 8 || kind == 9) {
      final f = v('focal') * (mode == 0 ? 1 : -1),
          image = ImageSolution(f, v('u'), v('height'));
      state.addAll(image.state);
      state['focal'] = f;
      if (image.distance != null && image.distance! > 0) {
        state['focusError'] = (image.distance! - v('screen')).abs();
      }
      profile = [
        for (int i = 0; i <= 256; i++)
          {
            't': .05 + .95 * i / 256,
            'imageVergence': 1 / f - 1 / (.05 + .95 * i / 256),
          },
      ];
    } else {
      state.addAll({
        'intensity': opticalIntensity(
          kind == 10,
          v('wavelength'),
          v('aperture'),
          v('screen'),
          v('probe'),
        ),
        'fresnelNumber':
            v('aperture') * v('aperture') / (v('wavelength') * v('screen')),
        'angle': math.atan(v('probe') / v('screen')) * 180 / math.pi,
        'spacing': v('wavelength') * v('screen') / v('aperture'),
        if (kind == 11 &&
            diffractionMinimum(
                  v('wavelength'),
                  v('aperture'),
                  v('screen'),
                  1,
                ) !=
                null)
          'centralWidth':
              2 *
              diffractionMinimum(
                v('wavelength'),
                v('aperture'),
                v('screen'),
                1,
              )!,
      });
      profile = [
        for (int i = 0; i <= 800; i++)
          {
            't': -.03 + .06 * i / 800,
            'intensity': opticalIntensity(
              kind == 10,
              v('wavelength'),
              v('aperture'),
              v('screen'),
              -.03 + .06 * i / 800,
            ),
          },
      ];
    }
    revision++;
  }
}
