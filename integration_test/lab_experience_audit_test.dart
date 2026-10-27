import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/features/workbench/workbench.dart';

import 'phase1_test.dart' show capture;
import 'phase9_restore_test.dart' as restoration;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Native lab experience: every studio, workspace, inspector and graph',
    (t) async {
      await app.main();
      await t.pumpAndSettle();
      var labCount = 0, inspectorCount = 0, graphCount = 0;
      for (final studio in studios) {
        final folder =
            '${(studios.indexOf(studio) + 1).toString().padLeft(2, '0')}_${studio.id}';
        router.go('/studio/${studio.id}');
        await t.pumpAndSettle();
        await capture(t, binding, '$folder/00_studio');
        for (final entry in studio.entries) {
          router.go('/lab/${entry.id}');
          await t.pumpAndSettle();
          if (entry.interactive) {
            await t.tap(find.byKey(const Key('workspace-scene')));
            await t.pumpAndSettle();
            final before = t
                .widget<InstrumentShell>(find.byType(InstrumentShell))
                .controls()
                .map((c) => c.value)
                .toList();
            await capture(t, binding, '$folder/${entry.id}_apparatus');
            labCount++;
            await t.tap(find.byKey(const Key('workspace-inspect')));
            await t.pumpAndSettle();
            expect(find.text('Inspect ${entry.title}'), findsOneWidget);
            await capture(t, binding, '$folder/${entry.id}_inspect');
            inspectorCount++;
            await t.tap(find.byTooltip('Close inspector'));
            await t.pumpAndSettle();
            expect(
              t
                  .widget<InstrumentShell>(find.byType(InstrumentShell))
                  .controls()
                  .map((c) => c.value)
                  .toList(),
              before,
              reason: entry.id,
            );
            await t.tap(find.byKey(const Key('workspace-graph')));
            await t.pumpAndSettle();
            expect(find.byKey(const Key('graph-pane-scroll')), findsOneWidget);
            await capture(t, binding, '$folder/${entry.id}_graph');
            graphCount++;
          } else {
            await capture(t, binding, '$folder/${entry.id}_tool');
            labCount++;
          }
          expect(t.takeException(), isNull, reason: entry.id);
        }
      }
      expect(labCount, 102);
      expect(inspectorCount, 96);
      expect(graphCount, 96);
      router.go('/');
      await t.pumpAndSettle();
      binding.reportData!['labExperienceAudit'] = {
        'studios': 17,
        'destinations': labCount,
        'inspectors': inspectorCount,
        'graphs': graphCount,
        'controlSignaturesPreserved': true,
      };
    },
  );
  restoration.main();
}
