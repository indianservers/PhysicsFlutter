import '../test/ui_navigation.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';

import 'phase1_test.dart' show capture;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const stage = String.fromEnvironment('AUDIT_STAGE', defaultValue: 'before');

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
      await chooseSection(tester, 'Experiment');
      await tester.pumpAndSettle();
      await capture(tester, binding, 'phase8-$stage-$id');
    }
  });
}
