import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/features/electronics_thermal/curriculum.dart';
import 'package:physics_atelier/features/electronics_thermal/workspace.dart';

import '../test/et_app_test.dart' show etScene, etMode;
import '../test/em_app_test.dart' show top, edit;
import 'phase1_test.dart' show show, capture;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Phase 6 all labs modes persistence actual CSV and lifecycle', (
    t,
  ) async {
    await app.main();
    await t.pumpAndSettle();
    final store = ProviderScope.containerOf(t.element(find.byType(PhysicsApp)))
        .read(notebookProvider);
    final originalTrials = store.trials.map((x) => x.toJson()).toList(),
        checks = <String, dynamic>{};
    for (final e in allEntries.where((e) => e.electronicsThermal)) {
      router.go('/lab/${e.id}');
      await t.pumpAndSettle();
      await t.tap(find.text('Experiment').last);
      await t.pumpAndSettle();
      await show(t, find.text('Restore defaults'));
      await t.tap(find.text('Restore defaults'));
      await t.pumpAndSettle();
      await top(t);
      final kind = (e.studioIndex - 12) * 6 + e.index;
      for (int m = 0; m < etModes[kind].length; m++) {
        await etMode(t, m);
        expect(etScene(t).run.invalid, isEmpty);
        final controls = etControls(kind, m);
        await edit(t, controls.first.key, '${controls.first.initial}');
        if (etScene(t).run.dynamicLab) {
          for (int i = 0; i < 120; i++) {
            etScene(t).run.step();
          }
          etScene(t).run.refresh();
        }
        expect(etScene(t).run.invalid, isEmpty);
        checks['${e.id}:$m'] = Map.of(etScene(t).run.state);
      }
      await etMode(t, 0);
      if (etScene(t).run.dynamicLab) {
        for (int i = 0; i < 300; i++) {
          etScene(t).run.step();
        }
        etScene(t).run.refresh();
      }
      (t.state(find.byType(ETWorkspace)) as dynamic).tick.value++;
      await t.pumpAndSettle();
      await top(t);
      await capture(t, binding, 'phase6-${e.id}');
      final reading = etScene(t).run.state[etLessons[kind].metric];
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
      expect(etScene(t).run.state[etLessons[kind].metric], reading);
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
    binding.reportData!['phase6Validation'] = {
      'modes': checks,
      'newTrials': store.trials.length - originalTrials.length,
      'originalTrialsPreserved': originalTrials.length,
    };
    binding.reportData!['csv'] = csvEncode(
      store.trials.where((x) => x.model == 'electronics-thermal-6.0').toList(),
    );
    binding.reportData!['csvFile'] = 'phase6-verified-results.csv';
    router.go('/');
    await t.pumpAndSettle();
  });
}
