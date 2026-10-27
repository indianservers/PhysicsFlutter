import 'package:flutter/foundation.dart';

class InstrumentControl {
  final String keyName, label, unit;
  final double value, min, max;
  final ValueChanged<double> change;
  const InstrumentControl(
    this.keyName,
    this.label,
    this.unit,
    this.value,
    this.min,
    this.max,
    this.change,
  );
}

class InstrumentReading {
  final String label, value, unit;
  const InstrumentReading(this.label, this.value, [this.unit = '']);
}
