import '../test/ui_navigation.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:flutter/material.dart';
import 'package:physics_atelier/features/advanced/scene.dart' show LabPlot;

import 'phase1_test.dart' show capture, show;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const stage = String.fromEnvironment('AUDIT_STAGE', defaultValue: 'before');
  testWidgets('Phase 4 representative quality audit', (tester) async {
    await app.main();
    await tester.pumpAndSettle();
    await capture(tester, binding, 'phase4-$stage-home');
    for (final index in [1, 2, 6, 7, 8, 9]) {
      router.go('/studio/${studios[index].id}');
      await tester.pumpAndSettle();
      await capture(tester, binding, 'phase4-$stage-studio-$index');
    }
    for (final id in [
      's01-e01',
      's02-e00',
      's03-e03',
      's04-e03',
      's06-e03',
      's07-e01',
      's07-e04',
    ]) {
      router.go('/lab/$id');
      await tester.pumpAndSettle();
      await chooseSection(tester, 'Experiment');
      await tester.pumpAndSettle();
      await capture(tester, binding, 'phase4-$stage-$id');
    }
    if (stage == 'after') {
      router.go('/lab/s08-e04');
      await tester.pumpAndSettle();
      await chooseSection(tester, 'Visualize');
      await tester.pumpAndSettle();
      final quantity = find.byType(DropdownButtonFormField<String>);
      await show(tester, quantity);
      tester.widget<DropdownButtonFormField<String>>(quantity).onChanged!(
        'spectrum',
      );
      await tester.pumpAndSettle();
      final plot = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is LabPlot,
      );
      await show(tester, plot);
      await capture(tester, binding, 'phase4-after-fft-spectrum');
    }
  });
}
