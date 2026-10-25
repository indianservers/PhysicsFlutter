import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:flutter/material.dart';
import 'package:physics_atelier/features/advanced/scene.dart' show LabPlot;

import 'phase1_test.dart' show capture, show, top;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const stage = String.fromEnvironment('AUDIT_STAGE', defaultValue: 'before');
  testWidgets('Phase 5 representative quality audit', (tester) async {
    await app.main();
    await tester.pumpAndSettle();
    await capture(tester, binding, 'phase5-$stage-home');
    for (final index in [1, 2, 6, 7, 8, 9, 10, 11]) {
      router.go('/studio/${studios[index].id}');
      await tester.pumpAndSettle();
      await capture(tester, binding, 'phase5-$stage-studio-$index');
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
    ]) {
      router.go('/lab/$id');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Experiment').last);
      await tester.pumpAndSettle();
      await capture(tester, binding, 'phase5-$stage-$id');
    }
    if (stage == 'after') {
      for (final entry in allEntries.where((e) => e.electromagnetism)) {
        router.go('/lab/${entry.id}');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Experiment').last);
        await tester.pumpAndSettle();
        await show(tester, find.text('Restore documented defaults'));
        await tester.tap(find.text('Restore documented defaults'));
        await tester.pumpAndSettle();
        if (['s11-e01', 's11-e04'].contains(entry.id)) {
          await show(tester, find.byKey(const Key('replay-em')));
          await tester.tap(find.byKey(const Key('replay-em')));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byType(TextField).last,
            entry.id == 's11-e01' ? '0.000003' : '.8',
          );
          await tester.tap(find.text('Apply'));
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
        }
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        // Native focus/IME and PageStorage restoration can arrive after a jump.
        for (int i = 0; i < 3; i++) {
          await top(tester);
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 200)),
          );
          await tester.pumpAndSettle();
        }
        await top(tester);
        expect(
          tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position
              .pixels,
          closeTo(0, .01),
        );
        await capture(tester, binding, 'phase5-${entry.id}');
      }
      router.go('/lab/s08-e04');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Visualize').last);
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
      await capture(tester, binding, 'phase5-after-fft-spectrum');
    }
  });
}
