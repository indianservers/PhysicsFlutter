import 'package:flutter/material.dart';

import '../../core/design_system/reading_presentation.dart';
import '../advanced/scene.dart';

/// Numerically inspect the actual plotted series; no synthetic observations.
class GraphMeasurement extends StatefulWidget {
  final LabPlot plot;
  const GraphMeasurement(this.plot, {super.key});
  @override
  State<GraphMeasurement> createState() => _GraphMeasurementState();
}

class _GraphMeasurementState extends State<GraphMeasurement> {
  String? selected;
  double start = 0, end = 1;
  @override
  Widget build(BuildContext context) {
    final plot = widget.plot;
    final keys = plot.keys
        .where(
          (key) => plot.data.any(
            (p) => (p[key]?.isFinite ?? false) && (p['t']?.isFinite ?? false),
          ),
        )
        .toList();
    if (keys.isEmpty) {
      return const Text('Run or step the model to inspect graph samples.');
    }
    final key = keys.contains(selected) ? selected! : keys.first;
    final data = plot.data
        .where(
          (p) => (p[key]?.isFinite ?? false) && (p['t']?.isFinite ?? false),
        )
        .toList();
    if (data.length < 2) {
      return const Text(
        'Run or step the model to collect at least two graph samples.',
      );
    }
    final first = (start * (data.length - 1)).round(),
        last = (end * (data.length - 1)).round();
    final dx = data[last]['t']! - data[first]['t']!,
        dy = data[last][key]! - data[first][key]!;
    var area = 0.0;
    for (var i = first + 1; i <= last; i++) {
      area +=
          (data[i]['t']! - data[i - 1]['t']!) *
          (data[i][key]! + data[i - 1][key]!) /
          2;
    }
    final xUnit =
        RegExp(r'\(([^)]+)\)\s*$').firstMatch(plot.xLabel)?.group(1) ??
        'horizontal-axis unit';
    void move(bool isStart, double delta) => setState(() {
      if (isStart) {
        start = (start + delta).clamp(0, end);
      } else {
        end = (end + delta).clamp(start, 1);
      }
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: key,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Plotted series'),
          items: [
            for (final k in keys) DropdownMenuItem(value: k, child: Text(k)),
          ],
          onChanged: (v) => setState(() => selected = v),
        ),
        SizedBox(
          height: 220,
          child: CustomPaint(
            painter: LabPlot(
              data,
              [key],
              plot.xLabel,
              plot.unit,
              last,
              scatter: plot.scatter,
              histogramKeys: plot.histogramKeys.intersection({key}),
              errorKeys: plot.errorKeys,
            ),
          ),
        ),
        Text('Interval along ${plot.xLabel}'),
        RangeSlider(
          values: RangeValues(start, end),
          labels: RangeLabels(
            conciseNumber(data[first]['t']!),
            conciseNumber(data[last]['t']!),
          ),
          onChanged: (v) => setState(() {
            start = v.start;
            end = v.end;
          }),
        ),
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: () => move(true, -1 / (data.length - 1)),
              child: const Text('Start −'),
            ),
            TextButton(
              onPressed: () => move(true, 1 / (data.length - 1)),
              child: const Text('Start +'),
            ),
            TextButton(
              onPressed: () => move(false, -1 / (data.length - 1)),
              child: const Text('End −'),
            ),
            TextButton(
              onPressed: () => move(false, 1 / (data.length - 1)),
              child: const Text('End +'),
            ),
          ],
        ),
        SelectableText(
          'Start: ${conciseNumber(data[first]['t']!)} $xUnit → ${conciseNumber(data[first][key]!)} ${plot.unit}\nEnd: ${conciseNumber(data[last]['t']!)} $xUnit → ${conciseNumber(data[last][key]!)} ${plot.unit}',
        ),
        if (!plot.scatter && !plot.histogramKeys.contains(key))
          Text(
            dx == 0
                ? 'Secant slope undefined: choose two different horizontal positions.'
                : 'Secant slope Δy/Δx: ${conciseNumber(dy / dx, precision: 5)} ${plot.unit}/($xUnit)',
          ),
        if (!plot.scatter && !plot.histogramKeys.contains(key))
          Text(
            'Signed area (trapezoidal approximation): ${conciseNumber(area, precision: 5)} ${plot.unit}·($xUnit)',
          ),
        const Text(
          'Computed from the plotted samples. The slope is an interval average; the signed area depends on the selected quantity and axis. Moving these markers does not change the experiment.',
        ),
      ],
    );
  }
}
