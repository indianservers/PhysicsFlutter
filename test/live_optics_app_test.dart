import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/core/physics/live_optics.dart';
import 'package:physics_atelier/core/rendering/optics_assets.dart';
import 'package:physics_atelier/core/rendering/materials.dart';
import 'package:physics_atelier/features/optics_live/workspace.dart';
import 'package:physics_atelier/features/optics_live/scene.dart';

import 'app_test.dart' show notebook;

void main() {
  testWidgets(
    'Ten live optics rigs render and respond to objects, controls, tabs and records',
    (t) async {
      t.view.physicalSize = const Size(1280, 820);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.runAsync(() async {
        final font = FontLoader('HomeManrope')
          ..addFont(rootBundle.load('assets/home/Manrope.ttf'));
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await font.load();
        await icons.load();
        await LabMaterials.initialize();
        await OpticsAssets.initialize();
      });
      final store = await notebook(), boundary = GlobalKey();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: RepaintBoundary(key: boundary, child: const PhysicsApp()),
        ),
      );
      await t.pumpAndSettle();
      const gestures = {
        's09-e00': ['mirror', 'angle', 0.0, 55.0],
        's09-e01': ['block', 'n2', 55.0, 0.0],
        's09-e02': ['object', 'u', 40.0, 0.0],
        's09-e03': ['object', 'u', 40.0, 0.0],
        's09-e04': ['slit', 'aperture', 40.0, 0.0],
        's09-e05': ['slit', 'aperture', 40.0, 0.0],
        's09-e06': ['analyzer', 'angle', 35.0, 20.0],
        's09-e07': ['prism', 'angle', 45.0, 0.0],
        's09-e08': ['film', 'thickness', 0.0, 40.0],
        's09-e09': ['eyepiece', 'separation', 40.0, 0.0],
      };
      for (final def in opticsDefinitions) {
        router.go('/lab/${def.id}');
        await t.pumpAndSettle();
        expect(find.byType(LiveOpticsWorkspace), findsOneWidget);
        expect(find.byType(InteractiveOpticsScene), findsOneWidget);
        expect(
          find.byType(Image),
          findsNothing,
          reason: 'never show the mockup',
        );
        expect(t.takeException(), isNull, reason: '${def.title} initial');
        await t.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('screenshots/optics-live/${def.id}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        final state = t.state<LiveOpticsWorkspaceState>(
          find.byType(LiveOpticsWorkspace),
        );
        final gesture = gestures[def.id]!,
            key = gesture[1] as String,
            before = state.model.p[key]!;
        final target = find.byKey(Key('optics-object-${gesture[0]}'));
        final offset = Offset(gesture[2] as double, gesture[3] as double);
        if (def.kind == 6) {
          await t.dragFrom(
            t.getCenter(target) + const Offset(-35, -30),
            offset,
          );
        } else {
          await t.drag(target, offset);
        }
        await t.pumpAndSettle();
        expect(
          state.model.p[key],
          isNot(before),
          reason: '${def.title} direct apparatus gesture',
        );
        expect(t.takeException(), isNull, reason: '${def.title} gesture');
        final slider = find.byKey(Key('optics-control-${def.primary.key}'));
        await t.drag(slider, const Offset(25, 0));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        for (final tab in [
          'workspace-graph',
          'workspace-inspect',
          'workspace-results',
          'workspace-scene',
        ]) {
          await t.tap(find.byKey(Key(tab)));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull, reason: '${def.title} $tab');
        }
        if (state.model.observation == null) {
          final count = store.trials.length;
          await state.record();
          expect(
            store.trials.length,
            count,
            reason: 'undefined response must not become a numeric trial',
          );
          state.reset();
          await t.pumpAndSettle();
        }
        await state.record();
        await t.pumpAndSettle();
        final saved = store.trials.last;
        expect(saved.model, liveOpticsVersion);
        expect(saved.labId, def.id);
        expect(saved.configuration['p'], state.model.p);
        expect(state.model.restore(saved.configuration), true);
      }
      // Phone portrait and landscape both keep touch controls reachable.
      for (final size in [const Size(720, 1280), const Size(1280, 720)]) {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 2;
        router.go('/lab/s09-e01');
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: 'phone $size');
      }
      router.go('/');
      await t.pumpAndSettle();
    },
  );
}
