import 'package:flutter/material.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/features/studio/studio_mission.dart';
import 'package:physics_atelier/features/workbench/workbench.dart';

import 'app_test.dart' show notebook;

Future<void> press(WidgetTester t, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final list = find.byKey(const Key('studio-mission-scroll'));
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
  await t.tap(finder);
  await t.pumpAndSettle();
}

Future<StudioMissionSession> openMission(WidgetTester t, String id) async {
  router.go('/studio/$id');
  await t.pumpAndSettle();
  await press(t, find.byKey(const Key('studio-mission-launch')));
  return t.widget<StudioMissionPanel>(find.byType(StudioMissionPanel)).session;
}

void main() {
  setUpAll(() async {
    final font = FontLoader('HomeManrope')
      ..addFont(rootBundle.load('assets/home/Manrope.ttf'));
    await font.load();
  });
  test('Ten ranked studios have distinct activities and twenty valid in-studio lab links', () {
    expect(priorityStudioMissions.length, 10);
    expect(priorityStudioMissions.map((m) => m.studio).toSet().length, 10);
    expect(priorityStudioMissions.map((m) => m.title).toSet().length, 10);
    for (final m in priorityStudioMissions) {
      expect(m.why, isNotEmpty);
      expect(m.limits, isNotEmpty);
      expect(m.labs.length, 2);
      for (final id in m.labs) {
        expect(entryById(id).interactive, true);
        expect(studios[entryById(id).studioIndex].id, m.studio);
      }
      final s = StudioMissionSession(m);
      for (final p in m.inputs) {
        expect(s.change(p.key, double.nan), false);
        expect(s.change(p.key, p.min - 1), false);
        expect(s.change('unknown', 0), false);
        for (final v in [p.min, p.max, p.initial]) {
          expect(s.change(p.key, v), true);
          expect(
            s.readings.values.every((x) => x.isFinite),
            true,
            reason: '${m.studio}/${p.key}/$v',
          );
        }
      }
      s.predict('invalid');
      s.reveal();
      expect(s.revealed, false);
      s.predict(s.answer);
      s.reveal();
      expect(s.revealed, true);
      expect(s.explanation, isNotEmpty);
      s.change(m.inputs.first.key, m.inputs.first.max);
      expect(s.revealed, false);
      expect(s.prediction, isNull);
      s.reset();
      expect(s.values, {for (final p in m.inputs) p.key: p.initial});
      expect(s.mode, 0);
      s.dispose();
    }
  });
  test(
    'Every scientific classification and singular lens limit is correct',
    () {
      StudioMissionSession get(String id) =>
          StudioMissionSession(missionForStudio(id)!);
      final measure = get('s01');
      measure.change('gap', .01);
      measure.change('q', 1);
      expect(measure.answer, 'Below one division');
      measure.change('gap', 1);
      expect(measure.answer, 'At least one division');
      final lever = get('s02');
      expect(lever.answer, 'Balanced');
      lever.change('mass', 5);
      expect(lever.answer, 'Left descends');
      lever.change('mass', .5);
      expect(lever.answer, 'Right descends');
      final motion = get('s03');
      motion.change('t', 2);
      expect(motion.answer, 'Stopped');
      expect(motion.readings['Position (m)'], 2);
      motion.change('t', 3);
      expect(motion.answer, 'Backward');
      motion.change('t', 1);
      expect(motion.answer, 'Forward');
      final force = get('s04');
      force.change('left', 6);
      expect(force.answer, 'Zero');
      force.change('left', 10);
      expect(force.answer, 'Left');
      force.change('left', 0);
      expect(force.answer, 'Right');
      expect(force.readings['Acceleration (m/s²)'], 3);
      final energy = get('s05');
      for (final fraction in [0.0, .5, 1.0]) {
        energy.change('retained', fraction);
        final r = energy.readings;
        expect(
          r['Kinetic energy (J)']! + r['Dissipated energy (J)']!,
          closeTo(r['Input gravitational energy (J)']!, 1e-12),
        );
        expect(
          energy.answer,
          fraction == 0
              ? 'Dissipated'
              : fraction == .5
              ? 'Equal shares'
              : 'Kinetic',
        );
      }
      final circuit = get('s10');
      expect(circuit.answer, 'R2');
      expect(
        circuit.readings['Source current magnitude (A)'],
        closeTo(.2, 1e-10),
      );
      circuit.selectMode(1);
      expect(circuit.answer, 'R1');
      expect(
        circuit.readings['Source current magnitude (A)'],
        closeTo(.9, 1e-10),
      );
      circuit.change('r2', 10);
      expect(circuit.answer, 'Equal power');
      final wave = get('s08');
      expect(wave.scrubWaveTime(double.nan), false);
      expect(wave.scrubWaveTime(3), false);
      expect(wave.scrubWaveTime(1), true);
      expect(wave.waveTime, 1);
      expect(wave.answer, 'Same speed');
      wave.change('w', 1);
      expect(wave.answer, 'Faster');
      wave.change('w', .1);
      expect(wave.answer, 'Slower');
      final heat = get('s13');
      heat.change('k', 50);
      expect(heat.answer, 'Equal rate');
      heat.change('k', 205);
      expect(heat.answer, 'Rod A');
      heat.change('k', 1);
      expect(heat.answer, 'Rod B');
      final lens = get('s09');
      expect(lens.answer, 'Real');
      lens.change('u', .1);
      expect(lens.answer, 'At infinity');
      expect(lens.readings.containsKey('Signed image distance (m)'), false);
      lens.change('u', .05);
      expect(lens.answer, 'Virtual');
      lens.change('u', 1);
      lens.selectMode(1);
      expect(lens.answer, 'Virtual');
      final flux = get('s11');
      for (final item in [
        (0.0, 'Positive'),
        (90.0, 'Zero'),
        (180.0, 'Negative'),
      ]) {
        flux.change('angle', item.$1);
        expect(flux.answer, item.$2);
      }
      for (final s in [
        measure,
        lever,
        motion,
        force,
        energy,
        circuit,
        wave,
        heat,
        lens,
        flux,
      ]) {
        s.dispose();
      }
    },
  );
  testWidgets(
    'All ten studio activities predict, drag, reset, retain evidence and open both real labs',
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
      for (final m in priorityStudioMissions) {
        final s = await openMission(t, m.studio);
        if (const bool.fromEnvironment('STUDIO_MISSION_VISUALS')) {
          final boundary = t.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('studio-mission-surface')),
          );
          await t.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final directory = Directory('Target UI/priorityStudioScreens')
              ..createSync(recursive: true);
            File('${directory.path}/${m.studio}.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        final gesture = find
            .descendant(
              of: find.byType(StudioMissionPanel),
              matching: find.byWidgetPredicate(
                (w) => w is GestureDetector && w.onPanStart != null,
              ),
            )
            .first;
        await t.ensureVisible(gesture);
        await t.pumpAndSettle();
        final before = Map.of(s.values);
        await t.drag(gesture, const Offset(45, 0));
        await t.pumpAndSettle();
        expect(s.values, isNot(before));
        final input = m.inputs.first;
        final beforeButton = s.v(input.key);
        await press(t, find.text('Increase ${input.label}'));
        expect(s.v(input.key), greaterThanOrEqualTo(beforeButton));
        if (m.studio == 's10') {
          await press(t, find.widgetWithText(ChoiceChip, 'Parallel'));
          expect(s.mode, 1);
        }
        if (m.studio == 's09') {
          await press(t, find.widgetWithText(ChoiceChip, 'Diverging'));
          expect(s.mode, 1);
        }
        if (m.studio == 's08') {
          final time = find.byKey(const Key('mission-wave-time'));
          await press(t, time);
          await t.drag(time, const Offset(30, 0));
          await t.pumpAndSettle();
          expect(s.waveTime, isNot(.25));
        }
        await press(t, find.widgetWithText(ChoiceChip, s.answer));
        await press(t, find.byKey(const Key('mission-reveal')));
        expect(s.revealed, true);
        expect(find.byKey(const Key('mission-feedback')), findsOneWidget);
        await t.tap(find.byTooltip('Close studio activity'));
        await t.pumpAndSettle();
        await press(t, find.byKey(const Key('studio-mission-launch')));
        expect(
          t.widget<StudioMissionPanel>(find.byType(StudioMissionPanel)).session,
          s,
        );
        expect(s.revealed, true);
        await press(t, find.text('Reset studio preview'));
        expect(s.revealed, false);
        expect(s.prediction, isNull);
        for (int i = 0; i < 2; i++) {
          await press(t, find.byKey(Key('mission-lab-$i')));
          expect(
            t.widget<InstrumentShell>(find.byType(InstrumentShell)).id,
            m.labs[i],
          );
          router.pop();
          await t.pumpAndSettle();
          await press(t, find.byKey(const Key('studio-mission-launch')));
        }
        await t.tap(find.byTooltip('Close studio activity'));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: m.studio);
      }
      expect(store.trials, isEmpty);
      expect(store.completed, isEmpty);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'All seventeen studio pages and ten activities fit small portrait and short landscape at 200% text',
    (t) async {
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
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = 2;
      for (final size in [const Size(320, 568), const Size(640, 320)]) {
        t.view.physicalSize = size;
        for (final studio in studios) {
          router.go('/studio/${studio.id}');
          await t.pumpAndSettle();
          final mission = missionForStudio(studio.id);
          expect(
            find.byKey(const Key('studio-mission-launch')),
            mission == null ? findsNothing : findsOneWidget,
          );
          if (mission != null) {
            await press(t, find.byKey(const Key('studio-mission-launch')));
            final s = t
                .widget<StudioMissionPanel>(find.byType(StudioMissionPanel))
                .session;
            s.predict(s.mission.choices.first);
            s.reveal();
            await t.pumpAndSettle();
            final scroll = find
                .descendant(
                  of: find.byKey(const Key('studio-mission-scroll')),
                  matching: find.byType(Scrollable),
                )
                .first;
            for (int i = 0; i < 12; i++) {
              await t.drag(scroll, const Offset(0, -220));
              await t.pumpAndSettle();
              expect(t.takeException(), isNull, reason: '${studio.id} $size');
            }
            await t.tap(find.byTooltip('Close studio activity'));
            await t.pumpAndSettle();
          }
          expect(t.takeException(), isNull, reason: studio.id);
        }
      }
      router.go('/');
      await t.pumpAndSettle();
    },
  );
}
