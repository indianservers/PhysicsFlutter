import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';
import 'package:physics_atelier/core/physics/astronomy_run.dart';
import 'package:physics_atelier/content/learning.dart';
import 'package:physics_atelier/features/astronomy/workspace.dart';
import 'package:physics_atelier/features/astronomy/curriculum.dart';
import 'package:physics_atelier/features/overview/workspace.dart';
import 'package:physics_atelier/features/overview/compare_workspace.dart';
import 'package:physics_atelier/features/advanced/scene.dart' show LabPlot;

import 'app_test.dart' show notebook;
import 'waves_app_test.dart' show show;
import 'em_app_test.dart' show top, edit;

Future<void> astroBoot(WidgetTester t, LocalNotebook store, String id) async {
  await t.pumpWidget(
    ProviderScope(
      overrides: [notebookProvider.overrideWithValue(store)],
      child: const PhysicsApp(),
    ),
  );
  router.go('/lab/$id');
  await t.pumpAndSettle();
}

AstronomyWorkspaceState astroState(WidgetTester t) =>
    t.state(find.byType(AstronomyWorkspace));
Future<void> scrollEnds(WidgetTester t) async {
  for (int i = 0; i < 6; i++) {
    final state = t.state<ScrollableState>(find.byType(Scrollable).first);
    state.position.jumpTo(state.position.maxScrollExtent);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }
  await top(t);
}

