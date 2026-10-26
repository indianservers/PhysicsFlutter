import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../core/physics/measurement.dart';

class Experiment extends ChangeNotifier {
  final int kind;
  double a = 0,
      b = 0,
      zero = 0,
      resolution = .001,
      distance = .5,
      v0 = .2,
      acceleration = .3;
  String unit = 'm', note = '';
  List<double> samples = [];
  List<String> propagationInputs = ['', '', '', ''];
  String propagationOp = '+',
      propagationOutput = 'Enter two values and their standard uncertainties.';
  bool reveal = false, guides = true;
  bool resolutionKnown = true;
  int step = 0;
  bool adjusted = false;
  String? predictionSignature;
  String _initialInputs = '';
  String get inputSignature => jsonEncode([
    kind,
    a,
    b,
    zero,
    resolution,
    resolutionKnown,
    distance,
    v0,
    acceleration,
    unit,
    samples,
  ]);
  String get observationSignature => jsonEncode([inputSignature, elapsed]);
  bool get predictionMatches => predictionSignature == observationSignature;
  void checkPrediction(double answer) {
    final expected = result;
    final tolerance = kind == 4
        ? .005
        : kind == 5
        ? math.max(1e-9, expected == null ? 0 : expected.abs() * .005)
        : leastCount / 2;
    predictionSignature =
        expected != null &&
            answer.isFinite &&
            (answer - expected).abs() <= tolerance
        ? observationSignature
        : null;
    changed();
  }

  bool matchesTrial(Map<String, dynamic> state) =>
      state['observationSignature'] == observationSignature;
  bool get evidenceReady =>
      adjusted && predictionMatches && note.trim().length >= 12;
  final Stopwatch _clock = Stopwatch();
  Timer? _timer;
  final clockTick = ValueNotifier<double>(0);
  double _elapsed = 0;
  Experiment(this.kind) {
    reset();
  }
  bool get running => _clock.isRunning;
  double get elapsed {
    final time = _elapsed + _clock.elapsedMicroseconds / 1e6;
    // A delayed UI timer must not extend the defined automatic finish event.
    return kind == 4 ? math.min(duration, time) : time;
  }

  double get duration => finishTime(distance, v0, acceleration);
  ScaleReading get reading => kind == 1
      ? ScaleReading.vernier(a + zero)
      : ScaleReading.micrometer(a + zero);
  double get h => a - zero;
  double get travelled =>
      math.min(distance, trackPosition(elapsed, v0, acceleration));
  double? get result => switch (kind) {
    0 => rulerLength(a, b),
    1 || 2 => corrected(reading.observed, zero),
    3 => curvatureRadius(b, h),
    4 => elapsed > 0 ? travelled / elapsed : null,
    5 => samples.isEmpty ? null : Statistics(samples, resolution).mean,
    _ => null,
  };
  String get quantity => switch (kind) {
    0 || 1 || 2 => 'length',
    3 => 'radius',
    4 => 'speed',
    _ =>
      unit == 'm'
          ? 'length'
          : unit == 'kg'
          ? 'mass'
          : 'time',
  };
  String get siUnit => kind == 4
      ? 'm/s'
      : kind == 5
      ? unit
      : 'm';
  double get leastCount => switch (kind) {
    0 => .001,
    1 => .0001,
    2 => .00001,
    3 => .00001,
    4 => .001,
    _ => resolution,
  };
  void changed() {
    if (_initialInputs.isNotEmpty && inputSignature != _initialInputs) {
      adjusted = true;
    }
    notifyListeners();
  }

  void setA(double x) {
    a = switch (kind) {
      0 => quantize(x, .001).clamp(0, b - .001),
      1 => quantize(x, .0001).clamp(0, .05),
      2 => quantize(x, .00001).clamp(b, .025),
      3 => quantize(x, .00001).clamp(-.003, .003),
      _ => x,
    };
    changed();
  }

  void setB(double x) {
    b = kind == 0
        ? quantize(x, .001).clamp(a + .001, .1)
        : kind == 2
        ? quantize(x, .00001).clamp(.0001, .005)
        : x;
    if (kind == 2 && a < b) {
      a = b;
    }
    changed();
  }

