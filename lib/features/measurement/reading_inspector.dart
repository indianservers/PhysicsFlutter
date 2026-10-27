import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design_system/reading_presentation.dart';
import '../../core/physics/measurement.dart';
import 'experiment.dart';

/// Readable counterparts to scale marks. All numbers come from the live model.
class MeasurementInspector extends StatelessWidget {
  final Experiment experiment;
  const MeasurementInspector(this.experiment, {super.key});
  @override
  Widget build(BuildContext context) {
    final e = experiment;
    String mm(double x) => '${conciseNumber(x * 1000, precision: 6)} mm';
    final lines = switch (e.kind) {
      0 => [
        'Endpoint A: ${mm(e.a)}',
        'Endpoint B: ${mm(e.b)}',
        'Length = B − A = ${mm(e.b - e.a)}',
        'Read both endpoints; aligning the object to zero is optional.',
      ],
      1 || 2 => [
        'Main scale: ${mm(e.reading.main)}',
        '${e.kind == 1 ? 'Coincident vernier' : 'Thimble'} division: ${e.reading.division}',
        'Fractional contribution: ${mm(e.reading.fraction)}',
        'Observed: ${mm(e.reading.observed)}',
        'Signed zero error: ${mm(e.zero)}',
        'Corrected = main + fraction − zero = ${mm(e.result!)}',
        if (e.kind == 2) 'One full turn: 0.50 mm. One division: 0.01 mm.',
      ],
      3 => [
        '1. Use a plane reference and record screw contact.',
        '2. Select curved glass; lower the screw gently to contact.',
        '3. Compare the two contacts to find signed sagitta h.',
        'Centre-to-leg distance r: ${mm(e.b)}',
        'Leg spacing l = √3 r: ${mm(math.sqrt(3) * e.b)}',
        'Sagitta h: ${e.spherometer?.measuredH == null ? 'Record both contacts' : mm(e.spherometer!.measuredH!)}',
        'R = (r² + h²) / (2h). Convex: +h / +R; concave: −h / −R.',
        'At h = 0 the spherical radius is infinite; a flat surface has zero curvature.',
      ],
      4 => [
        'Travelled: ${conciseNumber(e.travelled)} m',
        'Elapsed: ${conciseNumber(e.elapsed)} s',
        'Average speed: ${e.result == null ? 'Run the timer first' : '${conciseNumber(e.result!)} m/s'}',
        'Instantaneous speed: ${conciseNumber(e.v0 + e.acceleration * e.elapsed)} m/s',
        'The timer starts on release and stops at the end of the defined track.',
      ],
      _ => [
        'Repeated readings: ${e.samples.length}',
        for (final x in e.samples.indexed)
          '${x.$1 + 1}. ${conciseNumber(x.$2, precision: 6)} ${e.unit}',
        if (e.samples.length >= 2) ...[
          'Mean: ${conciseNumber(Statistics(e.samples, e.resolution).mean!)} ${e.unit}',
          'Spread describes individual readings. Uncertainty of the mean describes the estimated mean.',
        ],
        'Instrument resolution and repeated-reading scatter are different contributions.',
      ],
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Read the instrument',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (e.kind == 3 && e.spherometer != null) ...[
            Wrap(
              spacing: 8,
              children: [
                for (final view in ['Perspective', 'Top', 'Section'])
                  ChoiceChip(
                    label: Text(view),
                    selected: e.spherometer!.view == view,
                    onSelected: (_) {
                      e.spherometer!.view = view;
                      e.changed();
                    },
                  ),
              ],
            ),
            SwitchListTile(
              title: const Text('Geometry labels'),
              value: e.spherometer!.labels,
              onChanged: (v) {
                e.spherometer!.labels = v;
                e.changed();
              },
            ),
            SwitchListTile(
              title: const Text('Exaggerate vertical curvature ×12'),
              subtitle: const Text(
                'Display only; readings and physical dimensions stay unchanged.',
              ),
              value: e.spherometer!.exaggerated,
              onChanged: (v) {
                e.spherometer!.exaggerated = v;
                e.changed();
              },
            ),
          ],
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: SelectableText(line),
            ),
        ],
      ),
    );
  }
}
