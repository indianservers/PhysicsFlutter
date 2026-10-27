import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/features/workbench/lab_research.dart';

import 'app_test.dart' show notebook;
import 'lab_research_test.dart' show openResearch;

void main() {
  testWidgets(
    'A saved worksheet is discoverable and opens its explanation directly from Saved',
    (t) async {
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      router.go('/lab/s02-e08');
      await t.pumpAndSettle();
      await openResearch(t);
      final session = t
          .widget<LabResearchSheet>(find.byType(LabResearchSheet))
          .session;
      session.claim =
          'At fixed stiffness the restoring-force magnitude follows extension.';
      session.reasoning = 'My captured spring model is linear.';
      expect(await session.save(), true);
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Close lab-specific tools'));
      await t.pumpAndSettle();
      router.go('/?tab=saved');
      await t.pumpAndSettle();
      final saved = find.byKey(const Key('saved-worksheet-s02-e08'));
      await t.ensureVisible(saved);
      await t.tap(saved);
      await t.pumpAndSettle();
      expect(find.byType(LabResearchSheet), findsOneWidget);
      expect(
        find.byKey(const Key('research-claim')).hitTestable(),
        findsOneWidget,
      );
      expect(
        t
            .widget<TextField>(find.byKey(const Key('research-claim')))
            .controller!
            .text,
        session.claim,
      );
      expect(
        store.favorites,
        isEmpty,
        reason: 'worksheet saving does not silently favorite a lab',
      );
      expect(store.trials, isEmpty);
      expect(store.completed, isEmpty);
      await t.tap(find.byTooltip('Close lab-specific tools'));
      await t.pumpAndSettle();
      router.go('/');
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'Mode-dependent controls are never silently substituted and circuit undo retains the selected part',
    (t) async {
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      router.go('/lab/s10-e05');
      await t.pumpAndSettle();
      await openResearch(t);
      var s = t.widget<LabResearchSheet>(find.byType(LabResearchSheet)).session;
      expect(s.control('gap'), isNotNull);
      await t.tap(find.text('Model options').first);
      await t.pumpAndSettle();
      final mode = find
          .descendant(
            of: find.byType(LabResearchSheet),
            matching: find.byKey(const Key('em-model')),
          )
          .first;
      t.widget<DropdownButtonFormField<int>>(mode).onChanged!(2);
      await t.pumpAndSettle();
      expect(s.control('gap'), isNull);
      expect(s.control('resistance'), isNotNull);
      expect(s.apply('gap', .001), false);
      expect(s.capturePoint('gap', 'capacitance'), false);
      expect(s.points, isEmpty);
      await t.tap(find.byTooltip('Close lab-specific tools'));
      await t.pumpAndSettle();
      router.go('/lab/s10-e04');
      await t.pumpAndSettle();
      await openResearch(t);
      s = t.widget<LabResearchSheet>(find.byType(LabResearchSheet)).session;
      expect(s.control('component')!.label, 'R1');
      expect(s.control('component')!.unit, 'Ω');
      expect(s.apply('component', 20), true);
      await t.pumpAndSettle();
      expect(s.undoSetup(), true);
      await t.pumpAndSettle();
      expect(s.control('component')!.label, 'R1');
      expect(s.control('component')!.unit, 'Ω');
      expect(s.apply('component', 30), true);
      await t.pumpAndSettle();
      final current = double.parse(
        s.readings().firstWhere((r) => r.label == 'current').value,
      );
      expect(current, closeTo(6 / (30 + 20), 1e-10));
      await t.tap(find.byTooltip('Close lab-specific tools'));
      await t.pumpAndSettle();
      router.go('/');
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );
}
