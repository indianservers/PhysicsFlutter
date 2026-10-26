import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    'Native compact launchers and a working instrument from every studio',
    (t) async {
      binding.reportData = {'images': <String, String>{}};
      final preferences = await SharedPreferences.getInstance();
      for (final key
          in preferences
              .getKeys()
              .where(
                (k) =>
                    k.startsWith('workspace:') ||
                    k.startsWith('workspaceGuide:'),
              )
              .toList()) {
        await preferences.remove(key);
      }
      await app.main();
      await t.pumpAndSettle();
      await capture(t, binding, 'workspace-after-home');
      for (final studio in studios) {
        router.go('/studio/${studio.id}');
        await t.pumpAndSettle();
        await capture(t, binding, 'workspace-after-studio-${studio.id}');
      }
      for (final e in allEntries) {
        router.go('/lab/${e.id}');
        await t.pumpAndSettle();
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 180)),
        );
        await t.pumpAndSettle();
        if (e.interactive) expect(find.byType(InstrumentShell), findsOneWidget);
        await capture(t, binding, 'workspace-after-entry-${e.id}');
        expect(t.takeException(), isNull, reason: e.id);
      }
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
    timeout: const Timeout(Duration(minutes: 15)),
  );
  restoration.main();
}
