import 'waves_app_test.dart' as controls;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';

import 'app_test.dart' show notebook;

void main() {
  testWidgets(
    'Every new lab builds all five sections at large text and small width',
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
      for (final e in allEntries.where((e) => e.dynamics)) {
        router.go('/lab/${e.id}');
        await tester.pumpAndSettle();
        for (final tab in [
          'Experiment',
          'Visualize',
          'Formulas',
          'Results',
          'Learn',
        ]) {
          await tester.tap(find.text(tab).last);
          await tester.pumpAndSettle();
          final scroll = find.byType(Scrollable).first;
          for (int i = 0; i < 30; i++) {
            final pos = tester.state<ScrollableState>(scroll).position;
            if (pos.pixels >= pos.maxScrollExtent) {
              break;
            }
            pos.jumpTo((pos.pixels + 400).clamp(0, pos.maxScrollExtent));
            await tester.pumpAndSettle();
          }
        }
      }
      tester.view.physicalSize = const Size(1280, 720);
      router.go('/lab/s04-e05');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Experiment').last);
      await tester.pumpAndSettle();
      router.go('/');
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'Step, model edit, record, restore and attempt are real state changes',
    (tester) async {
      final store = await notebook();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      router.go('/lab/s04-e01');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Experiment').last);
      await tester.pumpAndSettle();
      Future<void> show(Finder target) => controls.show(tester, target);

      await show(find.byKey(const Key('edit-m')));
      await tester.tap(find.byKey(const Key('edit-m')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '3');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      await show(find.byKey(const Key('step-dynamics')));
      await tester.tap(find.byKey(const Key('step-dynamics')));
      await tester.pumpAndSettle();
      await show(find.byKey(const Key('predict-dynamics')));
      await tester.tap(find.byKey(const Key('predict-dynamics')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '2');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      await show(find.byKey(const Key('record-dynamics')));
      await tester.tap(find.byKey(const Key('record-dynamics')));
      await tester.pumpAndSettle();
      expect(store.trials.length, 1);
      expect(store.trials.single.value, 2);
      expect(store.trials.single.configuration['ticks'], 1);
      expect(
        (store.trials.single.configuration['attempts'] as List)
            .single['correct'],
        true,
      );
      await tester.tap(find.text('Results').last);
      await tester.pumpAndSettle();
      await show(find.text('Reopen configuration'));
      await tester.tap(find.text('Reopen configuration'));
      await tester.pumpAndSettle();
      expect(find.text('Pause'), findsNothing);
      await tester.tap(find.text('Results').last);
      await tester.pumpAndSettle();
      await show(find.text('Challenge history'));
      expect(find.text('Challenge history'), findsOneWidget);
      expect(
        find.text('Reopen configuration'),
        findsNothing,
        reason: 'Summary must not duplicate trial cards',
      );
      router.go('/');
      await tester.pumpAndSettle();
    },
  );
}
