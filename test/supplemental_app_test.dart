import 'package:physics_atelier/features/supplemental/scene.dart';
import 'package:physics_atelier/features/advanced/scene.dart' show LabPlot;
import 'package:physics_atelier/features/lab_workspace/workspace.dart'
    show NumericInputDialog;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/core/physics/supplemental_labs.dart';
import 'package:physics_atelier/features/supplemental/workspace.dart';
import 'package:physics_atelier/features/workbench/workbench.dart';

import 'app_test.dart' show notebook;
import 'ui_navigation.dart';

void main() {
  testWidgets(
    'Every new lab manipulates, records and restores independently with graph and learning routes',
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
      for (final lab in supplementalLabs) {
        router.go('/lab/${lab.id}');
        await t.pumpAndSettle();
        final source = t.state<SupplementalWorkspaceState>(
          find.byType(SupplementalWorkspace),
        );
        var shell = t.widget<InstrumentShell>(find.byType(InstrumentShell));
        final original = jsonEncode(shell.captureConfiguration!());
        final c = shell.controls().first;
        c.change(
          (c.value + (c.value == c.max ? -1 : 1) * (c.max - c.min) * .01).clamp(
            c.min,
            c.max,
          ),
        );
        await t.pumpAndSettle();
        source.notes.text =
            'Independent ${lab.title} prediction and observation.';
        final painted =
            t
                    .widget<CustomPaint>(
                      find.byWidgetPredicate(
                        (w) =>
                            w is CustomPaint &&
                            w.painter is SupplementalPainter,
                      ),
                    )
                    .painter!
                as SupplementalPainter;
        expect(
          painted.parameters,
          source.parameters,
          reason: '${lab.id}: visible apparatus inputs',
        );
        expect(
          painted.state,
          source.state,
          reason: '${lab.id}: visible apparatus quantities',
        );
        expect(source.changed, true);
        expect(source.state, isNotEmpty, reason: lab.id);
        final snapshot = jsonDecode(
          jsonEncode(source.configuration()),
        ) as Map<String, dynamic>;
        await source.record();
        await t.pumpAndSettle();
        final trial = store.trials.last;
        expect(trial.labId, lab.id);
        expect(trial.note, source.notes.text);
        expect(trial.value, source.state[lab.quantity]);
        expect(trial.model, supplementalVersion);
        await source.persist();
        expect(await store.readSession(lab.id), snapshot);
        shell = t.widget<InstrumentShell>(find.byType(InstrumentShell));
        shell.reset();
        await t.pumpAndSettle();
        expect(source.parameters, lab.defaults);
        expect(store.trials.where((t) => t.labId == lab.id).length, 1);
        expect(shell.restoreConfiguration!(snapshot), true);
        await t.pumpAndSettle();
        expect(source.configuration(), snapshot);
        expect(jsonEncode(source.configuration()), isNot(original));
        final beforeBad = jsonEncode(source.configuration());
        expect(
          source.restore({
            ...snapshot,
            'parameters': {'bad': double.nan},
          }),
          false,
        );
        expect(jsonEncode(source.configuration()), beforeBad);
        expect(source.restore({...snapshot, 'guide': 'corrupt'}), false);
        expect(jsonEncode(source.configuration()), beforeBad);
        shell = t.widget<InstrumentShell>(find.byType(InstrumentShell));
        shell.selectSection(2);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: '${lab.id} graph');
        await chooseSection(t, 'Learn');
        expect(source.section, 0);
        expect(
          find.byKey(const Key('learn-explore-apparatus')),
          findsOneWidget,
        );
        expect(t.takeException(), isNull, reason: lab.id);
        await chooseSection(t, 'Formulas');
        expect(find.text('Formulas'), findsOneWidget);
        expect(t.takeException(), isNull, reason: lab.id);
        await chooseSection(t, 'Experiment');
        shell = t.widget<InstrumentShell>(find.byType(InstrumentShell));
        if (lab.dynamicModel) {
          shell.play();
          await t.pump(const Duration(milliseconds: 100));
          await t.pump(const Duration(milliseconds: 300));
          expect(source.time, greaterThan(0));
          shell.pause();
        }
        router.go('/');
        await t.pumpAndSettle();
        router.go('/lab/${lab.id}');
        await t.pumpAndSettle();
        final reopened = t.state<SupplementalWorkspaceState>(
          find.byType(SupplementalWorkspace),
        );
        expect(reopened.running, false);
        expect(reopened.notes.text, trial.note);
        expect(
          reopened.parameters,
          Map<String, double>.from(snapshot['parameters']),
        );
        expect(t.takeException(), isNull, reason: '${lab.id} reopen');
      }
      expect(store.trials.length, 20);
      expect(store.completed, isEmpty);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Invalid rolling inputs cannot be recorded and background or covered routes pause playback',
    (t) async {
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      router.go('/lab/s02-e07');
      await t.pumpAndSettle();
      final source = t.state<SupplementalWorkspaceState>(
        find.byType(SupplementalWorkspace),
      );
      source.change('friction', 0);
      await t.pumpAndSettle();
      expect(source.state, isEmpty);
      expect(
        t.widget<InstrumentShell>(find.byType(InstrumentShell)).canRecord(),
        false,
      );
      await source.record();
      expect(store.trials, isEmpty);
      t.widget<InstrumentShell>(find.byType(InstrumentShell)).selectSection(2);
      await t.pumpAndSettle();
      expect(find.textContaining('Insufficient static friction'), findsWidgets);
      expect(t.takeException(), isNull);
      source.change('friction', .5);
      source.play();
      await t.pump(const Duration(milliseconds: 50));
      router.push('/settings');
      await t.pumpAndSettle();
      expect(source.running, false);
      router.pop();
      await t.pumpAndSettle();
      expect(source.running, false);
      await source.checkInvestigation();
      expect(store.completed, isEmpty);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Completion needs a current prediction and trial; a direct pause updates the visible playback action',
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
      final source = t.state<SupplementalWorkspaceState>(
        find.byType(SupplementalWorkspace),
      );
      source.change('extension', .1);
      source.notes.text =
          'Force rises linearly while energy rises quadratically.';
      await source.record();
      await source.checkInvestigation();
      expect(store.completed, isEmpty);
      source.predict();
      await t.pumpAndSettle();
      expect(find.byType(NumericInputDialog), findsOneWidget);
      await t.enterText(
        find.descendant(
          of: find.byType(NumericInputDialog),
          matching: find.byType(TextField),
        ),
        source.state['force']!.toString(),
      );
      await t.tap(find.text('Apply'));
      await t.pumpAndSettle();
      await source.checkInvestigation();
      expect(store.completed, contains('s02-e08'));
      expect((await store.readSession('s02-e08'))!['notes'], source.notes.text);
      router.go('/lab/s03-e06');
      await t.pumpAndSettle();
      final falling = t.state<SupplementalWorkspaceState>(
        find.byType(SupplementalWorkspace),
      );
      falling.play();
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));
      expect(find.text('Pause'), findsOneWidget);
      falling.pause();
      await t.pump();
      expect(find.text('Run Experiment'), findsOneWidget);
      expect(falling.running, false);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Live apparatus and graph respond to controls and model time while their panes remain open',
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
      final falling = t.state<SupplementalWorkspaceState>(
        find.byType(SupplementalWorkspace),
      );
      SupplementalPainter apparatus() =>
          t
                  .widget<CustomPaint>(
                    find.byWidgetPredicate(
                      (w) =>
                          w is CustomPaint && w.painter is SupplementalPainter,
                    ),
                  )
                  .painter!
              as SupplementalPainter;
      final initialHeight = apparatus().state['height']!;
      falling.play();
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));
      expect(apparatus().state['height'], lessThan(initialHeight));
      expect(apparatus().time, falling.time);
      falling.pause();
      router.go('/lab/s02-e08');
      await t.pumpAndSettle();
      final spring = t.state<SupplementalWorkspaceState>(
        find.byType(SupplementalWorkspace),
      );
      spring.change('extension', .12);
      await t.pumpAndSettle();
      expect(apparatus().state['force'], 6);
      expect(apparatus().parameters['extension'], .12);
      t.widget<InstrumentShell>(find.byType(InstrumentShell)).selectSection(2);
      await t.pumpAndSettle();
      LabPlot plot() =>
          t
                  .widget<CustomPaint>(
                    find.byWidgetPredicate(
                      (w) => w is CustomPaint && w.painter is LabPlot,
                    ),
                  )
                  .painter!
              as LabPlot;
      expect(plot().data.last['force'], 10);
      spring.change('stiffness', 100);
      await t.pumpAndSettle();
      expect(plot().data.last['force'], 20);
      expect(plot().cursor, 144);
      expect(t.takeException(), isNull);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
}
