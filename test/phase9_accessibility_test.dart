import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/core/design_system/theme.dart';
import 'package:physics_atelier/features/advanced/scene.dart';

import 'app_test.dart' show notebook;

void main() {
  test('Normal instructional teal on white meets WCAG AA contrast', () {
    final ratio = 1.05 / (teal.computeLuminance() + .05);
    expect(ratio, greaterThanOrEqualTo(4.5));
  });
  testWidgets(
    'Graphs expose computed ranges and selected readings without live announcements',
    (t) async {
      final handle = t.ensureSemantics();

      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 240,
              child: CustomPaint(
                painter: LabPlot(
                  [
                    {'t': 0.0, 'x': -.2},
                    {'t': 1.0, 'x': .4},
                  ],
                  ['x'],
                  'time (s)',
                  'm',
                  1,
                ),
              ),
            ),
          ),
        ),
      );
      final tree = t
          .binding
          .renderViews
          .first
          .owner!
          .semanticsOwner!
          .rootSemanticsNode!
          .toStringDeep();
      expect(tree, contains('Data graph'));
      expect(tree, contains('cursor 0.4000 m'));
      handle.dispose();
    },
  );
  testWidgets(
    'All studios support small phone tablet landscape and 200 percent text',
    (t) async {
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      for (final setup in [
        (const Size(640, 1136), 2.0, 2.0),
        (const Size(1600, 2560), 2.0, 1.0),
        (const Size(1600, 900), 2.0, 1.6),
      ]) {
        t.view.physicalSize = setup.$1;
        t.view.devicePixelRatio = setup.$2;
        t.platformDispatcher.textScaleFactorTestValue = setup.$3;
        for (int i = 0; i < 17; i++) {
          router.go('/studio/s${i.toString().padLeft(2, '0')}');
          await t.pumpAndSettle();
          final scroll = find.byType(Scrollable).first;
          final pos = t.state<ScrollableState>(scroll).position;
          pos.jumpTo(pos.maxScrollExtent);
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
        }
      }
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Critical home actions have Android touch targets and semantic labels',
    (t) async {
      final handle = t.ensureSemantics();

      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      router.go('/');
      await t.pumpAndSettle();
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    },
  );
}
