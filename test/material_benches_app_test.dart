import 'ui_navigation.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/core/physics/thermal_library.dart';
import 'package:physics_atelier/features/lab_workspace/workspace.dart';
import 'package:physics_atelier/features/material_bench/workspace.dart';
import 'package:physics_atelier/features/workbench/workbench.dart';

import 'app_test.dart' show notebook;

import 'package:physics_atelier/core/persistence/notebook.dart';

void main() {
  testWidgets(
    'New graph, split and full-screen panes have bounded layout and preserve scientific state',
    (t) async {
      final store = await notebook();
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetPhysicalSize);
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      for (final size in [const Size(320, 568), const Size(740, 360)]) {
        t.view.physicalSize = size;
        for (final id in ['s13-e01', 's09-e01']) {
          router.go('/lab/$id/bench');
          await t.pumpAndSettle();
          final bench = t.state<MaterialBenchState>(
            find.byType(MaterialBenchWorkspace),
          );
          final before = jsonEncode(bench.configuration());
          final dynamic shell = t.state(find.byType(InstrumentShell));
          for (final pane in WorkspacePane.values) {
            shell.choose(pane);
            await t.pumpAndSettle();
            expect(t.takeException(), isNull, reason: '$id / $pane / $size');
            expect(jsonEncode(bench.configuration()), before);
          }
        }
      }
      router.go('/');
      await t.pumpAndSettle();
    },
  );

  testWidgets(
    'Spherometer real controls, reference subtraction, camera invariance, record/reset and reopen',
    (t) async {
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      router.go('/lab/s01-e03');
      await t.pumpAndSettle();
      final dynamic state = t.state(find.byType(Workspace));
      final e = state.experiment;
      expect(find.byType(NavigationBar), findsNothing);
      expect(
        find.byKey(const Key('sphero-numeric')).hitTestable(),
        findsOneWidget,
      );
      await t.tap(find.byKey(const Key('sphero-numeric')));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), '-3');
      await t.tap(find.text('Apply'));
      await t.pumpAndSettle();
      expect(e.a, 0);
      await t.tap(find.byKey(const Key('record-trial')));
      await t.pumpAndSettle();
      expect(e.spherometer.reference, 0);
      expect(store.trials.length, 1);
      t
          .widget<DropdownButtonFormField<int>>(
            find.byType(DropdownButtonFormField<int>),
          )
          .onChanged!(1);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('sphero-numeric')));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), '-3');
      await t.tap(find.text('Apply'));
      await t.pumpAndSettle();
      expect(e.a, closeTo(.00044, 1e-12));
      await t.tap(find.byKey(const Key('record-trial')));
      await t.pumpAndSettle();
      expect(e.spherometer.measuredH, closeTo(.00044, 1e-12));
      expect(store.trials.length, 2);
      final recorded = store.trials.last;
      expect(recorded.quantity, 'radius');
      final before = e.toJson();
      await tapViewportTool(t, 'Pan / zoom camera');
      await t.pumpAndSettle();
      await t.drag(
        find.byKey(const Key('workspace-camera')),
        const Offset(20, 10),
      );
      await t.pumpAndSettle();
      expect(e.toJson(), before);
      await tapViewportTool(t, 'Fit apparatus / reset view');
      await tapViewportTool(t, 'Manipulate apparatus');
      await t.pumpAndSettle();
      await t.tap(find.text('Reveal / Check'));
      await t.pumpAndSettle();
      expect(find.textContaining('simulated R:'), findsOneWidget);
      await t.tap(find.text('Close check'));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Reset'));
      await t.pumpAndSettle();
      expect(e.spherometer.reference, isNull);
      expect(e.result, isNull);
      final shell = t.widget<InstrumentShell>(find.byType(InstrumentShell));
      expect(shell.reopenTrial!(recorded), isTrue);
      await t.pumpAndSettle();
      expect(e.result, recorded.value);
      expect(t.takeException(), isNull);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Spherometer screw drag starts on knob; section/top preserve measurement and scale reader',
    (t) async {
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      router.go('/lab/s01-e03');
      await t.pumpAndSettle();
      final dynamic state = t.state(find.byType(Workspace));
      final e = state.experiment;
      final area = t.getRect(find.byKey(const Key('spherometer-apparatus')));
      final fit = (area.width / 350) < (area.height / 260)
          ? area.width / 350
          : area.height / 260;
      final origin =
          area.topLeft +
          Offset(
            (area.width - 350 * fit) / 2 - 45 * fit,
            (area.height - 260 * fit) / 2 - 20 * fit,
          );
      final start = e.a;
      await t.dragFrom(
        origin + const Offset(220, 90) * fit,
        const Offset(0, -35),
      );
      await t.pumpAndSettle();
      expect(e.a, greaterThan(start));
      final after = e.a;
      await t.tap(find.byKey(const Key('workspace-inspect')));
      await t.pumpAndSettle();
      await t.ensureVisible(
        find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.text('Top'),
            )
            .last,
      );
      await t.pumpAndSettle();
      await t.tap(
        find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.text('Top'),
            )
            .last,
      );
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Close inspector'));
      await t.pumpAndSettle();
      expect(e.a, after);
      await t.tap(find.byKey(const Key('workspace-inspect')));
      await t.pumpAndSettle();
      await t.ensureVisible(
        find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.text('Section'),
            )
            .last,
      );
      await t.pumpAndSettle();
      await t.tap(
        find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.text('Section'),
            )
            .last,
      );
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Close inspector'));
      await t.pumpAndSettle();
      expect(e.a, after);
      await t.tap(find.byTooltip('Scale magnifier'));
      await t.pumpAndSettle();
      expect(find.text('Circular scale · 50 divisions'), findsOneWidget);
      await t.tap(find.byTooltip('Back').last);
      await t.pumpAndSettle();
      expect(e.a, after);
      expect(t.takeException(), isNull);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'All six Measurement labs: compact primary workflow at small/landscape/200% text',
    (t) async {
      final store = await notebook();
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetPhysicalSize);
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      for (final size in [
        const Size(320, 568),
        const Size(740, 360),
        const Size(1024, 768),
      ]) {
        t.view.physicalSize = size;
        for (int i = 0; i < 6; i++) {
          router.go('/lab/s01-e0$i');
          await t.pumpAndSettle();
          expect(find.byType(NavigationBar), findsNothing);
          expect(find.byType(InstrumentShell), findsOneWidget);
          expect(find.byTooltip('Reset').hitTestable(), findsOneWidget);
          expect(t.takeException(), isNull, reason: '$i / $size');
        }
      }
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Thermal bench material selection updates calculations; save/reopen/CSV retain versions',
    (t) async {
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      router.go('/lab/s13-e01/bench');
      await t.pumpAndSettle();
      final state = t.state<MaterialBenchState>(
        find.byType(MaterialBenchWorkspace),
      );
      expect(state.thermal.readings.first['power'], closeTo(4.01, 1e-12));
      state.thermal.materials[0] = 'ptfe';
      state.changed();
      await t.pumpAndSettle();
      expect(state.thermal.readings.first['power'], closeTo(.0022, 1e-12));
      await t.tap(find.byKey(const Key('record-trial')));
      await t.pumpAndSettle();
      expect(store.trials.single.model, materialBenchVersion);
      expect(
        store.trials.single.configuration['materialRecords'][0]['id'],
        'ptfe',
      );
      final saved = store.trials.single;
      await state.save();
      state.thermal.materials[0] = 'copper';
      state.changed();
      expect(state.restore(saved.configuration), isTrue);
      expect(state.thermal.materials[0], 'ptfe');
      expect(csvEncode([saved]), contains(thermalDataVersion));
      state.thermal.materials[0] = 'granite';
      state.changed();
      await t.pumpAndSettle();
      expect(
        t.widget<FilledButton>(find.byKey(const Key('record-trial'))).onPressed,
        isNull,
      );
      expect(t.takeException(), isNull);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Shared optical registry: geometry gestures, presets, camera isolation and reopening',
    (t) async {
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      router.go('/lab/s09-e01/bench');
      await t.pumpAndSettle();
      final state = t.state<MaterialBenchState>(
        find.byType(MaterialBenchWorkspace),
      );
      final before = state.optical.components.first.position;
      final canvas = t.getRect(find.byKey(const Key('optical-canvas')));
      await t.dragFrom(canvas.center, const Offset(25, 12));
      await t.pumpAndSettle();
      expect(
        (state.optical.components.first.position - before).length,
        greaterThan(0),
      );
      final physical = jsonEncode(state.configuration());
      await tapViewportTool(t, 'Pan / zoom camera');
      await t.pumpAndSettle();
      await t.drag(
        find.byKey(const Key('workspace-camera')),
        const Offset(20, 10),
      );
      await t.pumpAndSettle();
      expect(jsonEncode(state.configuration()), physical);
      for (int i = 0; i < MaterialBenchState.investigations.length; i++) {
        state.investigation(i);
        expect(state.optical.error, isEmpty, reason: 'preset $i');
        expect(state.traced, isNotEmpty);
        expect(
          state.traced.first.segments.any((s) => s.event != 'exit'),
          isTrue,
          reason: 'preset $i',
        );
      }
      await state.record();
      await t.pumpAndSettle();
      final trial = store.trials.single;
      expect(Trial.fromJson(trial.toJson()).value, trial.value);
      state.investigation(0);
      expect(state.restore(trial.configuration), isTrue);
      expect(state.optical.components.single.component, 'corner');
      expect(state.traced.first.accounted, closeTo(1, 1e-9));
      expect(t.takeException(), isNull);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'New benches remain usable with large text, small landscape, tablet and keyboard',
    (t) async {
      final store = await notebook();
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetPhysicalSize);
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      for (final size in [
        const Size(320, 568),
        const Size(740, 360),
        const Size(1024, 768),
      ]) {
        t.view.physicalSize = size;
        for (final id in [
          's13-e01',
          's09-e00',
          's09-e01',
          's09-e02',
          's09-e03',
        ]) {
          router.go('/lab/$id/bench');
          await t.pumpAndSettle();
          expect(find.byTooltip('Reset').hitTestable(), findsOneWidget);
          expect(t.takeException(), isNull, reason: '$id/$size');
        }
      }
      await t.tap(find.byTooltip('Selected geometry and source'));
      await t.pumpAndSettle();
      await t.tap(find.textContaining('Position X (m)').first);
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).last, '0.3');
      await t.tap(find.text('Apply'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
}
