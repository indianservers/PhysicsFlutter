import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/features/electromagnetism/scene.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';

import 'app_test.dart' show notebook;
import 'waves_app_test.dart' show show;

Future<void> top(WidgetTester t) async {
  t.state<ScrollableState>(find.byType(Scrollable).first).position.jumpTo(0);
  await t.pumpAndSettle();
}

EMPainter scene(WidgetTester t) => t
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((w) => w.painter)
    .whereType<EMPainter>()
    .first;
Future<void> edit(WidgetTester t, String key, String value) async {
  await show(t, find.byKey(Key('edit-$key')));
  await t.tap(find.byKey(Key('edit-$key')));
  await t.pumpAndSettle();
  await t.enterText(find.byType(TextField).last, value);
  await t.tap(find.text('Apply'));
  FocusManager.instance.primaryFocus?.unfocus();
  await t.pumpAndSettle();
  await top(t);
}

Future<void> boot(WidgetTester t, LocalNotebook store, String id) async {
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

Future<void> mode(WidgetTester t, int value) async {
  await show(t, find.byKey(const Key('em-model')));
  t
      .widget<DropdownButtonFormField<int>>(find.byKey(const Key('em-model')))
      .onChanged!(value);
  await t.pumpAndSettle();
  await top(t);
}

void main() {
  testWidgets(
    'Twelve EM labs five sections, all lower controls at 160% text and landscape',
    (t) async {
      t.view.physicalSize = const Size(640, 1136);
      t.view.devicePixelRatio = 2;
      t.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      expect(allEntries.where((e) => e.interactive).length, 90);
      for (final e in allEntries.where((e) => e.electromagnetism)) {
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
            await t.pumpAndSettle();
          }
          expect(t.takeException(), null, reason: '${e.id} $tab');
        }
      }
      t.view.physicalSize = const Size(1280, 720);
      for (final id in ['s10-e01', 's10-e04', 's11-e01']) {
        router.go('/lab/$id');
        await t.pumpAndSettle();
        await t.tap(find.text('Experiment').last);
        await t.pumpAndSettle();
        expect(t.takeException(), null);
      }
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Real numeric input, prediction, record notes, reopened inputs and paused lifecycle',
    (t) async {
      final store = await notebook();
      await boot(t, store, 's10-e03');
      await edit(t, 'voltage', '9');
      await show(t, find.byKey(const Key('step-em')));
      await t.tap(find.byKey(const Key('step-em')));
      await t.pumpAndSettle();
      await top(t);
      expect(scene(t).run.state['current'], closeTo(.6, 1e-12));
      expect(scene(t).run.state['charge']!, greaterThan(0));
      await show(t, find.byKey(const Key('predict-em')));
      await t.tap(find.byKey(const Key('predict-em')));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).last, '.6');
      await t.tap(find.text('Apply'));
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      await show(t, find.byKey(const Key('record-em')));
      await t.enterText(find.byType(TextField).last, 'EM test actual .6 A');
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('record-em')));
      await t.pumpAndSettle();
      expect(store.trials.last.value, closeTo(.6, 1e-12));
      expect(store.trials.last.note, 'EM test actual .6 A');
      ScaffoldMessenger.of(t.element(find.byType(Scaffold).last))
          .clearSnackBars();
      await t.pumpAndSettle();
      await t.tap(find.text('Results').last);
      await t.pumpAndSettle();
      await show(t, find.text('Reopen configuration'));
      await t.tap(find.text('Reopen configuration').first);
      await t.pumpAndSettle();
      await top(t);
      expect(scene(t).run.p['voltage'], 9);
      await show(t, find.byKey(const Key('play-em')));
      await t.tap(find.byKey(const Key('play-em')));
      await t.pump(const Duration(milliseconds: 80));
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pumpAndSettle();
      expect(find.text('Play'), findsOneWidget);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Circuit examples, real editing/movement/wiring and invalid meters',
    (t) async {
      final store = await notebook();
      await boot(t, store, 's10-e04');
      await top(t);
      expect(scene(t).run.state['current'], closeTo(.2, 1e-12));
      await show(t, find.byKey(const Key('example-1')));
      await t.tap(find.byKey(const Key('example-1')));
      await t.pumpAndSettle();
      await top(t);
      expect(scene(t).run.state['current'], closeTo(.9, 1e-12));
      final oldSolution = scene(t).run.network;
      await show(t, find.byKey(const Key('layout-x')));
      t.widget<Slider>(find.byKey(const Key('layout-x'))).onChanged!(.7);
      await t.pumpAndSettle();
      await top(t);
      expect(scene(t).run.circuit.parts.firstWhere((p) => p.id == 'R1').x, .7);
      expect(identical(scene(t).run.network, oldSolution), true);
      await show(t, find.byKey(const Key('edit-component')));
      await t.tap(find.byKey(const Key('edit-component')));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).last, '20');
      await t.tap(find.text('Apply'));
      await t.pumpAndSettle();
      await top(t);
      expect(scene(t).run.state['current'], closeTo(.6, 1e-12));
      await show(t, find.byKey(const Key('add-part')));
      await t.tap(find.byKey(const Key('add-part')));
      await t.pumpAndSettle();
      await top(t);
      expect(scene(t).run.invalid, contains('Floating'));
      expect(scene(t).run.network!.currents, isEmpty);
      Future<void> wire(String a, String b) async {
        await show(t, find.text('Connect these terminals'));
        final dropdowns = t
            .widgetList<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>),
            )
            .where(
              (w) =>
                  w.decoration.labelText == 'Wire from terminal' ||
                  w.decoration.labelText == 'Wire to terminal',
            )
            .toList();
        expect(dropdowns.length, 2);
        dropdowns[0].onChanged!(a);
        await t.pumpAndSettle();
        final to = t
            .widgetList<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>),
            )
            .firstWhere((w) => w.decoration.labelText == 'Wire to terminal');
        to.onChanged!(b);
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('connect-terminals')));
        await t.pumpAndSettle();
      }

      await wire('C1:a', 'B1:a');
      await wire('C1:b', 'B1:b');
      await top(t);
      expect(scene(t).run.invalid, isEmpty);
      expect(scene(t).run.state['current'], closeTo(1, 1e-12));
      await show(t, find.byKey(const Key('record-em')));
      await t.tap(find.byKey(const Key('record-em')));
      await t.pumpAndSettle();
      expect(
        (store.trials.last.configuration['circuit']['wires'] as List).length,
        11,
      );
      ScaffoldMessenger.of(t.element(find.byType(Scaffold).last))
          .clearSnackBars();
      await t.pumpAndSettle();
      await show(t, find.byKey(const Key('delete-wire-10')));
      await t.tap(find.byKey(const Key('delete-wire-10')));
      await t.pumpAndSettle();
      await top(t);
      expect(scene(t).run.invalid, isEmpty);
      expect(scene(t).run.state['current'], closeTo(.6, 1e-12));
      await show(t, find.byKey(const Key('delete-wire-9')));
      await t.tap(find.byKey(const Key('delete-wire-9')));
      await t.pumpAndSettle();
      await top(t);
      expect(scene(t).run.invalid, contains('Floating'));
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Isolated capacitor charge held and RC switching preserves voltage',
    (t) async {
      final store = await notebook();
      await boot(t, store, 's10-e05');
      await top(t);
      final initialQ = scene(t).run.state['charge'];
      await mode(t, 1);
      await edit(t, 'area', '.01');
      expect(scene(t).run.state['charge'], initialQ);
      expect(scene(t).run.state['voltage'], closeTo(3, 1e-12));
      await mode(t, 2);
      await show(t, find.byKey(const Key('replay-em')));
      await t.tap(find.byKey(const Key('replay-em')));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).last, '.75');
      await t.tap(find.text('Apply'));
      await t.pumpAndSettle();
      await top(t);
      final vc = scene(t).run.state['voltage']!;
      expect(vc, greaterThan(0));
      await mode(t, 3);
      expect(scene(t).run.time, 0);
      expect(scene(t).run.state['voltage'], vc);
      expect(scene(t).run.state['current']!, lessThan(0));
      router.go('/');
      await t.pumpAndSettle();
    },
  );
}
