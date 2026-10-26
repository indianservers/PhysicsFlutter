import 'dart:math' as math;

import 'astronomy.dart';
export 'astronomy.dart';

class AstronomyRun {
  final int kind, mode;
  final Map<String, double> p;
  int ticks = 0, revision = 0;
  double time = 0;
  String invalid = '';
  bool finished = false;
  AstroState state = {};
  List<AstroState> profile = [], samples = [];
  List<AstroState> orbitStates = [];
  double v(String key) => p[key]!;
  bool get dynamicLab => [0, 1, 5].contains(kind);
  double get maxTime => 20;
  double get timeScale => switch (kind) {
    0 => julianYear,
    1 =>
      (stellarTracks[mode].last[0] - stellarTracks[mode].first[0]) *
          julianYear /
          20,
    5 => v('periodDays') * day * .08 / 20,
    _ => 1,
  };
  AstronomyRun(
    this.kind,
    Map<String, double> parameters, {
    this.mode = 0,
    AstronomyRun? cached,
  }) : p = Map.of(parameters) {
    try {
      astroRequire(
        kind >= 0 &&
            kind < 6 &&
            mode >= 0 &&
            mode < [8, 3, 2, 2, 1, 1][kind] &&
            p.values.every((x) => x.isFinite),
        'Valid finite model selection required',
      );
      calculate();
      final ignored = switch (kind) {
        0 => ['elapsedDays', 'scaleMode'],
        1 => ['ageFraction'],
        2 => ['wavelength'],
        3 => ['radiusKpc'],
        4 => ['redshift'],
        5 => ['phase'],
        _ => <String>[],
      };
      if (cached != null &&
          cached.kind == kind &&
          cached.mode == mode &&
          p.entries
              .where((e) => !ignored.contains(e.key))
              .every((e) => cached.p[e.key] == e.value)) {
        profile = cached.profile;
      } else {
        buildProfile();
      }
      capture();
    } on ArgumentError catch (e) {
      invalid = e.message.toString();
      state = {};
    }
  }
  void calculate() {
    if (invalid.isNotEmpty) return;
    try {
      switch (kind) {
        case 0:
          final seconds = v('elapsedDays') * day + time * timeScale;
          orbitStates = [for (final planet in planets) planet.at(seconds)];
          state = Map.of(orbitStates[mode]);
        case 1:
          state = stellar(mode, (v('ageFraction') + time / 20).clamp(0, 1));
        case 2:
          state = spectrumAt(
            v('wavelength'),
            v('temperature'),
            v('velocity'),
            v('resolution'),
            lines: mode == 0,
          );
          state['radialVelocity'] = v('velocity');
          state['dopplerFactor'] = dopplerFactor(v('velocity'));
        case 3:
          state = galaxy(
            v('radiusKpc') * kpc,
            v('bulgeMass') * solarMass,
            v('diskMass') * solarMass,
            v('diskScale') * kpc,
            v('haloSpeed'),
            halo: mode == 0,
          );
        case 4:
          state = cosmology(v('redshift'), v('h0'), v('omegaMatter'));
        case 5:
          state = transit(
            v('starMass'),
            v('starRadius'),
            v('radiusRatio'),
            v('periodDays'),
            v('inclination'),
            v('phase') * v('periodDays') * day + time * timeScale,
          );
          state['timeFromMidTransit'] =
              v('phase') * v('periodDays') * day + time * timeScale;
      }
      state.remove('t');
      if (kind == 2) state['wavelength'] = v('wavelength');
      state['playbackSeconds'] = time;
    } on ArgumentError catch (e) {
      invalid = e.message.toString();
      state = {};
    }
  }

  void buildProfile() {
    switch (kind) {
      case 0:
        profile = [
          for (int i = 0; i <= 240; i++)
            {
              't': i / 240 * planets[mode].period,
              ...planets[mode].at(i / 240 * planets[mode].period),
            },
        ];
      case 1:
        final rows = stellarTracks[mode];
        final selected = <int>{
          0,
          rows.length - 1,
          for (int i = 0; i < rows.length; i += 6) i,
          for (int i = 1; i < rows.length; i++)
            if (rows[i][3] != rows[i - 1][3]) ...[i - 1, i],
        }.toList()..sort();
        profile = [
          for (final i in selected)
            {
              't': -rows[i][2],
              'luminositySolar': math.pow(10, rows[i][1]).toDouble(),
              'logLuminosity': rows[i][1],
              'temperature': math.pow(10, rows[i][2]).toDouble(),
              'age': rows[i][0] * julianYear,
              'phase': rows[i][3],
            },
        ];
      case 2:
        final wavelengths = <double>{
          for (int i = 0; i <= 900; i++) 350e-9 + 450e-9 * i / 900,
        };
        for (final line in balmerVacuum) {
          final centre = line * dopplerFactor(v('velocity')),
              sigma = math.sqrt(
                math.pow(.12e-9 * dopplerFactor(v('velocity')), 2) +
                    math.pow(centre / (v('resolution') * 2.354820045), 2),
              );
          for (int i = -40; i <= 40; i++) {
            final w = centre + i * sigma / 8;
            if (w >= 350e-9 && w <= 800e-9) wavelengths.add(w);
          }
        }
        for (final line in balmerVacuum) {
          final sigma = math.sqrt(
            math.pow(.12e-9, 2) +
                math.pow(line / (v('resolution') * 2.354820045), 2),
          );
          for (int i = -40; i <= 40; i++) {
            final w = line + i * sigma / 8;
            if (w >= 350e-9 && w <= 800e-9) wavelengths.add(w);
          }
        }
        final sorted = wavelengths.toList()..sort();
        profile = [
          for (final w in sorted)
            {
              ...spectrumAt(
                w,
                v('temperature'),
                v('velocity'),
                v('resolution'),
                lines: mode == 0,
              ),
              'restReference': spectrumAt(
                w,
                v('temperature'),
                0,
                v('resolution'),
                lines: mode == 0,
              )['syntheticFlux']!,
            },
        ];
      case 3:
        profile = [
          for (int i = 0; i <= 240; i++)
            {
              't': (.1 + 29.9 * i / 240) * kpc,
              ...galaxy(
                (.1 + 29.9 * i / 240) * kpc,
                v('bulgeMass') * solarMass,
                v('diskMass') * solarMass,
                v('diskScale') * kpc,
                v('haloSpeed'),
                halo: mode == 0,
              ),
            },
        ];
      case 4:
        profile = [
          for (int i = 0; i <= 120; i++)
            {
              't': 5 * i / 120,
              ...cosmology(5 * i / 120, v('h0'), v('omegaMatter')),
            },
        ];
      case 5:
        profile = noisyTransit(p, v('seed').round(), v('noise'));
    }
  }

  void capture() {
    if (state.isEmpty) return;
    samples.add({'t': time, ...state});
    while (samples.length > 301) {
      samples.removeAt(0);
    }
  }

  void refresh() {
    calculate();
    revision++;
  }

  void step() {
    if (!dynamicLab || finished || invalid.isNotEmpty) return;
    ticks++;
    time = ticks / 120;
    if (ticks % 4 == 0) refresh();
    if (ticks % 8 == 0) capture();
    if (ticks >= 2400 || kind == 1 && v('ageFraction') + time / 20 >= 1) {
      finished = true;
      refresh();
      capture();
    }
  }

  void seek(double playbackSeconds) {
    final target = (playbackSeconds.clamp(0, 20) * 120).round();
    while (ticks < target && !finished && invalid.isEmpty) {
      step();
    }
    refresh();
  }
}
