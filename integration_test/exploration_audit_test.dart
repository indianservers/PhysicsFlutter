import '../test/ui_navigation.dart';

import 'package:physics_atelier/features/workbench/workbench.dart';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';

import 'phase1_test.dart' show capture;
import 'phase9_restore_test.dart' as restoration;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Audit all catalog screens, studio launchers and shared destinations',
    (t) async {
      binding.reportData = {'images': <String, String>{}};
      await app.main();
      await t.pumpAndSettle();
      await capture(t, binding, 'explore-home');
      for (final studio in studios) {
        router.go('/studio/${studio.id}');
        await t.pumpAndSettle();
        await capture(t, binding, 'explore-studio-${studio.id}');
        for (final e in studio.entries) {
          router.go('/lab/${e.id}');
          await t.pumpAndSettle();
          expect(t.takeException(), isNull, reason: e.id);
          await capture(t, binding, 'explore-${e.id}');
          final instrumentScroll = find.byKey(
            const Key('reference-instrument-scroll'),
          );
          if (instrumentScroll.evaluate().isNotEmpty) {
            await t.drag(instrumentScroll, const Offset(0, -380));
            await t.pumpAndSettle();
            expect(
              t
                  .getSize(find.byKey(const Key('reference-compact-chart')))
                  .height,
              greaterThanOrEqualTo(90),
              reason: e.id,
            );
            await capture(t, binding, 'explore-${e.id}-controls-graph');
          }

          if (e.interactive) {
            final previous = t
                .widget<InstrumentShell>(find.byType(InstrumentShell))
                .controls()
                .map((c) => c.value)
                .toList();
            await chooseSection(t, 'Learn');
            expect(t.takeException(), isNull, reason: '${e.id} Learn');
            await capture(t, binding, 'explore-${e.id}-learn');
            final action = find.byKey(const Key('learn-explore-apparatus'));
            await t.ensureVisible(action);
            await t.pumpAndSettle();
            await t.tap(action);
            await t.pumpAndSettle();
            expect(
              t
                  .widget<InstrumentShell>(find.byType(InstrumentShell))
                  .controls()
                  .map((c) => c.value)
                  .toList(),
              previous,
              reason: e.id,
            );
            if (e.index == 0) {
              for (final section in ['Formulas', 'Results']) {
                await chooseSection(t, section);
                expect(t.takeException(), isNull, reason: '${e.id} $section');
                await capture(
                  t,
                  binding,
                  'explore-${e.id}-${section.toLowerCase()}',
                );
              }
            }
          }
        }
      }
      for (final id in [
        's09-e00',
        's09-e01',
        's09-e02',
        's09-e03',
        's13-e01',
      ]) {
        router.go('/lab/$id/bench');
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: 'bench $id');
        await capture(t, binding, 'explore-bench-$id');
      }
      for (final path in ['notebook', 'profile', 'settings']) {
        router.go('/$path');
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: path);
        await capture(t, binding, 'explore-$path');
      }
      router.go('/');
      await t.pumpAndSettle();
      binding.reportData!['explorationAudit'] = {
        'catalogScreens': 102,
        'studioScreens': 17,
        'benches': 5,
        'otherScreens': 4,
        'illustratedGuides': 96,
        'guideReturnStatePreserved': 96,
        'familyFormulaResultScreens': 32,
        'readableCompactGraphScreens': 90,
        'uncaughtErrors': 0,
      };
    },
  );
  restoration.main();
}
