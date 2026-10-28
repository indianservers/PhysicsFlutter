import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/content/studio_evidence_routes.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';
import 'package:physics_atelier/features/studio/studio_evidence.dart';
import 'package:physics_atelier/features/workbench/workbench.dart';

import 'app_test.dart' show notebook;

Trial fixture(
  String id, {
  String lab = 's01-e02',
  String quantity = 'length',
  String unit = 'm',
  String model = 'measurement-1.0',
  double value = .01,
  int mode = 0,
}) => Trial(
  id: id,
  labId: lab,
  quantity: quantity,
  unit: unit,
  model: model,
  value: value,
  resolution: null,
  note: 'PRIVATE source note',
  configuration: {
    'mode': mode,
    'ticks': 120,
    'parameters': {'x': value},
    'notes': 'PRIVATE apparatus note',
  },
);

class FailingStore extends LocalNotebook {
  @override
  Future<bool> saveStudioInvestigation(
    String id,
    String body, {
    String? retained,
  }) async => false;
}

Future<void> show(WidgetTester t, Finder finder) async {
  final list = find.byKey(const Key('studio-evidence-scroll'));
  if (finder.evaluate().isEmpty) {
    final scroll = find
        .descendant(of: list, matching: find.byType(Scrollable))
        .first;
    t.state<ScrollableState>(scroll).position.jumpTo(0);
    await t.pumpAndSettle();
    if (finder.evaluate().isEmpty) {
      await t.scrollUntilVisible(finder, 200, scrollable: scroll);
    }
  }
  await t.ensureVisible(finder);
  await t.pumpAndSettle();
}

Future<void> press(WidgetTester t, Finder finder) async {
  await show(t, finder);
  await t.tap(finder);
  await t.pumpAndSettle();
}

Future<StudioEvidenceSession> open(WidgetTester t, String studio) async {
  router.go('/studio/$studio');
  await t.pumpAndSettle();
  await press(t, find.byKey(const Key('studio-evidence-launch')));
  return t
      .widget<StudioEvidenceSheet>(find.byType(StudioEvidenceSheet))
      .session;
}

