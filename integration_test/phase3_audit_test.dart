import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';

import 'phase1_test.dart' show capture;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const stage = String.fromEnvironment('AUDIT_STAGE', defaultValue: 'before');
  testWidgets('Previous modules native visual audit', (tester) async {
    await app.main();
    await tester.pumpAndSettle();
    await capture(tester, binding, 'phase3-$stage-home');
    for (int i = 0; i < (stage == 'before' ? 5 : 17); i++) {
      router.go('/studio/${studios[i].id}');
      await tester.pumpAndSettle();
      await capture(tester, binding, 'phase3-$stage-studio-$i');
    }
    for (final entry in allEntries.where(
      (e) => e.studioIndex >= 1 && e.studioIndex <= 4,
    )) {
      router.go('/lab/${entry.id}');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Experiment').last);
      await tester.pumpAndSettle();
      await capture(tester, binding, 'phase3-$stage-${entry.id}');
    }
    if (stage == 'after') {
      for (final entry in allEntries.where((e) => e.advanced)) {
        router.go('/lab/${entry.id}');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Experiment').last);
        await tester.pumpAndSettle();
        await capture(tester, binding, 'phase3-final-${entry.id}');
      }
    }
  });
}
