import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:physics_atelier/core/rendering/micrometer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/features/lab_workspace/workspace.dart';
import 'package:physics_atelier/features/workbench/workbench.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';

import 'phase1_test.dart' show capture;
import 'phase9_restore_test.dart' as restoration;
import '../test/ui_navigation.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Micrometer reference workflow and every native workspace destination',
    (t) async {
      binding.reportData = {'images': <String, String>{}};
      await app.main();
      await t.pumpAndSettle();
      final store = ProviderScope.containerOf(
        t.element(find.byType(PhysicsApp)),
      ).read(notebookProvider);
      final count = store.trials.length;
      await capture(t, binding, 'micrometer-after-home');
      router.go('/lab/s01-e02');
      await t.pumpAndSettle();
      final dynamic state = t.state(find.byType(Workspace));
      final e = state.experiment;
      expect(find.byType(NavigationBar), findsNothing);
      expect(
        find.byKey(const Key('dock-edit-zero')).hitTestable(),
        findsOneWidget,
      );
      await capture(t, binding, 'micrometer-after-default');
      final area = t.getRect(find.byKey(const Key('micrometer-thimble')));
      final geometry = MicrometerGeometry(e.a, e.b, e.zero);
      final fit = math.min(area.width / 440, area.height / 250);
      final origin =
          area.topLeft +
          Offset((area.width - 440 * fit) / 2, (area.height - 250 * fit) / 2);
      final point = origin + geometry.thimble.center * fit;
      final opening = e.a;
      await t.dragFrom(point, const Offset(0, 60));
      await t.pumpAndSettle();
      expect(e.a, greaterThan(opening));
      await t.tap(find.byTooltip('Pan / zoom camera'));
      await t.pumpAndSettle();
      final afterDrag = e.a;
      await t.dragFrom(point, const Offset(20, 35));
      await t.pumpAndSettle();
      expect(e.a, afterDrag);
      await t.tap(find.byTooltip('Fit apparatus / reset view'));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Manipulate apparatus'));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Workspace panes'));
      await t.pumpAndSettle();
      await t.tap(find.text('Full-screen Scene').last);
      await t.pumpAndSettle();
      await capture(t, binding, 'micrometer-after-fullscreen-apparatus');
      await t.tap(find.byTooltip('Back'));
      await t.pumpAndSettle();
      expect(state.experiment, same(e));

      e.setA(.00737);
      e.zero = 0.0;
      e.changed();
      await t.pumpAndSettle();
      expect(e.reading.division, 37);
      await capture(t, binding, 'micrometer-after-7-37-mm');
      await t.tap(find.byTooltip('Full-screen precision reading'));
      await t.pumpAndSettle();
      await capture(t, binding, 'micrometer-after-precision-scale');
      await t.tap(find.byTooltip('Close precision reading'));
      await t.pumpAndSettle();
      await t.drag(
        find.byKey(const Key('micrometer-lens')),
        const Offset(-70, -40),
      );
      await t.pumpAndSettle();
      final physical = e.a;
      await t.tap(find.byTooltip('Zoom in'));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Fit apparatus / reset view'));
      await t.pumpAndSettle();
      expect(e.a, physical);
      e.setA(e.b);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('dock-edit-zero')));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).last, '0.02');
      await t.tap(find.text('Apply'));
      await t.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await t.pumpAndSettle();
      expect(e.zero, closeTo(.00002, 1e-12));
      expect(e.result, closeTo(e.b, 1e-12));
      e.note = 'Micrometer workspace native validation; simulated contact reading, signed zero correction.';
      await capture(t, binding, 'micrometer-after-contact-zero-correction');
      await t.tap(find.byKey(const Key('record-trial')));
      await t.pumpAndSettle();
      expect(store.trials.length, count + 1);
      final trial = store.trials.last;
      expect(trial.value, e.result);
      expect(trial.unit, 'm');
      expect(trial.resolution, .00001);
      expect(csvEncode([trial]), contains('s01-e02'));
      await t.tap(find.byTooltip('Reset'));
      await t.pumpAndSettle();
      expect(e.zero, 0);
      await chooseSection(t, 'Results');
      await t.tap(find.byIcon(Icons.chevron_right).first);
      await t.pumpAndSettle();
      await capture(t, binding, 'micrometer-after-recorded-trial');
      await t.tap(find.text('Reopen configuration'));
      await t.pumpAndSettle();
      expect(e.zero, closeTo(.00002, 1e-12));
      expect(e.result, trial.value);
      expect(state.experiment, same(e));
      e.zero = -.00002;
      e.changed();
      await t.pumpAndSettle();
      await capture(t, binding, 'micrometer-after-negative-zero');
      final rows = <String, dynamic>{};
      for (final studio in studios) {
        router.go('/studio/${studio.id}');
        await t.pumpAndSettle();
        await capture(t, binding, 'micrometer-studio-${studio.id}');
      }
      for (final entry in allEntries) {
        router.go('/lab/${entry.id}');
        await t.pumpAndSettle();
        if (entry.interactive) {
          expect(find.byType(InstrumentShell), findsOneWidget);
          expect(find.byType(NavigationBar), findsNothing);
          expect(
            find.byKey(const Key('record-trial')).hitTestable(),
            findsOneWidget,
          );
        }
        await capture(t, binding, 'micrometer-entry-${entry.id}');
        expect(t.takeException(), isNull, reason: entry.id);
        rows[entry.id] = {
          'route': '/lab/${entry.id}',
          'nativeRendered': true,
          'noPermanentSectionBar': entry.interactive,
          'screenshot': 'micrometer-entry-${entry.id}.png',
          'qualification': 'Native render and visible action; full interaction/geometry checks in targeted Micrometer and existing family regressions',
        };
      }
      binding.reportData!['micrometerAudit'] = {
        'entries': rows,
        'originalTrials': count,
        'trialsAfterExplicitRecord': store.trials.length,
        'micrometerFineRecordReopenAndCsv': true,
        'qualification': 'Actual Android debug/software renderer; one explicitly recorded simulated QA observation. Original state restored in following test.',
      };
      router.go('/');
      await t.pumpAndSettle();
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
  restoration.main();
}
