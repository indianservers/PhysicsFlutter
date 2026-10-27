import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/content/studio_investigations.dart';
import 'package:physics_atelier/features/overview/workspace.dart';
import 'package:physics_atelier/features/workbench/exploration_workbench.dart';
import 'package:physics_atelier/features/workbench/workbench.dart';

import 'app_test.dart' show notebook;

// Relative checks must remain meaningful for subatomic masses and charges.
double inputTolerance(double value) => value == 0 ? 1e-14 : value.abs() * 1e-8;

Future<void> openExploration(WidgetTester t) async {
  await t.tap(find.byTooltip('Lab options').last);
  await t.pumpAndSettle();
  await t.tap(find.text('Exploration workbench'));
  await t.pumpAndSettle();
}

Future<void> explorationTab(WidgetTester t, String name) async {
  await t.ensureVisible(find.text(name).last);
  await t.tap(find.text(name).last);
  await t.pumpAndSettle();
}

void main() {
  test('Each of 17 studios has ten distinct working entry points and all physical labs are covered', () {
    expect(studioInvestigations.length, 170);
    expect(studioInvestigations.map((v) => v.id).toSet().length, 170);
    for (var s = 0; s < 17; s++) {
      final items = studioInvestigations.where((v) => v.studio == s).toList();
      expect(items.length, 10);
      expect(items.map((v) => v.title).toSet().length, 10);
      for (final item in items) {
        expect(entryById(item.labId).studioIndex, s);
        if (s > 0) {
          expect(item.a, isNotEmpty);
          expect(item.b, isNotEmpty);
          expect(jsonEncode(item.a), isNot(jsonEncode(item.b)));
          expect(item.watch, isNotEmpty);
        } else {
          expect(item.overview, isNotEmpty);
        }
      }
    }
    expect(
      studioInvestigations
          .where((v) => v.studio > 0)
          .map((v) => v.labId)
          .toSet(),
      allEntries.where((v) => v.interactive).map((v) => v.id).toSet(),
    );
  });
  test('Atomic setup, undo redo, mode readiness and secants preserve scientific and private data', () {
    var state = <String, dynamic>{
      'parameters': {'x': .1, 'k': 50.0},
      'time': 0.0,
      'mode': 0,
      'model': 'test-source',
      'notes': 'PRIVATE ORIGINAL NOTE',
    };
    bool ready = true, fail = false;
    Map<String, double> params() =>
        Map<String, double>.from(state['parameters']);
    void change(String key, double v) {
      if (fail && key == 'k') throw StateError('Rejected');
      (state['parameters'] as Map)[key] = v;
    }

    final c = ExplorationController(
      controls: () => [
        InstrumentControl(
          'x',
          'Extension',
          'm',
          params()['x']!,
          0,
          1,
          (v) => change('x', v),
        ),
        if (state['mode'] == 0)
          InstrumentControl(
            'k',
            'Stiffness',
            'N/m',
            params()['k']!,
            1,
            100,
            (v) => change('k', v),
          ),
      ],
      readings: () => [
        InstrumentReading('force', '${params()['x']! * params()['k']!}', 'N'),
        InstrumentReading('region', params()['x']! < .35 ? '1' : '2'),
      ],
      configuration: () => state,
      restore: (value) {
        state = ExplorationController.clone(value);
        return true;
      },
      valid: () => ready,
      pause: () {},
    );
    final original = jsonEncode(state);
    fail = true;
    expect(c.apply({'x': .2, 'k': 60}), false);
    expect(jsonEncode(state), original);
    expect(c.canUndo, false);
    fail = false;
    expect(c.apply({'x': .2}), true);
    expect(c.undo(), true);
    expect(params()['x'], .1);
    expect(c.redo(), true);
    expect(params()['x'], .2);
    expect(c.restoreBaseline(), true);
    expect(jsonEncode(state), original);
    expect(c.undo(), true);
    expect(params()['x'], .2);
    expect(c.apply({'x': .3}), true);
    expect(c.canRedo, false);
    expect(c.captureState(false), true);
    expect(c.apply({'x': .4}), true);
    expect(c.captureState(true), true);
    expect(c.secant('force'), closeTo(50, 1e-9));
    expect(
      c.secant('region'),
      isNull,
      reason:
          'Category codes cannot be treated as measured scalar sensitivities',
    );
    state['time'] = 1.0;
    expect(c.captureState(true), true);
    expect(c.secant('force'), isNull);
    state['time'] = 0.0;
    state['mode'] = 1;
    expect(c.apply({'k': 40}), false);
    expect(params()['k'], 50);
    expect(c.captureState(true), true);
    expect(c.secant('force'), isNull);
    ready = false;
    final oldB = c.b;
    expect(c.captureState(true), false);
    expect(c.b, same(oldB));
    final shared = jsonEncode(c.sharedEvidence('s02-e08'));
    expect(shared, isNot(contains('PRIVATE ORIGINAL NOTE')));
    expect(shared, isNot(contains('notes')));
    expect(state['notes'], 'PRIVATE ORIGINAL NOTE');
    c.dispose();
  });
  testWidgets(
    'All 160 physical studio setups use real source controls and reversible history',
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
      var tested = 0;
      for (final entry in allEntries.where((v) => v.interactive)) {
        router.go('/lab/${entry.id}');
        await t.pumpAndSettle();
        final source = t.widget<InstrumentShell>(find.byType(InstrumentShell));
        final original = ExplorationController.clone(
          source.captureConfiguration!(),
        );
        await openExploration(t);
        final c = t
            .widget<ExplorationWorkbench>(find.byType(ExplorationWorkbench))
            .controller;
        final originalInputs = {
          for (final v in c.controls()) v.keyName: v.value,
        };
        for (final tool in studioInvestigations.where(
          (v) => v.labId == entry.id,
        )) {
          for (final setup in [tool.a, tool.b]) {
            expect(c.apply(setup), true, reason: '${tool.id}: ${c.feedback}');
            await t.pumpAndSettle();
            for (final v in setup.entries) {
              expect(
                c.control(v.key)!.value,
                closeTo(v.value, inputTolerance(v.value)),
                reason: tool.id,
              );
            }
            expect(
              c.captureState(false),
              source.canRecord(),
              reason: '${tool.id} readiness',
            );
            expect(c.undo(), true, reason: tool.id);
            await t.pumpAndSettle();
            expect(c.redo(), true, reason: tool.id);
            await t.pumpAndSettle();
            expect(c.restoreBaseline(), true, reason: tool.id);
            await t.pumpAndSettle();
            for (final v in originalInputs.entries) {
              expect(
                c.control(v.key)!.value,
                closeTo(v.value, inputTolerance(v.value)),
                reason: '${tool.id} full input restoration',
              );
            }
          }
          tested++;
        }
        await t.tap(find.byTooltip('Close exploration workbench'));
        await t.pumpAndSettle();
        expect(source.restoreConfiguration!(original), true);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: entry.id);
        debugPrint('STUDIO_SOURCE_CHECKED ${entry.id}');
      }
      expect(tested, 160);
      expect(store.trials, isEmpty);
      expect(store.completed, isEmpty);
      expect(
        store.preferences.getKeys().where((k) => k.startsWith('exploration:')),
        isEmpty,
      );
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'All ten overview discovery actions change actual validated tool state',
    (t) async {
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      for (final tool in studioInvestigations.where((v) => v.studio == 0)) {
        router.go('/lab/${tool.labId}?studioTool=${tool.id}');
        await t.pumpAndSettle();
        final state = t.state<OverviewWorkspaceState>(
          find.byType(OverviewWorkspace),
        );
        expect(state.activeStudioTool?.id, tool.id, reason: tool.id);
        final action = tool.overview;
        if (action.containsKey('query')) expect(state.query, action['query']);
        if (action['view'] == 'cards') expect(state.listView, true);
        if (action['view'] == 'map') expect(state.listView, false);
        if (action.containsKey('focus')) expect(state.focus, action['focus']);
        if (action.containsKey('path')) expect(state.pathId, action['path']);
        if (action.containsKey('stage')) expect(state.stage, action['stage']);
        if (action.containsKey('topic')) {
          expect(state.topic, 1);
          expect(state.question.studio, 1);
        }
        expect(t.takeException(), isNull, reason: tool.id);
      }
      expect(store.trials, isEmpty);
      expect(store.completed, isEmpty);
      expect(await store.readAttempts('s00-e05'), isEmpty);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Discovery previews do not apply a setup and common search, stepping, pinning and copy work',
    (t) async {
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      final tool = studioInvestigations.firstWhere((v) => v.labId == 's02-e08');
      router.go('/lab/s02-e08');
      await t.pumpAndSettle();
      final source = t.widget<InstrumentShell>(find.byType(InstrumentShell));
      final before = source
          .controls()
          .firstWhere((v) => v.keyName == 'extension')
          .value;
      router.go('/lab/s02-e08?studioTool=${tool.id}');
      await t.pumpAndSettle();
      final panel = t.widget<ExplorationWorkbench>(
        find.byType(ExplorationWorkbench),
      );
      expect(panel.tool?.id, tool.id);
      expect(
        panel.controller.control('extension')!.value,
        before,
        reason: 'Opening previews never apply presets',
      );
      final c = panel.controller;
      final controlsScroll = find
          .descendant(
            of: find.byKey(const Key('exploration-controls-scroll')),
            matching: find.byType(Scrollable),
          )
          .first;
      await t.scrollUntilVisible(
        find.byKey(const Key('exploration-setup-preview')),
        100,
        scrollable: controlsScroll,
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Preview studio setups'));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.byKey(const Key('exploration-apply-a')),
        100,
        scrollable: controlsScroll,
      );
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('exploration-apply-a')));
      await t.pumpAndSettle();
      await explorationTab(t, 'Compare');
      expect(c.captureState(false), true);
      await t.pumpAndSettle();
      await explorationTab(t, 'Controls');
      await t.scrollUntilVisible(
        find.byKey(const Key('exploration-apply-b')),
        100,
        scrollable: controlsScroll,
      );
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('exploration-apply-b')));
      await t.pumpAndSettle();
      for (final entry in tool.b.entries) {
        expect(
          c.control(entry.key)!.value,
          closeTo(entry.value, inputTolerance(entry.value)),
        );
      }
      expect(c.restoreBaseline(), true);
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.byKey(const Key('Search controls')),
        -100,
        scrollable: controlsScroll,
      );
      await t.enterText(find.byKey(const Key('Search controls')), 'extension');
      await t.pumpAndSettle();
      expect(find.text('1 of 2 current inputs'), findsOneWidget);
      final increase = find.byKey(const Key('exploration-increase-extension'));
      await t.scrollUntilVisible(
        increase.hitTestable(),
        150,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('exploration-controls-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await t.tap(increase);
      await t.pumpAndSettle();
      expect(c.control('extension')!.value, greaterThan(before));
      await explorationTab(t, 'Readings');
      final pin = find.byKey(const Key('exploration-pin-force'));
      await t.scrollUntilVisible(
        pin.hitTestable(),
        150,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('exploration-readings-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await t.tap(pin);
      await t.pumpAndSettle();
      expect(find.byTooltip('Unpin Force'), findsOneWidget);
      await explorationTab(t, 'Compare');
      expect(c.captureState(false), true);
      expect(c.apply({'extension': .15}), true);
      await t.pumpAndSettle();
      expect(c.captureState(true), true);
      expect(c.secant('force'), closeTo(50, 1e-7));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.byKey(const Key('exploration-secant-force')),
        100,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('exploration-compare-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await t.pumpAndSettle();
      expect(find.byKey(const Key('exploration-secant-force')), findsOneWidget);
      await explorationTab(t, 'Guide');
      final copy = find.byKey(const Key('exploration-copy'));
      await t.scrollUntilVisible(
        copy.hitTestable(),
        150,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('exploration-guide-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      String? copied;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = call.arguments['text'];
            }
            return null;
          });
      await t.tap(copy);
      await t.pumpAndSettle();
      expect(copied, contains('exploration-evidence-1.0'));
      expect(copied, isNot(contains('notes')));
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
      c.restoreBaseline();
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Close exploration workbench'));
      await t.pumpAndSettle();
      router.go('/');
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'Playback advances the actual model and temporary evidence survives apparatus access',
    (t) async {
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      router.go('/lab/s03-e06');
      await t.pumpAndSettle();
      await openExploration(t);
      final c = t
          .widget<ExplorationWorkbench>(find.byType(ExplorationWorkbench))
          .controller;
      expect(c.captureState(false), true);
      final initialTime = c.a!.time!;
      final run = find.byKey(const Key('exploration-run'));
      await t.scrollUntilVisible(
        run,
        100,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('exploration-controls-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await t.tap(run);
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 100));
      await t.tap(run);
      await t.pumpAndSettle();
      expect(c.captureState(true), true);
      expect(c.b!.time!, greaterThan(initialTime));
      expect(
        c.secant('speed'),
        isNull,
        reason: 'Different model times are not presented as input sensitivity',
      );
      final savedA = c.a;
      await t.tap(find.byTooltip('Close exploration workbench'));
      await t.pumpAndSettle();
      await openExploration(t);
      final reopened = t
          .widget<ExplorationWorkbench>(find.byType(ExplorationWorkbench))
          .controller;
      expect(reopened, same(c));
      expect(reopened.a, same(savedA));
      expect(store.trials, isEmpty);
      expect(store.completed, isEmpty);
      reopened.restoreBaseline();
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Close exploration workbench'));
      await t.pumpAndSettle();
      router.go('/');
      await t.pumpAndSettle();
    },
  );
}
