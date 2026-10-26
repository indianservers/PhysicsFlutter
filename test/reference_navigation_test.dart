import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/core/design_system/reference_style.dart';
import 'package:physics_atelier/features/workbench/workbench.dart';

import 'app_test.dart' show notebook;

void main() {
  testWidgets('Compact graphs keep a readable plotting area on a small phone', (
    t,
  ) async {
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
    for (final id in ['s03-e00', 's09-e00', 's13-e00', 's16-e00']) {
      router.go('/lab/$id');
      await t.pumpAndSettle();
      final chart = find.byKey(const Key('reference-compact-chart'));
      expect(t.getSize(chart).height, greaterThanOrEqualTo(90), reason: id);
      await t.ensureVisible(chart);
      await t.pumpAndSettle();
      expect(chart.hitTestable(), findsOneWidget, reason: id);
      expect(t.takeException(), isNull, reason: id);
    }
    router.go('/');
    await t.pumpAndSettle();
  });

  testWidgets(
    'Reference footer destinations work in every physical workspace family',
    (t) async {
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      for (final id in [
        's01-e00',
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
        expect(find.byKey(const Key('reference-nav-learn')), findsOneWidget);
        final before = t
            .widget<InstrumentShell>(find.byType(InstrumentShell))
            .controls()
            .map((c) => c.value)
            .toList();
        await t.tap(find.byKey(const Key('reference-nav-results')));
        await t.pumpAndSettle();
        expect(
          t
              .widget<ReferenceNavigation>(find.byType(ReferenceNavigation))
              .selected,
          2,
        );
        await t.tap(find.byKey(const Key('reference-nav-labs')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('reference-nav-learn')));
        await t.pumpAndSettle();
        expect(
          find.byType(InstrumentShell),
          findsNothing,
          reason: '$id reader',
        );
        expect(
          t
              .widget<ReferenceNavigation>(find.byType(ReferenceNavigation))
              .selected,
          0,
        );
        await t.tap(find.byKey(const Key('reference-nav-labs')));
        await t.pumpAndSettle();
        expect(
          t
              .widget<InstrumentShell>(find.byType(InstrumentShell))
              .controls()
              .map((c) => c.value)
              .toList(),
          before,
        );
        await t.tap(find.byKey(const Key('reference-nav-profile')));
        await t.pumpAndSettle();
        expect(find.text('Your learning'), findsOneWidget);
        expect(t.takeException(), isNull, reason: id);
      }
      router.go('/');
      await t.pumpAndSettle();
    },
  );
}
