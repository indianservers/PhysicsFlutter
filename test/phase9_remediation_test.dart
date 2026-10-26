import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';
import 'package:physics_atelier/core/physics/comparisons.dart';
import 'package:physics_atelier/core/physics/dynamics.dart';
import 'package:physics_atelier/features/measurement/experiment.dart';
import 'package:physics_atelier/features/lab_workspace/workspace.dart';
import 'package:physics_atelier/features/advanced/scene.dart';

import 'app_test.dart' show notebook;

void main() {
  test('Measurement completion binds changed inputs prediction notes and current trial', () {
    for (int kind = 0; kind < 6; kind++) {
      final e = Experiment(kind);
      expect(e.evidenceReady, false);
      if (kind == 5) {
        e.samples = [.02, .021, .022];
        e.changed();
      } else {
        e.setA(e.a + (kind == 0 ? .001 : .0001));
      }
      if (kind == 3) {
        e.spherometer!
          ..reference = 0
          ..surface = 1;
        e.setA(-.003);
        e.spherometer!.contactReading = e.a;
        e.changed();
      }
      e.note = 'A reasoned measurement observation.';
      if (kind != 4) {
        e.checkPrediction(e.result!);
        expect(e.evidenceReady, true);
        final state = e.toJson();
        expect(e.matchesTrial(state), true);
        e.setA(e.a + .001);
        expect(e.predictionMatches, false);
        expect(e.matchesTrial(state), false);
      }
      e.reset();
      expect(e.evidenceReady, false);
      e.dispose();
    }
  });
  test('CSV neutralizes formula-like notes but retains signed numeric values and original notes', () {
    for (final note in ['=1+1', '+SUM(A1)', '-1+2', '@SUM(A1)', '  =cmd()']) {
      final t = Trial(
        id: 'safe',
        labId: 's01-e00',
        quantity: 'length',
        unit: 'm',
        value: -.2,
        resolution: null,
        configuration: {},
        note: note,
      );
      expect(csvEncode([t]), contains('"\'$note"'));
      expect(csvEncode([t]), contains('"-0.2"'));
      expect(t.note, note);
    }
  });
  test('Measurement automatic finish is exact even if the timer callback is delayed', () {
    final e = Experiment(4)
      ..distance = .1
      ..v0 = 2
      ..acceleration = 0;
    e.start();
    final blocked = Stopwatch()..start();
    while (blocked.elapsedMilliseconds < 80) {
      /* Deliberate isolated event-loop stall. */
    }
    expect(e.elapsed, closeTo(.05, 1e-12));
    expect(e.result, closeTo(2, 1e-12));
    e.pause();
    expect(e.elapsed, .05);
    e.dispose();
  });
  test('Comparison source routes identify interference and capacitors', () {
    expect(comparisonLabs[2][1], 's09-e04');
    expect(comparisonLabs[3][0], 's10-e05');
  });
  test('Opt-in plot revision caches immutable graphs while mutable histories repaint', () {
    const data = [
      {'t': 0.0, 'x': 1.0},
    ];
    const a = LabPlot(data, ['x'], 's', 'm', 0, contentRevision: 1);
    const b = LabPlot(data, ['x'], 's', 'm', 0, contentRevision: 1);
    expect(b.shouldRepaint(a), false);
    expect(
      const LabPlot(
        data,
        ['x'],
        's',
        'm',
        0,
        contentRevision: 2,
      ).shouldRepaint(a),
      true,
    );
    expect(const LabPlot(data, ['x'], 's', 'm', 0).shouldRepaint(a), true);
    expect(
      const LabPlot(
        data,
        ['x'],
        's',
        'm',
        1,
        contentRevision: 1,
      ).shouldRepaint(a),
      true,
    );
  });
  test(
    'Fixed timestep is invariant to frame grouping at accepted elapsed times',
    () {
      final a = FixedClock(), b = FixedClock();
      int x = 0, y = 0;
      for (int i = 0; i < 120; i++) {
        a.advance(1 / 120, () => x++);
      }
      for (int i = 0; i < 20; i++) {
        b.advance(.05, () => y++);
      }
      expect(x, 120);
      expect(y, x);
      a.advance(30, () => x++);
      expect(x, 132);
      expect(a.droppedWallTime, greaterThan(29));
      a.pause();
      expect(a.accumulator, 0);
    },
  );
  testWidgets(
    'Corrupt session envelope is retained before defaults replace the row',
    (t) async {
      final store = await notebook();
      await store.preferences.setString('session:s01-e00', '{broken');
      expect(await store.readSession('s01-e00'), isNull);
      final backups = (await store.savedSessionIds())
          .where((k) => k.startsWith('backup:s01-e00:'))
          .toList();
      expect(backups, hasLength(1));
      final backup = await store.readSession(backups.single);
      expect(backup!['original']['unreadableRaw'], '{broken');
      await store.saveSession('s01-e00', Experiment(0).toJson());
      expect(
        (await store.readSession(backups.single))!['original']['unreadableRaw'],
        '{broken',
      );
    },
  );
  testWidgets('Malformed tool fields are backed up without crashing', (
    t,
  ) async {
    final store = await notebook();
    await store.saveSession('s00-e00', {
      'model': 'learning-tools-8.0',
      'query': 42,
      'opened': [false],
    });
    await t.pumpWidget(
      ProviderScope(
        overrides: [notebookProvider.overrideWithValue(store)],
        child: const PhysicsApp(),
      ),
    );
    router.go('/lab/s00-e00');
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    router.go('/');
    await t.pumpAndSettle();
    expect(
      (await store.savedSessionIds()).where(
        (k) => k.startsWith('backup:s00-e00:'),
      ),
      isNotEmpty,
    );
  });
  testWidgets(
    'Out-of-range saved launcher filters recover without dropdown assertions',
    (t) async {
      final store = await notebook();
      await store.saveSession('s00-e03', {
        'model': 'learning-tools-8.0',
        'studio': 999,
        'apparatus': 'Missing apparatus',
        'stage': 'Unsupported',
      });
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      router.go('/lab/s00-e03');
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      router.go('/');
      await t.pumpAndSettle();
      expect(
        (await store.savedSessionIds()).where(
          (k) => k.startsWith('backup:s00-e03:'),
        ),
        isNotEmpty,
      );
    },
  );
  testWidgets(
    'Measurement timer stops on a pushed route and old trials cannot complete a new activity',
    (t) async {
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      router.go('/lab/s01-e04');
      await t.pumpAndSettle();
      final dynamic w = t.state(find.byType(Workspace));
      w.experiment.start();
      await t.pump(const Duration(milliseconds: 100));
      router.push('/lab/s06-e03');
      await t.pumpAndSettle();
      expect(w.experiment.running, false);
      final elapsed = w.experiment.elapsed;
      await t.pump(const Duration(seconds: 2));
      expect(w.experiment.elapsed, elapsed);
      router.pop();
      await t.pumpAndSettle();
      expect(w.completionReady, false);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Rejected earlier-model session is backed up with its exact configuration',
    (t) async {
      final store = await notebook();
      final old = {
        'model': 'future-model',
        'notes': 'Keep original text',
        'parameters': {'m': 123},
      };
      await store.saveSession('s07-e00', old);
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      router.go('/lab/s07-e00');
      await t.pumpAndSettle();
      router.go('/');
      await t.pumpAndSettle();
      final keys = (await store.savedSessionIds()).where(
        (k) => k.startsWith('backup:s07-e00:'),
      );
      expect(keys, hasLength(1));
      expect(
        jsonEncode((await store.readSession(keys.single))!['original']),
        jsonEncode(old),
      );
    },
  );
}
