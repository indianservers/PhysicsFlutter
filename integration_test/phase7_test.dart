import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/features/fluid_modern/curriculum.dart';
import 'package:physics_atelier/features/fluid_modern/workspace.dart';

import '../test/fm_app_test.dart' show fmScene, fmMode;
import '../test/em_app_test.dart' show top, edit;
import 'phase1_test.dart' show show, capture;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Phase 7 all labs modes persistence actual CSV and lifecycle', (
    t,
  ) async {
    await app.main();
    await t.pumpAndSettle();
    final store = ProviderScope.containerOf(t.element(find.byType(PhysicsApp)))
        .read(notebookProvider);
    final originalTrials = store.trials.map((x) => x.toJson()).toList(),
        checks = <String, dynamic>{};
    for (final e in allEntries.where((e) => e.fluidModern)) {
      router.go('/lab/${e.id}');
      await t.pumpAndSettle();
      await t.tap(find.text('Experiment').last);
      await t.pumpAndSettle();
      await show(t, find.text('Restore defaults'));
      await t.tap(find.text('Restore defaults'));
      await t.pumpAndSettle();
      await top(t);
      final kind = (e.studioIndex - 14) * 6 + e.index;
      for (int m = 0; m < fmModes[kind].length; m++) {
        await fmMode(t, m);
        expect(fmScene(t).run.invalid, isEmpty);
        final controls = fmControls(kind, m);
        final c = controls.first;
        final next = ['n', 'upper', 'seed', 'initialN'].contains(c.key)
            ? c.initial + 1
            : c.initial + (c.max - c.min) * .005;
        await edit(t, c.key, '${next.clamp(c.min, c.max)}');
        if (fmScene(t).run.dynamicLab) {
          for (int i = 0; i < 120; i++) {
            fmScene(t).run.step();
          }
          fmScene(t).run.refresh();
        }
        expect(fmScene(t).run.invalid, isEmpty);
        checks['${e.id}:$m'] = Map.of(fmScene(t).run.state);
      }
      await fmMode(t, 0);
      if (fmScene(t).run.dynamicLab) {
        for (int i = 0; i < 300; i++) {
          fmScene(t).run.step();
        }
        fmScene(t).run.refresh();
      }
      (t.state(find.byType(FMWorkspace)) as dynamic).tick.value++;
      await t.pumpAndSettle();
      await top(t);
      await capture(t, binding, 'phase7-${e.id}');
      final reading = fmScene(t).run.state[fmLessons[kind].metric];
      await show(t, find.byKey(const Key('record-trial')));
      await t.tap(find.byKey(const Key('record-trial')));
      await t.pumpAndSettle();
      expect(store.trials.last.value, reading);
      await t.tap(find.byTooltip('Save session'));
      await t.pumpAndSettle();
      router.go('/');
      await t.pumpAndSettle();
      router.go('/lab/${e.id}');
      await t.pumpAndSettle();
      await t.tap(find.text('Experiment').last);
      await t.pumpAndSettle();
      await top(t);
      expect(fmScene(t).run.state[fmLessons[kind].metric], reading);
      for (final tab in ['Visualize', 'Formulas', 'Results', 'Learn']) {
        await t.tap(find.text(tab).last);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      }
    }
    for (final old in originalTrials) {
      expect(store.trials.firstWhere((x) => x.id == old['id']).toJson(), old);
    }
    binding.reportData ??= {};
    binding.reportData!['phase7Validation'] = {
      'modes': checks,
      'newTrials': store.trials.length - originalTrials.length,
      'originalTrialsPreserved': originalTrials.length,
    };
    binding.reportData!['csv'] = csvEncode(
      store.trials.where((x) => x.model == 'fluid-modern-7.0').toList(),
    );
    binding.reportData!['csvFile'] = 'phase7-verified-results.csv';
    router.go('/');
    await t.pumpAndSettle();
  });
}
