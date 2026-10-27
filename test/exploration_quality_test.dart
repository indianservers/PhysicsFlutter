import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/core/design_system/reading_presentation.dart';
import 'package:physics_atelier/core/design_system/theme.dart';
import 'package:physics_atelier/features/workbench/learning_header.dart';
import 'package:physics_atelier/features/workbench/workbench.dart';

import 'app_test.dart' show notebook;
import 'ui_navigation.dart';

void main() {
  test('Shared blue and secondary text meet normal-text contrast on white', () {
    for (final color in [cobalt, muted]) {
      expect(
        1.05 / (color.computeLuminance() + .05),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  testWidgets(
    'Studios and working labs expose labeled Android-size tap targets',
    (t) async {
      t.view.physicalSize = const Size(720, 1280);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final semantics = t.ensureSemantics();
      try {
        final store = await notebook();
        await t.pumpWidget(
          ProviderScope(
            overrides: [notebookProvider.overrideWithValue(store)],
            child: const PhysicsApp(),
          ),
        );
        for (final route in [
          ...studios.map((s) => '/studio/${s.id}'),
          ...allEntries.where((e) => e.interactive).map((e) => '/lab/${e.id}'),
        ]) {
          router.go(route);
          await t.pumpAndSettle();
          await expectLater(
            t,
            meetsGuideline(androidTapTargetGuideline),
            reason: route,
          );
          await expectLater(
            t,
            meetsGuideline(labeledTapTargetGuideline),
            reason: route,
          );
        }
        router.go('/');
        await t.pumpAndSettle();
      } finally {
        semantics.dispose();
      }
    },
  );

  test('Readable SI prefixes retain polarity and the raw SI tooltip', () {
    final current = presentReading('current', '-0.0000025', 'A');
    expect(current.value, '-2.5');
    expect(current.unit, 'µA');
    expect(current.tooltip, 'current: -0.0000025 A');
    expect(presentReading('field', '0.0000000032', 'T').unit, 'nT');
    expect(presentReading('capacitance', '0.0000000000442', 'F').value, '44.2');
    expect(presentReading('wavelength', '0.00000065', 'm').unit, 'nm');
    expect(presentReading('VX', '3', 'm/s').label, 'Velocity (x)');
    expect(presentReading('Model t', '0', 's').label, 'Elapsed time');
    for (final input in ['0', 'Undefined', '—', 'NaN']) {
      expect(presentReading('value', input, 'A').value, input);
      expect(presentReading('value', input, 'A').unit, 'A');
    }
    expect(presentReading('height', '0.44', 'mm').unit, 'mm');
  });

  testWidgets(
    'All illustrated guides return to the same live controls at200% text',
    (t) async {
      t.view.physicalSize = const Size(640, 1136);
      t.view.devicePixelRatio = 2;
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final store = await notebook();
      store.reducedMotion = true;
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      for (final e in allEntries.where((e) => e.interactive)) {
        router.go('/lab/${e.id}');
        await t.pumpAndSettle();
        final before = t
            .widget<InstrumentShell>(find.byType(InstrumentShell))
            .controls()
            .map((c) => c.value)
            .toList();
        await chooseSection(t, 'Learn');
        expect(find.byType(LabLearningHeader), findsOneWidget, reason: e.id);
        final button = find.byKey(const Key('learn-explore-apparatus'));
        await t.ensureVisible(button);
        await t.pumpAndSettle();
        expect(button.hitTestable(), findsOneWidget, reason: e.id);
        await t.tap(button);
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
      router.go('/');
      await t.pumpAndSettle();
    },
  );

  testWidgets(
    'Studio filters and collection actions persist and leave live science intact',
    (t) async {
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      router.go('/studio/s01');
      await t.pumpAndSettle();
      final save = find.byKey(const Key('studio-save-s01-e00'));
      await t.ensureVisible(save);
      await t.pumpAndSettle();
      await t.tap(save);
      await t.pumpAndSettle();
      expect(store.favorites, contains('s01-e00'));
      await t.tap(find.byKey(const Key('studio-filter-Saved')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('launch-s01-e00')), findsOneWidget);
      expect(find.byKey(const Key('launch-s01-e01')), findsNothing);
      await t.tap(find.byKey(const Key('launch-s01-e00')));
      await t.pumpAndSettle();
      final before = t
          .widget<InstrumentShell>(find.byType(InstrumentShell))
          .controls()
          .map((c) => c.value)
          .toList();
      await t.tap(find.byTooltip('Lab options'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Remove from saved labs'));
      await t.pumpAndSettle();
      await t.tap(find.text('Remove from saved labs'));
      await t.pumpAndSettle();
      expect(store.favorites, isNot(contains('s01-e00')));
      expect(
        t
            .widget<InstrumentShell>(find.byType(InstrumentShell))
            .controls()
            .map((c) => c.value)
            .toList(),
        before,
      );
      await t.tap(find.byTooltip('Lab options'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Explore this studio'));
      await t.pumpAndSettle();
      await t.tap(find.text('Explore this studio'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('studio-search')), findsOneWidget);
      await t.enterText(
        find.byKey(const Key('studio-search')),
        'no matching apparatus',
      );
      await t.pumpAndSettle();
      expect(find.text('No matching labs'), findsOneWidget);
      await t.tap(find.text('Show all labs'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('launch-s01-e00')), findsOneWidget);
      expect(t.takeException(), isNull);
      router.go('/');
      await t.pumpAndSettle();
    },
  );

  testWidgets(
    'Every physical lab accepts a primary control adjustment without losing its workspace',
    (t) async {
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
        final controls = shell.controls();
        if (controls.isNotEmpty) {
          final c = controls.first;
          final span = c.max - c.min;
          final target = span <= 10
              ? (c.value <= (c.min + c.max) / 2 ? c.max : c.min)
              : (c.value + span * .25).clamp(c.min, c.max);
          c.change(target);
          await t.pumpAndSettle();
          final updated = t
              .widget<InstrumentShell>(find.byType(InstrumentShell))
              .controls()
              .first;
          expect(updated.value.isFinite, isTrue, reason: e.id);
          expect(
            updated.value,
            inInclusiveRange(updated.min, updated.max),
            reason: e.id,
          );
          if (target != c.value) {
            expect(updated.value, isNot(c.value), reason: e.id);
          }
        }
        expect(t.takeException(), isNull, reason: e.id);
      }
      expect(store.trials, isEmpty);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
}
