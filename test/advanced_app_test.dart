import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';

import 'app_test.dart' show notebook;

void main() {
  testWidgets(
    'All 18 new labs: five sections, scrolled controls, large text and landscape',
    (tester) async {
      tester.view.physicalSize = const Size(640, 1136);
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final store = await notebook();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      for (final entry in allEntries.where((e) => e.advanced)) {
        router.go('/lab/${entry.id}');
        await tester.pumpAndSettle();
        for (final tab in [
          'Learn',
          'Experiment',
          'Visualize',
          'Formulas',
          'Results',
        ]) {
          await tester.tap(find.text(tab).last);
          await tester.pumpAndSettle();
          final scroll = find.byType(Scrollable).first;
          for (int i = 0; i < 45; i++) {
            final pos = tester.state<ScrollableState>(scroll).position;
            if (pos.pixels >= pos.maxScrollExtent) break;
            pos.jumpTo((pos.pixels + 300).clamp(0, pos.maxScrollExtent));
            await tester.pumpAndSettle();
          }
        }
      }
      tester.view.physicalSize = const Size(1280, 720);
      router.go('/lab/s07-e05');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Experiment').last);
      await tester.pumpAndSettle();
      router.go('/');
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'Real advanced parameter, step, record, restored notes and persistence',
    (tester) async {
      final store = await notebook();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      router.go('/lab/s07-e00');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Experiment').last);
      await tester.pumpAndSettle();
      Future<void> show(Finder target) async {
        final scroll = find.byType(Scrollable).first;
        tester.state<ScrollableState>(scroll).position.jumpTo(0);
        await tester.pumpAndSettle();
        for (int i = 0; i < 50 && target.evaluate().isEmpty; i++) {
          final pos = tester.state<ScrollableState>(scroll).position;
          pos.jumpTo((pos.pixels + 250).clamp(0, pos.maxScrollExtent));
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(target.first);
        await tester.pumpAndSettle();
      }

      await show(find.byKey(const Key('edit-m')));
      await tester.tap(find.byKey(const Key('edit-m')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '2');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      await show(find.byKey(const Key('step-advanced')));
      await tester.tap(find.byKey(const Key('step-advanced')));
      await tester.pumpAndSettle();
      await show(find.byKey(const Key('record-advanced')));
      await tester.enterText(find.byType(TextField).last, 'Spring observation');
      await tester.tap(find.byKey(const Key('record-advanced')));
      await tester.pumpAndSettle();
      expect(store.trials.last.configuration['parameters']['m'], 2);
      expect(store.trials.last.configuration['ticks'], 1);
      expect(store.trials.last.note, 'Spring observation');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(seconds: 4));
      await show(find.byKey(const Key('edit-m')));
      await tester.tap(find.byKey(const Key('edit-m')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '3');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Results').last);
      await tester.pumpAndSettle();
      await show(find.text('Reopen configuration'));
      await tester.tap(find.text('Reopen configuration').first);
      await tester.pumpAndSettle();
      expect(find.text('Pause'), findsNothing);
      await show(find.byKey(const Key('edit-m')));
      expect(find.text('2.00000 kg ✎'), findsOneWidget);
      router.go('/');
      await tester.pumpAndSettle();
    },
  );
}
