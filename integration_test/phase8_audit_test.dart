import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';

import 'phase1_test.dart' show capture;

import 'phase8_storage_test.dart' as storage;

import 'package:flutter/material.dart';
import 'package:physics_atelier/features/advanced/scene.dart' show LabPlot;
import 'package:physics_atelier/features/astronomy/workspace.dart';
import 'package:physics_atelier/features/overview/compare_workspace.dart';

import '../test/em_app_test.dart' show top;
import 'phase1_test.dart' show show;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const stage = String.fromEnvironment('AUDIT_STAGE', defaultValue: 'after');

  storage.main();
  testWidgets('Phase 8 representative quality audit', (tester) async {
    binding.reportData ??= {};
    binding.reportData!['images'] = <String, String>{};
    await app.main();
    await tester.pumpAndSettle();
    await capture(tester, binding, 'phase8-$stage-home');
    for (final index in List.generate(17, (i) => i)) {
      router.go('/studio/${studios[index].id}');
      await tester.pumpAndSettle();
      await capture(tester, binding, 'phase8-$stage-studio-$index');
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
      's00-e00',
      's00-e01',
      's00-e02',
      's00-e03',
      's00-e04',
      's00-e05',
      's16-e00',
      's16-e01',
      's16-e02',
      's16-e03',
      's16-e04',
      's16-e05',
    ]) {
      router.go('/lab/$id');
      await tester.pumpAndSettle();
      if (find.text('Experiment').evaluate().isNotEmpty) {
        await tester.tap(find.text('Experiment').last);
        await tester.pumpAndSettle();
      }
      await capture(tester, binding, 'phase8-after-$id');
    }
    for (final id in [
      's16-e00',
      's16-e01',
      's16-e02',
      's16-e03',
      's16-e04',
      's16-e05',
    ]) {
      router.go('/lab/$id');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Experiment').last);
      await tester.pumpAndSettle();
      for (int i = 0; i < 3; i++) {
        await top(tester);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pumpAndSettle();
      }
      await capture(tester, binding, 'phase8-$id');
      await tester.tap(find.text('Visualize').last);
      await tester.pumpAndSettle();
      if (id == 's16-e03') {
        final field = find.byType(DropdownButtonFormField<String>);
        await show(tester, field);
        tester.widget<DropdownButtonFormField<String>>(field).onChanged!(
          'SPARC observed NGC2403',
        );
        await tester.pumpAndSettle();
      }
      await show(
        tester,
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LabPlot),
      );
      await capture(tester, binding, 'phase8-graph-$id');
    }
    router.go('/lab/s16-e00');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Experiment').last);
    await tester.pumpAndSettle();
    final solar = tester.state<AstronomyWorkspaceState>(
      find.byType(AstronomyWorkspace),
    );
    solar.chooseMode(2);
    solar.update('scaleMode', 0);
    await tester.pumpAndSettle();
    await top(tester);
    await capture(tester, binding, 'phase8-mode-physical-earth');
    solar.chooseMode(5);
    solar.update('scaleMode', 1);
    await tester.pumpAndSettle();
    await top(tester);
    await capture(tester, binding, 'phase8-mode-artist-saturn');
    router.go('/lab/s16-e01');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Experiment').last);
    await tester.pumpAndSettle();
    final star = tester.state<AstronomyWorkspaceState>(
      find.byType(AstronomyWorkspace),
    );
    star.update('ageFraction', .99999999);
    await tester.pumpAndSettle();
    await top(tester);
    await capture(tester, binding, 'phase8-mode-late-stellar-reference');
    router.go('/lab/s00-e04');
    await tester.pumpAndSettle();
    final compare = tester.state<CompareWorkspaceState>(
      find.byType(CompareWorkspace),
    );
    compare.choose(3);
    await tester.pumpAndSettle();
    await show(
      tester,
      find
          .byWidgetPredicate((w) => w is CustomPaint && w.painter is LabPlot)
          .first,
    );
    await capture(tester, binding, 'phase8-graph-comparison-normalized');
  });
}
