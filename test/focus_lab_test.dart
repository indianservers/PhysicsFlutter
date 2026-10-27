import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/core/physics/electromagnetism.dart';
import 'package:physics_atelier/features/workbench/focus_lab.dart';

import 'app_test.dart' show notebook;

Future<FocusLabSession> open(WidgetTester t, String id) async {
  router.go('/lab/$id');
  await t.pumpAndSettle();
  await t.tap(find.byTooltip('Lab options').last);
  await t.pumpAndSettle();
  await t.tap(find.text('Interactive challenge'));
  await t.pumpAndSettle();
  return t.widget<FocusLabPanel>(find.byType(FocusLabPanel)).session;
}

Future<void> press(WidgetTester t, String text) async {
  final finder = find.text(text).last;
  await t.ensureVisible(finder);
  await t.pumpAndSettle();
  await t.tap(finder);
  await t.pumpAndSettle();
}

Future<void> close(WidgetTester t) async {
  await t.tap(find.byTooltip('Close interactive experience'));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final font = FontLoader('HomeManrope')
      ..addFont(rootBundle.load('assets/home/Manrope.ttf'));
    await font.load();
  });
  test('Circuit paths respect switch and meter physics; existing solver diagnoses conflicts', () {
    final g = CircuitGraph.example(0);
    expect(circuitPath(g, 'B1:a', 'B1:b'), isNotEmpty);
    expect(solveCircuit(g).valid, true);
    g.parts.firstWhere((p) => p.id == 'S1').closed = false;
    // The battery itself still connects its terminals. An isolated meter
    // terminal must not obtain a conducting path through its ideal input.
    final meter = CircuitGraph([CircuitPart('V', 'voltmeter')], []);
    expect(circuitPath(meter, 'V:a', 'V:b'), isEmpty);
    final sw = CircuitGraph([CircuitPart('S', 'switch', closed: false)], []);
    expect(circuitPath(sw, 'S:a', 'S:b'), isEmpty);
    sw.parts.first.closed = true;
    expect(circuitPath(sw, 'S:a', 'S:b'), ['S:a', 'S:b']);
    final short = CircuitGraph.example(0)..wires.add(['B1:a', 'B1:b']);
    expect(solveCircuit(short).valid, false);
    expect(solveCircuit(short).message, contains('short'));
  });
  testWidgets(
    'Ten challenges use live source models and preserve notebook observations',
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
      for (final id in focusLabs.keys) {
        debugPrint('FOCUS_SOURCE_START $id');
        final s = await open(t, id);
        final originalConfig = s.configuration();
        final noteKey = originalConfig.containsKey('notes') ? 'notes' : 'note';
        expect(
          s.restore({...originalConfig, noteKey: 'Existing learner note'}),
          true,
        );
        await t.pumpAndSettle();
        expect(find.text(focusLabs[id]!), findsOneWidget);
        if (const bool.fromEnvironment('FOCUS_VISUALS')) {
          final boundary = t.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('focus-surface')),
          );
          await t.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final directory = Directory('Target UI/topTenUXScreens')
              ..createSync(recursive: true);
            File('${directory.path}/$id.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        switch (id) {
          case 's04-e01':
            s.prediction = s.value('ax')!;
            s.predictionY = s.value('ay')!;
            await press(t, 'Compare with model');
            expect(s.feedback, contains('discrepancy 0'));
            expect(s.change('force', -6), true);
            await t.pumpAndSettle();
            expect(s.stale, true);
            expect(s.value('ax'), closeTo(-6 / s.input('m'), 1e-10));
            break;
          case 's05-e03':
            await press(t, 'Record a new run');
            await t.pump(const Duration(milliseconds: 400));
            s.stopReplay();
            await t.pumpAndSettle();
            expect(s.frames.length, greaterThan(1));
            final total =
                s.frames.first['K']! +
                s.frames.first['U']! +
                s.frames.first['loss']!;
            for (final r in s.frames) {
              expect(r['K']! + r['U']! + r['loss']!, closeTo(total, 1e-4));
            }
            final sourceTime = s.value('t');
            s.update(() => s.frame = 0);
            await t.pumpAndSettle();
            expect(
              s.value('t'),
              sourceTime,
              reason: 'Replay must not change apparatus time',
            );
            break;
          case 's10-e04':
            final before = solveCircuit(s.circuit).currents['B1'];
            s.trace('R1:a');
            s.trace('R1:b');
            await t.pumpAndSettle();
            expect(s.tracedPath, isNotEmpty);
            await press(t, 'Open S1');
            expect(
              s.circuit.parts.firstWhere((p) => p.id == 'S1').closed,
              false,
            );
            await press(t, 'Undo switch edit');
            expect(
              solveCircuit(s.circuit).currents['B1'],
              closeTo(before!, 1e-12),
            );
            break;
          case 's08-e00':
            final f = s.input('frequency'), w = s.input('wavelength');
            expect(s.value('waveSpeed'), closeTo(f * w, 1e-12));
            await press(t, 'Mark next crest at A');
            expect(s.crestStart, greaterThanOrEqualTo(s.value('t')!));
            s.update(() => s.probeB = .8);
            await t.pumpAndSettle();
            expect(t.takeException(), isNull);
            break;
          case 's09-e02':
            s.rayParallel = math.atan(-s.input('height') / s.value('focal')!);
            s.rayCentral = math.atan(-s.input('height') / s.input('u'));
            await press(t, 'Reveal model rays');
            expect(s.feedback, contains('0.0000 rad'));
            s.change('u', .05);
            await t.pumpAndSettle();
            s.reveal();
            await t.pumpAndSettle();
            expect(s.feedback, contains('virtual image'));
            s.change('u', s.input('focal'));
            await t.pumpAndSettle();
            s.reveal();
            await t.pumpAndSettle();
            expect(s.feedback, contains('infinity'));
            break;
          case 's13-e01':
            s.change('probe', 0);
            await t.pumpAndSettle();
            expect(s.value('probeTemperature'), s.input('leftT'));
            s.change('probe', 1);
            await t.pumpAndSettle();
            expect(s.value('probeTemperature'), s.input('rightT'));
            break;
          case 's11-e04':
            final emf = s.value('emf')!, velocity = s.input('velocity');
            s.change('velocity', -velocity);
            await t.pumpAndSettle();
            expect(s.value('emf'), closeTo(-emf, emf.abs() * 1e-8));
            expect(s.value('current'), 0);
            s.change('closed', 1);
            await t.pumpAndSettle();
            expect(
              s.value('current'),
              closeTo(s.value('emf')! / s.input('resistance'), 1e-12),
            );
            break;
          case 's14-e02':
            s.prediction = s.value('equilibriumFraction')!;
            await press(t, 'Test waterline prediction');
            expect(s.feedback, contains('0.0 percentage points'));
            s.change('objectDensity', 2000);
            await t.pumpAndSettle();
            s.reveal();
            await t.pumpAndSettle();
            expect(s.value('equilibriumFraction'), 1);
            expect(s.feedback, contains('sinks'));
            break;
          case 's01-e01':
            s.graduation = (s.value('fraction')! / .0001).round();
            await press(t, 'Reveal scale breakdown');
            expect(s.feedback, contains('coincident division ${s.graduation}'));
            s.change('zero', .0003);
            await t.pumpAndSettle();
            s.reveal();
            await t.pumpAndSettle();
            expect(
              s.value('length'),
              closeTo(s.value('main')! + s.value('fraction')! - .0003, 1e-12),
            );
            break;
          case 's15-e01':
            s.change('wavelength', 800e-9);
            await t.pumpAndSettle();
            await press(t, 'Capture threshold trial');
            expect(s.trials.last['emitting'], 0);
            s.change('wavelength', 200e-9);
            await t.pumpAndSettle();
            await press(t, 'Capture threshold trial');
            expect(s.trials.last['emitting'], 1);
            final energy = s.value('maximumKineticEnergy');
            s.change('intensity', 0);
            await t.pumpAndSettle();
            expect(s.value('maximumKineticEnergy'), energy);
            expect(s.value('current'), 0);
            await press(t, 'Capture threshold trial');
            expect(s.feedback, contains('bracket'));
            while (s.trials.length < 6) {
              expect(s.capturePhoto(), true);
            }
            expect(s.capturePhoto(), false);
            final phi = s.input('workFunction');
            s.update(() => s.trials.removeLast());
            s.change('workFunction', phi * 1.1);
            await t.pumpAndSettle();
            expect(s.capturePhoto(), false);
            expect(s.feedback, contains('Work function changed'));
            break;
        }
        expect(t.takeException(), isNull, reason: id);
        expect(
          s.configuration()[noteKey],
          'Existing learner note',
          reason: '$id retains notes',
        );
        await close(t);
        // Evidence survives closing the panel during the same lab visit.
        await t.tap(find.byTooltip('Lab options').last);
        await t.pumpAndSettle();
        await t.tap(find.text('Interactive challenge'));
        await t.pumpAndSettle();
        expect(t.widget<FocusLabPanel>(find.byType(FocusLabPanel)).session, s);
        await close(t);
      }
      expect(store.trials, isEmpty);
      expect(store.completed, isEmpty);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Drag gestures and button alternatives update predictions and real probe controls',
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
      for (final id in [
        's04-e01',
        's08-e00',
        's09-e02',
        's13-e01',
        's11-e04',
        's14-e02',
      ]) {
        final s = await open(t, id);
        final canvas = find
            .descendant(
              of: find.byType(FocusLabPanel),
              matching: find.byWidgetPredicate(
                (w) => w is GestureDetector && w.onPanDown != null,
              ),
            )
            .first;
        await t.ensureVisible(canvas);
        await t.pumpAndSettle();
        await t.drag(canvas, const Offset(45, -20));
        await t.pumpAndSettle();
        switch (id) {
          case 's04-e01':
            expect(s.prediction, isNot(0));
            await press(t, 'Increase Predicted ax');
            break;
          case 's08-e00':
            expect(s.probeA != .3 || s.probeB != .9, true);
            await press(t, 'Increase Probe A position / m');
            break;
          case 's09-e02':
            expect(s.rayParallel, isNot(0));
            await press(t, 'Increase Parallel ray angle / rad');
            break;
          case 's13-e01':
            expect(s.input('probe'), isNot(.5));
            await press(t, 'Increase Probe position / length');
            break;
          case 's11-e04':
            expect(s.input('initialZ'), isNot(-.15));
            await press(t, 'Increase Initial axial source position');
            break;
          case 's14-e02':
            expect(s.prediction, isNot(0));
            await press(t, 'Increase Predicted submerged fraction');
            break;
        }
        expect(t.takeException(), isNull, reason: id);
        await close(t);
      }
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'All challenge content fits narrow portrait and short landscape at 200% text',
    (t) async {
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      for (final size in [const Size(320, 568), const Size(640, 320)]) {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = 2;
        for (final id in focusLabs.keys) {
          final s = await open(t, id);
          if (id == 's05-e03') {
            s.startReplay();
            await t.pump(const Duration(milliseconds: 100));
            s.stopReplay();
          }
          if (id == 's15-e01') {
            for (int i = 0; i < 6; i++) {
              s.capturePhoto();
            }
          }
          if (id == 's10-e04') {
            s.trace('B1:a');
            s.trace('L1:b');
          }
          s.reveal();
          await t.pumpAndSettle();
          final scroll = find
              .descendant(
                of: find.byType(FocusLabPanel),
                matching: find.byType(Scrollable),
              )
              .first;
          for (int i = 0; i < 8; i++) {
            await t.drag(scroll, const Offset(0, -220));
            await t.pumpAndSettle();
            expect(t.takeException(), isNull, reason: '$id $size');
          }
          await close(t);
        }
      }
      t.view.resetPhysicalSize();
      t.view.resetDevicePixelRatio();
      t.platformDispatcher.clearTextScaleFactorTestValue();
      router.go('/');
      await t.pumpAndSettle();
    },
  );
}