  void start() {
    if (kind != 4 || running) {
      return;
    }
    _clock.start();
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (elapsed >= duration) {
        pause();
        _elapsed = duration;
      }
      clockTick.value = elapsed;
    });
    changed();
  }

  void pause() {
    _elapsed = elapsed;
    _clock.stop();
    _clock.reset();
    _timer?.cancel();
    changed();
  }

  void resetTimer() {
    pause();
    _elapsed = 0;
    changed();
  }

  void reset() {
    pause();
    _elapsed = 0;
    zero = 0;
    reveal = false;
    step = 0;
    adjusted = false;
    predictionSignature = null;
    _initialInputs = '';
    samples = [];
    propagationInputs = ['', '', '', ''];
    propagationOp = '+';
    propagationOutput = 'Enter two values and their standard uncertainties.';
    note = '';
    unit = 'm';
    distance = .5;
    v0 = .2;
    acceleration = .3;
    resolution = .001;
    resolutionKnown = true;
    a = switch (kind) {
      0 => .012,
      1 => .0236,
      2 => .00052,
      3 => .00044,
      4 => .02845,
      _ => .001,
    };
    b = switch (kind) {
      0 => .066,
      2 => .0005,
      3 => .05,
      _ => .05,
    };
    _initialInputs = inputSignature;
    changed();
  }

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'adjusted': adjusted,
    'predictionSignature': predictionSignature,
    'observationSignature': observationSignature,
    'a': a,
    'b': b,
    'zero': zero,
    'resolution': resolution,
    'resolutionKnown': resolutionKnown,
    'distance': distance,
    'v0': v0,
    'acceleration': acceleration,
    'elapsed': elapsed,
    'samples': samples,
    'propagationInputs': propagationInputs,
    'propagationOp': propagationOp,
    'propagationOutput': propagationOutput,
    'unit': unit,
    'note': note,
    'step': step,
    'guides': guides,
    'reveal': reveal,
    'model': modelVersion,
  };
  bool restore(Map<String, dynamic> m) {
    if (m['model'] != modelVersion || m['kind'] != kind) {
      return false;
    }
    try {
      final numbers = [
        'a',
        'b',
        'zero',
        'resolution',
        'distance',
        'v0',
        'acceleration',
        'elapsed',
      ].map((k) => (m[k] as num).toDouble()).toList();
      if (!numbers.every((n) => n.isFinite) ||
          numbers[3] <= 0 ||
          numbers[4] <= 0 ||
          numbers[5] <= 0 ||
          numbers[6] < 0 ||
          numbers[7] < 0) {
        return false;
      }
      final restoredSamples = (m['samples'] as List)
          .map((v) => (v as num).toDouble())
          .toList();
      bool within(double x, double min, double max) =>
          x >= min - 1e-12 && x <= max + 1e-12;
      final validGeometry = switch (kind) {
        0 =>
          within(numbers[0], 0, .099) &&
              within(numbers[1], numbers[0] + .001, .1),
        1 => within(numbers[0], 0, .05) && within(numbers[2], -.001, .001),
        2 =>
          within(numbers[1], .0001, .005) &&
              within(numbers[0], numbers[1], .025) &&
              within(numbers[2], -.0001, .0001),
        3 =>
          within(numbers[0], -.003, .003) &&
              within(numbers[1], .01, .1) &&
              within(numbers[2], -.003, .003),
        4 => within(numbers[0], .001, .1) && within(numbers[2], 0, .1),
        _ => true,
      };
      if (!validGeometry ||
          !within(numbers[3], .00001, .01) ||
          !within(numbers[4], .1, 2) ||
          !within(numbers[5], .1, 2) ||
          !within(numbers[6], 0, 2)) {
        return false;
      }
      if (m['note'] is! String ||
          m['step'] is! int ||
          m['guides'] is! bool ||
          m['reveal'] is! bool) {
        return false;
      }
      if (!restoredSamples.every((v) => v.isFinite) ||
          !['m', 'kg', 's'].contains(m['unit'])) {
        return false;
      }
      pause();
      a = numbers[0];
      b = numbers[1];
      zero = numbers[2];
      resolution = numbers[3];
      resolutionKnown = m['resolutionKnown'] ?? true;
      distance = numbers[4];
      v0 = numbers[5];
      acceleration = numbers[6];
      _elapsed = math.min(numbers[7], duration);
      samples = restoredSamples;
      if (m['propagationInputs'] is List &&
          (m['propagationInputs'] as List).length == 4 &&
          (m['propagationInputs'] as List).every((v) => v is String)) {
        propagationInputs = List<String>.from(m['propagationInputs']);
      }
      propagationOp = ['+', '−', '×', '÷'].contains(m['propagationOp'])
          ? m['propagationOp']
          : '+';
      propagationOutput = m['propagationOutput'] is String
          ? m['propagationOutput']
          : 'Enter two values and their standard uncertainties.';
      unit = m['unit'];
      note = m['note'] ?? '';
      step = (m['step'] as int).clamp(0, 3);
      adjusted = m['adjusted'] == true;
      predictionSignature = m['predictionSignature'] is String
          ? m['predictionSignature']
          : null;
      guides = m['guides'] ?? true;
      reveal = m['reveal'] ?? false;
      changed();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clock.stop();
    clockTick.dispose();
    super.dispose();
  }
}
