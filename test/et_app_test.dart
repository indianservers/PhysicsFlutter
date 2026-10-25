import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';
import 'package:physics_atelier/features/electronics_thermal/scene.dart';
import 'package:physics_atelier/features/electronics_thermal/workspace.dart';
import 'package:physics_atelier/features/electronics_thermal/curriculum.dart';

import 'app_test.dart' show notebook;
import 'em_app_test.dart' show edit, top;
import 'waves_app_test.dart' show show;

ETPainter etScene(WidgetTester t) => t
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((w) => w.painter)
    .whereType<ETPainter>()
    .first;
Future<void> etMode(WidgetTester t, int m) async {
  await top(t);
  final f = find.byType(DropdownButtonFormField<int>);
  await show(t, f);
  t.widget<DropdownButtonFormField<int>>(f).onChanged!(m);
  await t.pumpAndSettle();
  await top(t);
}

Future<void> etBoot(WidgetTester t, LocalNotebook store, String id) async {
  await t.pumpWidget(
    ProviderScope(
      overrides: [notebookProvider.overrideWithValue(store)],
      child: const PhysicsApp(),
    ),
  );
  router.go('/lab/$id');
  await t.pumpAndSettle();
  await t.tap(find.text('Experiment').last);
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
    'All 12 labs and five views at large text, narrow portrait and landscape',
    (t) async {
      t.view.physicalSize = const Size(640, 1136);
      t.view.devicePixelRatio = 2;
      t.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final store = await notebook();
      await etBoot(t, store, 's12-e00');
      expect(allEntries.length, 102);
      expect(allEntries.where((e) => e.interactive).length, 90);
      for (final e in allEntries.where((e) => e.electronicsThermal)) {
        router.go('/lab/${e.id}');
        await t.pumpAndSettle();
        for (final tab in [
          'Learn',
          'Experiment',
          'Visualize',
          'Formulas',
          'Results',
        ]) {
          await t.tap(find.text(tab).last);
          await t.pumpAndSettle();
          for (int i = 0; i < 70; i++) {
            final p = t
                .state<ScrollableState>(find.byType(Scrollable).first)
                .position;
            if (p.pixels >= p.maxScrollExtent) break;
            p.jumpTo((p.pixels + 350).clamp(0, p.maxScrollExtent));
            await t.pump();
          }
          expect(t.takeException(), isNull, reason: '${e.id}:$tab');
        }
        await t.tap(find.text('Experiment').last);
        await t.pumpAndSettle();
        for (
          int m = 0;
          m < etModes[(e.studioIndex - 12) * 6 + e.index].length;
          m++
        ) {
          await etMode(t, m);
          expect(etScene(t).run.invalid, isEmpty, reason: '${e.id}:$m');
        }
        t.view.physicalSize = const Size(1136, 640);
        await t.pumpAndSettle();
        await top(t);
        expect(t.takeException(), isNull);
        t.view.physicalSize = const Size(640, 1136);
        await t.pumpAndSettle();
      }
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets('Actual trial save reopen and correct sensor units', (t) async {
    final store = await notebook();
    await etBoot(t, store, 's12-e05');
    await etMode(t, 2);
    await edit(t, 'distance', '2');
    final value = etScene(t).run.state['sensorOutput'];
    await show(t, find.byKey(const Key('record-trial')));
    await t.tap(find.byKey(const Key('record-trial')));
    await t.pumpAndSettle();
    expect(store.trials.last.unit, 's');
    expect(store.trials.last.configuration['units']['distance'], 'm');
    expect(store.trials.last.configuration['units']['sensorOutput'], 's');
    expect(store.trials.last.value, value);
    await edit(t, 'distance', '3');
    await t.tap(find.text('Results').last);
    await t.pumpAndSettle();
    await show(t, find.text('Reopen configuration'));
    await t.tap(find.text('Reopen configuration'));
    await t.pumpAndSettle();
    await top(t);
    expect(etScene(t).run.p['distance'], 2);
    expect(etScene(t).run.state['sensorOutput'], value);
    router.go('/');
    await t.pumpAndSettle();
  });
  testWidgets('Invalid sensor and invalid Biot suppress recording', (t) async {
    final store = await notebook();
    await etBoot(t, store, 's12-e05');
    await edit(t, 'temperature', '220');
    expect(etScene(t).run.invalid, contains('TMP36'));
    await show(t, find.byKey(const Key('record-trial')));
    expect(
      t.widget<FilledButton>(find.byKey(const Key('record-trial'))).onPressed,
      isNull,
    );
    router.go('/lab/s13-e01');
    await t.pumpAndSettle();
    await t.tap(find.text('Experiment').last);
    await t.pumpAndSettle();
    await etMode(t, 1);
    await edit(t, 'conductivity', '.1');
    expect(etScene(t).run.invalid, contains('Bi'));
    router.go('/');
    await t.pumpAndSettle();
  });
  testWidgets(
    'Background pauses physical clock and completion requires activity',
    (t) async {
      final store = await notebook();
      await etBoot(t, store, 's13-e05');
      final dynamic workspace = t.state(find.byType(ETWorkspace));
      workspace.play();
      await t.pump();
      await t.pump(const Duration(milliseconds: 80));
      final time = etScene(t).run.time;
      expect(time, greaterThan(0));
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(etScene(t).run.time, time);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      expect(workspace.ticker.isActive, false);
      await show(t, find.text('Complete investigation'));
      expect(
        t
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Complete investigation'),
            )
            .onPressed,
        isNull,
      );
      await edit(t, 'hotT', '610');
      workspace.notes.text = 'Compared reservoir temperatures; ideal reversible engine assumption.';
      await workspace.submit(etScene(t).run.state['efficiency']!);
      await workspace.record();
      await t.pumpAndSettle();
      await show(t, find.text('Complete investigation'));
      await t.tap(find.text('Complete investigation'));
      await t.pumpAndSettle();
      expect(store.completed, contains('s13-e05'));
      router.go('/');
      await t.pumpAndSettle();
    },
  );
}
