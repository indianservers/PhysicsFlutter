import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/core/rendering/micrometer.dart';
import 'package:physics_atelier/features/workbench/workbench.dart';
import 'package:physics_atelier/features/lab_workspace/workspace.dart';

import 'app_test.dart' show notebook;
import 'ui_navigation.dart';

void main() {
  test('Manufacturer 7.37 mm example and pitch determine opposed faces and real graduations', () {
    const g = MicrometerGeometry(.00737, .0005, 0);
    expect(g.reading.main, closeTo(.007, 1e-12));
    expect(g.reading.division, 37);
    expect(g.graduationY(37), closeTo(100, 1e-10));
    expect(g.graduationY(40), lessThan(100));
    expect(g.graduationY(35), greaterThan(100));
    expect(g.sleeveMark(14), lessThan(g.edge));
    expect(g.sleeveMark(15), greaterThan(g.edge));
    expect(
      g.spindleFace - MicrometerGeometry.anvilFace,
      closeTo(.00737 * 3000, 1e-12),
    );
    const next = MicrometerGeometry(.00787, .0005, 0);
    expect(next.turns - g.turns, closeTo(1, 1e-12));
    expect(next.edge - g.edge, closeTo(1.5, 1e-12));
    const calibrated = MicrometerGeometry(.00735, .0005, .00002);
    expect(calibrated.reading.observed, g.reading.observed);
    expect(calibrated.spindleFace, lessThan(g.spindleFace));
  });
  test('Sleeve edge and thimble stay coherent at half-millimetre boundaries and signed zero errors', () {
    for (final opening in [.0005, .00099, .001, .00749, .0075, .02499, .025]) {
      for (final zero in [-.0001, 0.0, .0001]) {
        final g = MicrometerGeometry(opening, .0005, zero);
        final last = (g.reading.main / .0005).round();
        expect(g.sleeveMark(last), lessThanOrEqualTo(g.edge + 1e-8));
        expect(g.sleeveMark(last + 1), greaterThan(g.edge));
        expect(g.graduationY(g.reading.division), closeTo(100, 1e-7));
        expect(g.objectRect.right, lessThanOrEqualTo(g.spindleFace));
      }
    }
  });
  testWidgets(
    'Micrometer fine adjustment lens camera precision and record/reopen use one model',
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
      router.go('/lab/s01-e02');
      await t.pumpAndSettle();
      final dynamic state = t.state(find.byType(Workspace));
      final e = state.experiment;
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.textContaining('PHASE 1'), findsNothing);
      expect(find.byTooltip('Run'), findsNothing);
      expect(
        t
            .widget<InstrumentShell>(find.byType(InstrumentShell))
            .controls()
            .length,
        2,
      );
      expect(
        find.byKey(const Key('dock-edit-zero')).hitTestable(),
        findsOneWidget,
      );
      await t.tap(find.byTooltip('Open spindle by 0.01 mm'));
      await t.pumpAndSettle();
      expect(e.a, closeTo(.00053, 1e-12));
      final before = e.toJson();
      await t.drag(
        find.byKey(const Key('micrometer-lens')),
        const Offset(-45, -35),
      );
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Zoom in'));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Fit apparatus / reset view'));
      await t.pumpAndSettle();
      expect(e.toJson(), before);
      await t.tap(find.byTooltip('Full-screen precision reading'));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Open spindle by 0.01 mm').last);
      await t.pumpAndSettle();
      expect(e.a, closeTo(.00054, 1e-12));
      await t.tap(find.byTooltip('Close precision reading'));
      await t.pumpAndSettle();
      for (final section in ['Learn', 'Formulas', 'Visualize', 'Experiment']) {
        await chooseSection(t, section);
        expect(state.experiment, same(e));
        expect(e.a, closeTo(.00054, 1e-12));
      }
      await t.tap(find.byKey(const Key('record-trial')));
      await t.pumpAndSettle();
      expect(store.trials.single.value, closeTo(.00054, 1e-12));
      await t.tap(find.byTooltip('Reset'));
      await t.pumpAndSettle();
      expect(e.a, closeTo(.00052, 1e-12));
      await chooseSection(t, 'Results');
      await t.tap(find.byIcon(Icons.chevron_right).first);
      await t.pumpAndSettle();
      await t.tap(find.text('Reopen configuration'));
      await t.pumpAndSettle();
      expect(e.a, closeTo(.00054, 1e-12));
      expect(state.experiment, same(e));
      expect(t.takeException(), isNull);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Micrometer precision reading remains usable at 200 percent text and landscape',
    (t) async {
      t.view.physicalSize = const Size(640, 1136);
      t.view.devicePixelRatio = 2;
      t.platformDispatcher.textScaleFactorTestValue = 2;
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
      router.go('/lab/s01-e02');
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.tap(find.byTooltip('Full-screen precision reading'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      t.view.physicalSize = const Size(1136, 640);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.tap(find.byTooltip('Close precision reading'));
      await t.pumpAndSettle();
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Thimble drag changes the real opening; pan mode and lens drag cannot',
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
      router.go('/lab/s01-e02');
      await t.pumpAndSettle();
      final dynamic state = t.state(find.byType(Workspace));
      final e = state.experiment;
      final area = t.getRect(find.byKey(const Key('micrometer-thimble')));
      final g = MicrometerGeometry(e.a, e.b, e.zero);
      final scale = math.min(area.width / 440, area.height / 250);
      final origin =
          area.topLeft +
          Offset(
            (area.width - 440 * scale) / 2,
            (area.height - 250 * scale) / 2,
          );
      final start = origin + g.thimble.center * scale;
      final before = e.a;
      await t.dragFrom(start, const Offset(0, 60));
      await t.pumpAndSettle();
      expect(e.a, greaterThan(before));
      final changed = e.a;
      await t.tap(find.byTooltip('Pan / zoom camera'));
      await t.pumpAndSettle();
      await t.dragFrom(start, const Offset(25, 50));
      await t.pumpAndSettle();
      expect(e.a, changed);
      await t.tap(find.byTooltip('Manipulate apparatus'));
      await t.pumpAndSettle();
      await t.drag(
        find.byKey(const Key('micrometer-lens')),
        const Offset(-30, -25),
      );
      await t.pumpAndSettle();
      expect(e.a, changed);
      expect(t.takeException(), isNull);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
}
