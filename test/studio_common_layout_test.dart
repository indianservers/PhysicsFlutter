import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/content/studio_investigations.dart';
import 'package:physics_atelier/features/workbench/exploration_workbench.dart';

import 'app_test.dart' show notebook;
import 'studio_common_experience_test.dart'
    show openExploration, explorationTab;

void main() {
  testWidgets(
    'All 116 common workbenches fit small phones at 200 percent text',
    (t) async {
      t.view.physicalSize = const Size(640, 1136);
      t.view.devicePixelRatio = 2;
      t.platformDispatcher.textScaleFactorTestValue = 2;
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
      for (final entry in allEntries.where((v) => v.interactive)) {
        router.go('/lab/${entry.id}');
        await t.pumpAndSettle();
        await openExploration(t);
        for (final name in ['Controls', 'Readings', 'Compare', 'Guide']) {
          await explorationTab(t, name);
          expect(t.takeException(), isNull, reason: '${entry.id}: $name');
        }
        await t.tap(find.byTooltip('Close exploration workbench'));
        await t.pumpAndSettle();
      }
      expect(store.trials, isEmpty);
      expect(store.completed, isEmpty);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Every studio exposes ten searchable tools without changing source values',
    (t) async {
      t.view.physicalSize = const Size(640, 1136);
      t.view.devicePixelRatio = 2;
      t.platformDispatcher.textScaleFactorTestValue = 2;
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
      for (final studio in studios) {
        router.go('/studio/${studio.id}');
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('studio-exploration-tools')));
        await t.pumpAndSettle();
        expect(find.byType(StudioToolCatalog), findsOneWidget);
        final index = studios.indexOf(studio),
            tools = studioInvestigations
                .where((v) => v.studio == studios.indexOf(studio))
                .toList();
        expect(tools.length, 10);
        for (final tool in tools) {
          final action = find.byKey(Key('studio-tool-${tool.id}'));
          await t.scrollUntilVisible(
            action,
            200,
            scrollable: find
                .descendant(
                  of: find.byKey(const Key('studio-tool-list')),
                  matching: find.byType(Scrollable),
                )
                .first,
            maxScrolls: 150,
          );
          await t.pumpAndSettle();
          expect(action.hitTestable(), findsOneWidget);
          expect(t.takeException(), isNull, reason: 'studio $index ${tool.id}');
        }
        await t.enterText(
          find.byKey(const Key('studio-tool-search')),
          'no matching studio tool',
        );
        await t.pumpAndSettle();
        expect(find.text('0 of 10 tools'), findsOneWidget);
        await t.tap(find.byTooltip('Clear tool search'));
        await t.pumpAndSettle();
        expect(find.text('10 of 10 tools'), findsOneWidget);
        await t.tap(find.byTooltip('Close studio tools'));
        await t.pumpAndSettle();
      }
      expect(store.trials, isEmpty);
      expect(store.completed, isEmpty);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Short landscape and keyboard retain the new controls, feedback and precision editor',
    (t) async {
      t.view.physicalSize = const Size(1136, 640);
      t.view.devicePixelRatio = 2;
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetViewInsets);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      for (final id in [
        's01-e03',
        's02-e00',
        's05-e03',
        's08-e03',
        's10-e05',
        's12-e04',
        's14-e05',
        's16-e05',
        's15-e07',
      ]) {
        final tool = studioInvestigations.firstWhere((v) => v.labId == id);
        router.go('/lab/$id?studioTool=${tool.id}');
        await t.pumpAndSettle();
        final c = t
            .widget<ExplorationWorkbench>(find.byType(ExplorationWorkbench))
            .controller;
        c.feedback = 'A long experiment notice should remain readable and expandable even on a short screen with large text.';
        c.changed();
        await t.pumpAndSettle();
        for (final name in ['Controls', 'Readings', 'Compare', 'Guide']) {
          await explorationTab(t, name);
          expect(t.takeException(), isNull, reason: '$id $name');
        }
        await t.tap(find.byTooltip('Close exploration workbench'));
        await t.pumpAndSettle();
      }
      t.view.physicalSize = const Size(720, 1280);
      router.go('/lab/s02-e08');
      await t.pumpAndSettle();
      await openExploration(t);
      t.view.viewInsets = const FakeViewPadding(bottom: 500);
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('Search controls')), 'extension');
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      t.view.resetViewInsets();
      await t.pumpAndSettle();
      final edit = find.byKey(const Key('exploration-edit-extension'));
      await t.scrollUntilVisible(
        edit.hitTestable(),
        150,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('exploration-controls-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await t.tap(edit);
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      final compactController = t
          .widget<ExplorationWorkbench>(find.byType(ExplorationWorkbench))
          .controller;
      compactController.feedback = 'A complete notice remains available while the landscape keyboard is open.';
      compactController.changed();
      t.view.physicalSize = const Size(1136, 640);
      t.view.viewInsets = const FakeViewPadding(bottom: 400);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.byTooltip('Read experiment notice'), findsOneWidget);
      t.view.resetViewInsets();
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Close exploration workbench'));
      await t.pumpAndSettle();
      router.go('/');
      await t.pumpAndSettle();
    },
  );
}
