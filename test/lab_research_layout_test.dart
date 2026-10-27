import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/features/workbench/lab_research.dart';

import 'app_test.dart' show notebook;
import 'lab_research_test.dart' show openResearch;

void main() {
  testWidgets(
    'All 580 lab-specific panels fit a small phone at 200 percent text',
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
      for (final e in allEntries.where((e) => e.interactive)) {
        router.go('/lab/${e.id}');
        await t.pumpAndSettle();
        await openResearch(t);
        for (final tab in ['Tune', 'Compare', 'Watch', 'Plot', 'Explain']) {
          await t.ensureVisible(find.text(tab).last);
          await t.pumpAndSettle();
          await t.tap(find.text(tab).last);
          await t.pumpAndSettle();
          expect(t.takeException(), isNull, reason: '${e.id} $tab');
        }
        await t.tap(find.byTooltip('Close lab-specific tools'));
        await t.pumpAndSettle();
      }
      expect(store.trials, isEmpty);
      expect(store.completed, isEmpty);
      expect(
        store.preferences.getKeys().where((k) => k.startsWith('lab-research:')),
        isEmpty,
      );
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Short landscape and keyboard layouts retain all tools; unsaved explanations are protected',
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
        router.go('/lab/$id');
        await t.pumpAndSettle();
        await openResearch(t);
        final session = t
            .widget<LabResearchSheet>(find.byType(LabResearchSheet))
            .session;
        session.feedback = 'A detailed experiment notice needs to fit even when several lines would otherwise be required.';
        session.changed();
        await t.pumpAndSettle();
        for (final tab in ['Tune', 'Compare', 'Watch', 'Plot', 'Explain']) {
          await t.ensureVisible(find.text(tab).last);
          await t.tap(find.text(tab).last);
          await t.pumpAndSettle();
          expect(t.takeException(), isNull, reason: '$id $tab landscape');
        }
        await t.tap(find.byTooltip('Close lab-specific tools'));
        await t.pumpAndSettle();
      }
      t.view.physicalSize = const Size(720, 1280);
      router.go('/lab/s02-e08');
      await t.pumpAndSettle();
      await openResearch(t);
      await t.ensureVisible(find.text('Explain').last);
      await t.tap(find.text('Explain').last);
      await t.pumpAndSettle();
      t.view.viewInsets = const FakeViewPadding(bottom: 500);
      await t.pumpAndSettle();
      final field = find.byKey(const Key('research-claim'));
      await t.scrollUntilVisible(
        field.hitTestable(),
        100,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('research-worksheet-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await t.enterText(
        field,
        'The current spring force increases with extension.',
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      t.view.resetViewInsets();
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Close lab-specific tools'));
      await t.pumpAndSettle();
      expect(find.text('Save this worksheet?'), findsOneWidget);
      await t.tap(find.text('Keep editing'));
      await t.pumpAndSettle();
      expect(find.byType(LabResearchSheet), findsOneWidget);
      await t.tap(find.byTooltip('Close lab-specific tools'));
      await t.pumpAndSettle();
      await t.tap(find.text('Save and close'));
      await t.pumpAndSettle();
      expect(
        store.preferences.getString('lab-research:s02-e08'),
        contains('The current spring force increases'),
      );
      router.go('/');
      await t.pumpAndSettle();
    },
  );
}
