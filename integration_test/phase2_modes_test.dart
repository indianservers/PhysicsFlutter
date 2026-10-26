import '../test/ui_navigation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';

import 'phase1_test.dart' show show, top, capture;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Final apparatus captures, supported modes, frames and lifecycle pause',
    (tester) async {
      await app.main();
      await tester.pumpAndSettle();
      Future<void> enter(String id) async {
        router.go('/lab/$id');
        await tester.pumpAndSettle();
        await chooseSection(tester, 'Experiment');
        await tester.pumpAndSettle();
      }

      Future<void> seek(double time) async {
        await show(tester, find.text('Time scrubber / deterministic replay'));
        await tester.tap(find.text('Time scrubber / deterministic replay'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).last, '$time');
        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();
      }

      Future<void> mode(String text) async {
        await show(tester, find.byType(DropdownButtonFormField<int>));
        await tester.tap(find.byType(DropdownButtonFormField<int>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text(text).last);
        await tester.pumpAndSettle();
      }

      for (final e in allEntries.where((e) => e.dynamics)) {
        await enter(e.id);
        final k = (e.studioIndex - 2) * 6 + e.index;
        await seek(
          k == 1
              ? 0.6
              : k == 2
              ? 0.4
              : k == 14
              ? 0.5
              : k == 9
              ? 0.8
              : 2,
        );
        await top(tester);
        await capture(tester, binding, 'phase2-${e.id}-${e.index + 1}');
      }
      await enter('s02-e02');
      await mode('One movable pulley');
      await seek(.4);
      await top(tester);
      await capture(tester, binding, 'phase2-mode-movable-pulley');
      await enter('s02-e04');
      await mode('Suspended equilibrium');
      await seek(1);
      await top(tester);
      await capture(tester, binding, 'phase2-mode-suspension');
      await enter('s03-e02');
      await mode('Two-segment schedule');
      await seek(3);
      await show(tester, find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ax (m/s²)').last);
      await tester.pumpAndSettle();
      await capture(tester, binding, 'phase2-mode-piecewise-graph');
      await enter('s03-e04');
      await seek(1.5);
      await mode('Object A');
      await tester.tap(find.byTooltip('Save session'));
      await tester.pumpAndSettle();
      final store = LocalNotebook();
      await store.initialize();
      final state = await store.readSession('s03-e04');
      expect(state!['ticks'], 180);
      expect(state['frame'], 1);
      await top(tester);
      await capture(tester, binding, 'phase2-mode-relative-frame-A');
      await enter('s04-e04');
      await mode('Block on table');
      await seek(1);
      await top(tester);
      await capture(tester, binding, 'phase2-mode-normal-contact');
      await enter('s04-e05');
      await show(tester, find.byKey(const Key('play-dynamics')));
      await tester.tap(find.byKey(const Key('play-dynamics')));
      await tester.pump(const Duration(milliseconds: 100));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Pause'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
