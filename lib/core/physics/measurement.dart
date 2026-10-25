import 'dart:math' as math;

const modelVersion = 'measurement-1.0';
double mm(double metres) => metres * 1000;
double metres(double millimetres) => millimetres / 1000;
double corrected(double observed, double signedZero) => observed - signedZero;
double rulerLength(double a, double b) => (b - a).abs();
double quantize(double x, double step) => (x / step).round() * step;

class ScaleReading {
  final double observed, main, fraction, leastCount;
  final int division;
  const ScaleReading(
    this.observed,
    this.main,
    this.fraction,
    this.leastCount,
    this.division,
  );
  factory ScaleReading.vernier(double opening) {
    final ticks = (opening / .0001).round();
    final mainTicks = (ticks / 10).floor();
    final division = ticks % 10;
    return ScaleReading(
      ticks * .0001,
      mainTicks * .001,
      division * .0001,
      .0001,
      division,
    );
  }
  factory ScaleReading.micrometer(double opening) {
    final ticks = (opening / .00001).round();
    final mainTicks = (ticks / 50).floor();
    final division = ticks % 50;
    return ScaleReading(
      ticks * .00001,
      mainTicks * .0005,
      division * .00001,
      .00001,
      division,
    );
  }
}

double spindleFromTurns(double turns, {double pitch = .0005}) => turns * pitch;
double? curvatureRadius(double r, double h) =>
    h.abs() < 1e-9 ? null : (r * r + h * h) / (2 * h);
double? curvatureFromLegSeparation(double l, double h) =>
    curvatureRadius(l / math.sqrt(3), h);
double trackPosition(double t, double v0, double acceleration) =>
    v0 * t + .5 * acceleration * t * t;
double finishTime(double distance, double v0, double acceleration) =>
    acceleration == 0
    ? distance / v0
    : (-v0 + math.sqrt(v0 * v0 + 2 * acceleration * distance)) / acceleration;

class Statistics {
  final List<double> values;
  final double? resolution;
  Statistics(this.values, this.resolution);
  double? get mean =>
      values.isEmpty ? null : values.reduce((a, b) => a + b) / values.length;
  double? get sd => values.length < 2
      ? null
      : math.sqrt(
          values.fold<double>(0, (s, x) => s + math.pow(x - mean!, 2)) /
              (values.length - 1),
        );
  double? get sem => sd == null ? null : sd! / math.sqrt(values.length);
  double? get instrument => resolution == null || resolution! < 0
      ? null
      : resolution! / math.sqrt(12);
  double? get combined => sem == null || instrument == null
      ? null
      : math.sqrt(sem! * sem! + instrument! * instrument!);
  double? get percent => combined == null || mean == null || mean == 0
      ? null
      : combined! / mean!.abs() * 100;
  double? get spread =>
      values.isEmpty ? null : values.reduce(math.max) - values.reduce(math.min);
}

({double value, double uncertainty}) propagate(
  double a,
  double ua,
  double b,
  double ub,
  String op,
) {
  if (ua < 0 || ub < 0 || ![a, ua, b, ub].every((v) => v.isFinite)) {
    throw ArgumentError(
      'Finite inputs and nonnegative standard uncertainties required.',
    );
  }
  return switch (op) {
    '+' => (value: a + b, uncertainty: math.sqrt(ua * ua + ub * ub)),
    '−' => (value: a - b, uncertainty: math.sqrt(ua * ua + ub * ub)),
    '×' => (
      value: a * b,
      uncertainty: math.sqrt(b * b * ua * ua + a * a * ub * ub),
    ),
    '÷' when b != 0 => (
      value: a / b,
      uncertainty: math.sqrt(
        ua * ua / (b * b) + a * a * ub * ub / math.pow(b, 4),
      ),
    ),
    _ => throw ArgumentError('Division by zero or unsupported operation'),
  };
}

String uncertaintyRounded(double value, double uncertainty) {
  if (uncertainty <= 0 || !uncertainty.isFinite) {
    return '$value';
  }
  final exponent = 1 - (math.log(uncertainty) / math.ln10).floor();
  final factor = math.pow(10, exponent);
  final roundedValue = (value * factor).round() / factor;
  final roundedUncertainty = (uncertainty * factor).round() / factor;
  final decimals = exponent.clamp(0, 12);
  return '${roundedValue.toStringAsFixed(decimals)} ± ${roundedUncertainty.toStringAsFixed(decimals)}';
}

class ViewTransform {
  final double scale, offset;
  const ViewTransform(this.scale, this.offset);
  double toScreen(double model) => model * scale + offset;
  double toModel(double screen) => (screen - offset) / scale;
}