void main() {
  test('Ten new investigation guides provide thirty valid goal routes and specific reasoning checks', () {
    expect(studioEvidenceRoutes.length, 10);
    expect(studioEvidenceRoutes.map((r) => r.studio).toSet().length, 10);
    expect(studioEvidenceRoutes.map((r) => r.title).toSet().length, 10);
    for (final r in studioEvidenceRoutes) {
      expect(r.answers.length, 3);
      expect(r.correct, inInclusiveRange(0, 2));
      expect(r.explanation, isNotEmpty);
      expect(r.goals.length, 3);
      for (final g in r.goals) {
        expect(g.task, isNotEmpty);
        expect(studios[entryById(g.lab).studioIndex].id, r.studio);
        expect(entryById(g.lab).interactive, true);
      }
    }
  });
  test('Recorded evidence is filtered, guarded, saved by reference and isolated from source notes and trials', () async {
    final store = await notebook();
    for (final t in [
      fixture('A'),
      fixture('B', value: .02),
      fixture('different-unit', quantity: 'time', unit: 's'),
      fixture('different-mode', mode: 1),
      fixture('foreign', lab: 's02-e00'),
    ]) {
      await store.addTrial(t);
    }
    await store.saveSession('s01-e02', {'notes': 'KEEP this apparatus note'});
    final original = jsonEncode(store.trials.map((t) => t.toJson()).toList());
    final s = StudioEvidenceSession(evidenceRouteFor('s01')!, store);
    expect(s.dirty, false);
    expect(s.bank.length, 4);
    expect(s.pick(false, 'foreign'), false);
    expect(s.pick(false, 'A'), true);
    expect(s.pick(true, 'A'), false);
    expect(s.pick(true, 'B'), true);
    expect(s.comparison, contains('0.01 m'));
    expect(s.comparison, contains('not proof of causation'));
    s.pick(true, 'different-unit');
    expect(s.comparison, contains('No numeric difference'));
    s.pick(true, 'different-mode');
    expect(s.comparison, contains('No numeric difference'));
    s.pick(true, 'B');
    s.chooseGoal(2);
    s.choosePlan(s.route.correct);
    s.writeClaim('Observed claim');
    s.writeReason('Controlled comparison');
    expect(await s.save(), true);
    expect(s.dirty, false);
    final raw = store.preferences.getString('studio-evidence:s01')!;
    expect(raw, contains('"a":"A"'));
    expect(raw, contains('"b":"B"'));
    expect(raw, isNot(contains('PRIVATE')));
    expect(raw, isNot(contains('parameters')));
    final restored = StudioEvidenceSession(s.route, store);
    expect(restored.goal, 2);
    expect(restored.claim, 'Observed claim');
    expect(restored.aId, 'A');
    expect(restored.bId, 'B');
    expect(restored.dirty, false);
    store.trials.removeWhere((t) => t.id == 'B');
    expect(restored.b, isNull);
    expect(restored.comparison, contains('unavailable'));
    store.trials.add(fixture('B', value: .02));
    expect(
      jsonEncode(store.trials.map((t) => t.toJson()).toList()),
      isNotEmpty,
    );
    expect(
      (await store.readSession('s01-e02'))!['notes'],
      'KEEP this apparatus note',
    );
    expect(store.completed, isEmpty);
    // Check the saved source records rather than the deliberate in-memory delete/re-add.
    expect(
      jsonEncode((await store.readTrials()).map((t) => t.toJson()).toList()),
      original,
    );
    restored.dispose();
    s.dispose();
  });
  test('Corrupt or future investigations are retained and backed up before explicit replacement', () async {
    final store = await notebook();
    const raw = '{"version":"future-version","claim":"do not lose me"}';
    await store.preferences.setString('studio-evidence:s01', raw);
    final s = StudioEvidenceSession(evidenceRouteFor('s01')!, store);
    expect(s.retained, raw);
    expect(store.preferences.getString('studio-evidence:s01'), raw);
    s.choosePlan(0);
    expect(await s.save(), true);
    final backups = store.preferences.getKeys().where(
      (k) => k.startsWith('studio-evidence-backup:s01:'),
    );
    expect(backups.length, 1);
    expect(store.preferences.getString(backups.single), raw);
    final doc = s.document()
      ..['a'] = 'same'
      ..['b'] = 'same';
    await store.preferences.setString('studio-evidence:s01', jsonEncode(doc));
    final duplicate = StudioEvidenceSession(s.route, store);
    expect(duplicate.retained, isNotNull);
    final unicodeClaim = List.filled(4000, '🔬').join();
    duplicate.writeClaim(unicodeClaim);
    expect(duplicate.claim, unicodeClaim);
    expect(await duplicate.save(), true);
    final unicodeRestored = StudioEvidenceSession(s.route, store);
    expect(unicodeRestored.claim, unicodeClaim);
    unicodeRestored.dispose();
    expect(
      () => store.saveStudioInvestigation('unknown', '{}'),
      throwsArgumentError,
    );
    duplicate.dispose();
    s.dispose();
  });
  test('Failed saves preserve dirty edits and do not replace existing investigation data', () async {
    await notebook();
    final store = FailingStore();
    await store.initialize();
    await store.preferences.setString('studio-evidence:s01', 'original');
    final s = StudioEvidenceSession(evidenceRouteFor('s01')!, store);
    s.writeClaim('New unsaved explanation');
    expect(await s.save(), false);
    expect(s.dirty, true);
    expect(s.saving, false);
    expect(store.preferences.getString('studio-evidence:s01'), 'original');
    expect(s.claim, 'New unsaved explanation');
    s.dispose();
  });
  testWidgets(
    'All ten guides branch to real labs, protect unsaved work and retain new notebook evidence',
    (t) async {
      t.view.physicalSize = const Size(720, 1280);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      for (final r in studioEvidenceRoutes) {
        final s = await open(t, r.studio);
        expect(s.bank, isEmpty);
        await press(
          t,
          find.widgetWithText(RadioListTile<int>, r.answers[r.correct]),
        );
        expect(s.plan, r.correct);
        await t.tap(find.byTooltip('Close studio investigation'));
        await t.pumpAndSettle();
        expect(find.text('Save this investigation?'), findsOneWidget);
        await t.tap(find.text('Keep editing'));
        await t.pumpAndSettle();
        expect(find.byType(StudioEvidenceSheet), findsOneWidget);
        for (int i = 0; i < r.goals.length; i++) {
          await press(t, find.widgetWithText(ChoiceChip, r.goals[i].title));
          await press(t, find.byKey(const Key('evidence-open-lab')));
          if (find.text('Save this investigation?').evaluate().isNotEmpty) {
            await t.tap(find.text('Save and continue'));
            await t.pumpAndSettle();
          }
          expect(
            t.widget<InstrumentShell>(find.byType(InstrumentShell)).id,
            r.goals[i].lab,
          );
          router.pop();
          await t.pumpAndSettle();
          await press(t, find.byKey(const Key('studio-evidence-launch')));
        }
        final count = store.trials.length;
        // Simulate a newly recorded notebook event while the guide is open.
        await store.addTrial(
          fixture('record-${r.studio}', lab: r.goals.first.lab),
        );
        await t.pumpAndSettle();
        expect(s.bank.length, 1);
        await press(t, find.byKey(const ValueKey('evidence-A-null')));
        await press(
          t,
          find
              .textContaining('${entryById(r.goals.first.lab).title} · length')
              .last,
        );
        expect(s.aId, 'record-${r.studio}');
        expect(find.textContaining('PRIVATE'), findsNothing);
        final field = find.byKey(const Key('studio-evidence-claim'));
        await show(t, field);
        await t.enterText(field, 'A claim for ${r.studio}');
        await t.pumpAndSettle();
        await press(t, find.byKey(const Key('save-studio-evidence')));
        expect(s.dirty, false);
        expect(
          store.trials.length,
          count + 1,
          reason: 'Only the explicit synthetic notebook event adds a Trial',
        );
        expect(store.completed, isEmpty);
        expect(t.takeException(), isNull, reason: r.studio);
        await t.tap(find.byTooltip('Close studio investigation'));
        await t.pumpAndSettle();
      }
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Investigation panels fit 200% portrait, landscape and keyboard with real evidence cards',
    (t) async {
      final errorHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        debugPrint(details.toString());
        errorHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = errorHandler);
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetViewInsets);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = 2;
      for (final size in [const Size(320, 568), const Size(640, 320)]) {
        t.view.physicalSize = size;
        for (final r in studioEvidenceRoutes) {
          final s = await open(t, r.studio);
          if (s.bank.isEmpty) {
            await store.addTrial(
              fixture('layout-${r.studio}', lab: r.goals.first.lab),
            );
          }
          s.pick(false, 'layout-${r.studio}');
          s.choosePlan(r.correct);
          await s.save();
          await t.pumpAndSettle();
          final scroll = find
              .descendant(
                of: find.byKey(const Key('studio-evidence-scroll')),
                matching: find.byType(Scrollable),
              )
              .first;
          for (int i = 0; i < 15; i++) {
            await t.drag(scroll, const Offset(0, -200));
            await t.pumpAndSettle();
            expect(t.takeException(), isNull, reason: '${r.studio} $size');
          }
          final field = find.byKey(const Key('studio-evidence-reason'));
          await show(t, field);
          await t.tap(field);
          await t.pumpAndSettle();
          t.view.viewInsets = FakeViewPadding(
            bottom: size.height > 500 ? 250 : 150,
          );
          await t.pumpAndSettle();
          expect(t.takeException(), isNull, reason: '${r.studio} keyboard');
          t.view.resetViewInsets();
          FocusManager.instance.primaryFocus?.unfocus();
          await t.pumpAndSettle();
          await t.tap(find.byTooltip('Close studio investigation'));
          await t.pumpAndSettle();
        }
      }
      router.go('/');
      await t.pumpAndSettle();
    },
  );
}
