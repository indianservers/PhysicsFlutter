import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';
import 'package:physics_atelier/core/physics/astronomy_run.dart';
import 'package:physics_atelier/features/astronomy/workspace.dart';
import 'package:physics_atelier/features/astronomy/curriculum.dart';
import 'package:physics_atelier/features/overview/workspace.dart';
import 'package:physics_atelier/features/overview/compare_workspace.dart';
import 'package:physics_atelier/content/learning.dart';

import '../test/em_app_test.dart' show top, edit;
import 'phase1_test.dart' show capture, show;

class Phase8Lifecycle extends WidgetsBindingObserver {
  final events = <AppLifecycleState>[];
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    events.add(s);
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Phase8 native astronomy overview comparisons persistence and real OS lifecycle',
    (t) async {
      await app.main();
      await t.pumpAndSettle();
      final store = ProviderScope.containerOf(
            t.element(find.byType(PhysicsApp)),
          ).read(notebookProvider),
          original = store.trials.map((x) => x.toJson()).toList();
      final checks = <String, dynamic>{};
      AstronomyWorkspaceState astronomy() =>
          t.state(find.byType(AstronomyWorkspace));
      Future<void> shot(String name) async {
        FocusManager.instance.primaryFocus?.unfocus();
        for (int i = 0; i < 3; i++) {
          await top(t);
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 200)),
          );
          await t.pumpAndSettle();
        }
        await capture(t, binding, 'phase8-$name');
      }

      for (int k = 0; k < 6; k++) {
        router.go('/lab/s16-e0$k');
        await t.pumpAndSettle();
        await t.tap(find.text('Experiment').last);
        await t.pumpAndSettle();
        await show(t, find.text('Restore defaults'));
        await t.tap(find.text('Restore defaults'));
        await t.pumpAndSettle();
        await top(t);
        for (int m = 0; m < astroModes[k].length; m++) {
          astronomy().chooseMode(m);
          await t.pumpAndSettle();
          expect(astronomy().run.invalid, isEmpty);
          checks['s16-e0$k:$m'] = Map.of(astronomy().run.state);
        }
        astronomy().chooseMode(0);
        await t.pumpAndSettle();
        final c = astroLessons[k].controls.first;
        await edit(t, c.key, '${c.initial + (c.max - c.min) * .001}');
        if (astronomy().run.dynamicLab) {
          astronomy().run.seek(2);
          astronomy().tick.value++;
        }
        await t.pumpAndSettle();
        astronomy().notes.text =
            'Phase8 native calculated model trial. ${astroLessons[k].limits}';
        final reading = astronomy().result;
        await astronomy().submit(reading!);
        await shot('s16-e0$k');
        await show(t, find.byKey(const Key('record-trial')));
        await t.tap(find.byKey(const Key('record-trial')));
        await t.pumpAndSettle();
        expect(store.trials.last.value, reading);
        expect(astronomy().eligible, true);
        await t.tap(find.byTooltip('Save session'));
        await t.pumpAndSettle();
        final state = Map.of(astronomy().run.state);
        router.go('/');
        await t.pumpAndSettle();
        router.go('/lab/s16-e0$k');
        await t.pumpAndSettle();
        expect(astronomy().run.state, state);
        expect(astronomy().ticker.isActive, false);
        for (final tab in [
          'Learn',
          'Experiment',
          'Visualize',
          'Formulas',
          'Results',
        ]) {
          await t.tap(find.text(tab).last);
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
        }
      }
      for (int tool = 0; tool < 6; tool++) {
        router.go('/lab/s00-e0$tool');
        await t.pumpAndSettle();
        if (tool == 4) {
          final state = t.state<CompareWorkspaceState>(
            find.byType(CompareWorkspace),
          );
          for (int pair = 0; pair < 5; pair++) {
            state.choose(pair);
            await t.pumpAndSettle();
            final control = comparisonControls[pair].first;
            await edit(
              t,
              control.key,
              '${control.initial + (control.max - control.min) * .001}',
            );
            await show(t, find.byKey(const Key('comparison-coordinate')));
            t
                .widget<Slider>(find.byKey(const Key('comparison-coordinate')))
                .onChanged!(8);
            await t.pumpAndSettle();
            expect(state.model.left, isNotEmpty);
            expect(state.model.right, isNotEmpty);
            checks['comparison:$pair'] = Map.of(state.model.values);
            await shot('comparison-$pair');
          }
          state.notes.text = 'All five comparisons inspected with separate units and documented synchronization; analogy limits retained.';
          await state.save();
          final values = Map.of(state.model.values);
          router.go('/');
          await t.pumpAndSettle();
          router.go('/lab/s00-e04');
          await t.pumpAndSettle();
          expect(
            t
                .state<CompareWorkspaceState>(find.byType(CompareWorkspace))
                .model
                .values,
            values,
          );
        }
        if (tool == 0) {
          await t.enterText(find.byType(TextFormField).first, 'orbital');
          FocusManager.instance.primaryFocus?.unfocus();
          await t.pumpAndSettle();
          expect(store.completed.contains('s00-e00'), false);
        }
        if (tool == 1) {
          final field = find.byType(DropdownButtonFormField<String>);
          t.widget<DropdownButtonFormField<String>>(field).onChanged!(
            'Gravitation',
          );
          await t.pumpAndSettle();
        }
        if (tool == 2) {
          final field = find.byType(DropdownButtonFormField<String>);
          t.widget<DropdownButtonFormField<String>>(field).onChanged!(
            'astronomy',
          );
          await t.pumpAndSettle();
          expect(learningPaths.last.progress(store.completed), 0);
        }
        if (tool == 3) {
          await t.enterText(find.byType(TextFormField).first, 'Exoplanets');
          FocusManager.instance.primaryFocus?.unfocus();
          await t.pumpAndSettle();
          final filter = find.byType(DropdownButtonFormField<int>);
          await show(t, filter);
          t.widget<DropdownButtonFormField<int>>(filter).onChanged!(16);
          await t.pumpAndSettle();
          await show(t, find.byKey(const Key('favorite-s16-e05')));
          if (!store.favorites.contains('s16-e05')) {
            await t.tap(find.byKey(const Key('favorite-s16-e05')));
            await t.pumpAndSettle();
          }
          expect(store.favorites, contains('s16-e05'));
          await show(t, find.text('Launch documented defaults'));
          await t.tap(find.text('Launch documented defaults'));
          await t.pumpAndSettle();
          await t.tap(find.text('Use documented defaults'));
          await t.pumpAndSettle();
          expect(astronomy().parameters, astroLessons[5].defaults);
          router.pop();
          await t.pumpAndSettle();
          expect(
            (await store.savedSessionIds()).where(
              (id) => id.startsWith('backup:s16-e05:'),
            ),
            isNotEmpty,
          );
        }
        if (tool == 5) {
          final q = masteryQuestions.first;
          await show(t, find.byKey(const Key('mastery-answer')));
          await t.enterText(
            find.byKey(const Key('mastery-answer')),
            '${q.answer()}',
          );
          FocusManager.instance.primaryFocus?.unfocus();
          await t.pumpAndSettle();
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 300)),
          );
          await t.pumpAndSettle();
          await show(t, find.byKey(const Key('mastery-submit')));
          await t.tap(find.byKey(const Key('mastery-submit')));
          await t.pumpAndSettle();
          expect((await store.readAttempts('s00-e05')).first['correct'], true);
        }
        await shot('s00-e0$tool');
        if (tool != 4) {
          final state = t.state<OverviewWorkspaceState>(
            find.byType(OverviewWorkspace),
          );
          await state.save();
        }
      }
      router.go('/lab/s00-e04');
      await t.pumpAndSettle();
      final comparison = t.state<CompareWorkspaceState>(
            find.byType(CompareWorkspace),
          ),
          trace = Phase8Lifecycle();
      WidgetsBinding.instance.addObserver(trace);
      comparison.play();
      await t.pump();
      await t.pump(const Duration(milliseconds: 80));
      debugPrint('PHASE8_READY_FOR_OS_BACKGROUND');
      await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 8)));
      await t.pump();
      expect(trace.events, contains(AppLifecycleState.paused));
      expect(trace.events.last, AppLifecycleState.resumed);
      expect(comparison.ticker.isActive, false);
      final coordinate = comparison.coordinate;
      await t.pump(const Duration(milliseconds: 300));
      expect(comparison.coordinate, coordinate);
      WidgetsBinding.instance.removeObserver(trace);
      checks['realOSLifecycle'] = trace.events.map((e) => e.name).toList();
      for (final old in original) {
        expect(store.trials.firstWhere((x) => x.id == old['id']).toJson(), old);
      }
      binding.reportData ??= {};
      binding.reportData!['phase8Validation'] = {
        'checks': checks,
        'nativeAstronomySelections': 17,
        'newTrials': store.trials.length - original.length,
        'originalTrialsPreserved': original.length,
        'realOSBackgroundResume': true,
        'favoritesSaved': store.favorites.contains('s16-e05'),
        'comparisonReplayExact': true,
        'defaultBackupPreserved': true,
      };
      binding.reportData!['csv'] = csvEncode(
        store.trials.where((t) => t.model == astroVersion).toList(),
      );
      binding.reportData!['csvFile'] = 'phase8-verified-results.csv';
      router.go('/');
      await t.pumpAndSettle();
    },
  );
}
