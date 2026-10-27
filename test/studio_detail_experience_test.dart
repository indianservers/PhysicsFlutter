import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/features/workbench/workbench.dart';
import 'package:physics_atelier/features/waves/scene.dart';
import 'package:physics_atelier/features/astronomy/hr_diagram.dart';
import 'package:physics_atelier/features/electromagnetism/circuit_schematic.dart';

import 'app_test.dart' show notebook;

void main() {
  testWidgets(
    'Wavelength ruler moves independently of the scientific controls',
    (t) async {
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      router.go('/lab/s08-e00');
      await t.pumpAndSettle();
      final shell = t.widget<InstrumentShell>(find.byType(InstrumentShell));
      final before = shell.controls().map((c) => c.value).toList();
      final scene = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is WavePainter,
      );
      final rect = t.getRect(scene),
          painter = t.widget<CustomPaint>(scene).painter! as WavePainter;
      final original = painter.wavelengthRuler!;
      await t.dragFrom(
        rect.topLeft +
            Offset(
              (30 + 150 * (original + .2)) * rect.width / 360,
              206 * rect.height / 270,
            ),
        const Offset(40, 0),
      );
      await t.pumpAndSettle();
      expect(
        (t.widget<CustomPaint>(scene).painter! as WavePainter).wavelengthRuler,
        greaterThan(original),
      );
      expect(
        t
            .widget<InstrumentShell>(find.byType(InstrumentShell))
            .controls()
            .map((c) => c.value)
            .toList(),
        before,
      );
      expect(store.trials, isEmpty);
      expect(t.takeException(), isNull);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Connected schematic is an alternate view of the actual circuit',
    (t) async {
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      router.go('/lab/s10-e04');
      await t.pumpAndSettle();
      final before = jsonEncode(
        t
            .widget<InstrumentShell>(find.byType(InstrumentShell))
            .captureConfiguration!(),
      );
      await t.tap(find.byKey(const Key('workspace-inspect')));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Schematic / component readings'));
      await t.pumpAndSettle();
      await t.tap(find.text('Schematic / component readings'));
      await t.pumpAndSettle();
      final schematic = t.widget<CircuitSchematic>(
        find.byType(CircuitSchematic),
      );
      expect(schematic.circuit.parts, isNotEmpty);
      expect(schematic.circuit.wires, isNotEmpty);
      expect(find.text('Actual wire connections'), findsOneWidget);
      await t.tap(find.byTooltip('Close inspector'));
      await t.pumpAndSettle();
      expect(
        jsonEncode(
          t
              .widget<InstrumentShell>(find.byType(InstrumentShell))
              .captureConfiguration!(),
        ),
        before,
      );
      expect(t.takeException(), isNull);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'H–R age cursor changes the source stellar model without fabricating observations',
    (t) async {
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      router.go('/lab/s16-e01');
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('workspace-inspect')));
      await t.pumpAndSettle();
      final diagram = t.widget<HRDiagram>(find.byType(HRDiagram));
      final original = diagram.logLuminosity;
      diagram.changeAge(.9);
      await t.pumpAndSettle();
      expect(
        t.widget<HRDiagram>(find.byType(HRDiagram)).logLuminosity,
        isNot(original),
      );
      expect(store.trials, isEmpty);
      expect(t.takeException(), isNull);
      await t.tap(find.byTooltip('Close inspector'));
      await t.pumpAndSettle();
      router.go('/');
      await t.pumpAndSettle();
    },
  );
}