void main() {
  testWidgets(
    'Mastery parameter target rejects invalid model inputs and records full source configuration',
    (t) async {
      final store = await notebook();
      await astroBoot(t, store, 's00-e05');
      final field = find.byType(DropdownButtonFormField<String>).last;
      await show(t, field);
      t.widget<DropdownButtonFormField<String>>(field).onChanged!(
        'resistor-target-01',
      );
      await t.pumpAndSettle();
      await show(t, find.byKey(const Key('mastery-answer')));
      await t.enterText(find.byKey(const Key('mastery-answer')), '-10');
      await t.pumpAndSettle();
      final state = t.state<OverviewWorkspaceState>(
        find.byType(OverviewWorkspace),
      );
      expect(state.adjustmentPreview(), contains('supported current'));
      await state.submit();
      expect(await store.readAttempts('s00-e05'), isEmpty);
      await t.enterText(find.byKey(const Key('mastery-answer')), '2500');
      await state.submit();
      await t.pumpAndSettle();
      final a = (await store.readAttempts('s00-e05')).single;
      expect(a['correct'], true);
      expect(a['sourceModel'], 'electromagnetism-5.0');
      expect(a['modelConfiguration']['sourceVoltage_V'], 5);
      router.go('/');
      await t.pumpAndSettle();
    },
  );

  testWidgets(
    'Incompatible astronomy reference remains intact until explicit adoption',
    (t) async {
      final store = await notebook(),
          old = <String, dynamic>{
            'model': astroVersion,
            'dataset': 'future-unknown',
            'kind': 4,
            'parameters': {'redshift': 1},
            'notes': 'Retain exact original assumptions',
          };
      await store.saveSession('s16-e04', old);
      await astroBoot(t, store, 's16-e04');
      expect(astroState(t).incompatible, true);
      router.go('/');
      await t.pumpAndSettle();
      expect(await store.readSession('s16-e04'), old);
      router.go('/lab/s16-e04');
      await t.pumpAndSettle();
      await astroState(t).save();
      await t.pumpAndSettle();
      final backups = (await store.savedSessionIds())
          .where((id) => id.startsWith('backup:s16-e04:'))
          .toList();
      expect(backups.length, 1);
      expect((await store.readSession(backups.single))!['original'], old);
      expect((await store.readSession('s16-e04'))!['dataset'], astroDataset);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Astronomy completion requires changed science and current actual evidence',
    (t) async {
      final store = await notebook();
      await astroBoot(t, store, 's16-e04');
      final state = astroState(t);
      state.update('redshift', state.parameters['redshift']!);
      expect(state.changed, false);
      state.update('redshift', .8);
      state.notes.text = 'Flat FLRW only; distance measures differ.';
      await state.submit(state.result!);
      expect(state.eligible, false);
      await state.record();
      await t.pumpAndSettle();
      expect(state.eligible, true);
      await show(t, find.text('Complete investigation'));
      await t.tap(find.text('Complete investigation'));
      await t.pumpAndSettle();
      expect(store.completed, contains('s16-e04'));
      state.update('redshift', 1.0);
      await t.pumpAndSettle();
      expect(state.eligible, false);
      router.go('/');
      await t.pumpAndSettle();
    },
  );

  testWidgets(
    'All six astronomy labs every selection and section at160% text and landscape',
    (t) async {
      final store = await notebook();
      t.view.physicalSize = const Size(640, 1136);
      t.view.devicePixelRatio = 2;
      t.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await astroBoot(t, store, 's16-e00');
      for (int k = 0; k < 6; k++) {
        router.go('/lab/s16-e0$k');
        await t.pumpAndSettle();
        for (final section in [
          'Learn',
          'Experiment',
          'Visualize',
          'Formulas',
          'Results',
        ]) {
          await t.tap(find.text(section).last);
          await t.pumpAndSettle();
          await scrollEnds(t);
        }
        await t.tap(find.text('Experiment').last);
        await t.pumpAndSettle();
        for (int m = 0; m < astroModes[k].length; m++) {
          astroState(t).chooseMode(m);
          await t.pumpAndSettle();
          expect(astroState(t).run.invalid, isEmpty);
          expect(t.takeException(), isNull);
        }
        t.view.physicalSize = const Size(1800, 960);
        await t.pumpAndSettle();
        await scrollEnds(t);
        t.view.physicalSize = const Size(640, 1136);
        await t.pumpAndSettle();
      }
      router.go('/');
      await t.pumpAndSettle();
      expect(store.completed, isEmpty);
    },
  );
  testWidgets(
    'All six overview tools scroll with large text and tablet layouts',
    (t) async {
      final store = await notebook();
      t.view.physicalSize = const Size(640, 1136);
      t.view.devicePixelRatio = 2;
      t.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await astroBoot(t, store, 's00-e00');
      for (int i = 0; i < 6; i++) {
        router.go('/lab/s00-e0$i');
        await t.pumpAndSettle();
        await scrollEnds(t);
        t.view.physicalSize = const Size(1900, 1050);
        await t.pumpAndSettle();
        await scrollEnds(t);
        t.view.physicalSize = const Size(640, 1136);
        await t.pumpAndSettle();
      }
      router.go('/');
      await t.pumpAndSettle();
      expect(store.completed, isEmpty);
    },
  );
  testWidgets(
    'Astronomy record noise seed and exact replay survive save and reopen',
    (t) async {
      final store = await notebook();
      await astroBoot(t, store, 's16-e05');
      await t.tap(find.text('Experiment').last);
      await t.pumpAndSettle();
      await edit(t, 'noise', '.001');
      await edit(t, 'phase', '-.02');
      final state = astroState(t);
      state.run.seek(3);
      state.tick.value++;
      await t.pumpAndSettle();
      final actual = Map.of(state.run.state), profile = state.run.profile;
      state.notes.text =
          'Uniform disk; synthetic seeded detector noise, not observations.';
      await show(t, find.byKey(const Key('record-trial')));
      await t.tap(find.byKey(const Key('record-trial')));
      await t.pumpAndSettle();
      expect(store.trials.last.quantity, 'relativeIntensity');
      expect(store.trials.last.configuration['dataset'], astroDataset);
      expect(store.trials.last.configuration['profile'], profile);
      router.go('/');
      await t.pumpAndSettle();
      router.go('/lab/s16-e05');
      await t.pumpAndSettle();
      expect(astroState(t).run.state, actual);
      expect(astroState(t).run.profile, profile);
      expect(astroState(t).ticker.isActive, false);
      expect(csvEncode(store.trials), contains('astronomy-8.0'));
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Transit graph cursor drives exact scene geometry and observed error bars remain separate',
    (t) async {
      final store = await notebook();
      await astroBoot(t, store, 's16-e05');
      await t.tap(find.text('Visualize').last);
      await t.pumpAndSettle();
      final state = astroState(t), data = state.run.profile;
      await show(t, find.byType(Slider));
      t.widget<Slider>(find.byType(Slider)).onChanged!(80);
      await t.pumpAndSettle();
      expect(
        state.parameters['phase'],
        closeTo(data[80]['t']! / (5 * day), 1e-14),
      );
      expect(state.run.state['flux'], closeTo(data[80]['flux']!, 1e-12));
      router.go('/lab/s16-e03');
      await t.pumpAndSettle();
      await t.tap(find.text('Visualize').last);
      await t.pumpAndSettle();
      final field = find.byType(DropdownButtonFormField<String>);
      await show(t, field);
      t.widget<DropdownButtonFormField<String>>(field).onChanged!(
        'SPARC observed NGC2403',
      );
      await t.pumpAndSettle();
      await show(
        t,
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LabPlot),
      );
      final painter = t
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<LabPlot>()
          .first;
      expect(painter.scatter, true);
      expect(painter.errorKeys, {'observed': 'uncertainty'});
      expect(painter.data.first['observed'], 24500);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Favorites, defaults backups and saved IDs share the original notebook',
    (t) async {
      final store = await notebook();
      await store.saveSession('s16-e05', {
        'note': 'Keep old saved configuration',
        'parameters': {'periodDays': 5},
      });
      await store.toggleFavorite('s16-e05');
      await store.requestDocumentedDefaults('s16-e05');
      expect(await store.readSession('s16-e05'), isNull);
      final keys = await store.savedSessionIds(),
          backup = keys.singleWhere((k) => k.startsWith('backup:s16-e05:'));
      expect(
        (await store.readSession(backup))!['original']['note'],
        'Keep old saved configuration',
      );
      expect(
        (await store.readSession('s16-e05'))!['parameters']['periodDays'],
        5,
      );
      expect(store.favorites, contains('s16-e05'));
      expect(store.completed, isEmpty);
      await astroBoot(t, store, 's00-e03');
      expect(find.byKey(const Key('favorite-s16-e05')), findsNothing);
      await scrollEnds(t);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Mastery starts empty and saves real model-backed attempts for reopen',
    (t) async {
      final store = await notebook();
      await astroBoot(t, store, 's00-e05');
      expect(await store.readAttempts('s00-e05'), isEmpty);
      final state = t.state<OverviewWorkspaceState>(
        find.byType(OverviewWorkspace),
      );
      final q = masteryQuestions.first;
      await show(t, find.byKey(const Key('mastery-answer')));
      await t.enterText(
        find.byKey(const Key('mastery-answer')),
        '${q.answer()}',
      );
      await t.tap(find.byKey(const Key('mastery-submit')));
      await t.pumpAndSettle();
      expect(state.correctIds, {q.id});
      expect((await store.readAttempts('s00-e05')).single['correct'], true);
      expect(store.completed, isEmpty);
      router.go('/');
      await t.pumpAndSettle();
      router.go('/lab/s00-e05');
      await t.pumpAndSettle();
      expect(
        t
            .state<OverviewWorkspaceState>(find.byType(OverviewWorkspace))
            .correctIds,
        {q.id},
      );
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'All five comparisons use responsive actual models and save configurations',
    (t) async {
      final store = await notebook();
      store.reducedMotion = true;
      await astroBoot(t, store, 's00-e04');
      final state = t.state<CompareWorkspaceState>(
        find.byType(CompareWorkspace),
      );
      for (int pair = 0; pair < 5; pair++) {
        state.choose(pair);
        await t.pumpAndSettle();
        state.coordinate = 8;
        state.model.at(8);
        state.tick.value++;
        await t.pumpAndSettle();
        await scrollEnds(t);
        expect(state.model.left, isNotEmpty);
        expect(state.model.right, isNotEmpty);
      }
      state.update('velocity', 1.5);
      state.notes.text =
          'Classical position is a trajectory; quantum events are an ensemble.';
      await state.save();
      final actual = Map.of(state.model.values);
      state.play();
      await t.pump();
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final coordinate = state.coordinate;
      await t.pump(const Duration(seconds: 1));
      expect(state.coordinate, coordinate);
      expect(state.ticker.isActive, false);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      router.go('/');
      await t.pumpAndSettle();
      router.go('/lab/s00-e04');
      await t.pumpAndSettle();
      expect(
        t
            .state<CompareWorkspaceState>(find.byType(CompareWorkspace))
            .model
            .values,
        actual,
      );
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets('Related navigation returns to the same paused astronomy state', (
    t,
  ) async {
    final store = await notebook();
    await astroBoot(t, store, 's16-e02');
    final state = astroState(t);
    state.update('temperature', 6200);
    await t.pumpAndSettle();
    await show(t, find.text('Atomic Spectra'));
    await t.tap(find.text('Atomic Spectra'));
    await t.pumpAndSettle();
    expect(find.byType(AstronomyWorkspace), findsNothing);
    router.pop();
    await t.pumpAndSettle();
    expect(astroState(t), same(state));
    expect(state.parameters['temperature'], 6200);
    router.go('/');
    await t.pumpAndSettle();
  });
}
