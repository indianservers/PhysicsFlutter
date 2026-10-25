import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/core/physics/measurement.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';
import 'package:physics_atelier/features/measurement/experiment.dart';

void main() {
  test(
    'Zero bias moves observed indication while corrected geometry stays fixed',
    () {
      for (final kind in [1, 2]) {
        final e = Experiment(kind);
        final original = e.a;
        for (final bias in [-.0001, 0.0, .0001]) {
          e.zero = bias;
          expect(e.result, closeTo(original, 1e-12));
          expect(
            e.reading.main + e.reading.fraction,
            closeTo(e.reading.observed, 1e-12),
          );
        }
        e.dispose();
      }
      final negative = ScaleReading.vernier(-.0001);
      expect(
        negative.main + negative.fraction,
        closeTo(negative.observed, 1e-12),
      );
    },
  );
  test(
    'Curriculum has exactly 17 studios, six entries each, 102 distinct IDs',
    () {
      expect(studios.length, 17);
      expect(studios.every((s) => s.entries.length == 6), true);
      expect(allEntries.length, 102);
      expect(allEntries.map((e) => e.id).toSet().length, 102);
      expect(allEntries.where((e) => e.interactive).length, 6);
      expect(allEntries.where((e) => e.tool).length, 6);
      expect(studios[1].entries.map((e) => e.title), [
        'Meter Scale',
        'Vernier Caliper',
        'Micrometer',
        'Spherometer',
        'Mass & Time',
        'Uncertainty',
      ]);
    },
  );
  test('SI conversions and view inverse preserve ruler length at any zoom', () {
    expect(metres(mm(.0123)), closeTo(.0123, 1e-12));
    for (final zoom in [1.0, 2.7, 5.0]) {
      final t = ViewTransform(3160 * zoom, -83);
      final a = t.toModel(t.toScreen(.012)), b = t.toModel(t.toScreen(.066));
      expect(rulerLength(a, b), closeTo(.054, 1e-12));
    }
  });
  test('Every vernier tick produces its exact main/vernier coincidence', () {
    for (int i = 0; i <= 500; i++) {
      final r = ScaleReading.vernier(i * .0001);
      expect(r.main + r.fraction, closeTo(r.observed, 1e-12));
      final coincidence = r.observed + r.division * .0009;
      expect(
        coincidence / .001,
        closeTo((coincidence / .001).roundToDouble(), 1e-8),
      );
    }
  });
  test('Signed zero error is subtracted', () {
    expect(corrected(.0236, .0002), closeTo(.0234, 1e-12));
    expect(corrected(.0236, -.0002), closeTo(.0238, 1e-12));
  });
  test('Micrometer screw pitch and half-mm marks agree with integer ticks', () {
    expect(spindleFromTurns(2), .001);
    for (int i = 0; i <= 2500; i++) {
      final r = ScaleReading.micrometer(i * .00001);
      expect(r.main + r.fraction, closeTo(r.observed, 1e-12));
      expect(r.leastCount, .00001);
      expect(r.division, inInclusiveRange(0, 49));
    }
    expect(ScaleReading.micrometer(.00052).main, .0005);
  });
  test('Micrometer cannot penetrate the defined object', () {
    final e = Experiment(2);
    e.setA(0);
    expect(e.a, e.b);
    e.dispose();
  });
  test('Spherometer equivalent geometries and signed flat limits', () {
    expect(
      curvatureRadius(.05, .00044),
      closeTo(curvatureFromLegSeparation(math.sqrt(3) * .05, .00044)!, 1e-10),
    );
    expect(curvatureRadius(.05, 0), isNull);
    expect(curvatureRadius(.05, 1e-12), isNull);
    expect(curvatureRadius(.05, -.00044), lessThan(0));
    expect(
      curvatureRadius(.05, .00001),
      greaterThan(curvatureRadius(.05, .00044)!),
    );
  });
  test('Timing derives from documented constant-acceleration motion', () {
    final t = finishTime(.5, .2, .3);
    expect(trackPosition(t, .2, .3), closeTo(.5, 1e-10));
    expect(finishTime(.5, .2, 0), 2.5);
    expect(trackPosition(0, .2, .3), 0);
  });
  test('Uncertainty boundary cases and sample statistics', () {
    expect(Statistics([], null).mean, isNull);
    expect(Statistics([1], .1).sd, isNull);
    expect(Statistics([0, 0], .1).percent, isNull);
    final s = Statistics([1, 2, 3], .1);
    expect(s.mean, 2);
    expect(s.sd, 1);
    expect(s.sem, closeTo(1 / math.sqrt(3), 1e-12));
    expect(s.instrument, closeTo(.1 / math.sqrt(12), 1e-12));
    expect(s.combined, closeTo(math.sqrt(1 / 3 + .01 / 12), 1e-12));
    expect(Statistics([1, 2], null).combined, isNull);
  });
  test('Propagation uses independent-input derivatives including zeros', () {
    expect(propagate(0, .1, 2, .2, '×').uncertainty, closeTo(.2, 1e-12));
    expect(propagate(1, .1, 2, .2, '+').value, 3);
    expect(propagate(1, .1, 2, .2, '−').value, -1);
    expect(propagate(1, .1, 2, .2, '÷').value, .5);
    expect(() => propagate(1, .1, 0, .1, '÷'), throwsArgumentError);
    expect(() => propagate(1, -1, 2, 1, '+'), throwsArgumentError);
  });
  test(
    'Trial serialization preserves SI, config, metadata and CSV quoting',
    () {
      final e = Experiment(1);
      final t = Trial(
        id: 'test',
        labId: 's01-e01',
        quantity: 'length',
        unit: 'm',
        value: e.result!,
        resolution: e.leastCount,
        configuration: e.toJson(),
        note: 'A, "B"\nC',
      );
      final restored = Trial.fromJson(jsonDecode(jsonEncode(t.toJson())));
      expect(restored.value, t.value);
      expect(restored.configuration, t.configuration);
      expect(restored.note, t.note);
      expect(csvEncode([t]), contains('"A, ""B""\nC"'));
      e.dispose();
    },
  );
  test('Sessions restore exact state safely and timers remain paused', () {
    for (int k = 0; k < 6; k++) {
      final original = Experiment(k), restored = Experiment(k);
      original.note = 'Observation';
      original.propagationInputs=['1','.1','2','.2'];original.propagationOp='×';original.propagationOutput='2.00 ± 0.28 m²';
      expect(restored.restore(original.toJson()), true);
      expect(restored.toJson(), original.toJson());
      expect(restored.running, false);
      expect(restored.restore({'model': 'future'}), false);
      original.dispose();
      restored.dispose();
    }
  });
}
