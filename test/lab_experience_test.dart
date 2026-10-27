import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/core/design_system/reading_presentation.dart';
import 'package:physics_atelier/features/workbench/workbench.dart';

import 'app_test.dart' show notebook;

void main() {
  test('Display units retain SI values, signs and meaningful zeros', () {
    expect(conciseNumber(1000), '1000');
    expect(conciseNumber(-0.0), '0');
    expect(presentReading('efficiency', '.8', '').value, '80');
    expect(presentReading('efficiency', '.8', '').unit, '%');
    expect(presentReading('distance', '149597870700', 'm').value, '1');
    expect(presentReading('distance', '149597870700', 'm').unit, 'AU');
    expect(presentReading('period', '86400', 's').value, '1');
    final scale = displayScale(-.000002, 'C');
    expect(scale.unit, 'µC');
    expect(-2 * scale.factor, closeTo(-.000002, 1e-20));
    expect(
      presentReading('charge', '-.000002', 'C').tooltip,
      'charge: -.000002 C',
    );
  });
  testWidgets(
    'All lab inspectors fit 200 percent text and preserve controls and trial records',
    (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      t.view.physicalSize = const Size(640, 1136);
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
      for (final e in allEntries.where((e) => e.interactive)) {
        router.go('/lab/${e.id}');
        await t.pumpAndSettle();
        final shell = t.widget<InstrumentShell>(find.byType(InstrumentShell));
        final before = shell.controls().map((c) => c.value).toList();
        await t.ensureVisible(find.byKey(const Key('workspace-inspect')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('workspace-inspect')));
        await t.pumpAndSettle();
        expect(find.text('Inspect ${e.title}'), findsOneWidget);
        await t.ensureVisible(find.byKey(const Key('pin-comparison')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('pin-comparison')));
        await t.pumpAndSettle();
        expect(find.text('Replace pinned comparison'), findsOneWidget);
        await t.tap(find.byTooltip('Close inspector'));
        await t.pumpAndSettle();
        expect(
          t
              .widget<InstrumentShell>(find.byType(InstrumentShell))
              .controls()
              .map((c) => c.value)
              .toList(),
          before,
          reason: e.id,
        );
        expect(t.takeException(), isNull, reason: e.id);
      }
      expect(store.trials, isEmpty);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Reset undo restores complete configurations across all model families',
    (t) async {
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      for (final id in [
        's01-e03',
        's02-e00',
        's05-e00',
        's08-e00',
        's10-e00',
        's12-e00',
        's14-e00',
        's16-e00',
      ]) {
        router.go('/lab/$id');
        await t.pumpAndSettle();
        var shell = t.widget<InstrumentShell>(find.byType(InstrumentShell));
        final c = shell.controls().first;
        c.change((c.value + (c.max - c.min) * .05).clamp(c.min, c.max));
        await t.pumpAndSettle();
        shell = t.widget<InstrumentShell>(find.byType(InstrumentShell));
        final before = jsonDecode(jsonEncode(shell.captureConfiguration!()));
        await t.tap(find.byTooltip('Reset'));
        await t.pumpAndSettle();
        await t.tap(find.text('Undo'));
        await t.pumpAndSettle();
        final after = t
            .widget<InstrumentShell>(find.byType(InstrumentShell))
            .captureConfiguration!();
        expect(after, before, reason: id);
        expect(t.takeException(), isNull, reason: id);
      }
      router.go('/');
      await t.pumpAndSettle();
    },
  );
}
