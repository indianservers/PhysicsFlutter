import 'dart:math' as math;

import 'measurement.dart';

/// Signed height is positive when the surface centre is above the outer-tip plane.
class SpherometerSetup {
  static const pitch = .0005;
  static const divisions = 50;
  static const leastCount = pitch / divisions;
  int surface = 0;
  double truthSagitta = .00044, offset = 0;
  double? reference, contactReading;
  bool revealed = false;
  String view = 'Perspective';
  bool labels = true, lens = true, exaggerated = true;
  double get target => surface == 0
      ? 0
      : surface == 1
      ? truthSagitta
      : -truthSagitta;
  double get contactStop =>
      ((target + offset) / leastCount - 1e-10).ceil() * leastCount;
  bool atContact(double indication) =>
      (indication - contactStop).abs() < leastCount * .01;
  double? get measuredH => reference == null || contactReading == null
      ? null
      : contactReading! - reference!;
  double? radius(double r) =>
      measuredH == null ? null : curvatureRadius(r, measuredH!);
  double surfaceHeight(double radial, double r) {
    if (surface == 0 || target.abs() < 1e-12) return 0;
    final signedR = curvatureRadius(r, target)!;
    final rr = signedR.abs();
    if (radial > rr) return 0;
    return target -
        signedR +
        signedR.sign * math.sqrt(math.max(0, rr * rr - radial * radial));
  }

  List<({double x, double y})> legs(double r) => [
    for (int i = 0; i < 3; i++)
      (
        x: r * math.cos(-math.pi / 2 + i * 2 * math.pi / 3),
        y: r * math.sin(-math.pi / 2 + i * 2 * math.pi / 3),
      ),
  ];
  Map<String, dynamic> toJson() => {
    'version': 1,
    'surface': surface,
    'truthSagitta': truthSagitta,
    'offset': offset,
    'reference': reference,
    'contactReading': contactReading,
    'revealed': revealed,
    'view': view,
    'labels': labels,
    'lens': lens,
    'exaggerated': exaggerated,
  };
  static SpherometerSetup fromJson(Map<String, dynamic> j) {
    double n(String k, double lo, double hi) {
      final x = (j[k] as num).toDouble();
      if (!x.isFinite || x < lo || x > hi) throw FormatException(k);
      return x;
    }

    if (j['version'] != 1 ||
        j['surface'] is! int ||
        j['surface'] < 0 ||
        j['surface'] > 2 ||
        !['Perspective', 'Top', 'Section'].contains(j['view'])) {
      throw const FormatException('Spherometer configuration');
    }
    final s = SpherometerSetup()
      ..surface = j['surface']
      ..truthSagitta = n('truthSagitta', 0, .006)
      ..offset = n('offset', -.003, .003)
      ..view = j['view']
      ..revealed = j['revealed'] as bool
      ..labels = j['labels'] as bool
      ..lens = j['lens'] as bool
      ..exaggerated = j['exaggerated'] as bool;
    s.reference = j['reference'] == null ? null : n('reference', -.003, .003);
    s.contactReading = j['contactReading'] == null
        ? null
        : n('contactReading', -.003, .003);
    return s;
  }
}
