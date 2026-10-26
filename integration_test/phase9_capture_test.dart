import '../test/ui_navigation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';

import 'phase1_test.dart' show capture, top;
import 'phase9_restore_test.dart' as restoration;
import 'phase9_storage_test.dart' as storage;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  storage.main();
  testWidgets(
    'Final source screenshot pack all102 destinations and17 studios',
    (t) async {
      binding.reportData ??= {};
      binding.reportData!['images'] = <String, String>{};
      await app.main();
      await t.pumpAndSettle();
      await capture(t, binding, 'phase9-home');
      for (final studio in studios) {
        router.go('/studio/${studio.id}');
        await t.pumpAndSettle();
        await capture(t, binding, 'phase9-studio-${studio.id}');
      }
      for (final e in allEntries) {
        router.go('/lab/${e.id}');
        await t.pumpAndSettle();
        if (e.interactive) {
          await chooseSection(t, 'Experiment');
          await t.pumpAndSettle();
        }
        await top(t);
        await capture(t, binding, 'phase9-entry-${e.id}');
        expect(t.takeException(), isNull);
      }
      router.go('/settings');
      await t.pumpAndSettle();
      await capture(t, binding, 'phase9-settings');
      final scroll = find.byType(Scrollable).first;
      t
          .state<ScrollableState>(scroll)
          .position
          .jumpTo(t.state<ScrollableState>(scroll).position.maxScrollExtent);
      await t.pumpAndSettle();
      await t.tap(find.text('Open-source licenses'));
      await t.pumpAndSettle();
      expect(find.text('Licenses'), findsOneWidget);
      await capture(t, binding, 'phase9-open-source-notices');
      Navigator.of(t.element(find.text('Licenses'))).pop();
      await t.pumpAndSettle();
      router.go('/notebook');
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Export all trials as CSV'));
      debugPrint('PHASE9_READY_FOR_SHARE');
      await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 8)));
      await t.pumpAndSettle();
      expect(find.text('Your notebook'), findsOneWidget);
      router.go('/');
      await t.pumpAndSettle();
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
  restoration.main();
}
