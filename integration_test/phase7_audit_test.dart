import '../test/ui_navigation.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:flutter/material.dart';
import 'package:physics_atelier/features/advanced/scene.dart' show LabPlot;

import 'phase1_test.dart' show capture, top, show;
import 'phase7_storage_test.dart' as storage;

import 'package:physics_atelier/features/fluid_modern/workspace.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const stage = String.fromEnvironment('AUDIT_STAGE', defaultValue: 'before');
  if (stage == 'after') storage.main();
  testWidgets('Phase 7 representative quality audit', (tester) async {
    binding.reportData ??= {};
    binding.reportData!['images'] = <String, String>{};
    await app.main();
    await tester.pumpAndSettle();
    await capture(tester, binding, 'phase7-$stage-home');
    for (final index in [1, 6, 8, 10, 11, 12, 13, 14, 15]) {
      router.go('/studio/${studios[index].id}');
      await tester.pumpAndSettle();
      await capture(tester, binding, 'phase7-$stage-studio-$index');
    }
    for (final id in [
      's01-e01',
      's02-e00',
      's03-e03',
      's04-e03',
      's06-e03',
      's07-e01',
      's07-e04',
      's08-e02',
      's09-e01',
      's10-e02',
      's10-e04',
      's11-e01',
      's13-e00',
      's13-e01',
      's13-e05',
    ]) {
      router.go('/lab/$id');
      await tester.pumpAndSettle();
      await chooseSection(tester, 'Experiment');
      await tester.pumpAndSettle();
      await capture(tester, binding, 'phase7-$stage-$id');
    }
    if (stage == 'after') {
      for (final entry in allEntries.where((e) => e.fluidModern)) {
        router.go('/lab/${entry.id}');
        await tester.pumpAndSettle();
        await chooseSection(tester, 'Experiment');
        await tester.pumpAndSettle();
        FocusManager.instance.primaryFocus?.unfocus();
        for (int i = 0; i < 3; i++) {
          await top(tester);
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 200)),
          );
          await tester.pumpAndSettle();
        }
        await top(tester);
        final dynamic workspace = tester.state(find.byType(FMWorkspace));
        final config = workspace.configuration() as Map<String, dynamic>;
        expect(config['stateUnits'], isNotEmpty);
        expect(config['profileAxis']['unit'], isNotNull);
        if (workspace.run.distribution != null) {
          expect(config['histogramMetadata']['axisUnit'], 'm');
        }
        await capture(tester, binding, 'phase7-${entry.id}');
      }
      for (final id in ['s15-e00', 's15-e02', 's15-e05', 's14-e04']) {
        router.go('/lab/$id');
        await tester.pumpAndSettle();
        await chooseSection(tester, 'Visualize');
        await tester.pumpAndSettle();
        await show(
          tester,
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is LabPlot,
          ),
        );
        await capture(tester, binding, 'phase7-graph-$id');
      }
    }
  });
}
