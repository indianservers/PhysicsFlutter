import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';
import 'package:physics_atelier/features/fluid_modern/scene.dart';
import 'package:physics_atelier/features/fluid_modern/workspace.dart';
import 'package:physics_atelier/features/fluid_modern/curriculum.dart';

import 'app_test.dart' show notebook;
import 'em_app_test.dart' show edit, top;
import 'waves_app_test.dart' show show;

FMPainter fmScene(WidgetTester t) => t
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((w) => w.painter)
    .whereType<FMPainter>()
    .first;
Future<void> fmMode(WidgetTester t, int m) async {
  await top(t);
  final field = find.byType(DropdownButtonFormField<int>);
  await show(t, field);
  t.widget<DropdownButtonFormField<int>>(field).onChanged!(m);
  await t.pumpAndSettle();
  await top(t);
}

Future<void> fmBoot(WidgetTester t, LocalNotebook store, String id) async {
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
    'Buoyancy drag changes object density; completion requires real activity',
    (t) async {
      final store = await notebook();
      await fmBoot(t, store, 's14-e02');
      final dynamic workspace = t.state(find.byType(FMWorkspace));
      final fluid = workspace.parameters['density'],
          body = workspace.parameters['objectDensity'];
      workspace.dragApparatus(
        DragUpdateDetails(
          globalPosition: Offset.zero,
          delta: const Offset(10, 0),
        ),
        360.0,
      );
      await t.pumpAndSettle();
      expect(workspace.parameters['density'], fluid);
      expect(workspace.parameters['objectDensity'], greaterThan(body));
      expect(workspace.eligible, false);
      expect(store.completed, isEmpty);
      workspace.notes.text = 'Static uniform block; capillarity and settling dynamics are omitted.';
      await workspace.submit(workspace.result);
      expect(workspace.eligible, false);
      await workspace.record();
      await t.pumpAndSettle();
      expect(
        store.trials.last.configuration['stateUnits']['buoyantForce'],
        'N',
      );
      expect(store.trials.last.configuration['profileAxis']['unit'], 'm');
      expect(workspace.eligible, true);
      await t.tap(find.text('Learn').last);
      await t.pumpAndSettle();
      await show(t, find.text('Complete investigation'));
      await t.tap(find.text('Complete investigation'));
      await t.pumpAndSettle();
      expect(store.completed, contains('s14-e02'));
      workspace.update('objectDensity', 2000.0);
      await t.pumpAndSettle();
      expect(workspace.eligible, false);
      router.go('/');
      await t.pumpAndSettle();
    },
  );

  testWidgets(
    'All 12 Phase 7 labs, every section/model, 160% text and landscape',
    (t) async {
      t.view.physicalSize = const Size(640, 1136);
      t.view.devicePixelRatio = 2;
      t.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final store = await notebook();
      await fmBoot(t, store, 's14-e00');
      expect(allEntries.length, 102);
      expect(allEntries.where((e) => e.interactive).length, 96);
      for (final e in allEntries.where((e) => e.fluidModern)) {
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
          for (int i = 0; i < 90; i++) {
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
        final k = (e.studioIndex - 14) * 6 + e.index;
        for (int m = 0; m < fmModes[k].length; m++) {
          await fmMode(t, m);
          expect(fmScene(t).run.invalid, isEmpty, reason: '${e.id}:$m');
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
  testWidgets(
    'Seeded histogram trial and saved replay reproduce actual events',
    (t) async {
      final store = await notebook();
      await fmBoot(t, store, 's15-e00');
      await edit(t, 'seed', '741');
      await show(t, find.byKey(const Key('sample-batch')));
      await t.tap(find.byKey(const Key('sample-batch')));
      await t.pumpAndSettle();
      await top(t);
      final counts = List.of(fmScene(t).run.histogram),
          positions = List.of(fmScene(t).run.positions);
      expect(fmScene(t).run.measurementCount, 100);
      await show(t, find.byKey(const Key('record-trial')));
      await t.tap(find.byKey(const Key('record-trial')));
      await t.pumpAndSettle();
      expect(store.trials.last.configuration['seed'], 741);
      expect(store.trials.last.configuration['histogram'], counts);
      expect(store.trials.last.configuration['units']['wellWidth'], 'm');
      await edit(t, 'seed', '123');
      await t.tap(find.text('Results').last);
      await t.pumpAndSettle();
      await show(t, find.text('Reopen configuration'));
      await t.tap(find.text('Reopen configuration'));
      await t.pumpAndSettle();
      await top(t);
      expect(fmScene(t).run.histogram, counts);
      expect(fmScene(t).run.positions, positions);
      expect(
        (t.state(find.byType(FMWorkspace)) as dynamic).ticker.isActive,
        false,
      );
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets('Invalid Reynolds and geometry states suppress recording', (
    t,
  ) async {
    final store = await notebook();
    await fmBoot(t, store, 's14-e05');
    await edit(t, 'radius', '.001');
    await edit(t, 'viscosity', '.001');
    expect(fmScene(t).run.invalid, contains('Re'));
    await show(t, find.byKey(const Key('record-trial')));
    expect(
      t.widget<FilledButton>(find.byKey(const Key('record-trial'))).onPressed,
      isNull,
    );
    router.go('/lab/s14-e01');
    await t.pumpAndSettle();
    await t.tap(find.text('Experiment').last);
    await t.pumpAndSettle();
    await fmMode(t, 1);
    await edit(t, 'density', '600');
    expect(fmScene(t).run.invalid, contains('density below'));
    router.go('/');
    await t.pumpAndSettle();
  });
  testWidgets(
    'Background and hidden views stop the clock; reduced motion retains real state',
    (t) async {
      final store = await notebook();
      store.reducedMotion = true;
      await fmBoot(t, store, 's14-e03');
      final dynamic workspace = t.state(find.byType(FMWorkspace));
      workspace.play();
      await t.pump();
      await t.pump(const Duration(milliseconds: 80));
      final time = fmScene(t).run.time;
      expect(time, greaterThan(0));
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(fmScene(t).run.time, time);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      expect(workspace.ticker.isActive, false);
      expect(fmScene(t).motion, false);
      await t.tap(find.text('Learn').last);
      await t.pumpAndSettle();
      expect(workspace.ticker.isActive, false);
      expect(store.completed, isEmpty);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets('Every graph channel has correct units and real histogram bars', (
    t,
  ) async {
    final store = await notebook();
    await fmBoot(t, store, 's15-e02');
    await show(t, find.byKey(const Key('sample-batch')));
    await t.tap(find.byKey(const Key('sample-batch')));
    await t.pumpAndSettle();
    await t.tap(find.text('Visualize').last);
    await t.pumpAndSettle();
    final dynamic workspace = t.state(find.byType(FMWorkspace));
    for (final option in workspace.graphOptions as List<String>) {
      final field = find.byType(DropdownButtonFormField<String>);
      await show(t, field);
      t.widget<DropdownButtonFormField<String>>(field).onChanged!(option);
      await t.pumpAndSettle();
      expect(workspace.plot.data, isNotEmpty);
      if (option == 'Detections histogram') {
        expect(workspace.plot.bars, contains('observedDensity'));
      }
      expect(workspace.plot.unit, 'm⁻¹');
      expect(t.takeException(), isNull);
    }
    router.go('/');
    await t.pumpAndSettle();
  });
}
