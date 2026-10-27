/// Display formatting only: stored measurements, controls and calculations stay SI.
String conciseNumber(double value, {int precision = 4}) {
  if (!value.isFinite) return 'Undefined';
  if (value == 0) return '0';
  final parts = value.toStringAsPrecision(precision).split('e');
  final mantissa = parts.first.contains('.')
      ? parts.first
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), '')
      : parts.first;
  return parts.length == 1 ? mantissa : '${mantissa}e${int.parse(parts.last)}';
}

/// A reversible display-unit transform. Numeric entry converts back to SI once.
({double factor, String unit}) displayScale(double value, String unit) {
  if (value != 0 &&
      value.isFinite &&
      const {
        'm',
        's',
        'A',
        'C',
        'F',
        'T',
        'J',
        'W',
        'V',
        'Pa',
        'Hz',
      }.contains(unit)) {
    final magnitude = value.abs();
    for (final prefix in const [
      (1e12, 'T'),
      (1e9, 'G'),
      (1e6, 'M'),
      (1e3, 'k'),
      (1.0, ''),
      (1e-3, 'm'),
      (1e-6, 'µ'),
      (1e-9, 'n'),
      (1e-12, 'p'),
      (1e-15, 'f'),
    ]) {
      if (magnitude >= prefix.$1 && magnitude < prefix.$1 * 1000) {
        return (factor: prefix.$1, unit: '${prefix.$2}$unit');
      }
    }
  }
  return (factor: 1, unit: unit);
}

({String label, String value, String unit, String tooltip}) presentReading(
  String label,
  String value,
  String unit,
) {
  const names = {
    'fx': 'Net force (x)',
    'fy': 'Net force (y)',
    'force2': 'Force on body B',
    'torque1': 'Torque A',
    'torque2': 'Torque B',
    'k': 'Kinetic energy',
    'u': 'Potential energy',
    'vx': 'Velocity (x)',
    'vy': 'Velocity (y)',
    'ax': 'Acceleration (x)',
    'ay': 'Acceleration (y)',
    'net torque': 'Net torque',
    'net work': 'Net work',
    'model t': 'Elapsed time',
    'playback': 'Playback time',
    'expected activity': 'Expected activity',
    'critical': 'Critical damping coefficient',
    'natural omega': 'Natural angular frequency',
    'delta u': 'Internal energy change',
  };
  final words = label.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (m) => '${m[1]} ${m[2]!.toLowerCase()}',
  );
  final expanded = names[words.toLowerCase()] ?? words;
  final displayLabel = expanded.isEmpty
      ? ''
      : '${expanded[0].toUpperCase()}${expanded.substring(1)}';
  var displayValue = value, displayUnit = unit;
  final number = double.tryParse(value);
  if (number != null &&
      number.isFinite &&
      (label.toLowerCase().contains('efficiency') || label == 'mid depth') &&
      unit.isEmpty) {
    displayValue = conciseNumber(number * 100);
    displayUnit = '%';
  } else if (number != null &&
      number.isFinite &&
      unit == 'J' &&
      (label.toLowerCase() == 'quantum energy' ||
          words.toLowerCase() == 'binding per nucleon')) {
    final nuclear = words.toLowerCase() == 'binding per nucleon';
    displayValue = conciseNumber(
      number / (1.602176634e-19 * (nuclear ? 1e6 : 1)),
      precision: 5,
    );
    displayUnit = nuclear ? 'MeV' : 'eV';
  } else if (number != null &&
      number.isFinite &&
      unit == 'W' &&
      label.toLowerCase() == 'luminosity') {
    displayValue = conciseNumber(number / 3.828e26, precision: 5);
    displayUnit = 'L☉';
  } else if (number != null &&
      number.isFinite &&
      unit == 'm' &&
      number.abs() >= 1e10) {
    final distance = number.abs();
    final factor = distance >= 3.085677581491367e22
        ? 3.085677581491367e22
        : distance >= 3.085677581491367e19
        ? 3.085677581491367e19
        : distance >= 3.085677581491367e16
        ? 3.085677581491367e16
        : 149597870700.0;
    displayValue = conciseNumber(number / factor, precision: 5);
    displayUnit = factor == 3.085677581491367e22
        ? 'Mpc'
        : factor == 3.085677581491367e19
        ? 'kpc'
        : factor == 3.085677581491367e16
        ? 'pc'
        : 'AU';
  } else if (number != null &&
      number.isFinite &&
      unit == 's' &&
      number.abs() >= 86400) {
    final years = number.abs() >= 31557600;
    displayValue = conciseNumber(
      number / (years ? 31557600 : 86400),
      precision: 5,
    );
    displayUnit = years ? 'yr' : 'd';
  } else if (number != null &&
      number.isFinite &&
      unit == 'm/s' &&
      number.abs() >= 1000) {
    displayValue = conciseNumber(number / 1000, precision: 5);
    displayUnit = 'km/s';
  } else if (number != null && number.isFinite) {
    final scale = displayScale(number, unit);
    displayValue = conciseNumber(number / scale.factor, precision: 5);
    displayUnit = scale.unit;
  }

  return (
    label: displayLabel,
    value: displayValue,
    unit: displayUnit,
    tooltip: '$label: $value${unit.isEmpty ? '' : ' $unit'}',
  );
}
