import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design_system/reading_presentation.dart';
import '../../core/design_system/theme.dart';

/// A signed comparison of model quantities sharing the same physical unit.
/// Zero is always the center; width denotes magnitude, never a probability.
class QuantityLedger extends StatelessWidget {
  final String title, unit;
  final Map<String, double> quantities;
  const QuantityLedger({
    super.key,
    required this.title,
    required this.unit,
    required this.quantities,
  });
  @override
  Widget build(BuildContext context) {
    final finite = quantities.entries.where((e) => e.value.isFinite).toList();
    if (finite.isEmpty) return const SizedBox.shrink();
    final maximum = finite.fold(0.0, (m, e) => math.max(m, e.value.abs()));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Text(
            'Calculated values ($unit) · signed bars, shared magnitude scale',
            style: const TextStyle(fontSize: 12, color: muted),
          ),
          const SizedBox(height: 8),
          for (final e in finite)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${presentReading(e.key, '${e.value}', unit).label}: ${conciseNumber(e.value, precision: 5)} $unit',
                  ),
                  const SizedBox(height: 4),
                  Semantics(
                    label: '${e.key}, ${e.value} $unit',
                    child: LayoutBuilder(
                      builder: (context, bounds) {
                        final width = maximum == 0
                            ? 0.0
                            : e.value.abs() / maximum * bounds.maxWidth / 2;
                        return SizedBox(
                          height: 12,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ColoredBox(
                                  color: const Color(0xffedf3fa),
                                ),
                              ),
                              Positioned(
                                left: bounds.maxWidth / 2,
                                height: 12,
                                width: 1,
                                child: const ColoredBox(color: muted),
                              ),
                              Positioned(
                                left: e.value < 0
                                    ? bounds.maxWidth / 2 - width
                                    : bounds.maxWidth / 2,
                                width: width,
                                height: 12,
                                child: ColoredBox(
                                  color: e.value < 0 ? teal : navy,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('−'), Text('0'), Text('+')],
          ),
        ],
      ),
    );
  }
}
