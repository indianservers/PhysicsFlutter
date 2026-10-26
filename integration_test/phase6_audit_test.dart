import '../test/ui_navigation.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:flutter/material.dart';
import 'package:physics_atelier/features/advanced/scene.dart' show LabPlot;

import 'phase1_test.dart' show capture, top, show;
import 'phase6_storage_test.dart' as storage;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const stage = String.fromEnvironment('AUDIT_STAGE', defaultValue: 'before');
  if (stage == 'after') storage.main();
  testWidgets('Phase 6 representative quality audit', (tester) async {
    binding.reportData ??= {};
    binding.reportData!['images'] = <String, String>{};
    await app.main();
    await tester.pumpAndSettle();
    await capture(tester, binding, 'phase6-$stage-home');
    for (final index in [1, 6, 8, 10, 11, 12, 13]) {
      router.go('/studio/${studios[index].id}');
      await tester.pumpAndSettle();
      await capture(tester, binding, 'phase6-$stage-studio-$index');
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
    ]) {
      router.go('/lab/$id');
      await tester.pumpAndSettle();
      await chooseSection(tester, 'Experiment');
      await tester.pumpAndSettle();
      await capture(tester, binding, 'phase6-$stage-$id');
    }
    if (stage == 'after') {
      for (final entry in allEntries.where((e) => e.electronicsThermal)) {
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
        await capture(tester, binding, 'phase6-${entry.id}');
      }
      for (final id in ['s12-e03', 's12-e04', 's13-e05']) {
        router.go('/lab/$id');
        await tester.pumpAndSettle();
        await chooseSection(tester, 'Visualize');
        await tester.pumpAndSettle();
        if (id == 's12-e04') {
          await show(tester, find.byType(SwitchListTile));
          tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged!(
            true,
          );
          await tester.pumpAndSettle();
        }
        await show(
          tester,
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is LabPlot,
          ),
        );
        await capture(tester, binding, 'phase6-graph-$id');
      }
    }
  });
}
