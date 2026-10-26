/// Display formatting only: stored measurements, controls and calculations stay SI.
({String label, String value, String unit, String tooltip}) presentReading(
  String label,
  String value,
  String unit,
) {
  const names = {
    'vx': 'Velocity (x)',
    'vy': 'Velocity (y)',
    'ax': 'Acceleration (x)',
    'ay': 'Acceleration (y)',
    'net torque': 'Net torque',
    'net work': 'Net work',
    'model t': 'Elapsed time',
    'playback': 'Playback time',
    'expected activity': 'Expected activity',
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
      number != 0 &&
      number.abs() < .001 &&
      const {'m', 's', 'A', 'C', 'F', 'T', 'J', 'W'}.contains(unit)) {
    for (final prefix in const [
      (1e-3, 'm'),
      (1e-6, 'µ'),
      (1e-9, 'n'),
      (1e-12, 'p'),
      (1e-15, 'f'),
    ]) {
      if (number.abs() >= prefix.$1) {
        displayValue = (number / prefix.$1)
            .toStringAsPrecision(5)
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), '');
        displayUnit = '${prefix.$2}$unit';
        break;
      }
    }
  }
  return (
    label: displayLabel,
    value: displayValue,
    unit: displayUnit,
    tooltip: '$label: $value${unit.isEmpty ? '' : ' $unit'}',
  );
}
