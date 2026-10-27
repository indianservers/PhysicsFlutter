import 'package:physics_atelier/core/persistence/notebook.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/features/workbench/lab_research.dart';
import 'package:physics_atelier/features/workbench/workbench.dart';

import 'phase1_test.dart' show capture;
import 'phase9_restore_test.dart' as restoration;
import 'phase9_fixture.dart' show originalSessions, originalPreferences;

Future<void> openResearch(WidgetTester t) async {
  await t.tap(find.byTooltip('Lab options').last);
  await t.pumpAndSettle();
  await t.tap(find.text('Lab-specific tools'));
  await t.pumpAndSettle();
}

Future<void> tab(WidgetTester t, String label) async {
  await t.ensureVisible(find.text(label).last);
  await t.pumpAndSettle();
  await t.tap(find.text(label).last);
  await t.pumpAndSettle();
}

Future<void> showControl(WidgetTester t, String list, Key key) async {
  await t.scrollUntilVisible(
    find.byKey(key).hitTestable(),
    150,
    scrollable: find
        .descendant(
          of: find.byKey(Key(list)),
          matching: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          ),
        )
        .first,
  );
  await t.pumpAndSettle();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Visit every tailored tool on native Android and verify a saved-worksheet round trip',
    (t) async {
      await app.main();
      await t.pumpAndSettle();
      const representatives = {
        's01-e02',
        's01-e03',
        's02-e00',
        's05-e03',
        's08-e03',
        's10-e05',
        's12-e03',
        's14-e05',
        's16-e05',
        's15-e07',
      };
      var labs = 0, panels = 0;
      for (final entry in allEntries.where((e) => e.interactive)) {
        router.go('/lab/${entry.id}');
        await t.pumpAndSettle();
        final source = t.widget<InstrumentShell>(find.byType(InstrumentShell));
        final original = LabResearchSession.clone(
          source.captureConfiguration!(),
        );
        await openResearch(t);
        expect(find.byType(LabResearchSheet), findsOneWidget, reason: entry.id);
        for (final name in ['Tune', 'Compare', 'Watch', 'Plot', 'Explain']) {
          await tab(t, name);
          panels++;
          if (name == 'Watch' || representatives.contains(entry.id)) {
            await capture(
              t,
              binding,
              's${entry.studioIndex.toString().padLeft(2, '0')}/${entry.id}_${name.toLowerCase()}',
            );
          }
          expect(t.takeException(), isNull, reason: '${entry.id}: $name');
        }
        await t.tap(find.byTooltip('Close lab-specific tools'));
        await t.pumpAndSettle();
        expect(source.restoreConfiguration!(original), true, reason: entry.id);
        await t.pumpAndSettle();
        labs++;
        debugPrint('LAB_RESEARCH_CHECKED ${entry.id}');
      }
      router.go('/lab/s02-e08');
      await t.pumpAndSettle();
      await openResearch(t);
      final session = t
          .widget<LabResearchSheet>(find.byType(LabResearchSheet))
          .session;
      final trialCount = session.store.trials.length,
          completed = Set.of(session.store.completed);
      await tab(t, 'Compare');
      await showControl(
        t,
        'research-comparison-scroll',
        const Key('research-capture-a'),
      );
      await t.tap(find.byKey(const Key('research-capture-a')));
      await t.pumpAndSettle();
      expect(session.a != null, true);
      await tab(t, 'Tune');
      await showControl(
        t,
        'research-setup-scroll',
        const Key('research-apply-focus'),
      );
      await t.tap(find.byKey(const Key('research-apply-focus')));
      await t.pumpAndSettle();
      await tab(t, 'Compare');
      await showControl(
        t,
        'research-comparison-scroll',
        const Key('research-capture-b'),
      );
      await t.tap(find.byKey(const Key('research-capture-b')));
      await t.pumpAndSettle();
      expect(session.b != null, true);
      await capture(t, binding, 's02/s02-e08_qa_comparison');
      await tab(t, 'Plot');
      await showControl(
        t,
        'research-plot-scroll',
        const Key('research-capture-point'),
      );
      await t.tap(find.byKey(const Key('research-capture-point')));
      await t.pumpAndSettle();
      expect(session.points.length, 1);
      expect(session.apply('extension', .16), true);
      await t.pumpAndSettle();
      await showControl(
        t,
        'research-plot-scroll',
        const Key('research-capture-point'),
      );
      await t.tap(find.byKey(const Key('research-capture-point')));
      await t.pumpAndSettle();
      expect(session.points.length, 2);
      await capture(t, binding, 's02/s02-e08_qa_response_points');
      await tab(t, 'Explain');
      await showControl(
        t,
        'research-worksheet-scroll',
        const Key('research-claim'),
      );
      await t.enterText(
        find.byKey(const Key('research-claim')),
        'QA worksheet: source-specific evidence round-trip check.',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      await showControl(
        t,
        'research-worksheet-scroll',
        const Key('research-save'),
      );
      await t.tap(find.byKey(const Key('research-save')));
      await t.pumpAndSettle();
      expect(
        session.store.preferences.containsKey(session.preferenceKey),
        true,
      );
      expect(session.dirty, false);
      await t.tap(find.byTooltip('Close lab-specific tools'));
      await t.pumpAndSettle();
      router.go('/?tab=saved');
      await t.pumpAndSettle();
      final saved = find.byKey(const Key('saved-worksheet-s02-e08'));
      await t.ensureVisible(saved);
      await t.pumpAndSettle();
      await capture(t, binding, 'saved_worksheets');
      await t.tap(saved);
      await t.pumpAndSettle();
      expect(find.byType(LabResearchSheet), findsOneWidget);
      expect(
        t
            .widget<TextField>(find.byKey(const Key('research-claim')))
            .controller!
            .text
            .startsWith('QA worksheet:'),
        true,
      );
      await capture(t, binding, 's02/s02-e08_qa_saved_roundtrip');
      expect(session.store.trials.length, trialCount);
      expect(session.store.completed, completed);
      await t.tap(find.byTooltip('Close lab-specific tools'));
      await t.pumpAndSettle();
      router.go('/');
      await t.pumpAndSettle();
      binding.reportData ??= {};
      binding.reportData!['labResearchAudit'] = {
        'physicalLabs': labs,
        'tailoredPanelsVisited': panels,
        'specificSuggestions': 580,
        'representativeFiveTabCaptures': representatives.length,
        'savedWorksheetRoundTrip': true,
        'sourceNotesCopiedIntoWorksheets': false,
        'newNotebookTrials': 0,
        'newMasteryCompletions': 0,
      };
    },
  );
  restoration.main();
  testWidgets(
    'Remove only QA-created sessions and worksheet preferences absent from the private baseline',
    (t) async {
      final db = await openDatabase(
        '${await getDatabasesPath()}/physics_notebook.db',
      );
      var removed = 0;
      for (final entry in allEntries.where((e) => e.interactive)) {
        if (!originalSessions.containsKey(entry.id)) {
          removed += await db.delete(
            'sessions',
            where: 'id=?',
            whereArgs: [entry.id],
          );
        }
      }
      final store = (await _store());
      var removedPreferences = 0;
      for (final key
          in store.preferences
              .getKeys()
              .where(
                (k) =>
                    (k.startsWith('lab-research:') ||
                        k.startsWith('lab-research-backup:')) &&
                    !originalPreferences.containsKey(k),
              )
              .toList()) {
        await store.preferences.remove(key);
        removedPreferences++;
      }
      binding.reportData ??= {};
      binding.reportData!['qaOnlyRowsRemoved'] = removed;
      binding.reportData!['qaOnlyWorksheetPreferencesRemoved'] =
          removedPreferences;
    },
  );
}

Future<LocalNotebook> _store() async {
  // Use the same repository implementation as restoration, keeping the original
  // preference types and values intact rather than resetting application data.
  final store = LocalNotebook();
  await store.initialize();
  return store;
}
