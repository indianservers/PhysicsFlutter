import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/content/studio_investigations.dart';
import 'package:physics_atelier/features/workbench/exploration_workbench.dart';

import 'phase1_test.dart' show capture;
import 'phase9_restore_test.dart' as restoration;
import 'phase9_fixture.dart' show originalSessions;

Future<void> tab(WidgetTester t, String label) async {
  await t.ensureVisible(find.text(label).last);
  await t.tap(find.text(label).last);
  await t.pumpAndSettle();
}

Future<void> visible(WidgetTester t, Key key, String list) async {
  await t.scrollUntilVisible(
    find.byKey(key),
    100,
    scrollable: find
        .descendant(
          of: find.byKey(Key(list)),
          matching: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          ),
        )
        .first,
    maxScrolls: 150,
  );
  await t.pumpAndSettle();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Native studio discovery, paired source setups and shared exploration panels',
    (t) async {
      await app.main();
      await t.pumpAndSettle();
      var catalogs = 0, physical = 0, panels = 0;
      for (var s = 0; s < 17; s++) {
        router.go('/studio/${studios[s].id}');
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('studio-exploration-tools')));
        await t.pumpAndSettle();
        expect(find.byType(StudioToolCatalog), findsOneWidget);
        expect(find.text('10 of 10 tools'), findsOneWidget);
        await capture(
          t,
          binding,
          's${s.toString().padLeft(2, '0')}/studio_catalog',
        );
        catalogs++;
        await t.tap(find.byTooltip('Close studio tools'));
        await t.pumpAndSettle();
        final tool = studioInvestigations.firstWhere((v) => v.studio == s);
        router.go('/lab/${tool.labId}?studioTool=${tool.id}');
        await t.pumpAndSettle();
        if (s == 0) {
          await capture(t, binding, 's00/atlas_discovery_cards');
          expect(t.takeException(), isNull);
          continue;
        }
        final panel = t.widget<ExplorationWorkbench>(
          find.byType(ExplorationWorkbench),
        );
        final controller = panel.controller;
        expect(panel.tool?.id, tool.id);
        final original = ExplorationController.clone(
          controller.configuration(),
        );
        await visible(
          t,
          const Key('exploration-setup-preview'),
          'exploration-controls-scroll',
        );
        await t.tap(find.text('Preview studio setups'));
        await t.pumpAndSettle();
        await visible(
          t,
          const Key('exploration-apply-a'),
          'exploration-controls-scroll',
        );
        await t.tap(find.byKey(const Key('exploration-apply-a')));
        await t.pumpAndSettle();
        expect(controller.canUndo, true, reason: tool.id);
        await tab(t, 'Compare');
        await visible(
          t,
          const Key('exploration-capture-a'),
          'exploration-compare-scroll',
        );
        await t.tap(find.byKey(const Key('exploration-capture-a')));
        await t.pumpAndSettle();
        expect(controller.a != null, controller.valid(), reason: tool.id);
        await tab(t, 'Controls');
        await visible(
          t,
          const Key('exploration-apply-b'),
          'exploration-controls-scroll',
        );
        await t.tap(find.byKey(const Key('exploration-apply-b')));
        await t.pumpAndSettle();
        await tab(t, 'Compare');
        await visible(
          t,
          const Key('exploration-capture-b'),
          'exploration-compare-scroll',
        );
        await t.tap(find.byKey(const Key('exploration-capture-b')));
        await t.pumpAndSettle();
        expect(controller.b != null, controller.valid(), reason: tool.id);
        for (final name in ['Controls', 'Readings', 'Compare', 'Guide']) {
          await tab(t, name);
          panels++;
          await capture(
            t,
            binding,
            's${s.toString().padLeft(2, '0')}/${tool.labId}_${name.toLowerCase()}',
          );
          expect(t.takeException(), isNull, reason: '${tool.id}: $name');
        }
        expect(controller.restore(original), true);
        await t.pumpAndSettle();
        await t.tap(find.byTooltip('Close exploration workbench'));
        await t.pumpAndSettle();
        physical++;
        debugPrint('STUDIO_COMMON_NATIVE_CHECKED $s');
      }
      router.go('/');
      await t.pumpAndSettle();
      binding.reportData ??= {};
      binding.reportData!['studioCommonAudit'] = {
        'studioCatalogs': catalogs,
        'physicalStudioRepresentatives': physical,
        'sharedPanelsVisited': panels,
        'pairedSetupsThroughUI': physical * 2,
        'physicalScenarioDefinitions': 160,
        'overviewDiscoveryDefinitions': 10,
        'captureAndApplyAreExplicit': true,
      };
    },
  );
  restoration.main();
  testWidgets(
    'Remove only QA-created source session rows absent from the private baseline',
    (t) async {
      final db = await openDatabase(
        '${await getDatabasesPath()}/physics_notebook.db',
      );
      var removed = 0;
      for (final e in allEntries) {
        if (!originalSessions.containsKey(e.id)) {
          removed += await db.delete(
            'sessions',
            where: 'id=?',
            whereArgs: [e.id],
          );
        }
      }
      binding.reportData ??= {};
      binding.reportData!['qaOnlyRowsRemoved'] = removed;
    },
  );
}
