import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';
import 'package:physics_atelier/core/physics/advanced.dart';

import 'phase1_test.dart' show capture;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Original notebook records are readable in the final app', (
    tester,
  ) async {
    final expected = const String.fromEnvironment('LEGACY_IDS')
        .split(',')
        .where((x) => x.isNotEmpty)
        .toSet();
    expect(expected, isNotEmpty);
    final store = LocalNotebook();
    await store.initialize();
    final ids = store.trials.map((t) => t.id).toSet();
    expect(ids.containsAll(expected), isTrue);
    expect(
      store.trials.where((t) => t.model == 'measurement-1.0').length,
      greaterThanOrEqualTo(8),
    );
    expect(
      store.trials.where((t) => t.model == 'dynamics-2.0').length,
      greaterThanOrEqualTo(18),
    );
    expect(
      store.trials
          .where((t) => t.model == advancedVersion)
          .map((t) => t.labId)
          .toSet()
          .length,
      18,
    );
    expect(store.recoveryMessage, isNull);
    await app.main();
    await tester.pumpAndSettle();
    router.go('/notebook');
    await tester.pumpAndSettle();
    expect(find.byTooltip('Export all trials as CSV'), findsOneWidget);
    await capture(tester, binding, 'phase3-preserved-notebook');
    binding.reportData!['phase3Preservation'] = {
      'originalIdsReadable': expected.length,
      'totalReadableTrials': store.trials.length,
      'oldModelsReadable': true,
      'newLabsWithRecords': 18,
      'recoveryWarning': store.recoveryMessage,
    };
  });
}
