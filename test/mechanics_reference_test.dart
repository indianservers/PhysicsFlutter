import 'package:physics_atelier/core/rendering/apparatus_sprites.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/features/workbench/mechanics_reference_lab.dart';
import 'package:physics_atelier/core/rendering/interactive_mechanics.dart';
import 'package:physics_atelier/core/rendering/materials.dart';
import 'package:physics_atelier/features/workbench/workbench.dart';

import 'app_test.dart' show notebook;

void main() {
  testWidgets(
    'Ten mechanics references render and keep real controls and tabs',
    (t) async {
      t.view.physicalSize = const Size(720, 1280);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.runAsync(() async {
        final textFont = FontLoader('HomeManrope')
          ..addFont(rootBundle.load('assets/home/Manrope.ttf'));
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await LabMaterials.initialize();
        await ApparatusSprites.initialize();
        await textFont.load();
        await icons.load();
      });
      final store = await notebook();
      final boundary = GlobalKey();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: RepaintBoundary(key: boundary, child: const PhysicsApp()),
        ),
      );
      await t.pumpAndSettle();
      for (final id in mechanicsReferences.keys) {
        router.go('/lab/$id');
        await t.pumpAndSettle();
        expect(find.byType(MechanicsReferenceLab), findsOneWidget, reason: id);
        expect(t.takeException(), isNull, reason: '$id initial layout');
        await t.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('screenshots/mechanics-interactive/$id.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        final shell = t.widget<InstrumentShell>(find.byType(InstrumentShell));

        expect(
          find.byType(Image),
          findsNothing,
          reason: '$id never displays a mockup',
        );
        expect(find.byType(InteractiveMechanics), findsOneWidget);
        const actions = {
          's02-e00': ['crate', 'x0'],
          's04-e01': ['cart', 'x0'],
          's02-e02': ['pulleyA', 'release'],
          's02-e03': ['leverA', 'r1'],
          's02-e04': ['pointA', 'x0'],
          's02-e05': ['velocityA', 'v0'],
          's02-e06': ['diskRadius', 'radius'],
          's02-e07': ['rolling', 'start'],
          's02-e08': ['spring', 'extension'],
          's02-e09': ['tensile', 'force'],
        };
        final action = actions[id]!;
        final old = shell
            .controls()
            .firstWhere((c) => c.keyName == action[1])
            .value;
        await t.drag(
          find.byKey(Key('apparatus-handle-${action[0]}')),
          ['s02-e02', 's02-e08', 's02-e09'].contains(id)
              ? const Offset(0, 44)
              : const Offset(44, 0),
        );
        await t.pump(const Duration(milliseconds: 160));
        shell.pause();
        await t.pumpAndSettle();
        final changed = t.widget<InstrumentShell>(find.byType(InstrumentShell));
        expect(
          changed.controls().firstWhere((c) => c.keyName == action[1]).value,
          isNot(old),
          reason: '$id touching the object changes the model',
        );
        expect(find.byType(InteractiveMechanics), findsOneWidget);
        expect(t.takeException(), isNull, reason: '$id dragging object');
        if (id == 's02-e06') {
          final disk = find.byKey(const Key('apparatus-handle-disk'));
          await t.dragFrom(
            t.getCenter(disk) + const Offset(-55, -45),
            const Offset(70, 25),
          );
          await t.pump();
          await t.pump(const Duration(milliseconds: 200));
          shell.pause();
          await t.pumpAndSettle();
          final spin = t.widget<InteractiveMechanics>(
            find.byType(InteractiveMechanics),
          );
          expect(spin.parameters['omega0']!.abs(), greaterThan(.01));
          expect(
            spin.values['angle']!.abs(),
            greaterThan(.001),
            reason: 'flick rotates the same disk',
          );
        }
        final key = id == 's02-e05'
            ? 'v0'
            : mechanicsReferences[id]!.keys.first;
        final before = shell.controls().firstWhere((c) => c.keyName == key);
        if (id != 's02-e02' && id != 's02-e04') {
          final slider = find.byKey(Key('mechanics-control-$key'));
          await t.drag(slider, const Offset(30, 0));
          await t.pumpAndSettle();
          final after = t
              .widget<InstrumentShell>(find.byType(InstrumentShell))
              .controls()
              .firstWhere((c) => c.keyName == key);
          expect(
            after.value,
            isNot(before.value),
            reason: '$id control updates source model',
          );
        }
        for (final tab in [
          'workspace-graph',
          'workspace-inspect',
          'workspace-results',
          'workspace-scene',
        ]) {
          await t.tap(find.byKey(Key(tab)));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull, reason: '$id $tab');
        }
      }
      router.go('/lab/s01-e04');
      await t.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      final massBefore = t
          .widget<InteractiveMechanics>(find.byType(InteractiveMechanics))
          .parameters['a']!;
      await t.drag(
        find.byKey(const Key('apparatus-handle-massBall')),
        const Offset(0, 30),
      );
      await t.pumpAndSettle();
      expect(
        t
            .widget<InteractiveMechanics>(find.byType(InteractiveMechanics))
            .parameters['a'],
        isNot(massBefore),
      );
      expect(t.takeException(), isNull, reason: 'Mass & Time real apparatus');
      router.go('/');
      await t.pumpAndSettle();
    },
  );
}
