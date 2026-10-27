import 'ui_navigation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/features/workbench/workbench.dart';

import 'app_test.dart' show notebook;
import 'waves_app_test.dart' as controls;

void main() {
  testWidgets(
    'Every physical lab opens its active instrument without an article and fits portrait',
    (t) async {
      t.view.physicalSize = const Size(720, 1280);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      for (final e in allEntries.where((e) => e.interactive)) {
        router.go('/lab/${e.id}');
        await t.pumpAndSettle();
        expect(find.byType(InstrumentShell), findsOneWidget, reason: e.id);
        expect(
          find.byKey(const Key('workspace-camera')),
          findsOneWidget,
          reason: e.id,
        );
        expect(
          find.byKey(const Key('record-trial')),
          findsOneWidget,
          reason: e.id,
        );
        expect(find.text('Learning objectives'), findsNothing, reason: e.id);
        expect(t.takeException(), isNull, reason: e.id);
      }
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Pane changes resizing zoom and controls keep one science session',
    (t) async {
      t.view.physicalSize = const Size(720, 1280);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      router.go('/lab/s03-e03');
      await t.pumpAndSettle();
      expect(find.byType(InstrumentShell), findsOneWidget);
      await tapViewportTool(t, 'Zoom in');
      await t.pumpAndSettle();
      Transform camera() => t.widget<Transform>(
        find
            .descendant(
              of: find.byKey(const Key('workspace-camera')),
              matching: find.byType(Transform),
            )
            .first,
      );
      expect(camera().transform.getMaxScaleOnAxis(), greaterThan(1));
      await tapViewportTool(t, 'Fit apparatus / reset view');
      await t.pumpAndSettle();
      expect(camera().transform.getMaxScaleOnAxis(), 1);
      await tapViewportTool(t, 'Workspace panes');
      await t.pumpAndSettle();
      await t.tap(find.text('Scene + Graph').last);
      await t.pumpAndSettle();
      expect(find.byKey(const Key('pane-divider')), findsOneWidget);
      expect(
        t.getSize(find.byKey(const Key('pane-divider'))).height,
        24,
        reason: 'Portrait panes stack vertically',
      );
      await t.drag(find.byKey(const Key('pane-divider')), const Offset(0, 25));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await chooseSection(t, 'Learn');
      await t.pumpAndSettle();
      expect(find.byType(InstrumentShell), findsNothing);
      await chooseSection(t, 'Experiment');
      await t.pumpAndSettle();
      expect(find.byType(InstrumentShell), findsOneWidget);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'All six overview tools use compact working layouts and accessible map lists',
    (t) async {
      t.view.physicalSize = const Size(720, 1280);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      for (final e in allEntries.where((e) => e.tool)) {
        router.go('/lab/${e.id}');
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: e.id);
      }
      router.go('/lab/s00-e00');
      await t.pumpAndSettle();
      if (find.text('List').evaluate().isNotEmpty) {
        await t.tap(find.text('List').last);
      }
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'All working destinations fit 200 percent text in small portrait and landscape',
    (t) async {
      t.view.physicalSize = const Size(640, 1136);
      t.view.devicePixelRatio = 2;
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final store = await notebook();
      store.reducedMotion = true;
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      for (final e in allEntries) {
        router.go('/lab/${e.id}');
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: '${e.id} portrait 200%');
        t.view.physicalSize = const Size(1136, 640);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: '${e.id} landscape 200%');
        t.view.physicalSize = const Size(640, 1136);
        await t.pumpAndSettle();
      }
      router.go('/');
      await t.pumpAndSettle();
    },
  );

  testWidgets(
    'Camera gestures and pane changes preserve paused science across every workspace family',
    (t) async {
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      for (final id in [
        's01-e01',
        's02-e00',
        's07-e00',
        's09-e00',
        's10-e04',
        's12-e00',
        's14-e00',
        's16-e00',
      ]) {
        router.go('/lab/$id');
        await t.pumpAndSettle();
        final shell = t.widget<InstrumentShell>(find.byType(InstrumentShell));
        final signature = shell.controls().map((c) => c.value).toList();
        final readings = shell.readings().map((r) => r.value).toList();
        final changes = shell.changes;
        await tapViewportTool(t, 'Pan / zoom camera');
        await t.pumpAndSettle();
        await tapViewportTool(t, 'Zoom in');
        await t.pumpAndSettle();
        await t.drag(
          find.byKey(const Key('workspace-camera')),
          const Offset(30, 15),
        );
        await t.pumpAndSettle();
        await tapViewportTool(t, 'Fit apparatus / reset view');
        await t.pumpAndSettle();
        final after = t.widget<InstrumentShell>(find.byType(InstrumentShell));
        expect(
          after.controls().map((c) => c.value).toList(),
          signature,
          reason: id,
        );
        expect(
          after.readings().map((r) => r.value).toList(),
          readings,
          reason: id,
        );
        expect(after.changes, same(changes), reason: id);
        expect(t.takeException(), isNull, reason: id);
      }
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Precise input and observation notes remain usable with a portrait keyboard',
    (t) async {
      t.view.physicalSize = const Size(720, 1280);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetViewInsets);
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      router.go('/lab/s02-e00');
      await t.pumpAndSettle();
      final c = t
          .widget<InstrumentShell>(find.byType(InstrumentShell))
          .controls()
          .first;
      await t.ensureVisible(find.byKey(ValueKey('dock-edit-${c.keyName}')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(ValueKey('dock-edit-${c.keyName}')));
      await t.pumpAndSettle();
      t.view.viewInsets = const FakeViewPadding(bottom: 600);
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).last, '2');
      await t.tap(find.text('Apply'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      t.view.resetViewInsets();
      await t.pumpAndSettle();
      final note = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Observation notes',
      );
      await controls.show(t, note);
      await t.tap(note);
      t.view.viewInsets = const FakeViewPadding(bottom: 600);
      await t.pumpAndSettle();
      await t.ensureVisible(note);
      await t.pumpAndSettle();
      await t.enterText(
        note,
        'Keyboard observation retained in the actual session.',
      );
      await t.pumpAndSettle();
      expect(t.getRect(note).top, lessThan(340));
      expect(t.takeException(), isNull);
      t.view.resetViewInsets();
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Close controls'));
      await t.pumpAndSettle();
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Guided steps require changed science and a matching actual record and preserve the final step',
    (t) async {
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      router.go('/lab/s01-e01');
      await t.pumpAndSettle();
      Future<void> guide() async {
        await tapViewportTool(t, 'Workspace panes');
        await t.pumpAndSettle();
        await t.tap(find.text('Guided investigation'));
        await t.pumpAndSettle();
      }

      Finder next() => find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Next guided step',
      );
      await guide();
      expect(t.widget<IconButton>(next()).onPressed, isNull);
      final control = t
          .widget<InstrumentShell>(find.byType(InstrumentShell))
          .controls()
          .first;
      control.change(
        (control.value + (control.max - control.min) * .05).clamp(
          control.min,
          control.max,
        ),
      );
      await t.pumpAndSettle();
      await t.tap(next());
      await t.pumpAndSettle();
      await t.tap(next());
      await t.pumpAndSettle();
      expect(t.widget<IconButton>(next()).onPressed, isNull);
      await t.widget<InstrumentShell>(find.byType(InstrumentShell)).record();
      await t.pumpAndSettle();
      await t.tap(next());
      await t.pumpAndSettle();
      expect(store.preferences.getInt('workspaceGuide:s01-e01'), 3);
      expect(store.completed, isEmpty);
      router.go('/');
      await t.pumpAndSettle();
      router.go('/lab/s01-e01');
      await t.pumpAndSettle();
      await guide();
      expect(find.textContaining('4/4'), findsOneWidget);
      expect(t.takeException(), isNull);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
}
