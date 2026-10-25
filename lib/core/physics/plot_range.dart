/// Unit-independent plot limits: a femtonewton is not numerically zero.
({double min, double max}) plotRange(
  Iterable<double> values, {
  bool includeZero = false,
}) {
  final finite = values.where((v) => v.isFinite).toList();
  if (includeZero) finite.add(0);
  if (finite.isEmpty) return (min: 0, max: 1);
  double low = finite.first, high = low;
  for (final value in finite) {
    if (value < low) low = value;
    if (value > high) high = value;
  }
  if (low == high) {
    final delta = low == 0 ? 1.0 : low.abs() * .1;
    return (min: low - delta, max: high + delta);
  }
  return (min: low, max: high);
}
